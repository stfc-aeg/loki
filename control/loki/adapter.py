from tornado.ioloop import IOLoop
# from tornado.escape import json_decode
# from odin.adapters.adapter import ApiAdapter, ApiAdapterResponse, request_types, response_types, wants_metadata
from odin.adapters.async_adapter import AsyncApiAdapter
# from odin._version import get_versions
from odin.adapters.parameter_tree import ParameterTreeError
from odin.adapters.parameter_tree import ParameterTree

from odin_devices.max5306 import MAX5306
from odin_devices.ltc2986 import LTC2986
from odin_devices.bme280 import BME280
from odin_devices.pac1921 import PAC1921, Measurement_Type as PAC1921_Measurement_Type
from odin_devices.si534x import SI5344
from odin_devices.firefly import FireFly
from odin_devices.i2c_device import I2CDevice

import logging
import gpiod
import time
import os
import concurrent.futures as futures
import threading
from contextlib import contextmanager

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

    def add_pin(self, friendly_name, pin_id, is_input, is_active_low=False, default_value=0):
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
        try:
            line.request(
                consumer=self._consumername,
                type=(gpiod.LINE_REQ_DIR_IN if is_input else gpiod.LINE_REQ_DIR_OUT),
                flags=(gpiod.LINE_REQ_FLAG_ACTIVE_LOW if is_active_low else 0),
                default_val=default_value)
        except Exception as e:
            raise RuntimeError('could not request line {}: {}'.format(line, e))

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
        allowed_settings = ['id', 'active_low', 'nc', 'is_input', 'default_value']
        for key in pin_config_options.keys():
            # Settings not in the list are ignored
            for allowed_setting in allowed_settings:
                if key.startswith(allowed_setting):
                    # Remove the setting prefix and the additional underscore
                    pin_name = key[len(allowed_setting) + 1:]
                    logging.debug('key {} -> pin {}'.format(key, pin_name))

                    # Add the pin to the dictionary if it does not exist
                    config_by_pin.setdefault(pin_name, {})

                    # Add the currently found setting for this pin
                    config_by_pin[pin_name].update({allowed_setting: pin_config_options[key]})

        return config_by_pin

    def add_pins_from_options(self, options):
        # Parse the options and extract pin configuration, separated by pin friendly name
        config_by_pin = self._sort_options_per_pin(options)

        logging.debug('Parsing pin options: {}'.format(config_by_pin))

        # Add each pin that has configuration information
        for pin_name in config_by_pin.keys():

            pin_info = config_by_pin[pin_name]

            try:
                pin_id = pin_info.get('id')
                pin_active_low = pin_info.get('active_low')
                pin_is_input = pin_info.get('is_input')
                pin_not_connected = pin_info.get('nc', False)   # This is optional, assumed pins are connected
                pin_default = pin_info.get('default_value', 1 if pin_active_low else 0)   # De-assert by default
            except KeyError as e:
                raise KeyError('Not enough information to register pin {}: {}'.format(pin_name, e))

            # If a pin is overridden to 'nc' it is assumed that it will not be used by anything.
            # As such, it will be ignored and not added to the accessible pins.
            if not pin_not_connected:
                self.add_pin(
                    friendly_name=pin_name,
                    pin_id=pin_id,
                    is_input=pin_is_input,
                    is_active_low=pin_active_low,
                    default_value=pin_default
                )

    def pinmap(self):
        # Print out the current pinmap
        pm = ''
        for pin_name in self.get_pin_names():
            pm += '{}: {}\n'.format(pin_name, self.get_pin(pin_name))
        return pm


