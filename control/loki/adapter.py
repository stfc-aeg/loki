from tornado.ioloop import IOLoop
# from tornado.escape import json_decode
# from odin.adapters.adapter import ApiAdapter, ApiAdapterResponse, request_types, response_types, wants_metadata
from odin.adapters.async_adapter import AsyncApiAdapter
# from odin._version import get_versions
from odin.adapters.parameter_tree import ParameterTreeError
from odin.adapters.parameter_tree import ParameterTree

import logging
import gpiod
import time
import concurrent.futures as futures

from abc import ABC, abstractmethod

'''
Current methods to include in an application project:
    1. Use default LokiAdapter (more robust, reccommended)
        For this method, construct an adapter for the application specifics, and interface with the LokiAdapter
        using inter-adapter communication to operate the carrier, and obtain carrier-specific interfaces for
        application use such as I2C buses, SPI buses, GPIO lines. Use pre-provided control functions where
        possible. This will also use default LokiCarrier support classes.

        This is the better option when using next generation carriers, or if using the TEBF0808 without anticipating
        later moving to the next gen carrier.

    2. Derive a custom LokiAdapter (fragile, last resort)
        Construct a class derived from LokiAdapter and re-implement the instantiate_carrier() function to allow
        support for a custom LokiCarrier class to be used. This will involve more work, and will break if the
        base LokiCarrier class changes significantly. However, may be a reasonable choice if the carrier classes
        available do not provide functionality to match the hardware in use.

        Most likely required if using the original TEBF0808 carrier, but only where hardware present on that board
        is similar to that expected by the LOKI Carrier and when anticipated pathway is to move to the next gen carrier.

        This does have the benefit that IF the LokiCarrier derived class interface matches the one for the next gen
        carrier THEN it should be very easy to substitute them.

        Seen LokiAdapter_MERCURY and LokiCarrier_TEBF0808_MERCURY.

'''


class LokiAdapter(AsyncApiAdapter):

    def __init__(self, **kwargs):
        # Init superclass
        super(LokiAdapter, self).__init__(**kwargs)

        # Determine carrier class sub-type (case insensitive)
        carrier_type = self.options.get('carrier_type').lower()
        self.instantiate_carrier(carrier_type)

        # Start asynchronous update loops
        self._slow_delay = self.options.get('slow_update_delay_s', 1.0)
        self._deadslow_delay = self.options.get('deadslow_update_delay_s', 5.0)
        self.slow_update_loop()
        self.deadslow_update_loop()

        logging.debug("LOKI adapter loaded")

    def slow_update_loop(self):
        self._carrier.event_slow_update()
        IOLoop.instance.call_later(self._slow_delay, self.slow_update_loop)

    def deadslow_update_loop(self):
        self._carrier.event_deadslow_update()
        IOLoop.instance.call_later(self._deadslow_delay, self.deadslow_update_loop)

    def instantiate_carrier(self, carrier_type):
        # Create the underlying carrier instance. If the application absolutely requires a different carrier class,
        # create a child adapter and derive a carrier from one of the existing ones, then re-implement this function.
        # Be carefule that the new carrier's parameter tree follows pattern of the existing ones.
        if carrier_type == 'tebf0808':
            # This is the generic TEBF0808 support class. It has limited external support.
            self._carrier = LokiCarrier_TEBF0808(self.options)
        elif carrier_type == 'loki_1v0':
            self._carrier = LokiCarrier_1v0(self.options)
        else:
            raise Exception('Unsupported carrier_type {}'.format(carrier_type))

    # todo adapter will basically just include redirect functions for get and set, potentially the 'loops'


