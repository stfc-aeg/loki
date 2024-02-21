import threading
import math
import csv
import logging
from contextlib import contextmanager

# tabulate module will give nicer results, but a rough table can be provided
try:
    from tabulate import tabulate
except ModuleNotFoundError:
    def tabulate(table, **kwargs):
        table.insert(1, ['-' * 20] * len(table[0]))
        rows = [('|').join([str(x)[:20].ljust(20) for x in tablerow]) for tablerow in table]
        return ('\n').join(rows)


class RegisterCache (object):
    def __init__(self, is_volatile, force_nocache=False):
        self._is_volatile = is_volatile
        self._value = None
        self._force_nocache = force_nocache

    def valid(self):
        return (self._is_volatile is False and
                self._value is not None and
                self._force_nocache is False)

    def get_value(self):
        # Return None if not available
        if self.valid():
            return self._value
        else:
            return None

    def set_value(self, value):
        self._value = value

    def enable_cache(self):
        self._force_nocache = False

    def disable_cache(self):
        self._force_nocache = True
        self._value = None

    def set_volatile(self):
        self._is_volatile = True


class Field (object):
    # A field is designed to hold a control / data value of grouped bits.
    # It can span several registers as long as the bits run into each other at the boundary.
    # Otherwise see MultiField.
    def __init__(self, controller, shortname, description, start_register_address, start_bit, length_bits, reversed_bits=False, is_subfield=False):
        self._controller = controller

        self.shortname = shortname
        self.description = description
        self.start_address = start_register_address
        self.start_bit = start_bit
        self.length_bits = length_bits
        self.reversed_bits = reversed_bits
        self.is_subfield = is_subfield

        self._controller._add_field(self)

    def __repr__(self):
        return '<field: {} at {}/{} length {}>'.format(
            self.shortname, self.start_address, self.start_bit, self.length_bits
        )

    def __lt__(self, other):
        # Operators are defined with respect to the location of the first bit
        if self.start_address != other.start_address:
            return self.start_address < other.start_address
        else:
            # Sorting via start bit is reversed, as MSB first
            return self.start_bit > other.start_bit

    def __mt__(self, other):
        # Operators are defined with respect to the location of the first bit
        if self.start_address != other.start_address:
            return self.start_address > other.start_address
        else:
            # Sorting via start bit is reversed, as MSB first
            return self.start_bit < other.start_bit

    def get_description(self):
        return self.description

    def _get_register_span(self):
        # Work out how many registers this field will span
        # overshoot is number of bits in the last register that are not part of this field.
        word_width = self._controller.get_word_width()

        # Length of field plus bits before start bit in first register, i.e. how far past
        # the start of the first register we read
        read_depth_bits = (word_width - (self.start_bit + 1)) + self.length_bits
        #print('read depth', read_depth_bits)

        # Registers spanned is determined by how many bits we aim to read
        registers_spanned = int((read_depth_bits-1) / word_width) + 1

        overshoot = (word_width - ((self.length_bits - (self.start_bit + 1)))) % word_width

        #print('field starting at bit {} length {} spans {} registers with overshoot {}'.format(
        #    self.start_bit, self.length_bits, registers_spanned, overshoot
        #))

        return registers_spanned, overshoot

    def read(self):
        # Read field value, potentially spanning multiple registers

        # Get all registers that contain parts of this field
        registers_spanned, overshoot = self._get_register_span()
        register_readback = self._controller.read_register(self.start_address, length=registers_spanned)
        #print('register readback: {}'.format([hex(x) for x in register_readback]))

        # Combine register values into single value, MSB first
        offset = self._controller.get_word_width() * (len(register_readback) - 1)
        combined_register_buffer = 0
        for regval in register_readback:
            combined_register_buffer |= (regval << offset)
            offset -= self._controller.get_word_width()
        #print('combined register buffer: {}'.format(hex(combined_register_buffer)))

        # Down shift so that field is now in LSBits
        shifted_buffer = int(combined_register_buffer >> overshoot)

        # Mask off any other bits (higher than the field)
        field_mask = int('1'*self.length_bits, 2)
        field_buffer = shifted_buffer & field_mask
        #print('field buffer: {}'.format(hex(field_buffer)))

        return field_buffer

    def write(self, value):
        # Write field value, potentially spanning multiple registers. Read-modify-write.

        if value >= math.pow(2, self.length_bits):
            raise Exception('writing beyond field boundary, is {} bits'.format(self.length_bits))

        # TODO need MUTEX PROTECTION HERE covering read and write

        # Get info for registers that contain parts of this field, read original values
        registers_spanned, overshoot = self._get_register_span()
        register_readback = self._controller.read_register(self.start_address, length=registers_spanned)

        # Combine register values into single value, MSB first
        offset = self._controller.get_word_width() * (registers_spanned - 1)
        combined_register_buffer = 0
        for regval in register_readback:
            combined_register_buffer |= (regval << offset)
            offset -= self._controller.get_word_width()
        #print('combined register buffer:', hex(combined_register_buffer))

        # Create a single value for the field, and shift it up to the correct offset for all registers
        field_shifted = value << overshoot

        # Mask shifted field onto the register values
        field_mask = int('1'*self.length_bits, 2) << overshoot
        modified_register_buffer = (combined_register_buffer & (~field_mask)) | field_shifted
        #print('modified register buffer:', hex(modified_register_buffer))

        # Write register values back
        work_mask = int('1'*self._controller.get_word_width(), 2)
        offset = self._controller.get_word_width() * (registers_spanned - 1)
        modified_register_buffer_list = []
        for i in range(registers_spanned):
            regval = (modified_register_buffer >> (offset)) & work_mask
            modified_register_buffer_list.append(regval)

            offset -= self._controller.get_word_width()

        # Write to registers
        self._controller.write_register(self.start_address, modified_register_buffer_list)