# todo note SOMEWHERE that when including LokiCarrier as well as extensions, it must be last for the MRO to work. It's also optional is it's auto included by the extensions anyway. Or create a custom warning somehow (the better solution).
class LokiCarrier(ABC):
    # Generic LOKI carrier support class. Lays out the structure that should be used
    # for all child carrier definitions.

    # todo ideally the base class should avoid refferring to specific devices in its external interfaces.

    def __init__(self, **kwargs):
        # Get system information
        try:
            with open('/etc/loki/version') as info:
                self.__lokiinfo_version = info.read()
        except FileNotFoundError:
            self.__lokiinfo_version = 'unknown'

        try:
            with open('/etc/loki/platform') as info:
                self.__lokiinfo_platform = info.read()
        except FileNotFoundError:
            self.__lokiinfo_platform = 'unknown'

        try:
            with open('/etc/loki/application-version') as info:
                self.__lokiinfo_application_version = info.read()
        except FileNotFoundError:
            self.__lokiinfo_application_version = 'unknown'

        try:
            with open('/etc/loki/application-name') as info:
                self.__lokiinfo_application_name = info.read()
        except FileNotFoundError:
            self.__lokiinfo_application_name = 'unknown'

        self._logger = logging.getLogger('LokiCarrier')

        self._supported_extensions = []
        self._change_callbacks = {}

        # Set the default configuration for generic control pins
        self._config_pin_defaults(kwargs)

        # Request all pins configured for the device, including those for extension classes, using options
        self._pin_handler = PinHandler(self._variant)
        self._pin_handler.add_pins_from_options(kwargs)

        self._logger.info('Pin mappings settled:\n{}'.format(self._pin_handler.pinmap()))

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
        self._logger.info('starting IO loops')
        self._start_io_loops(kwargs)
        self._logger.info('IO loops started')

    def _start_io_loops(self, options):
        # This function can be extended by the extension LokiCarrier classes if they would benefit from async loops.
        # However, make sure that super is called in each.
        self._thread_executor = futures.ThreadPoolExecutor(max_workers=None)

        # Structure to hold threads (including those created by derived classes) for monitoring
        self._threads = {}

        self._threads['gpio'] = self._thread_executor.submit(self._loop_gpiosync)
        self._threads['ams'] = self._thread_executor.submit(self._loop_ams)

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
    def _variant(self):
        pass


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
        def set_pin_options(friendly_name, pin_id, is_input, active_low, default_value=False):
            options.setdefault('pin_config_id_' + friendly_name, pin_id)
            options.setdefault('pin_config_is_input_' + friendly_name, is_input)
            options.setdefault('pin_config_active_low_' + friendly_name, active_low)
            options.setdefault('pin_config_default_value_' + friendly_name, default_value)

        # Set defaults for generic control pins, use gpiod pin names from device tree rather than numbers
        set_pin_options('app_present',      'APP nPRESENT',         is_input=True,  active_low=True)
        set_pin_options('bkpln_present',    'BACKPLANE nPRESENT',   is_input=True,  active_low=True)
        set_pin_options('app_en',          'APPLICATION nRST',     is_input=False, active_low=True, default_value=False)
        set_pin_options('per_en',          'PERIPHERAL nRST',      is_input=False, active_low=True, default_value=False)

    def _gen_paramtree_dict(self):

        base_tree_dict = {
            'carrier_info': {
                'version': (lambda: self.__lokiinfo_version, None, {"description": "LOKI system image repo tag"}),
                'application_version': (lambda: self.__lokiinfo_application_version, None, {"description": "Application version"}),
                'application_name': (lambda: self.__lokiinfo_application_name, None, {"description": "Application name"}),
                'platform': (lambda: self.__lokiinfo_platform, None, {"description": "Hardware platform"}),
                'classvariant': (lambda: self._variant, None, {"description": "Carrier class variant"}),
                'extensions': (self.get_avail_extensions, None, {"description": "Comma separated list of carrier's supported extensions"}),
                'application_interfaces': self._get_paramtree_interfaces_dict(),
                'loopstatus': (self.get_loop_status, None, {"description": "Reports on the state of the background loops"}),
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
            'power': {
            },
        }

        self._logger.debug('Base ParameterTree generated')

        return base_tree_dict

    def get_loop_status(self):
        try:
            # Assume that any thread in _threads is intended to run forever
            threadreport = {}
            for threadname in self._threads:
                threadreport.update(
                    {
                        threadname: {
                            'running': self._threads[threadname].running(),
                            'done': self._threads[threadname].done(),
                            'exception': 'N/A' if not self._threads[threadname].done() else self._threads[threadname].exception(),
                        }
                    }
                )

            return threadreport

        except Exception as e:
            self._logger.error('Failed to get thread info: {}'.format(e))
            return 'Failed to get thread info'

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
        self._logger.debug('Synced Zynq AMS temperatures: {}'.format(self._zynq_ams))

    #############################
    # Application Control Lines #
    #############################

    def get_backplane_present(self):
        return bool(self._pin_handler.get_pin_value('bkpln_present'))

    def get_app_present(self):
        # Polarity is not inverted here, as it is done during the pin request
        return bool(self._pin_handler.get_pin_value('app_present'))

    def set_app_enabled(self, enable=True):
        # Polarity is not inverted here, as it is done during the pin request
        previous_state = bool(self.get_app_enabled())
        enable = bool(enable)

        # Only act if the state has actually changed
        if previous_state != enable:
            # If being disabled, the callback is called after the line is down
            if not enable:
                self._onChange_execute_callbacks('application_enable', False)

            self._pin_handler.set_pin_value('app_en', enable)
            time.sleep(0.5)

            # If being enabled, the callback is called after the line is up
            if enable:
                self._onChange_execute_callbacks('application_enable', True)

    def get_app_enabled(self):
        return bool(self._pin_handler.get_pin_value('app_en'))

    def set_peripherals_enabled(self, enable=True):
        # Polarity is not inverted here, as it is done during the pin request
        previous_state = bool(self.get_peripherals_enabled())
        enable = bool(enable)

        # Only act if the state has actually changed
        if previous_state != enable:
            # If being disabled, the callback is called before the line goes down
            if not enable:
                self._onChange_execute_callbacks('peripheral_enable', False)

            self._pin_handler.set_pin_value('per_en', enable)
            #time.sleep(5)

            # If being enabled, the callback is called after the line is up
            if enable:
                self._onChange_execute_callbacks('peripheral_enable', True)

    def get_peripherals_enabled(self):
        # Polarity is not inverted here, as it is done during the pin request
        return bool(self._pin_handler.get_pin_value('per_en'))

    def register_change_callback(self, trigger, callback_function):
        # More than one callback can be added for the same change if desired.
        allowed_targets = ['peripheral_enable', 'application_enable']
        if trigger in allowed_targets:
            existing_callback_list = self._change_callbacks.get(trigger)
            if existing_callback_list is not None:
                self._change_callbacks[trigger].append(callback_function)
            else:
                self._change_callbacks[trigger] = [callback_function]
        else:
            raise Exception('Callback target {} not available. Try: {} '.format(
                trigger, allowed_targets
            ))

    def _onChange_execute_callbacks(self, trigger, state):
        callbacks = self._change_callbacks.get(trigger)
        if callbacks:
            for callback in callbacks:
                callback(state)

    ###############################################
    # Available Application Interface Definitions #
    ###############################################

    @property
    @abstractmethod
    def _application_interfaces_spi(self):
        # Carrier definition class should specify any spidev buses available, with names that can match
        # any PCB naming (or could just be numbers). These should only be for interfaces available to the
        # user / application, rather than those used by the on-board devices. If there are no interfaces,
        # define the dictionary but leave it empty.

        # Format:
        '''
        _application_interfaces_spi = {
            <interface name> : (spidev bus, spidev device),
        }
        '''
        pass

    @property
    @abstractmethod
    def _application_interfaces_i2c(self):
        # Carrier definition class should specify any i2c buses available, with names that can match
        # any PCB naming (or could just be numbers). These should only be for interfaces available to the
        # user / application, rather than those used by the on-board devices. If there are no interfaces,
        # define the dictionary but leave it empty.

        # Format:
        '''
        _application_interfaces_i2c = {
            <interface name> : <bus number>,
        }
        '''
        pass

    def _get_paramtree_interfaces_dict(self):
        interfaces_dict = {
            'spi': {},
            'i2c': {},
        }

        for spidev_interface_name in self._application_interfaces_spi.keys():
            spidev_bus, spidev_device = self._application_interfaces_spi.get(spidev_interface_name)
            interfaces_dict['spi'].update({
                spidev_interface_name: (
                    (lambda spidev_bus_internal, spidev_device_internal: lambda: '({},{})'.format(spidev_bus_internal, spidev_device_internal))(spidev_bus, spidev_device),
                    None,
                    {'description': 'spidev (bus, device) for application interface {}'.format(spidev_interface_name)},
                )
            })

        for i2c_interface_name in self._application_interfaces_i2c.keys():
            i2c_bus = self._application_interfaces_i2c.get(i2c_interface_name)
            interfaces_dict['i2c'].update({
                i2c_interface_name: (
                    (lambda i2c_bus_internal: lambda: '{}'.format(i2c_bus_internal))(i2c_bus),
                    None,
                    {'description': 'i2c bus for application interface {}'.format(i2c_interface_name)},
                )
            })

        return interfaces_dict


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
        for friendly_name in self._leds_namelist:
            # Assume that the ID has already been set in the carrier
            options.setdefault('pin_config_is_input_' + friendly_name, False)
            options.setdefault('pin_config_active_low_' + friendly_name, True)  # Override if necesary
            options.setdefault('pin_config_default_value_' + friendly_name, False)  # Override if necesary

    def _gen_paramtree_dict(self):
        base_tree = super(LokiCarrierLEDs, self)._gen_paramtree_dict()

        # Create the new key if it does not exist for the sensor type, with a blank dictionary
        base_tree['user_interaction'].setdefault('leds', {})

        # Add each LED with its friendly name to the parameter tree
        for friendly_name in self._leds_namelist:
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
    def _leds_namelist(self):
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
        for friendly_name in self._buttons_namelist:
            # Assume that the ID has already been set in the carrier
            options.setdefault('pin_config_is_input_' + friendly_name, True)
            options.setdefault('pin_config_active_low_' + friendly_name, True)  # Override if necesary

    def _gen_paramtree_dict(self):
        base_tree = super(LokiCarrierButtons, self)._gen_paramtree_dict()

        # Create the new key if it does not exist for the sensor type, with a blank dictionary
        base_tree['user_interaction'].setdefault('buttons', {})

        # Add each button with its friendly name to the parameter tree
        for friendly_name in self._buttons_namelist:
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
    def _buttons_namelist(self):
        pass


####################
# Clock Generation #
####################

class LokiCarrierClockgen(LokiCarrier, ABC):
    def __init__(self, **kwargs):
        # Call next in MRO / Base Class
        super(LokiCarrierClockgen, self).__init__(**kwargs)

        # todo register the device with the carrier power control system

        self._clkgen_current_config = None

        self._supported_extensions.append('clkgen')

    def _gen_paramtree_dict(self):
        base_tree = super(LokiCarrierClockgen, self)._gen_paramtree_dict()

        base_tree['clkgen'] = {
            'drivername': (lambda: self._clkgen_drivername, None, {"description": "Name of the device providing clock generator support"}),
            'num_outputs': (lambda: self._clkgen_numchannels, None, {"description": "Number of output channels available"}),
            'config_file': (self.clkgen_get_config, self.clkgen_set_config, {"description": "Current configuration file loaded for clock config"}),
            'config_files_avail': (self.clkgen_get_config_avail, None, {"description": "Available config files to choose from"}),
        }

        return base_tree

    def clkgen_get_config(self):
        try:
            return self._clkgen_current_config
        except AttributeError:
            return None

    def clkgen_set_config(self, configname):
        # Used to guard the lower level function while caching the last submitted result.
        # If an error is encountered, the setting is not cached.
        try:
            self._clkgen_set_config_direct(configname)
            self._clkgen_current_config = configname
        except Exception as e:
            raise Exception(
                'Failed to set clock generator settings to config {}: {}'.format(
                    configname, e
                )
            )

    @property
    @abstractmethod
    def _clkgen_drivername(self):
        pass

    @property
    @abstractmethod
    def _clkgen_numchannels(self):
        pass

    # Implemented for the specific clock generator by the carrier. If the operation fails
    # for some reason, an error should be returned so that the caller does not chache the
    # setting assuming that it has been applied.
    @abstractmethod
    def _clkgen_set_config_direct(self, config):
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
        for output_num in range(0, self._dac_num_outputs):
            output_tree[str(output_num)] = (
                # Protect the scope of output_num_internal so that it does not change between loops
                (lambda output_num_internal: lambda: self.dac_get_output(output_num_internal))(output_num),
                (lambda output_num_internal: lambda voltage: self.dac_set_output(output_num_internal, voltage))(output_num),
                {"description": "Get / Set DAC output value", "units": "v"}
            )

        base_tree['dac'] = {
            'drivername': (
                lambda: self._dac_drivername,
                None,
                {"description": "Name of the device providing clock generator support"}
            ),
            'num_outputs': (
                lambda: self._dac_num_outputs,
                None,
                {"description": "Number of output channels available"}
            ),
            'status': (
                self.dac_get_status,
                None,
                {"description": "Give some feedback on the device status, errors etc"},
            ),
            'outputs': output_tree,
        }

        return base_tree

    @property
    @abstractmethod
    def _dac_drivername(self):
        pass

    @property
    @abstractmethod
    def _dac_num_outputs(self):
        pass

    @abstractmethod
    def dac_set_output(self, output_num, voltage):
        pass

    @abstractmethod
    def dac_get_output(self, output_num):
        pass

    @abstractmethod
    def dac_get_status(self):
        pass


########################################
# Temperature  and Humidity Monitoring #
########################################

class LokiCarrierEnvmonitor(LokiCarrier, ABC):
    def __init__(self, **kwargs):
        self._env_cached_readings = {}

        self._env_reading_sync_period_s = kwargs.get('env_reading_sync_period_s', 5)

        # Call next in MRO / Base Class
        super(LokiCarrierEnvmonitor, self).__init__(**kwargs)

        self._supported_extensions.append('envmonitor')

    def _gen_paramtree_dict(self):
        base_tree = super(LokiCarrierEnvmonitor, self)._gen_paramtree_dict()

        # Expects this to be a list of (name, type, unit) tuples.
        # Type is typically 'temperature' or 'humidity'.
        # info is the dictionary passed to the paramtree including description, units etc.
        additional_sensors = self._env_sensor_info
        for (name, sType, info) in additional_sensors:
            # Create the new key if it does not exist for the sensor type, with a blank dictionary
            base_tree['environment'].setdefault(sType, {})

            # Add the sensor entry with its specific info, protecting scope of name_internal
            base_tree['environment'][sType][name] = (
                (lambda name_internal, type_internal: lambda: self.env_get_sensor_cached(name_internal, type_internal))(name, sType),
                None,
                info
            )

            # Also add the sensor cache structure for each sensor type.
            self._env_cached_readings.setdefault(sType, {})
            self._env_cached_readings[sType].setdefault(name, None)

        return base_tree

    def _start_io_loops(self, options):
        super(LokiCarrierEnvmonitor, self)._start_io_loops(options)
        # self._thread_executor should already be defined in the super function

        self._threads['env'] = self._thread_executor.submit(self._env_loop_readingsync)

    def env_get_sensor_cached(self, name, sType):
        return self._env_cached_readings[sType].get(name, 'No Reading')

    def _env_loop_readingsync(self):
        while True:
            self._env_sync_reading_cache()
            time.sleep(self._env_reading_sync_period_s)

    def _env_sync_reading_cache(self):
        for sType in self._env_cached_readings.keys():
            for name in self._env_cached_readings[sType].keys():
                try:
                    self._env_cached_readings[sType][name] = self._env_get_sensor(name, sType)
                except Exception as e:
                    self._logger.getChild('env').warning(
                        'Could not sync sensor reading for {} ({}): {}'.format(
                            name, sType, e
                        )
                    )

                    # If there was no valid reading, return set cached value to None to avoid
                    # communicating invalid information.
                    self._env_cached_readings[sType][name] = None

        self._logger.getChild('env').debug('Updated environmental readings:{}'.format(self._env_cached_readings))

    # list, see above
    @property
    @abstractmethod
    def _env_sensor_info(self):
        pass

    # Get the live version of a power sensor reading. This should not perform any caching, as the calling method
    # will be responsible.
    @abstractmethod
    def _env_get_sensor(self, name, sType):
        pass


####################
# Power Monitoring #
####################

class LokiCarrierPowerMonitor(LokiCarrier, ABC):
    # Power monitors will have a set of rails with a given name, each of which will have a
    # name tied to a readable current/voltage/power value if supported. Additionally, each
    # rail has a pattern for being enabled/disabled. It is up to the extending carrier to
    # determine if these are implemented and/or linked together.
    def __init__(self, **kwargs):
        self._psu_cached_readings = {}

        self._psu_reading_sync_period_s = kwargs.get('psu_reading_sync_period_s', 5)

        # Call next in MRO / Base Class
        super(LokiCarrierPowerMonitor, self).__init__(**kwargs)

        self._supported_extensions.append('powermonitor')

    def _gen_paramtree_dict(self):
        base_tree = super(LokiCarrierPowerMonitor, self)._gen_paramtree_dict()

        # self.psu_rail_info is a list of tuples of the form:
        # (name, voltageSupport (bool), currentSupport (bool), powerSupport (bool), enSupport (bool))
        for (name, voltageSupport, currentSupport, powerSupport, enSupport) in self._psu_rail_info:
            # Create the new key if it does not exist for the rail, with a blank dictionary
            base_tree['power'].setdefault(name, {})

            # Also add the sensor cache structure for each sensor type.
            self._psu_cached_readings.setdefault(name, {})

            # Add the sensor entry with its specific info, protecting scope of name_internal
            if voltageSupport:
                base_tree['power'][name]['voltage'] = (
                    (lambda name_internal: lambda: self.psu_get_rail_cached(name_internal, 'voltage'))(name),
                    None, {'description': 'cached voltage reading', 'units': 'V'},
                )
                self._psu_cached_readings[name].setdefault('voltage', {})   # Voltage is cached

            if currentSupport:
                base_tree['power'][name]['current'] = (
                    (lambda name_internal: lambda: self.psu_get_rail_cached(name_internal, 'current'))(name),
                    None, {'description': 'cached current reading', 'units': 'A'},
                )
                self._psu_cached_readings[name].setdefault('current', {})   # Current is cached

            if powerSupport:
                base_tree['power'][name]['power'] = (
                    (lambda name_internal: lambda: self.psu_get_rail_cached(name_internal, 'power'))(name),
                    None, {'description': 'cached power reading', 'units': 'W'},
                )
                self._psu_cached_readings[name].setdefault('power', {})     # Power is cached

            if enSupport:
                base_tree['power'][name]['enable'] = (
                    (lambda name_internal: lambda: self.psu_get_rail_en(name_internal))(name),
                    (lambda name_internal: lambda state: self.psu_set_rail_en(name_internal, state))(name),
                    {'description': 'rail enable state'},
                )

        return base_tree

    def _psu_loop_readingsync(self):
        while True:
            self._psu_sync_reading_cache()
            time.sleep(self._psu_reading_sync_period_s)

    def _psu_sync_reading_cache(self):
        for name in self._psu_cached_readings.keys():
            for reading_type in self._psu_cached_readings[name].keys():
                try:
                    self._psu_cached_readings[name][reading_type] = self._psu_get_rail(name, reading_type)
                except Exception as e:
                    self._logger.getChild('psu').warning(
                        'Could not power rail reading for {} ({}): {}'.format(
                            name, reading_type, e
                        )
                    )

                    # If there was no valid reading, return set cached value to None to avoid
                    # communicating invalid information.
                    self._psu_cached_readings[name][reading_type] = None

        self._logger.getChild('psu').debug('Updated power monitor readings:{}'.format(self._psu_cached_readings))

    def _start_io_loops(self, options):
        super(LokiCarrierPowerMonitor, self)._start_io_loops(options)
        # self._thread_executor should already be defined in the super function

        self._threads['psu'] = self._thread_executor.submit(self._psu_loop_readingsync)

    # Return the cached value of the rail reading specified
    def psu_get_rail_cached(self, name, reading_type):
        return self._psu_cached_readings[name].get(reading_type, 'No Reading')

    # list, see above
    @property
    @abstractmethod
    def _psu_rail_info(self):
        pass

    # Get the live version of a power rail reading. This should not perform any caching, as the calling method
    # will be responsible.
    @abstractmethod
    def _psu_get_rail(self, name, reading_type):
        pass

    # This is the method that will be used directly. Therefore any caching (if applicable) must be handled by the
    # carrier instance since the implementation is likely to vary greatly.
    @abstractmethod
    def psu_get_rail_en(self, name):
        pass

    # This is the method that will be used directly. Therefore any caching (if applicable) must be handled by the
    # carrier instance since the implementation is likely to vary greatly.
    @abstractmethod
    def psu_set_rail_en(self, name, value):
        pass

class LokiCarrier_TEBF0808(LokiCarrier):
    # Special case; as a prototype with minimal support for devices alone. Should be combined with an
    # application-specific adapter for the associated daughter board, which relies on interfaces provided
    # by this adapter (buses, GPIO pins). This second adapter will need to implement things like clock
    # config, etc.

    _variant = 'tebf0808'
    #leds_namelist = ['led0']

    def __init__(self, **kwargs):
        # Set the pin for LED0 to on-board LED, unless already overridden in settings
        #kwargs.setdefault('pin_config_id_led0', 'MIO40')

        super(LokiCarrier_TEBF0808, self).__init__(**kwargs)


#############################################
# Carrier Class for Next Generation Carrier #
#############################################

# First iteration of the new carrier for LOKI
class LokiCarrier_1v0(LokiCarrierButtons, LokiCarrierLEDs, LokiCarrierClockgen, LokiCarrierDAC, LokiCarrier):
    _variant = 'LOKI 1v0'
    _clkgen_drivername = 'SI5345'
    _clkgen_numchannels = 10
    _dac_drivername = 'MAX5306'
    _dac_num_outputs = 10
    _leds_namelist = ['led0', 'led1', 'led2', 'led3']
    _buttons_namelist = ['button0', 'button1']
    _application_interfaces_spi = {
        'SS0': (1, 0),
        'SS1': (1, 1),
        'SS2': (1, 2),
    }
    _application_interfaces_i2c = {
        'APP_EXT': 1,       # todo update this
        'APP_EXT2': 2,      # todo update this
        'APP_MGMT': 3,      # todo update this
        'APP_PWR': 4,       # todo update this
    }

    def __init__(self, **kwargs):
        self.__dac_outputval = {}

        kwargs.setdefault('pin_config_id_led0', 'LED0')
        kwargs.setdefault('pin_config_id_led1', 'LED1')
        kwargs.setdefault('pin_config_id_led2', 'LED2')
        kwargs.setdefault('pin_config_id_led3', 'LED3')

        kwargs.setdefault('pin_config_id_button0', 'BUTTON0')
        kwargs.setdefault('pin_config_id_button1', 'BUTTON1')

        super(LokiCarrier_1v0, self).__init__(**kwargs)

    def _clkgen_set_config_direct(self, configname):
        self._logger.getChild('clkgen').info('Setting clock configuration from {}'.format(configname))
        # todo
        pass

    def clkgen_get_config_avail(self):
        # todo
        pass

    def dac_get_output(self, output_num):
        return self.__dac_outputval.get('output_num', 'No Data')
        # todo
        pass

    def dac_set_output(self, output_num, voltage):
        self._logger.getChild('dac').info('Setting DAC output {} to {}'.format(output_num, voltage))
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


class DeviceHandler():
    # To help keep track of device availability. Can also be used as a place to track state
    # for different devices.
    def __init__(self, device=None, device_type_name=None, logger=None):
        self.device = device
        self.device_type_name = device_type_name
        self.initialised = False
        self.error = False
        self.error_message = False
        self.lock = threading.RLock()

        if logger is not None:
            # Prefer to use the supplied logger
            self._logger = logger
        else:
            if self.device_type_name is not None:
                # Otherwise try and use the device name
                self._logger = logging.getLogger(self.device_type_name)
            else:
                # If all else fails just use a new generic device logger
                self._logger = logging.getLogger('device')

    def __repr__(self):
        # Check if the device is locked by temporarily requesting it (non-blocking)
        # Todo : consider whether this should be cached somewhere if it is read by the paramtree
        if self.lock.acquire(blocking=False):
            device_unlocked = True
            self.lock.release()
        else:
            device_unlocked = False

        return '{} device ({}) ({}, {})'.format(
            str(self.device_type_name),
            type(self.device),
            'initialised' if self.initialised else 'not initialised',
            'unlocked' if device_unlocked else 'locked',
        )

    # Allow the handler to expose an acquire() method to be used with 'with' to protect access
    # with a thread-safe lock (mutex).
    @contextmanager
    def acquire(self, blocking=True, timeout=-1):
        # only permit access if the device has been initialised
        if not self.initialised:
            raise RuntimeError('Device was not initialised, cannot access it')

        # Grab the lock with the supplied settings
        result = self.lock.acquire(blocking=blocking, timeout=timeout)

        # Allow the caller to execute their 'with'. 'result' is needed so that
        # if the lock cannot be grabbed the user can handle it.
        yield result

        # Release the lock, if it was actually acquired
        if result:
            self.lock.release()

    def critical_error(self, message=''):
        # Mark the device not to be used, and record the error in log and paramtree status
        self.initialised = False
        self.error = True
        self.error_message = message
        self._logger.error('device error: {}'.format(message))


# This is a special case derived carrier for the control of the original prototype. This application-specific
# hardware is out of scope for LOKI, however is still included since it shares so many similarities (the LOKI
# carrier being based on it). Future application-specific odin instances should create a supplimentary adapter
# for their own daughter board, using interfaces provided via the generic LOKICarrier_TEBF0808 class for access
# to things like I2C, SPI, and GPIO specifics.
# Most 'devices' added are added via helper templates from the ABC. There are exceptions (e.g. FireFlies), but
# the implementation of these is still quite similar, just a bit more manual.
class LokiCarrier_TEBF0808_MERCURY(LokiCarrierPowerMonitor, LokiCarrierEnvmonitor, LokiCarrierClockgen, LokiCarrierDAC, LokiCarrier_TEBF0808):
    _variant = 'tebf0808_MERCURY'
    _clkgen_drivername = 'SI5344'
    _clkgen_numchannels = 4
    _dac_drivername = 'MAX5306'
    _dac_num_outputs = 10
    _env_sensor_info = [
        # name, type, info
        ('PT100', 'temperature', {"description": "PT100 on fly-lead", "units": "C"}),
        ('ASIC', 'temperature', {"description": "ASIC diode temperature", "units": "C"}),
        ('BOARD', 'temperature', {"description": "BME280 carrier board temperature", "units": "C"}),
        ('BOARD', 'humidity', {"description": "BME280 carrier board humidity RH", "units": "%"}),
    ]
    _psu_rail_info = [
        # name, voltageSupported, currentSupported, powerSupported, enSupported
        ('VDDD', True, True, True, False),
        ('VDDD_CNTRL', True, True, True, False),
        ('VDDA', True, True, True, False),
    ]

    # Although these interfaces are present, the boundary of the 'application' does not really exist, since
    # the COB devices are being considered part of the carrier itself.
    _application_interfaces_spi = {
    }
    _application_interfaces_i2c = {
    }

    def __init__(self, **kwargs):

        self._peripherals_i2c_bus = 1

        # Gather settings for MAX5306 DAC
        self._max5306 = DeviceHandler(device_type_name='MAX5306')
        self._max5306.vref = kwargs.get('max5306_reference', 2.048)
        self._max5306.spidev = kwargs.get('max5306_spidev', (1, 1))

        # Gather settings for LTC2986
        self._ltc2986 = DeviceHandler(device_type_name='LTC2986')
        self._ltc2986.spidev = kwargs.get('ltc2986_spidev', (1, 0))
        self._ltc2986.rsense_ohms = kwargs.get('ltc2986_rsense_ohms', 2000)
        self._ltc2986.pt100_channel = 6
        self._ltc2986.diode_channel = 2

        # Define the reset pin for the ltc2986 (requested below after super init)
        kwargs.setdefault('pin_config_id_temp_reset', 'LTC_NRST')
        kwargs.setdefault('pin_config_active_low_temp_reset', True)
        kwargs.setdefault('pin_config_is_input_temp_reset', False)
        kwargs.setdefault('pin_config_default_value_temp_reset', 1)     # Since pin is active low, 1 means grounded, i.e. in reset

        # Gather settings for BME280 monitoring device
        self._bme280 = DeviceHandler(device_type_name='BME280')
        self._bme280.i2c_bus = self._peripherals_i2c_bus

        # Gather settings for the PAC1921 power monitors
        self._pac1921_u3 = DeviceHandler(device_type_name='PAC1921')
        self._pac1921_u3.railname = 'VDDD_CNTRL'
        self._pac1921_u3.di_gain = kwargs.get('pac1921_vdddcntrl_di_gain', 1)
        self._pac1921_u3.dv_gain = kwargs.get('pac1921_vdddcntrl_dv_gain', 8)

        self._pac1921_u2 = DeviceHandler(device_type_name='PAC1921')
        self._pac1921_u2.railname = 'VDDD'
        self._pac1921_u2.di_gain = kwargs.get('pac1921_vddd_di_gain', 1)
        self._pac1921_u2.dv_gain = kwargs.get('pac1921_vddd_dv_gain', 1)

        self._pac1921_u1 = DeviceHandler(device_type_name='PAC1921')
        self._pac1921_u1.railname = 'VDDA'
        self._pac1921_u1.di_gain = kwargs.get('pac1921_vdda_di_gain', 1)
        self._pac1921_u1.dv_gain = kwargs.get('pac1921_vdda_dv_gain', 1)

        self._pac1921_array = [self._pac1921_u3, self._pac1921_u2, self._pac1921_u1]

        # Gather settings for the SI5344
        self._si5344 = DeviceHandler(device_type_name = 'SI5344')
        self._si5344.default_config = kwargs.get('clkgen_default_config')    # This is a requirement of this implementation
        self._si5344.config_base_dir = kwargs.get('clkgen_base_dir')                # This is a requirement of this implementation
        self._clkgen_sync_config_avail()           # Grab this once at startup

        # Gather settings for FireFlies (implemented without helpers)
        self._firefly_00to09 = DeviceHandler(device_type_name='FireFly')
        self._firefly_00to09.name = '00to09'
        self._firefly_00to09.select_pin_friendlyname = 'ff_sel_00to09'
        self._firefly_10to19 = DeviceHandler(device_type_name='FireFly')
        self._firefly_10to19.name = '10to19'
        self._firefly_10to19.select_pin_friendlyname = 'ff_sel_10to19'
        self._firefly_array = [self._firefly_00to09, self._firefly_10to19]

        # Get the select line pins for the FireFlies
        kwargs.setdefault('pin_config_id_{}'.format(self._firefly_00to09.select_pin_friendlyname), 'EMIO29')
        kwargs.setdefault('pin_config_id_{}'.format(self._firefly_10to19.select_pin_friendlyname), 'EMIO30')
        for friendlyname in [self._firefly_10to19.select_pin_friendlyname, self._firefly_00to09.select_pin_friendlyname]:
            kwargs.setdefault('pin_config_active_low_{}'.format(friendlyname), False)   # FF driver expects active high
            kwargs.setdefault('pin_config_is_input_{}'.format(friendlyname), False)
            kwargs.setdefault('pin_config_default_value_{}'.format(friendlyname), True) # Defaults to disable the device

        super(LokiCarrier_TEBF0808_MERCURY, self).__init__(**kwargs)

        self._ltc2986.pin_reset = self._pin_handler.get_pin('temp_reset')

        # Initially grab device locks so that they can be freed from the peripheral enable callback.
        # This also prevents the background threads running until the devices are enabled for the first time.
        self._bme280.lock.acquire()
        self._max5306.lock.acquire()
        self._pac1921_u3.lock.acquire()
        self._pac1921_u2.lock.acquire()
        self._pac1921_u1.lock.acquire()
        self._ltc2986.lock.acquire()
        self._si5344.lock.acquire()
        self._firefly_00to09.lock.acquire()
        self._firefly_10to19.lock.acquire()

        self.register_change_callback('peripheral_enable', self._onChange_periph_en)
        self.register_change_callback('application_enable', self._onChange_app_en)

        # todo request additional pins for daughter carrier-specific functionality functionality. However, leave out ASIC and application specifics. Try and keep 'generic'. This will be practice for loki 1v0...
        # todo add device drivers and hook them to power events for application and peripherals (VREG)

    def _onChange_periph_en(self, state):
        if state is True:
            self._logger.info('peripherals enabled, re-configuring devices')

            # Only re-configure if it is not initialised.
            if not self._max5306.initialised:
                self._config_max5306()
            self._max5306.lock.release

            # Only re-configure if it is not initialised.
            if not self._ltc2986.initialised:
                self._config_ltc2986()
            self._ltc2986.lock.release()

            # Only re-configure if it is not initialised.
            if not self._bme280.initialised:
                self._config_bme280()
            self._bme280.lock.release()        # Hard-release the lock to allow operation after power down

            # Re-configure if any of the power monitors did not initialised properly
            if any(not(x.initialised) for x in self._pac1921_array):
                self._config_pac1921_array()
            for device in self._pac1921_array:
                device.lock.release()

            # Re-configure if any of the fireflies did not initialised properly
            if any(not(x.initialised) for x in self._firefly_array):
                self._config_firefly_array()
            for device in self._firefly_array:
                device.lock.release()

            # Only re-configure if it is not initialised.
            if not self._si5344.initialised:
                self._config_si5344()
            self._si5344.lock.release()

        else:
            self._logger.info('peripherals disabled, disabling device contact')

            # on this particular carrier, having the periph en low (VREG_EN) will also disable the ASIC, so perform the same actions
            self._onChange_app_en(False)

            # For some devices, low VREG_EN simply disables contact with them (due to level shifters)
            # Hard-acquire the lock to prevent attempts to communicate, while preventing the pin going low until the system is ready
            self._max5306.lock.acquire()
            self._bme280.lock.acquire()
            self._pac1921_u3.lock.acquire()
            self._pac1921_u2.lock.acquire()
            self._pac1921_u1.lock.acquire()
            self._si5344.lock.acquire()
            self._firefly_00to09.lock.acquire()
            self._firefly_10to19.lock.acquire()

            # For other devices, low VREG_EN resets the device, meaning a new init will be required.
            self._ltc2986.lock.acquire()
            self._ltc2986.initialised = False
            self._ltc2986.pin_reset.set_value(1)    # Since with shifters down reset goes low anyway

    def _onChange_app_en(self, state):
        if state is True:
            pass
        else:
            pass

    def _clkgen_set_config_direct(self, configname):
        with self._si5344.acquire(blocking=True, timeout=1) as rslt:
            if not rslt:
                raise Exception('Failed to get clock generator lock, timed out')

            print('Setting clock configuration from {}'.format(configname))
            self._si5344.device.apply_register_map(self._si5344.config_base_dir + configname, verify=True)

    def _clkgen_sync_config_avail(self):
        configlist = []
        for configfile in os.listdir(self._si5344.config_base_dir):
            if configfile.endswith('.txt'):
                configlist.append(configfile)
        self._si5344.config_list = configlist

    def clkgen_get_config_avail(self):
        return self._si5344.config_list

    def clkgen_step_clk(self, clock_num, direction_upwards):
        # This function is specific to the implementation (device), therefore additional to the helpers.

        with self._si5344.acquire(blocking=True, timeout=1) as rslt:
            if not rslt:
                raise Exception('Failed to get clock generator lock, timed out')
            if direction_upwards:
                self._si5344.device.increment_channel_frequency(clock_num)
            else:
                self._si5344.device.decrement_channel_frequency(clock_num)

    def _psu_get_rail(self, name, sensor_type):
        # Since this is synced by a dedicated thread, the delays incurred by free running integration
        # are not a concern. For the requested sensor type, change the mode and perform a full free
        # running integration (with the exception of power, which is calculated).

        # With free-run integration mode, voltage and current measurement take max 365ms.

        for monitor in self._pac1921_array:
            # Only read the device we are interested in
            if monitor.railname == name:
                with monitor.acquire(blocking=True, timeout=1) as rslt:
                    if not rslt:
                        raise Exception('Failed to get power monitoring lock, timed out')

                    # Set the desired free-running mode
                    if sensor_type == 'current':
                        monitor.device.set_measurement_type(PAC1921_Measurement_Type.CURRENT)
                        monitor.device.config_freerun_integration_mode()
                        time.sleep(0.4)     # Required to guarantee integration completes
                        return monitor.device.read()
                    elif sensor_type == 'voltage':
                        monitor.device.set_measurement_type(PAC1921_Measurement_Type.VBUS)
                        monitor.device.config_freerun_integration_mode()
                        time.sleep(0.4)     # Required to guarantee integration completes
                        return monitor.device.read()
                    elif sensor_type == 'power':
                        cached_current = self.psu_get_rail_cached(name, 'current')
                        cached_voltage = self.psu_get_rail_cached(name, 'voltage')

                        # Power is calculated from the most recent voltage and current readings
                        try:
                            return cached_voltage * cached_current
                        except Exception as e:
                            raise Exception('Failed to calculate power with cached voltage and current: {}'.format(e))

    def psu_get_rail_en(self, name):
        # ABC enforces the presence of this, but it is unused
        pass

    def psu_set_rail_en(self, name, value):
        # ABC enforces the presence of this, but it is unused
        pass

    def dac_get_output(self, output_num):
        try:
            with self._max5306.acquire(blocking=True, timeout=1) as rslt:
                if not rslt:
                    self._logger.warning('Could not get MAX5306 mutex, timed out')
                    return 'N/A'

                # Return the last setting of the DAC, assuming that it is correct and unchanged
                return self._max5306.last_setting.get(output_num, 'unset')
        except RuntimeError as e:
            self._logger.warning('Failed to get DAC mutex: {}', e)
            return 'N/A'

    def dac_set_output(self, output_num, voltage):
        with self._max5306.acquire(blocking=True, timeout=1) as rslt:
            if not rslt:
                raise Exception('Could not get MAX5306 mutex, timed out')

            self._max5306.device.set_output(output_num, voltage)
            print('Setting DAC output {} to {}'.format(output_num, voltage))
            self._max5306.last_setting.update({output_num: voltage})

    def dac_get_status(self):
        return ('Initialised: {}, Error: {}'.format(
            self._max5306.initialised, self._max5306.error_message
        ))

    def _config_pac1921_array(self):
        # Use separate devices for each of the PAC1921 devices so that if the setup for one
        # fails (or the gain is wrong for example) the other rails will operate correctly.

        free_run_sample_num = 512

        try:
            self._pac1921_u3.initialised = False
            self._pac1921_u3.error = False
            self._pac1921_u3.error_message = False

            self._pac1921_u3.device = PAC1921(
                address_resistance=470,
                name=self._pac1921_u3.railname,
                r_sense=0.02,
                measurement_type=PAC1921_Measurement_Type.VBUS
            )
            self._pac1921_u3.device.config_gain(di_gain=self._pac1921_u3.di_gain, dv_gain=self._pac1921_u3.dv_gain)
            self._pac1921_u3.device.config_freerun_integration_mode(free_run_sample_num)

            self._pac1921_u3.initialised = True
        except Exception as e:
            self._pac1921_u3.critical_error(
                "Error initialising PAC1921 U3 ({}): {}".format(self._pac1921_u3.railname, e))

        try:
            self._pac1921_u2.initialised = False
            self._pac1921_u2.error = False
            self._pac1921_u2.error_message = False

            self._pac1921_u2.device = PAC1921(
                address_resistance=620,
                name=self._pac1921_u2.railname,
                r_sense=0.02,
                measurement_type=PAC1921_Measurement_Type.VBUS
            )
            self._pac1921_u2.device.config_gain(di_gain=self._pac1921_u2.di_gain, dv_gain=self._pac1921_u2.dv_gain)
            self._pac1921_u2.device.config_freerun_integration_mode(free_run_sample_num)

            self._pac1921_u2.initialised = True
        except Exception as e:
            self._pac1921_u2.critical_error(
                "Error initialising PAC1921 U2 ({}): {}".format(self._pac1921_u2.railname, e))

        try:
            self._pac1921_u1.initialised = False
            self._pac1921_u1.error = False
            self._pac1921_u1.error_message = False

            self._pac1921_u1.device = PAC1921(
                address_resistance=820,
                name=self._pac1921_u1.railname,
                r_sense=0.02,
                measurement_type=PAC1921_Measurement_Type.VBUS
            )
            self._pac1921_u1.device.config_gain(di_gain=self._pac1921_u1.di_gain, dv_gain=self._pac1921_u1.dv_gain)
            self._pac1921_u1.device.config_freerun_integration_mode(free_run_sample_num)

            self._pac1921_u1.initialised = True
        except Exception as e:
            self._pac1921_u1.critical_error(
                "Error initialising PAC1921 U1 ({}): {}".format(self._pac1921_u1.railname, e))

        # Initially, devices will all be set in power mode.
        #self._pac1921_array_current_measurement = pac1921.Measurement_Type.POWER

    def _config_max5306(self):
        # Attempt init, but on failure log error and continue
        try:
            self._max5306.initialised = False
            self._max5306.error = False
            self._max5306.error_message = False

            max5306_bus, max5306_device = self._max5306.spidev
            self._max5306.device = MAX5306(self._max5306.vref, bus=max5306_bus, device=max5306_device)

            self._max5306.last_setting = {}

            self._max5306.initialised = True

            self._logger.debug('MAX5306 init completed successfully')
        except Exception as e:
            self._max5306.critical_error('Failed to init MAX5306: {}'.format(e))

    def _env_get_sensor(self, name, sensor_type):
        # This will return the raw value, cached by the LokiCarrierEnvmonitor class automatically
        # this will need to return values for the BME280 as well as the LTC2986

        #self._logger.getChild('env').debug('Reading sensor {} ({})'.format(name, sensor_type))

        if name in ['PT100', 'ASIC']:
            # These sensors are provided by the ltc2986

            with self._ltc2986.acquire(blocking=True, timeout=1) as rslt:
                if not rslt:
                    raise Exception('Could not acquire lock for sensor {} ({}), timed out'.format(name, sensor_type))

                if name == 'PT100' and sensor_type == 'temperature':
                    return self._ltc2986.device.measure_channel(self._ltc2986.pt100_channel)
                elif name == 'ASIC' and sensor_type == 'temperature':
                    return self._ltc2986.device.measure_channel(self._ltc2986.diode_channel)

        if name in ['BOARD']:
            # These sensors are provided by the bme280

            with self._bme280.acquire(blocking=True, timeout=1) as rslt:
                if not rslt:
                    raise Exception('Could not acquire lock for sensor {} ({}), timed out'.format(name, sensor_type))

                if sensor_type == 'temperature':
                    return self._bme280.device.temperature
                elif sensor_type == 'humidity':
                    return self._bme280.device.humidity

        raise NotImplementedError('Sensor {} ({}) not implemented'.format(name, sensor_type))

    def _config_ltc2986(self):
        # The 'generic' version of this for LokiCarrier_1v0 will likely not define sensors off-board, so will need
        # a mechanism for the application-specific code to do so. Might just have to expose the function.
        try:
            self._ltc2986.initialised = False
            self._ltc2986.error = False
            self._ltc2986.error_message = False

            ltc2986_bus, ltc2986_device = self._ltc2986.spidev
            self._ltc2986.device = LTC2986(bus=ltc2986_bus, device=ltc2986_device)

            # Set the reset line inactive
            self._ltc2986.pin_reset.set_value(0)

            # todo this can stay, because there will be a PT100 socket on the new carrier
            self._ltc2986.device.add_rtd_channel(
                LTC2986.Sensor_Type.SENSOR_TYPE_RTD_PT100,
                LTC2986.RTD_RSense_Channel.CH4_CH3,
                self._ltc2986.rsense_ohms,
                LTC2986.RTD_Num_Wires.NUM_2_WIRES,
                LTC2986.RTD_Excitation_Mode.NO_ROTATION_NO_SHARING,
                LTC2986.RTD_Excitation_Current.CURRENT_500UA,
                LTC2986.RTD_Curve.EUROPEAN,
                channel_num=self._ltc2986.pt100_channel
            )

            # todo consider removing this; it is application specific
            self._ltc2986.device.add_diode_channel(
                endedness=LTC2986.Diode_Endedness.DIFFERENTIAL,
                conversion_cycles=LTC2986.Diode_Conversion_Cycles.CYCLES_2,
                average_en=LTC2986.Diode_Running_Average_En.OFF,
                excitation_current=LTC2986.Diode_Excitation_Current.CUR_80UA_320UA_640UA,
                diode_non_ideality=1.0,
                channel_num=self._ltc2986.diode_channel
            )
            self._ltc2986.initialised = True

            self._logger.debug('LTC2986 init completed successfully')
        except Exception as e:
            self._ltc2986.pin_reset.set_value(1)
            self._ltc2986.critical_error('Failed to init LTC2986: {}'.format(e))

    def _config_bme280(self):
        try:
            self._bme280.initialised = False
            self._bme280.error = False
            self._bme280.error_message = False

            I2CDevice.enable_exceptions()
            self._bme280.device = BME280(use_spi=False, bus=self._bme280.i2c_bus)

            self._bme280.initialised = True

            self._logger.debug('BME280 init completed successfully')
        except Exception as e:
            self._bme280.critical_error('Failed to init BME280: {}'.format(e))

    def _config_si5344(self):
        try:
            self._si5344.initialised = False
            self._si5344.error = False
            self._si5344.error_message = False

            I2CDevice.enable_exceptions()
            self._si5344.device = SI5344(i2c_address=0x68)

            # As soon as init is complete, set the default clock settings
            self.clkgen_set_config(self._si5344.default_config)

            self._si5344.initialised = True

            self._logger.debug('SI5344 init completed successfully')
        except Exception as e:
            self._si5344.critical_error('Failed to init SI5344: {}'.format(e))

    # FireFlies are pretty application specific, and therefore will not use built-in templates
    # They do however need to add custom additions to the parameter tree, which will be 'generic'.
    # The application parameter tree will later use these access functions directly.
    def _config_firefly_array(self):
        for fireflyDevice in self._firefly_array:
            try:
                fireflyDevice.initialised = False
                fireflyDevice.error = False
                fireflyDevice.error_message = False

                I2CDevice.enable_exceptions()
                fireflyDevice.device = FireFly(
                    base_address=0x50,
                    select_line=self._pin_handler.get_pin(fireflyDevice.select_pin_friendlyname)
                )

                # Initially turn off the FireFly channels
                fireflyDevice.device.disable_tx_channels(FireFly.CHANNEL_ALL)

                fireflyDevice.initialised = True

                self._logger.debug(
                    'FireFly {} init completed successfully'.format(fireflyDevice.name)
                )
            except Exception as e:
                fireflyDevice.critical_error(
                    'Failed to init FireFly {}: {}'.format(fireflyDevice.name, e)
                )