# todo note SOMEWHERE that when including LokiCarrier as well as extensions, it must be last for the MRO to work. It's also optional is it's auto included by the extensions anyway. Or create a custom warning somehow (the better solution).
class LokiCarrier(ABC):
    # Generic LOKI carrier support class. Lays out the structure that should be used
    # for all child carrier definitions.

    # todo ideally the base class should avoid refferring to specific devices in its external interfaces.

    def __init__(self, **kwargs):
        self._supported_extensions = []

        # Set the default configuration for generic control pins
        self._config_pin_defaults(kwargs)

        # Request all pins configured for the device, including those for extension classes, using options
        self._pin_handler = LokiCarrier.PinHandler(self.variant)
        self._pin_handler.add_pins_from_options(kwargs)

        print('Pin mappings settled:')
        self._pin_handler.pinmap()

        # Construct the parameter tree (will call extensions automatically)
        self._paramtree = ParameterTree(self._gen_paramtree_dict())

        # todo set up a logger

        # Check that other info, like bus numbers is provided by child, otherwise throw error.
        # todo

        # Get the current state of the enables before starting the state machines
        # todo

        # Create device handlers but do not init
        # todo

        # Set up state machines and timer loops (potentially in carrier)
        # todo, consider moving base call into adapter for once other adapters are initialised
        print('starting IO loops')
        self._start_io_loops(kwargs)
        print('IO loops started')

    def _start_io_loops(self, options):
        # This function can be extended by the extension LokiCarrier classes if they would benefit from async loops.
        # However, make sure that super is called in each.
        self._thread_executor = futures.ThreadPoolExecutor(max_workers=None)

        self._thread_gpio = self._thread_executor.submit(self._loop_gpiosync)
        self._thread_ams = self._thread_executor.submit(self._loop_ams)

    def _loop_gpiosync(self):
        while True:
            self._pin_handler.sync_pin_value_cache()
            time.sleep(0.1)

    def _loop_ams(self):
        while True:
            self._get_zynq_ams_temps_raw()
            time.sleep(5)

    @property
    @abstractmethod
    def variant(self):
        pass

    class PinHandler():
        # Class designed to separate off as much gpiod logic as possible, so that later upgrades to libgpiod2
        # are easier. Pins in the code are accessed by friendlier names, distinct from the IDs.
        # This driver can coexist with any other gpiod handling of pins, so is kept simple by only using the
        # flag for active_low. If additional functionality is required (e.g. events) implement separately.

        def __init__(self, consumername='LOKI'):
            self._pins = {}
            self._pin_states_cached = {}
            self._consumername = consumername

        # If id is a string, use gpiod.find_line to get the pin, otherwise use typical gpiod.get_line.
        @staticmethod
        def _gpiod_line_from_id(line_id):

            if line_id is None:
                return None

            try:
                # gpiochip0 is assumed since it is the only available chip on the ZynqMP platform
                chip = gpiod.Chip('gpiochip0')
                return chip.get_line(int(line_id))
            except ValueError:
                return gpiod.find_line(line_id)

        def get_pin(self, friendly_name):
            try:
                return self._pins[friendly_name]
            except KeyError:
                raise KeyError('Could not find a requested pin with friendly name {}'.format(friendly_name))

        def get_pin_names(self):
            return self._pins.keys()

        def is_pin_input(self, friendly_name):
            pin = self.get_pin(friendly_name)
            return pin.direction() == pin.DIRECTION_INPUT

        def sync_pin_value_cache(self, sync_output_pins=False):
            # Updates the cached pin values from gpio lines directly. Works only for input pins by default,
            # unless sync_output_pins=True is set. Should ideally be called by an asynchronous update loop.
            for pin_name in self._pins.keys():
                # By default, only syncs the inputs pins, unless sync_output_pins is specified
                if self.is_pin_input(pin_name) or sync_output_pins:
                    self._pin_states_cached.update({pin_name: self.get_pin(pin_name).get_value()}) 

        def get_pin_value(self, friendly_name):
            # Inputs pins should always be read, as they can change value without intervention. Outputs should
            # prioritise a cached value if available.

            # todo update this to make all input pins read on a loop somehow, and cached...

            if self.is_pin_input(friendly_name) or self._pin_states_cached.get(friendly_name) is None:
                # Read from the pin and cache the result for next time (ignored for input mode)
                latest_value = self.get_pin(friendly_name).get_value()
                self._pin_states_cached[friendly_name] = latest_value
                return latest_value
            else:
                # If there is a cached value, use it without reading the pin
                return self._pin_states_cached.get(friendly_name)

        def set_pin_value(self, friendly_name, value):
            # If in input mode, raise an error
            if not self.is_pin_input(friendly_name):
                # Set the pin and cache for later
                self.get_pin(friendly_name).set_value(value)
                self._pin_states_cached[friendly_name] = value
            else:
                raise Exception('Cannot set an input pin')

        def add_pin(self, friendly_name, pin_id, is_input, is_active_low=False):
            # Check if the name is already in use
            if self._pins.get(friendly_name) is not None:
                raise RuntimeError('pin friendly name {} already exists for {}, cannot use again for ID {}'.format(
                    friendly_name, self._pins[friendly_name], pin_id))

            # Find the line from its id
            line = self._gpiod_line_from_id(pin_id)
            if line is None:
                raise RuntimeError('could not find matching gpiod line for id {} (for pin name {})'.format(
                    pin_id, friendly_name))

            # Request the pin with given settings
            line.request(
                consumer=self._consumername,
                type=(gpiod.LINE_REQ_DIR_IN if is_input else gpiod.LINE_REQ_DIR_OUT),
                flags=(gpiod.LINE_REQ_FLAG_ACTIVE_LOW if is_active_low else 0),
                default_val=0)

            # Store the pin by friendly name
            self._pins[friendly_name] = line

        @staticmethod
        def _sort_options_per_pin(options):
            # Create a dictionary of only the pin-config tags, strip prefix
            # example keys before: pin_config_id_<friendly_name>
            # example keys after: id_<friendly_name>
            pin_config_prefix = 'pin_config_'
            pin_config_options = {}
            for key in options.keys():
                if key.startswith(pin_config_prefix):
                    pin_config_options[key[len(pin_config_prefix):]] = options[key]

            # Separate options by the pin friendly name they refer to
            config_by_pin = {}
            allowed_settings = ['id', 'active_low', 'nc', 'is_input']
            for key in pin_config_options.keys():
                # Settings not in the list are ignored
                for allowed_setting in allowed_settings:
                    if key.startswith(allowed_setting):
                        # Remove the setting prefix and the additional underscore
                        pin_name = key[len(allowed_setting) + 1:]

                        # Add the pin to the dictionary if it does not exist
                        config_by_pin.setdefault(pin_name, {})

                        # Add the currently found setting for this pin
                        config_by_pin[pin_name].update({allowed_setting: pin_config_options[key]})

            return config_by_pin

        def add_pins_from_options(self, options):
            # Parse the options and extract pin configuration, separated by pin friendly name
            config_by_pin = self._sort_options_per_pin(options)

            # Add each pin that has configuration information
            for pin_name in config_by_pin.keys():

                pin_info = config_by_pin[pin_name]

                try:
                    pin_id = pin_info.get('id')
                    pin_active_low = pin_info.get('active_low')
                    pin_is_input = pin_info.get('is_input')
                    pin_not_connected = pin_info.get('nc', False)   # This is optional, assumed pins are connected
                except KeyError as e:
                    raise KeyError('Not enough information to register pin {}: {}'.format(pin_name, e))

                # If a pin is overridden to 'nc' it is assumed that it will not be used by anything.
                # As such, it will be ignored and not added to the accessible pins.
                if not pin_not_connected:
                    self.add_pin(pin_name, pin_id, pin_is_input, pin_active_low)

        def pinmap(self):
            # Print out the current pinmap
            for pin_name in self.get_pin_names():
                print('{}: {}'.format(pin_name, self.get_pin(pin_name)))

    def _config_pin_defaults(self, options):
        # todo remove super(LokiCarrier, self)._config_pin_defaults(options)
        # Sets default configuration variables for control pins. Only take effect if they have not already
        # been defined by the options file or an extension / derived class. The friendly name will be used
        # in the parameter tree and elsewhere for accessing the pin after configuration.

        # Pin configuration options available:
        #
        #   pin_config_id_<friendly_name> <ID>
        #       Specify the gpiod pin ID (either name or number) that will be associated with the
        #       given friendly name. Required.
        #
        #   pin_config_is_input_<friendly_name> <True/False>
        #       Specify if the pin is an input or output. Required.
        #
        #   pin_config_active_low_<friendly_name> <True/false>
        #       Spefify if the pin is active high or low. Required.
        #
        #   pin_config_nc_<friendly_name> <True/False>
        #       Set to True if the pin should not be requested. Use to disable a pin. Optional.

        # Makes the listing of defaults a bit more succinct and clear
        def set_pin_options(friendly_name, pin_id, is_input, active_low):
            options.setdefault('pin_config_id_' + friendly_name, pin_id)
            options.setdefault('pin_config_is_input_' + friendly_name, is_input)
            options.setdefault('pin_config_active_low_' + friendly_name, active_low)

        # Set defaults for generic control pins, use gpiod pin names from device tree rather than numbers
        set_pin_options('app_present',      'APP nPRESENT',         is_input=True,  active_low=True)
        set_pin_options('bkpln_present',    'BACKPLANE nPRESENT',   is_input=True,  active_low=True)
        set_pin_options('app_rst',          'APPLICATION nRST',     is_input=False, active_low=True)
        set_pin_options('per_rst',          'PERIPHERAL nRST',      is_input=False, active_low=True)

    def _gen_paramtree_dict(self):

        base_tree_dict = {
            'carrier_info': {
                'variant': (lambda: self.variant, None, {"description": "Carrier variant"}),
                'extensions': (self.get_avail_extensions, None, {"description": "Comma separated list of carrier's supported extensions"}),
            },
            'control': {
                'application_enable': (self.get_app_enabled, self.set_app_enabled, {
                    "description": "Enable the application",
                }),
                'peripherals_enable': (self.get_peripherals_enabled, self.set_peripherals_enabled, {
                    "description": "Enable the application",
                }),
                'presence_detection': {
                    'application': (self.get_app_present, None, {
                        "description": "True if the application is mounted",
                    }),
                    'backplane': (self.get_backplane_present, None, {
                        "description": "True if the backplane is mounted",
                    }),
                },
            },
            'user_interaction': {
            },
            'environment': {
                'temperature': {
                    'zynq_pl': (lambda: self.get_zynq_ams_temp_cached('2_pl'), None, {
                        "description": "Zynq SoC Programmable Logic Temperature",
                        "units": "C",
                    }),
                    'zynq_ps': (lambda: self.get_zynq_ams_temp_cached('0_ps'), None, {
                        "description": "Zynq SoC Processing System Temperature",
                        "units": "C",
                    }),
                    'zynq_remote': (lambda: self.get_zynq_ams_temp_cached('1_remote'), None, {
                        "description": "Zynq SoC Remote (?) Temperature",
                        "units": "C",
                    }),
                },
                'humidity': {},
            },
        }

        print('Base tree generated')    # todo remove or make debug

        return base_tree_dict

    def get_avail_extensions(self):
        return ', '.join(self._supported_extensions)

    def get(self, path, wants_metadata=False):
        """Main get method for the parameter tree"""
        try:
            return self._paramtree.get(path, wants_metadata)
        except AttributeError:
            raise ParameterTreeError

    def set(self, path, data):
        """Main set method for the parameter tree"""
        try:
            return self._paramtree.set(path, data)
        except AttributeError:
            raise ParameterTreeError

    ########################################
    # Built-in Zynq Temperature Monitoring #
    ########################################

    def get_zynq_ams_temp_cached(self, temp_name):
        # These AMS temperatures should by synced by the deadslow loop. Latest readings returned externally.
        # todo hasattr is kind of a dirty fix
        if hasattr(self, '_zynq_ams'):
            return self._zynq_ams.get(temp_name)
        else:
            return None

    def _get_zynq_ams_temp_raw(self, temp_name):
        with open('/sys/bus/iio/devices/iio:device0/in_temp{}_temp_raw'.format(temp_name), 'r') as f:
            temp_raw = int(f.read())

        with open('/sys/bus/iio/devices/iio:device0/in_temp{}_temp_offset'.format(temp_name), 'r') as f:
            temp_offset = int(f.read())

        with open('/sys/bus/iio/devices/iio:device0/in_temp{}_temp_scale'.format(temp_name), 'r') as f:
            temp_scale = float(f.read())

        return round(((temp_raw + temp_offset) * temp_scale) / 1000, 2)

    def _get_zynq_ams_temps_raw(self):
        # todo call this in deadslow loop
        if not hasattr(self, '_zynq_ams'):
            self._zynq_ams = {}
        for ams_name in ['0_ps', '1_remote', '2_pl']:
            self._zynq_ams[ams_name] = self._get_zynq_ams_temp_raw(ams_name)

    #############################
    # Application Control Lines #
    #############################

    def get_backplane_present(self):
        return bool(self._pin_handler.get_pin_value('bkpln_present'))

    def get_app_present(self):
        return bool(self._pin_handler.get_pin_value('app_present'))

    def set_app_enabled(self, enable=True):
        return bool(self._pin_handler.set_pin_value('app_rst', not enable))

    def get_app_enabled(self):
        return not bool(self._pin_handler.get_pin_value('app_rst'))

    def set_peripherals_enabled(self, enable=True):
        return bool(self._pin_handler.set_pin_value('per_rst', not enable))

    def get_peripherals_enabled(self):
        return not bool(self._pin_handler.get_pin_value('per_rst'))

    # Provide access to carrier-specific interfaces for application use, via inter-adapter communication

    def get_interface_spi(self):
        # Returns a dictionary of buses to be used by the application. At least implement 'APP' and 'PERIPHERAL'.
        # Each key is a string name, each value is a bus number.
        raise Exception('Not implemented in base carrier adapter')

    def get_interface_i2c(self):
        # Returns a dictionary of buses to be used by the application. At least implement 'PERIPHERAL'.
        raise Exception('Not implemented in base carrier adapter')


