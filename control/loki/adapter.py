from tornado.ioloop import IOLoop
# from tornado.escape import json_decode
# from odin.adapters.adapter import ApiAdapter, ApiAdapterResponse, request_types, response_types, wants_metadata
from odin.adapters.async_adapter import AsyncApiAdapter
# from odin._version import get_versions
# from odin.adapters.parameter_tree import ParameterTreeError
from odin.adapters.parameter_tree import ParameterTree

import logging
import os
import gpiod
# import concurrent.futures as futures
from odin_devices import gpio_bus

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
# If id is a string, use gpiod.find_line to get the pin, otherwise use typical gpiod.get_line.
def get_gpiod_line_byType(line_id):
    if line_id is None:
        return None

    try:
        # gpiochip0 is assumed since it is the only available chip on the ZynqMP platform
        chip = gpiod.Chip('gpiochip0')
        return chip.get_line(int(line_id))
    except ValueError:
        return gpiod.find_line(line_id)

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

    # TODO (remove or rewrite this comment) This is more like a 'pin override mapping' when supplied by the user. Though we do need to store the defaults.
    class PinMapping():
        def __init__(self, gpiod_name, gpiod_num, forceNum,  noReq, isNC):
            self.gpiod_name = gpiod_name
            self.gpiod_num = gpiod_num
            self.forceNum = forceNum
            self.noReq = noReq
            self.isNC = isNC

    # List of pins that the carrier expects to be defined by the child or automatically by detect_control_pins.
    # Must have either a pin number or gpiod name to get the pin from gpiod.
    # name:
    # gpiod name:   Will be used to get the pin from gpiod. Default names already populated.
    # gpiod num:    Alternative to using a gpiod name. Will be ignored unless forceNum set True.
    # noReq:        Instructs carrier not to request the pin itself (expect child to do this with specific settings)
    # isNC:         Tells the carrier not to use this pin. May be allowed depending on the pin. clarify later. todo
    _default_pinmap = {
            # name                              gpiod name              gpiod num   forceNum    noReq       isNC
            'BACKPLANE nPRESENT': PinMapping(   'BACKPLANE nPRESENT',   None,       False,      False,      False   ),
            'APP nPRESENT': PinMapping(         'APP nPRESENT',         None,       False,      False,      False   ),
            'BUTTON0': PinMapping(              'BUTTON0',              None,       False,      False,      False   ),
            'BUTTON1': PinMapping(              'BUTTON1',              None,       False,      False,      False   ),
            'CTRL1': PinMapping(                'CTRL1',                None,       False,      True,      False   ),   # Will be defined but not reserved by LOKI
            'PERIPHERAL_nRST': PinMapping(      'PERIPHERAL_nRST',      None,       False,      False,      False   ),
            'APPLICATION nRST': PinMapping(     'APPLICATION nRST',     None,       False,      False,      False   ),
            'LED0': PinMapping(                 'LED0',                 None,       False,      False,      False   ),
            'LED1': PinMapping(                 'LED1',                 None,       False,      False,      False   ),
            'LED2': PinMapping(                 'LED2',                 None,       False,      False,      False   ),
            'LED3': PinMapping(                 'LED3',                 None,       False,      False,      False   ),
    }

    # todo ideally the base class should avoid refferring to specific devices in its external interfaces.

    def __init__(self, **kwargs):
        self._supported_extensions = []
        self.setup_control_pins2(kwargs)
        self._paramtree = ParameterTree(self._gen_paramtree_dict())

        # todo use the adapter_options?

        # todo set up a logger

        # Init the pin interface etc, however do not override existing pins from set_control_pin().
        #self._pinmap = self._default_pinmap
        #self.setup_gpio_bus()
        #self.detect_control_pins(self._custom_pinmap, respect_custom=True)
        # todo

        # Check that other info, like bus numbers is provided by child, otherwise throw error.
        # todo

        # Get the current state of the enables before starting the state machines
        #self._sync_enable_states()
        # todo

        # Create device handlers but do not init
        # todo

        # Set up device tree and pass to adapter(?)
        # todo

        # Set up state machines and timer loops (potentially in carrier)
        # todo

    @property
    @abstractmethod
    def variant(self):
        pass

    def setup_control_pins2(self, options):
        # options  examples:     pin_id_asic_cs = 'ASIC_nRST'
        #                       pin_id_asic_cs = 123

        # The value can be a pin number (assumed gpiochip0) or a pin name from the devicetree
        # Setting the pin to None will lead to it being skipped.

        # Create pin ID list ONLY if it does not already exist. This means derived classes can create it and alter pin defaults.
        if not hasattr(self, '_pin_ids'):
            self._pin_ids = {}

        # Settings from options / hardcoded default will only be used if the key does not already exist
        # Order of precedence (high -> low): already in _pin_ids -> found in options -> hardcoded default
        # setdefault options:   (<storage name>,    options.get(<options key>,      <hardcoded value>))
        self._pin_ids.setdefault('app_present',     options.get('pin_id_app_present',   'APP nPRESENT'))
        self._pin_ids.setdefault('bkpln_present',     options.get('pin_id_bkpln_present',   'BACKPLANE nPRESENT'))
        self._pin_ids.setdefault('app_rst',     options.get('pin_id_app_rst',   'APPLICATION nRST'))
        self._pin_ids.setdefault('per_rst',     options.get('pin_id_per_rst',   'PERIPHERAL nRST'))

        # todo alter this; really, any options should override everything else...

        # todo add options for reset and enabled signals being active low / high

        print('Control pin mappings settled: {}'.format(self._pin_ids))

        # Request pins now they have been found (or not if they are set to None)
        # Inversions should take place here
        # todo for now, stick to control pins. LEDs and user buttons may be a separate support extension to allow for different carrier implementations (e.g. LEDs switching high or low...)

        self._pin_app_present = get_gpiod_line_byType(self._pin_ids['app_present'])
        if self._pin_app_present is not None:
            self._pin_app_present.request(
                    consumer='LOKI',
                    type=gpiod.LINE_REQ_DIR_IN,
                    flags= gpiod.LINE_REQ_FLAG_ACTIVE_LOW,
                    default_val=0)

        self._pin_bkpln_present = get_gpiod_line_byType(self._pin_ids['bkpln_present'])
        if self._pin_bkpln_present is not None:
            self._pin_bkpln_present.request(
                    consumer='LOKI',
                    type=gpiod.LINE_REQ_DIR_IN,
                    flags= gpiod.LINE_REQ_FLAG_ACTIVE_LOW,
                    default_val=0)

        self._pin_app_rst = get_gpiod_line_byType(self._pin_ids['app_rst'])
        if self._pin_app_rst is not None:
            self._pin_app_rst.request(
                    consumer='LOKI',
                    type=gpiod.LINE_REQ_DIR_OUT,
                    flags= gpiod.LINE_REQ_FLAG_ACTIVE_LOW,
                    default_val=0)

        self._pin_per_rst = get_gpiod_line_byType(self._pin_ids['per_rst'])
        if self._pin_per_rst is not None:
            self._pin_per_rst.request(
                    consumer='LOKI',
                    type=gpiod.LINE_REQ_DIR_OUT,
                    flags= gpiod.LINE_REQ_FLAG_ACTIVE_LOW,
                    default_val=0)

        #todo add more pins

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
                'leds': {
                    'LED0': (lambda: self.get_led(0), lambda enable: self.set_led(0,  enable), {
                        "description": "LED0 Enable",
                        }),
                    'LED1': (lambda: self.get_led(1), lambda enable: self.set_led(1,  enable), {
                        "description": "LED1 Enable",
                        }),
                    'LED2': (lambda: self.get_led(2), lambda enable: self.set_led(2,  enable), {
                        "description": "LED2 Enable",
                        }),
                    'LED3': (lambda: self.get_led(3), lambda enable: self.set_led(3,  enable), {
                        "description": "LED3 Enable",
                        }),
                    },
                'buttons': {
                    'button0': (lambda: self.get_button_state(0), None, {
                        "description": "button0 Pressed",
                        }),
                    'button1': (lambda: self.get_button_state(1), None, {
                        "description": "button1 Pressed",
                        }),
                    },
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

    ########################################
    # Built-in Zynq Temperature Monitoring #
    ########################################

    def get_zynq_ams_temp_cached(self, temp_name):
        # These AMS temperatures should by synced by the deadslow loop. Latest readings returned externally.
        # todo hasattr is kind of a dirty fix
        if hasattr(self, '_zynq_ams'):
            return self._zynq_ams[temp_name]
        else:
            return None

    def _get_zynq_ams_temp_raw(self, temp_name):
        with open('/sys/bus/iio/devices/iio:device0/in_temp{}_temp_raw'.format(temp_name), 'r') as f:
            temp_raw = int(f.read())

        with open('/sys/bus/iio/devices/iio:device0/in_temp{}_temp_offset'.format(temp_name), 'r') as f:
            temp_offset = int(f.read())

        with open('/sys/bus/iio/devices/iio:device0/in_temp{}_temp_scale'.format(temp_name), 'r') as f:
            temp_scale = float(f.read())

        return round(((temp_raw+temp_offset)*temp_scale)/1000, 2)

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
        # todo use a cached value
        return bool(self._pin_bkpln_present.get_value() == 1)

    def get_app_present(self):
        # todo use a cached value
        return bool(self._pin_app_present.get_value() == 1)

    def get_button_state_raw(self, button_num):
        try:
            if button_num == 0:
                return (self._pin_button0.get_value() == 0)
            elif button_num == 1:
                return (self._pin_button1.get_value() == 0)
            else:
                raise Exception('button number {} does not exist'.format(button_num))
        except AttributeError as e:
            if 'NoneType' in e:
                raise AttributeError('button {} was not initialised'.format(button_num))
            else:
                raise

    def get_button_state(self, button_num):
        # todo
        pass

    def _sync_enable_states(self):
        self._app_enabled = bool(self._pin_app_rst.get_value() == 1)
        self._peripherals_enabled = bool(self._pin_per_rst.get_value() == 1)

    def set_app_enabled(self, enable=True):
        self._pin_app_rst.set_value(enable)
        self._sync_enable_states()

    def get_app_enabled(self):
        if not hasattr(self, '_app_enabled'):
            self._sync_enable_states()
        return self._app_enabled

    def set_peripherals_enabled(self, enable=True):
        self._pin_per_rst.set_value(not(enable))
        self._sync_enable_states()

    def get_peripherals_enabled(self):
        if not hasattr(self, '_peripherals_enabled'):
            self._sync_enable_states()
        return self._peripherals_enabled

    def set_led(self, led_num, on=True, switchedLow=True):
        raise Exception('Not implemented in base carrier adapter')

    def get_led_raw(self, led_num, switchedLow=True):
        try:
            # Return True if the LED is enabled, respecting being switched low or high
            if led_num == 0:
                return ((self._pin_led0.get_value() == 1) != switchedLow)
            elif led_num == 1:
                return ((self._pin_led1.get_value() == 1) != switchedLow)
            elif led_num == 2:
                return ((self._pin_led2.get_value() == 1) != switchedLow)
            elif led_num == 3:
                return ((self._pin_led3.get_value() == 1) != switchedLow)
            else:
                raise Exception('button number {} does not exist'.format(led_num))
        except AttributeError as e:
            if 'NoneType' in e:
                raise AttributeError('button {} was not initialised'.format(led_num))
            else:
                raise
        raise Exception ('Not implemented in base carrier adapter')

    def get_led(self, led_num):
        # todo
        pass

    # Provide access to carrier-specific interfaces for application use, via inter-adapter communication

    def get_interface_spi(self):
        # Returns a dictionary of buses to be used by the application. At least implement 'APP' and 'PERIPHERAL'.
        # Each key is a string name, each value is a bus number.
        raise Exception('Not implemented in base carrier adapter')

    def get_interface_i2c(self):
        # Returns a dictionary of buses to be used by the application. At least implement 'PERIPHERAL'.
        raise Exception('Not implemented in base carrier adapter')


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
                'drivername' : (lambda: self.clkgen_drivername, None, {"description": "Name of the device providing clock generator support"}),
                'num_outputs' : (lambda: self.clkgen_numchannels, None, {"description": "Number of output channels available"}),
                'config_file' : (self.clkgen_get_config, self.clkgen_set_config, {"description": "Current configuration file loaded for clock config"}),
                'confing_files_avail' : (self.clkgen_get_config_avail, None, {"description": "Available config files to choose from"}),
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
                    lambda: self.dac_get_output(output_num),
                    lambda: self.dac_set_output(output_num),
                    {"description": "Get / Set DAC output value", "units": "v"})

        base_tree['dac'] = {
                'drivername': (
                    lambda: self.clkgen_drivername,
                    None,
                    {"description": "Name of the device providing clock generator support"}),
                'num_outputs': (
                    lambda: self.clkgen_numchannels,
                    None,
                    {"description": "Number of output channels available"}),
                'outputs': output_tree,
                }

        return base_tree

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

        self._supported_extensions.append('dac')

    def _gen_paramtree_dict(self):
        base_tree = super(LokiCarrierEnvmonitor, self)._gen_paramtree_dict()

        # Expects this to be a list of (name, type, unit) tuples.
        # Type is typically 'temperature' or 'humidity'.
        # info is the dictionary passed to the paramtree including description, units etc.
        additional_sensors = self.env_sensor_info
        for (name, sType, info) in additional_sensors:
            # Create the new key if it does not exist for the sensor type, with a blank dictionary
            base_tree['environment'].setdefault(sType, {})

            # Add the sensor entry with its specific info
            base_tree['environment'][sType] = (lambda: self.env_get_sensor(name), None, info)

        return base_tree

    def _gen_paramtree_temp(self):
        temp_tree_dict = {
            # Add more temperatures in child carrier
            }

        return temp_tree_dict

    # dict, see above
    @property
    @abstractmethod
    def env_additional_sensors(self):
        pass

    # Get the (cached) version of a sensor reading that can be read as often as desired
    @abstractmethod
    def env_get_sensor(self, name):
        pass