class MultiField (Field):
    # A field that is comprised of several sub-fields of bits in separate locations, treated as one entity.
    # This can be used where a field is made up of the MSBs of register n and LSBs of register n+1.

    def __init__(self, controller, shortname, description, fields_msbfirst: list, reversed_bits=False):
        self._fields = fields_msbfirst

        full_length = 0
        for field in self._fields:
            full_length += field.length_bits
            field.is_subfield = True

        super(MultiField, self).__init__(
            controller=controller,
            shortname=shortname,
            description=description,
            start_register_address=self._fields[0].start_address,
            start_bit=self._fields[0].start_bit,
            length_bits=full_length,
            reversed_bits=reversed_bits,
        )

    def __repr__(self):
        return '<multi field: {} : {}>'.format(
            self.shortname, [fld.__repr__() for fld in self._fields]
        )

    def read(self):
        # The output value will be assembled bitwise from other fields
        assembly_buffer = int()

        # Loop through fields MSBit to LSBit
        start_offset = self.length_bits
        for field in self._fields:
            # Read the individual field and insert into buffer
            field_readval = field.read()
            assembly_buffer = assembly_buffer | (field_readval << (start_offset-field.length_bits) )

            start_offset -= field.length_bits

        return assembly_buffer

    def write(self, value):
        # The written value will be split bitwise into multiple fields, written individually
        # (inefficient, but probably the best way of doing it).

        # Loop through fields MSBit to LSBit
        start_offset = self.length_bits
        for field in self._fields:
            # Retrieve the sub-field value from the entire value
            field_mask = int('1'*field.length_bits, 2)
            value_shifted = value >> (start_offset-field.length_bits)
            value_masked = value_shifted & field_mask

            # Write the sub-field
            field.write(value_masked)

            start_offset -= field.length_bits