########
# LEDs #
########

class LokiCarrierLEDs(LokiCarrier, ABC):
    # Does not actually handle the requesting of lines, but assumes this to already have been completed by the main
    # gpio request procedure in LokiCarrier. Instead, this code provides the interface to a subset of pins and associates
    # them with friendlier names that might be found on the PCBs for easier use.

    def __init__(self, **kwargs):
        # Call next in MRO / Base Class
        super(LokiCarrierLEDs, self).__init__(**kwargs)

        self._supported_extensions.append('leds')

    def _config_pin_defaults(self, options):
        super(LokiCarrierLEDs, self)._config_pin_defaults(options)

        # All 'leds' will be outputs, active low (can be overridden in carrier init before super init).
        for friendly_name in self.leds_namelist:
            # Assume that the ID has already been set in the carrier
            options.setdefault('pin_config_is_input_' + friendly_name, False)
            options.setdefault('pin_config_active_low_' + friendly_name, True)  # Override if necesary

    def _gen_paramtree_dict(self):
        base_tree = super(LokiCarrierLEDs, self)._gen_paramtree_dict()

        # Create the new key if it does not exist for the sensor type, with a blank dictionary
        base_tree['user_interaction'].setdefault('leds', {})

        # Add each LED with its friendly name to the parameter tree
        for friendly_name in self.leds_namelist:
            base_tree['user_interaction']['leds'][friendly_name] = (
                (lambda friendly_name_internal: lambda: self.leds_get_led(friendly_name_internal))(friendly_name),
                (lambda friendly_name_internal: lambda value: self.leds_set_led(friendly_name_internal, bool(value)))(friendly_name),
                {"description": "LED control"}
            )

        return base_tree

    # LED setting is just gpio interaction, therefore does not need custom implementation per carrier
    def leds_get_led(self, friendly_name):
        return self._pin_handler.get_pin_value(friendly_name)

    def leds_set_led(self, friendly_name, value):
        return self._pin_handler.set_pin_value(friendly_name, value)

    # List of present leds (friendly names).
    # Every entry should have pin_config_id_<friendly_name> set in the carrier, as well as any other options
    # that are different to the LED defaults (active low, output).
    @property
    @abstractmethod
    def leds_namelist(self):
        pass