class LokiCarrier_TEBF0808(LokiCarrier):
    # Special case; as a prototype with minimal support for devices alone. Should be combined with an
    # application-specific adapter for the associated daughter board, which relies on interfaces provided
    # by this adapter (buses, GPIO pins). This second adapter will need to implement things like clock
    # config, etc.

    # Many pins do not exist on this version of the carrier, therefore will not be requested (isNC True).
    _custom_pinmap = {
            # name                              gpiod name              gpiod num   forceNum    noReq       isNC
            'BUTTON0': LokiCarrier.PinMapping(  'BUTTON0',              None,       False,      False,      True    ),
            'BUTTON1': LokiCarrier.PinMapping(  'BUTTON1',              None,       False,      False,      True    ),
            'LED0': LokiCarrier.PinMapping(     'MIO40',                None,       False,      False,      False   ),  # This LED is user operated, if RGPIO deactivated
            'LED1': LokiCarrier.PinMapping(     'LED1',                 None,       False,      False,      True    ),
            'LED2': LokiCarrier.PinMapping(     'LED2',                 None,       False,      False,      True    ),
            'LED3': LokiCarrier.PinMapping(     'LED3',                 None,       False,      False,      True    ),
    }
    # Alter LED0 to be on the on-board LED
    variant = 'tebf0808'

    def __init__(self, **kwargs):
        # Set the pin for LED0 to on-board LED, unless already overridden in settings
        kwargs.setdefault('pin_led0', 'MIO40')

        super(LokiCarrier_TEBF0808, self).__init__(**kwargs)

    def get_interface_spi(self):
        return {'APP': 0, 'PERIPHERAL': 1}

    def get_interface_i2c(self):
        return {'PERIPHERAL': 1}