class RegisterController (object):
    def __init__(self, func_readreg, func_writereg, word_width_bits, cache_enabled=True):
        # If cache_enabled is True, traffic will be minimised by returning known values
        # of registers from last read/write. This takes into account volatility,
        # so that registers can contain bits that are always read back directly. Setting
        # this false will mean every read/write will interact with the bus, meaning more
        # traffic.

        self._logger = logging.getLogger('REGISTER_CONTROLLER')

        # Assign direct SPI access registers, used internally only. Any chip specifics
        # such as page switching for upper addresses shall be defined by the caller.
        self._read_register_direct = func_readreg
        self._write_register_direct = func_writereg

        self._word_width_bits = word_width_bits

        # Create lock used to protect register cache and SPI access with
        # critical sections
        self._register_mutex = threading.RLock()
        #todo actually use this

        # Create register cache, which will be a dictionary of addressed registers, where
        # address is not strongly typed (but must be compatible with direct functions).
        self._register_cache = {}
        self._cache_enabled = cache_enabled

        # Create the field dictionary, indexed by unique names.
        # Cached field values rely on the register cache.
        self._fields = {}

        self.stats_reset()

    # Allow the register controller to expose an acquire() method that can be used with 'with' to
    # protect access to derived classes. This is not REQUIRED for use, as the mutex is already used
    # internallly to protect between separate transactions (supporting fields, multifields etc).
    @contextmanager
    def acquire(self, blocking=True, timeout=-1):
        # Grab the lock with the supplied settings
        result = self._register_mutex.acquire(blocking=blocking, timeout=timeout)

        # Allow the caller to execute their 'with'. 'result' is needed so that
        # if the lock cannot be grabbed the user can handle it.
        yield result

        # Release the lock, if it was actually acquired
        if result:
            self._register_mutex.release()

    def get_word_width(self):
        return self._word_width_bits

    def add_register(self, address, is_volatile):
        register_cache = RegisterCache(bool(is_volatile), force_nocache=not(self._cache_enabled))
        self._register_cache.update({address: register_cache})

    def _add_field(self, field: Field):
        self._fields.update({field.shortname: field})

    def _create_registers_for_field(self, field, is_volatile):
        # Get the registers this field will operate on
        register_span, overshoot = field._get_register_span()
        required_registers = range(field.start_address, field.start_address + register_span)

        for register_address in required_registers:
            # Add the registers if they do not exist
            if self._register_cache.get(register_address) is None:
                self._logger.info('register {} does not exist, creating...'.format(register_address))
                self.add_register(register_address, is_volatile)

    def add_field(self, shortname, description, start_register_address, start_bit, length_bits, reversed_bits=False, is_volatile=True):
        # Fields are volatile by default so that they will always be read back if the
        # caching is enabled.
        current_field = Field(
            controller=self,
            shortname=shortname,
            description=description,
            start_register_address=start_register_address,
            start_bit=start_bit,
            length_bits=length_bits,
            reversed_bits=reversed_bits,
            is_subfield=False,              # This will be set by multifield
        )

        self._create_registers_for_field(current_field, is_volatile)

        return current_field

    def add_multifield(self, shortname, description, fields_msbfirst: list, reversed_bits=False):
        current_field = MultiField(
            controller=self,
            shortname=shortname,
            description=description,
            fields_msbfirst=fields_msbfirst,
            reversed_bits=reversed_bits
        )

        # Creating registers for a multifield is not necessary, as it will be done when
        # creating sub-fields

        return current_field

    def read_register(self, start_address, length=1, direct_read=False):
        # Return the cached value unless it is invalid, in which case SPI is used
        # If direct_read is False, cache will always be ignored for this read

        with self.acquire(blocking=True, timeout=1) as mutex_rslt:
            if not mutex_rslt:
                raise Exception('Failed to get register controller mutex')

            # Attempt cache read
            cached_values = []
            for address in range(start_address, start_address+length):
                try:
                    regcache = self._register_cache[address].get_value()
                    cached_values.append(regcache)
                except Exception as e:
                    # If failed to get any cached value, abort
                    cached_values.append(None)

            # If any registers had no valid cache, read the values directly
            if None in cached_values or direct_read:
                #print('Failed to use cache, reading directly')
                try:
                    direct_read_values = self._read_register_direct(start_address, length)
                except Exception as e:
                    # Failed to read the direct interface of the device
                    self._stats_record_failread()
                    self._logger.error('Attempted a direct read of register 0x{}, failed: {}'.format(hex(start_address), e))
                    raise

                # Cache the values
                for i in range(length):
                    self._register_cache[start_address+i].set_value(direct_read_values[i])

                latest_values = direct_read_values
                self._stats_record_directread()
                self._logger.debug('Made a direct read to ASIC register 0x{}'.format(hex(start_address)))
            else:
                latest_values = cached_values
                self._stats_record_cachedread()

            return latest_values

    def write_register(self, start_address, values):
        # Write to the array as a whole register (single operation), and cache for later use

        with self.acquire(blocking=True, timeout=1) as mutex_rslt:
            if not mutex_rslt:
                raise Exception('Failed to get register controller mutex')

            # Write direct
            try:
                self._write_register_direct(start_address, values)
            except Exception as e:
                self._logger.error('Attempted a write of register 0x{}, failed: {}'.format(hex(start_address), e))
                raise

            # Cache the written values
            for i in range(len(values)):
                self._register_cache[start_address+i].set_value(values[i])


    def _stats_record_directread(self):
        # Record a register read operation that used the direct interface
        self._stats_direct += 1

    def _stats_record_cachedread(self):
        # Record a register read operation that used the cached value
        self._stats_cached += 1

    def _stats_record_failread(self):
        self._stats_failed += 1

    def stats_reset(self):
        self._stats_direct = 0
        self._stats_cached = 0
        self._stats_failed = 0

    def stats_cached_direct(self):
        return (self._stats_cached, self._stats_direct)

    def stats_failed(self):
        return self._stats_failed

    def _get_field(self, name):
        return self._fields[name]

    def get_fields(self):
        return list(self._fields.keys())

    def read_field(self, fieldname):
        with self.acquire(blocking=True, timeout=1) as mutex_rslt:
            if not mutex_rslt:
                raise Exception('Failed to get register controller mutex')

            return self._get_field(fieldname).read()

    def write_field(self, fieldname, value):
        with self.acquire(blocking=True, timeout=1) as mutex_rslt:
            if not mutex_rslt:
                raise Exception('Failed to get register controller mutex')

            self._get_field(fieldname).write(value)


    def summarise_fields(self, address_range=None, ignore_subfields=True, additional_decode=None):
        # Pretty-print a table of field information for fields starting within the given
        # register range. If address_range=None, list all registers. Subfields are ignored
        # by default so that table prints out top-level understanding.

        # additional_decode allows the user to provide a function that will further decode
        # field value for all fields in the range. This will add an additional column.
        # This function will be provided two arguments: <field shortname>, <value>

        table = [['Name', 'Description', 'Start Address', 'Start Bit', 'Length', 'Value', 'Value (Hex)']]

        if additional_decode:
            table[0].append('Decoded')

        for field in sorted(list(self._fields.values())):
            if address_range is None or field.start_address in address_range:
                if ignore_subfields and field.is_subfield:
                    continue

                # Attempt to read current value
                try:
                    value = field.read()
                except Exception as e:
                    value = 'ReadErr'

                newrow = [
                    field.shortname,
                    field.description[:30],
                    field.start_address,
                    field.start_bit,
                    field.length_bits,
                    value,
                    hex(value),
                ]

                if additional_decode:
                    if type(value) is int:
                        newrow.append(additional_decode(field.shortname, value))
                    else:
                        newrow.append(value)    # Read error

                table.append(newrow)

        return tabulate(table, headers='firstrow', tablefmt='fancy_grid')

    def enable_cache(self):
        self._cache_enabled = True

        # Enable cache for each register
        for address in self._register_cache.keys():
            self._register_cache[address].enable_cache()

        self._logger.warning('Cache Enabled')

    def disable_cache(self):
        self._cache_enabled = False

        # Diable cache for each register, and reset the cached value
        for address in self._register_cache.keys():
            self._register_cache[address].disable_cache()

        self.stats_reset()

        self._logger.warning('Cache Disabled')

    def cache_enabled(self):
        return self._cache_enabled

    def clear_cache(self):
        # To be called when it is known that the cache is invalid, and stored
        # values should not be trusted. For example, on ASIC reset.
        # Will leave cache enable state in whatever state it was in before this
        # was called.
        prev_enabled = self.cache_enabled()
        self.disable_cache()

        if prev_enabled:
            self.enable_cache()

        self._logger.warning('Cache Cleared')


    def process_csv_fields(self, csv_filename):
        # Take input CSV file for defining fields and registers.
        # Registers will be created automatically if they do not exist, and will be set
        # volatile if any field is volatile.

        # For multifields, populate the subfields key.

        # CSV format:
        # <shortname>, <description>, <startreg>, <startbit>, <length>, <subfields>, <volatile>
        # where <subfields> is defined as: "shortname1, shortname2, shortname3" or ""


        with open(csv_filename, newline='') as csvfile:
            csvreader = csv.reader(csvfile, delimiter=',', quotechar='"')
            for row in csvreader:
                if len(row) == 0:
                    # blank line
                    continue

                try:
                    subfields = row[5].strip()
                    is_multifield = bool(len(subfields) > 0)

                    if is_multifield:
                        # This is a MultiField
                        # We must assume that the subfields have been created already
                        # Therefore the registers will be handled

                        required_subfields = [self._get_field(fldname.strip()) for fldname in subfields.split(',')]

                        currentfield = self.add_multifield(
                            shortname=row[0],
                            description=row[1],
                            fields_msbfirst=required_subfields,
                        )

                        self._logger.debug('Added field {} comprised of {}'.format(
                            currentfield.shortname,
                            currentfield._fields,
                        ))

                    else:
                        # This is a Field

                        is_volatile = row[6].strip() == 'True'

                        currentfield = self.add_field(
                            shortname=row[0],
                            description=row[1],
                            start_register_address=int(row[2]),
                            start_bit=int(row[3]),
                            length_bits=int(row[4]),
                            is_volatile=is_volatile,
                        )

                        self._logger.debug('Added {} field {} to register {}/{} len {}'.format(
                            'volatile' if is_volatile else 'non-volatile',
                            currentfield.shortname,
                            currentfield.start_address,
                            currentfield.start_bit,
                            currentfield.length_bits,
                        ))
                except Exception as e:
                    self._logger.error('Failed to decode CSV on row {}: {}'.format(row, e))
                    raise (e)