###########
# Buttons #
###########

class LokiCarrierButtons(LokiCarrier, ABC):
    # Does not actually handle the requesting of lines, but assumes this to already have been completed by the main
    # gpio request procedure in LokiCarrier. Instead, this code provides the interface to a subset of pins and associates
    # them with friendlier names that might be found on the PCBs for easier use.

    def __init__(self, **kwargs):
        # Call next in MRO / Base Class
        super(LokiCarrierButtons, self).__init__(**kwargs)

        self._supported_extensions.append('buttons')

    def _config_pin_defaults(self, options):
        super(LokiCarrierButtons, self)._config_pin_defaults(options)

        # All 'buttons' will be inputs, active low (can be overridden in carrier init before super init).
        for friendly_name in self.buttons_namelist:
            # Assume that the ID has already been set in the carrier
            options.setdefault('pin_config_is_input_' + friendly_name, True)
            options.setdefault('pin_config_active_low_' + friendly_name, True)  # Override if necesary

    def _gen_paramtree_dict(self):
        base_tree = super(LokiCarrierButtons, self)._gen_paramtree_dict()

        # Create the new key if it does not exist for the sensor type, with a blank dictionary
        base_tree['user_interaction'].setdefault('buttons', {})

        # Add each button with its friendly name to the parameter tree
        for friendly_name in self.buttons_namelist:
            base_tree['user_interaction']['buttons'][friendly_name] = (
                (lambda friendly_name_internal: lambda: self.leds_get_led(friendly_name_internal))(friendly_name),
                None,
                {"description": "Carrier button state"}
            )

        return base_tree

    # Button reading is just gpio interaction, therefore does not need custom implementation per carrier
    def buttons_get_button(self, friendly_name):
        return self._pin_handler.get_pin_value(friendly_name)

    # List of present buttons (friendly names).
    # Every entry should have pin_config_id_<friendly_name> set in the carrier, as well as any other options
    # that are different to the button defaults (active low, input).
    @property
    @abstractmethod
    def buttons_namelist(self):
        pass