#############################################
# Carrier Class for Next Generation Carrier #
#############################################

# First iteration of the new carrier for LOKI
class LokiCarrier_1v0(LokiCarrierClockgen, LokiCarrierDAC, LokiCarrier):
    variant = 'LOKI 1v0'
    clkgen_drivername = 'SI5345'
    clkgen_numchannels = 10
    dac_num_outputs = 10

    def __init__(self, **kwargs):
        self.__clkgen_current_config = None
        self.__dac_outputval = {}

        super(LokiCarrier_1v0, self).__init__(**kwargs)

        #self.__clkgen_current_config = self.__clkgen_default_config

    def clkgen_get_config(self):
        # todo
        return self.__clkgen_current_config
        pass

    def clkgen_set_config(self, configname):
        print ('Setting clock configuration from {}'.format(configname))
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
        print ('Setting DAC output {} to {}'.format(output_num, voltage))
        self.__dac_outputval[output_num] = voltage
        # todo
        pass


#######################################################################
# Application-specific derived classes (option 2) example for MERCURY #
#######################################################################

# A class designed to exactly mimic the base adapter class, but provide suporrt for a custom LokiCarrier class
# providing additional functionality present on the ASIC carrier that aligns with functionality provided by the
# new carrier on-board.
class LokiAdapter_MERCURY(LokiAdapter):

    def __init__(self, **kwargs):
        # Init superclass
        super(LokiAdapter_MERCURY, self).__init__(**kwargs)

    def instantiate_carrier(self, carrier_type):
        # Add support for new carrier, otherwise default to those supported as standard
        if carrier_type == 'tebf0808_mercury':
            self._carrier = LokiCarrier_TEBF0808_MERCURY(self.options)
        else:
            super(LokiAdapter_MERCURY, self).instantiate_carrier(carrier_type)