####################
# Clock Generation #
####################

class LokiCarrierClockgen(LokiCarrier, ABC):
    def __init__(self, **kwargs):
        # Call next in MRO / Base Class
        super(LokiCarrierClockgen, self).__init__(**kwargs)

        self.__clkgen_default_config = kwargs.get('clkgen_default_config')
        # todo Use this after init later on

        # todo register the device with the carrier power control system

        self._supported_extensions.append('clkgen')

    def _gen_paramtree_dict(self):
        base_tree = super(LokiCarrierClockgen, self)._gen_paramtree_dict()

        base_tree['clkgen'] = {
            'drivername': (lambda: self.clkgen_drivername, None, {"description": "Name of the device providing clock generator support"}),
            'num_outputs': (lambda: self.clkgen_numchannels, None, {"description": "Number of output channels available"}),
            'config_file': (self.clkgen_get_config, self.clkgen_set_config, {"description": "Current configuration file loaded for clock config"}),
            'config_files_avail': (self.clkgen_get_config_avail, None, {"description": "Available config files to choose from"}),
        }

        return base_tree

    @property
    @abstractmethod
    def clkgen_drivername(self):
        pass

    @property
    @abstractmethod
    def clkgen_numchannels(self):
        pass

    @abstractmethod
    def clkgen_set_config(self, filename):
        pass

    @abstractmethod
    def clkgen_get_config(self):
        pass

    @abstractmethod
    def clkgen_get_config_avail(self):
        pass


#######
# DAC #
#######

class LokiCarrierDAC(LokiCarrier, ABC):
    def __init__(self, **kwargs):
        # Call next in MRO / Base Class
        super(LokiCarrierDAC, self).__init__(**kwargs)

        self._supported_extensions.append('dac')

    def _gen_paramtree_dict(self):
        base_tree = super(LokiCarrierDAC, self)._gen_paramtree_dict()

        output_tree = {}
        # This property is enforced as generated by the child
        # this probably won't work, see how I did it with the firefly channels before (double lambda...)
        for output_num in range(0, self.dac_num_outputs):
            output_tree[str(output_num)] = (
                # Protect the scope of output_num_internal so that it does not change between loops
                (lambda output_num_internal: lambda: self.dac_get_output(output_num_internal))(output_num),
                (lambda output_num_internal: lambda voltage: self.dac_set_output(output_num_internal, voltage))(output_num),
                {"description": "Get / Set DAC output value", "units": "v"}
            )

        base_tree['dac'] = {
            'drivername': (
                lambda: self.dac_drivername,
                None,
                {"description": "Name of the device providing clock generator support"}
            ),
            'num_outputs': (
                lambda: self.dac_num_outputs,
                None,
                {"description": "Number of output channels available"}
            ),
            'outputs': output_tree,
        }

        return base_tree

    @property
    @abstractmethod
    def dac_drivername(self):
        pass

    @property
    @abstractmethod
    def dac_num_outputs(self):
        pass

    @abstractmethod
    def dac_set_output(self, output_num, voltage):
        pass

    @abstractmethod
    def dac_get_output(self, output_num):
        pass


########################################
# Temperature  and Humidity Monitoring #
########################################

class LokiCarrierEnvmonitor(LokiCarrier, ABC):
    def __init__(self, **kwargs):
        # Call next in MRO / Base Class
        super(LokiCarrierEnvmonitor, self).__init__(**kwargs)

        self._supported_extensions.append('envmonitor')

    def _gen_paramtree_dict(self):
        base_tree = super(LokiCarrierEnvmonitor, self)._gen_paramtree_dict()

        # Expects this to be a list of (name, type, unit) tuples.
        # Type is typically 'temperature' or 'humidity'.
        # info is the dictionary passed to the paramtree including description, units etc.
        additional_sensors = self.env_sensor_info
        for (name, sType, info) in additional_sensors:
            # Create the new key if it does not exist for the sensor type, with a blank dictionary
            base_tree['environment'].setdefault(sType, {})

            # Add the sensor entry with its specific info, protecting scope of name_internal
            base_tree['environment'][sType] = ((lambda name_internal: lambda: self.env_get_sensor(name_internal))(name), None, info)

        return base_tree

    # dict, see above
    @property
    @abstractmethod
    def env_additional_sensors(self):
        pass

    # Get the (cached) version of a sensor reading that can be read as often as desired
    @abstractmethod
    def env_get_sensor(self, name):
        pass


class LokiCarrier_TEBF0808(LokiCarrierLEDs, LokiCarrier):
    # Special case; as a prototype with minimal support for devices alone. Should be combined with an
    # application-specific adapter for the associated daughter board, which relies on interfaces provided
    # by this adapter (buses, GPIO pins). This second adapter will need to implement things like clock
    # config, etc.

    variant = 'tebf0808'
    leds_namelist = ['led0']

    def __init__(self, **kwargs):
        # Set the pin for LED0 to on-board LED, unless already overridden in settings
        kwargs.setdefault('pin_config_id_led0', 'MIO40')

        super(LokiCarrier_TEBF0808, self).__init__(**kwargs)


#############################################
# Carrier Class for Next Generation Carrier #
#############################################

# First iteration of the new carrier for LOKI
class LokiCarrier_1v0(LokiCarrierButtons, LokiCarrierLEDs, LokiCarrierClockgen, LokiCarrierDAC, LokiCarrier):
    variant = 'LOKI 1v0'
    clkgen_drivername = 'SI5345'
    clkgen_numchannels = 10
    dac_drivername = 'MAX5306'
    dac_num_outputs = 10
    leds_namelist = ['led0', 'led1', 'led2', 'led3']
    buttons_namelist = ['button0', 'button1']

    def __init__(self, **kwargs):
        self.__clkgen_current_config = None
        self.__dac_outputval = {}

        kwargs.setdefault('pin_config_id_led0', 'LED0')
        kwargs.setdefault('pin_config_id_led1', 'LED1')
        kwargs.setdefault('pin_config_id_led2', 'LED2')
        kwargs.setdefault('pin_config_id_led3', 'LED3')

        kwargs.setdefault('pin_config_id_button0', 'BUTTON0')
        kwargs.setdefault('pin_config_id_button1', 'BUTTON1')

        super(LokiCarrier_1v0, self).__init__(**kwargs)

        #self.__clkgen_current_config = self.__clkgen_default_config

    def clkgen_get_config(self):
        # todo
        return self.__clkgen_current_config
        pass

    def clkgen_set_config(self, configname):
        print('Setting clock configuration from {}'.format(configname))
        self.__clkgen_current_config = configname
        # todo actually set the config
        pass

    def clkgen_get_config_avail(self):
        # todo
        pass

    def dac_get_output(self, output_num):
        return self.__dac_outputval.get('output_num', 'No Data')
        # todo
        pass

    def dac_set_output(self, output_num, voltage):
        print('Setting DAC output {} to {}'.format(output_num, voltage))
        self.__dac_outputval[output_num] = voltage
        # todo
        pass


#######################################################################
# Application-specific derived classes (option 2) example for MERCURY #
#######################################################################

# A class designed to exactly mimic the base adapter class, but provide suporrt for a custom LokiCarrier class
# providing additional functionality present on the ASIC carrier that aligns with functionality provided by the
# new carrier on-board.
####class LokiAdapter_MERCURY(LokiAdapter):
####
####    def __init__(self, **kwargs):
####        # Init superclass
####        super(LokiAdapter_MERCURY, self).__init__(**kwargs)
####
####    def instantiate_carrier(self, carrier_type):
####        # Add support for new carrier, otherwise default to those supported as standard
####        if carrier_type == 'tebf0808_mercury':
####            self._carrier = LokiCarrier_TEBF0808_MERCURY(self.options)
####        else:
####            super(LokiAdapter_MERCURY, self).instantiate_carrier(carrier_type)


# This is a special case derived carrier for the control of the original prototype. This application-specific
# hardware is out of scope for LOKI, however is still included since it shares so many similarities (the LOKI
# carrier being based on it). Future application-specific odin instances should create a supplimentary adapter
# for their own daughter board, using interfaces provided via the generic LOKICarrier_TEBF0808 class for access
# to things like I2C, SPI, and GPIO specifics.
####class LokiCarrier_TEBF0808_MERCURY(LokiCarrier_TEBF0808):
####    variant = 'tebf0808_MERCURY'
####
####    def __init__(self, **kwargs):
####        super(LokiCarrier_TEBF0808_MERCURY, self).__init__(**kwargs)
####
####        # todo request additional pins for daughter carrier-specific functionality functionality. However, leave out ASIC and application specifics. Try and keep 'generic'. This will be practice for loki 1v0...
####        # todo add device drivers and hook them to power events for application and peripherals (VREG)
####
####    def _gen_paramtree_clk(self):
####        original_tree = super(LokiCarrier_TEBF0808_MERCURY, self)
####
####        # todo this is a proof of concept that is pointless, remove it eventually. More useful for exposing functionality only available for this device, like stepping freqs etc
####        original_tree['drivername'] = 'si5344'

