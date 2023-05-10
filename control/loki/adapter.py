from tornado.ioloop import IOLoop
# from tornado.escape import json_decode
# from odin.adapters.adapter import ApiAdapter, ApiAdapterResponse, request_types, response_types, wants_metadata
from odin.adapters.async_adapter import AsyncApiAdapter
# from odin._version import get_versions
# from odin.adapters.parameter_tree import ParameterTreeError
from odin.adapters.parameter_tree import ParameterTree

import logging
import os
# import gpiod
# import concurrent.futures as futures
from odin_devices import gpio_bus

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
        slow_delay = self.options.get('slow_update_delay_s')
        deadslow_delay = self.options.get('deadslow_update_delay_s')
        self._slow_delay = slow_delay if slow_delay else 1.0                # Use option or 1.0s by default
        self._deadslow_delay = deadslow_delay if deadslow_delay else 5.0    # Use option or 5.0s by default
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


class LokiCarrier():
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
    _variant = 'base'

    # todo ideally the base class should avoid refferring to specific devices in its external interfaces.

    def __init__(self, adapter_options, custom_pinmap=None, **kwargs):

        # todo use the adapter_options?

        # todo set up a logger

        # Init the pin interface etc, however do not override existing pins from set_control_pin().
        self._pinmap = self._default_pinmap
        self.setup_gpio_bus()
        self.detect_control_pins(self._custom_pinmap, respect_custom=True)

        # Check that other info, like bus numbers is provided by child, otherwise throw error.
        # todo

        # Get the current state of the enables before starting the state machines
        self._sync_enable_states()

        # Create device handlers but do not init
        # todo

        # Set up device tree and pass to adapter(?)
        # todo
        self._gen_paramtree()

        # Set up state machines and timer loops (potentially in carrier)
        # todo

    def setup_gpio_bus(self):
        # Create a bus that can reference all pins exposed to ZynqMP (including MIO), for protected carrier pins only.
        self._gpio_bus = gpio_bus.GPIO_Bus(110, 0, 0)
        self._gpio_bus.set_consumer_name('LOKI Carrier Control')

        # Create a duplicate bus that can claim pins on behalf of the application
        self._gpio_bus_app = gpio_bus.GPIO_Bus(110, 0, 0)
        self._gpio_bus_app.set_consumer_name('LOKI Application')

    def setup_control_pins(self, custom_pins, respect_custom=True):
        # Attempt to automatically detect the control pin numbers from their
        # names propagated through the device tree. respect_custom being true
        # will use the custom pin rather than the default.
        # (typically because a child class has defined it already).

        # The custom pinmap is only for editing the default control pins, not
        # adding new ones. Flag any unique names in custom pins.
        if any([x not in self._pinmap for x in custom_pins.keys()]):
            raise Exception('Cannot alter a pin mapping for a named pin not in the following list: {}'.format(custom_pins.keys()))

        # If the child carrier (or application) has overridden something from
        # the default pinmap, use the overridden version.
        for pin_name in self._pinmap.keys():
            # If the child carrier has overridden the pin, apply it
            if pin_name in custom_pins.keys() and respect_custom:
                self._pinmap[pin_name] = custom_pins[pin_name]

        # Print out the final pinmap before pins are actually requested
        logging.debug('Final pinmap: {}'.format(self._pinmap))

        # If the pin is using a name rather than an offset number, convert it. From this
        # point, all pins should have offset numbers.
        for pin_name in self._pinmap.keys():

            # If the pin is NC, no further processing needs to occur
            if not self._pinmap[pin_name].isNC:

                # If forceNum is set, the default name should be ignored anyway
                if not self._pinmap[pin_name].forceNum:
                    self._pinmap[pin_name].gpiod_num = self._gpiod_name_to_num(self._pinmap[pin_name].gpiod_name)

                # If the pin does not have a number at this point, it is invalid
                if self._pinmap[pin_name].gpiod_num is None:
                    raise Exception('Pin {} could not resolve a gpiod offset number'.format(pin_name))

        # Request pins from gpiod, checking first that they are not NC, or noReq.
        if not self._pinmap['BUTTON0'].isNC:
            self._pin_button0 = self._gpio_bus.get_pin(
                    index=self._pinmap['BUTTON0'].gpiod_num,
                    direction=gpio_bus.GPIO_Bus.DIR_INPUT,
                    no_request=self._pinmap['BUTTON0'].noReq)
        else:
            self._pin_button0 = None

        if not self._pinmap['BUTTON1'].isNC:
            self._pin_button1 = self._gpio_bus.get_pin(
                    index=self._pinmap['BUTTON1'].gpiod_num,
                    direction=gpio_bus.GPIO_Bus.DIR_INPUT,
                    no_request=self._pinmap['BUTTON1'].noReq)
        else:
            self._pin_button1 = None

        if not self._pinmap['APP nPRESENT'].isNC:
            self._pin_app_npres = self._gpio_bus.get_pin(
                    index=self._pinmap['APP nPRESENT'].gpiod_num,
                    direction=gpio_bus.GPIO_Bus.DIR_INPUT,
                    no_request=self._pinmap['APP nPRESENT'].noReq)
        else:
            self._pin_app_npres = None

        if not self._pinmap['BACKPLANE nPRESENT'].isNC:
            self._pin_bkpln_npres = self._gpio_bus.get_pin(
                    index=self._pinmap['BACKPLANE nPRESENT'].gpiod_num,
                    direction=gpio_bus.GPIO_Bus.DIR_INPUT,
                    no_request=self._pinmap['BACKPLANE nPRESENT'].noReq)
        else:
            self._pin_bkpln_npres = None

        if not self._pinmap['APPLICATION nRST'].isNC:
            self._pin_app_nrst = self._gpio_bus.get_pin(
                    index=self._pinmap['APPLICATION nRST'].gpiod_num,
                    direction=gpio_bus.GPIO_Bus.DIR_OUTPUT,
                    no_request=self._pinmap['APPLICATION nRST'].noReq)
        else:
            self._pin_app_nrst = None

        if not self._pinmap['PERIPHERAL nRST'].isNC:
            self._pin_per_nrst = self._gpio_bus.get_pin(
                    index=self._pinmap['PERIPHERAL nRST'].gpiod_num,
                    direction=gpio_bus.GPIO_Bus.DIR_OUTPUT,
                    no_request=self._pinmap['PERIPHERAL nRST'].noReq)
        else:
            self._pin_per_nrst = None

        if not self._pinmap['LED0'].isNC:
            self._pin_led0 = self._gpio_bus.get_pin(
                    index=self._pinmap['LED0'].gpiod_num,
                    direction=gpio_bus.GPIO_Bus.DIR_OUTPUT,
                    no_request=self._pinmap['LED0'].noReq)
        else:
            self._pin_led0 = None

        if not self._pinmap['LED1'].isNC:
            self._pin_led1 = self._gpio_bus.get_pin(
                    index=self._pinmap['LED1'].gpiod_num,
                    direction=gpio_bus.GPIO_Bus.DIR_OUTPUT,
                    no_request=self._pinmap['LED1'].noReq)
        else:
            self._pin_led1 = None

        if not self._pinmap['LED2'].isNC:
            self._pin_led2 = self._gpio_bus.get_pin(
                    index=self._pinmap['LED2'].gpiod_num,
                    direction=gpio_bus.GPIO_Bus.DIR_OUTPUT,
                    no_request=self._pinmap['LED2'].noReq)
        else:
            self._pin_led2 = None

        if not self._pinmap['LED3'].isNC:
            self._pin_led3 = self._gpio_bus.get_pin(
                    index=self._pinmap['LED3'].gpiod_num,
                    direction=gpio_bus.GPIO_Bus.DIR_OUTPUT,
                    no_request=self._pinmap['LED3'].noReq)
        else:
            self._pin_led3 = None

    def _gpiod_name_to_num(searchname):
        # Parse gpioinfo to get a line number from the name provided by device tree.
        gpioinfo = os.system('gpioinfo | grep {}'.format(_gpiod_name_to_num))
        print(gpioinfo)
        # todo

    def _gen_paramtree(self):
        self.base_tree = ParameterTree({
            'carrier_info': {
                'variant': (lambda: self._variant, None, {"description": "Carrier variant"}),
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
            'clkgen': ParameterTree(self._gen_paramtree_clk()),
            'dac': ParameterTree(self._gen_paramtree_dac()),
            'environment': {
                'temperature': ParameterTree(self._gen_paramtree_temp()),
                'humidity': ParameterTree(self._gen_paramtree_hum()),
                },
            })

    ####################
    # Clock Generation #
    ####################

    # Returns a dictionary to be converted to a parameter tree, meaning it can be easily extended by a child
    # class, which can optionally use the output of this base function or use its own unique implementation.
    def _gen_paramtree_clk(self):
        clk_tree_dict = {
            'clock_setting_filename': (self.get_application_clock_file, self.set_application_clock_file, {
                "description": "Set the clock configuration file",
                }),
            'clock_available_settings_files': (self.get_application_available_clock_settings, None, {
                "description": "List of available clock settings files that can be specified for clock_setting_filename",
                }),
            }

        return clk_tree_dict

    def set_application_clock_file(self, filename):
        raise Exception('Not implemented in base carrier adapter')

    def get_application_clock_file(self):
        raise Exception('Not implemented in base carrier adapter')

    def get_application_available_clock_settings(self):
        raise Exception('Not implemented in base carrier adapter')

    #######
    # DAC #
    #######

    def _gen_paramtree_dac(self):
        dac_tree_dict = {
            'num_outputs': (lambda: 0, None, {
                "description": "Number of DAC outputs available to set",
                }),
            'outputs': {
                # Outputs should take form: '<number>': (lambda: self.get_dac_output(<number>), lambda voltage: self.set_dac_output(<number>, voltage), ...
                },
            }

        return dac_tree_dict

    ########################################
    # Temperature  and Humidity Monitoring #
    ########################################

    def _gen_paramtree_temp(self):
        temp_tree_dict = {
            'zynq_pl': (lambda: self.get_zynq_ams_temp_cached('2_pl'), None, {
                "description": "Zynq SoC Programmable Logic Temperature",
                "unit": "C",
                }),
            'zynq_ps': (lambda: self.get_zynq_ams_temp_cached('0_ps'), None, {
                "description": "Zynq SoC Processing System Temperature",
                "unit": "C",
                }),
            'zynq_remote': (lambda: self.get_zynq_ams_temp_cached('1_remote'), None, {
                "description": "Zynq SoC Remote (?) Temperature",
                "unit": "C",
                }),
            # Add more temperatures in child carrier
            }

        return temp_tree_dict

    def get_zynq_ams_temp_cached(self, temp_name):
        # These AMS temperatures should by synced by the deadslow loop. Latest readings returned externally.
        return self._zynq_ams[temp_name]

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
        for ams_name in ['0_ps', '1_remote', '2_pl']:
            self._zynq_ams[ams_name] = self._get_zynq_ams_temp_raw(ams_name)

    def _gen_paramtree_hum(self):
        # No default humidity readings, but reserved for adding them in future. Child can still add sensors.
        hum_tree_dict = {}

        return hum_tree_dict

    #############################
    # Application Control Lines #
    #############################

    def get_backplane_present(self):
        return bool(self._pin_bkpln_npres.get_value() == 0)

    def get_app_present(self):
        return bool(self._pin_app_npres.get_value() == 0)

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

    def get_button_state_cached(self, button_num):
        # todo
        pass

    def _sync_enable_states(self):
        self._app_enabled = bool(self._pin_app_nrst.get_value() == 0)
        self._prehiperals_enabled = bool(self._pin_per_nrst.get_value() == 0)

    def set_app_enabled(self, enable=True):
        self._pin_app_nrst.set_value(not(enable))
        self._sync_enable_states()

    def get_app_enabled(self):
        return self._app_enabled

    def set_peripherals_enabled(self, enable=True):
        self._pin_per_nrst.set_value(not(enable))
        self._sync_enable_states()
    def get_peripherals_enabled(self):
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

    def get_led_cached(self, led_num):
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

    def get_gpio_bus(self):
        return self.gpio_bus_app


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
    _variant = 'tebf0808'

    def __init__(self, **kwargs):
        super(LokiCarrier_TEBF0808, self).__init__(**kwargs)

    def get_interface_spi(self):
        return {'APP': 0, 'PERIPHERAL': 1}

    def get_interface_i2c(self):
        return {'PERIPHERAL': 1}


#############################################
# Carrier Class for Next Generation Carrier #
#############################################

# First iteration of the new carrier for LOKI
class LokiCarrier_1v0(LokiCarrier):
    _variant = 'LOKI 1v0'

    def __init__(self, **kwargs):
        super(LokiCarrier_1v0, self).__init__(**kwargs)


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


# This is a special case derived carrier for the control of the original prototype. This application-specific
# hardware is out of scope for LOKI, however is still included since it shares so many similarities (the LOKI
# carrier being based on it). Future application-specific odin instances should create a supplimentary adapter
# for their own daughter board, using interfaces provided via the generic LOKICarrier_TEBF0808 class for access
# to things like I2C, SPI, and GPIO specifics.
class LokiCarrier_TEBF0808_MERCURY(LokiCarrier_TEBF0808):
    _variant = 'tebf0808_MERCURY'

    def __init__(self, **kwargs):
        super(LokiCarrier_TEBF0808_MERCURY, self).__init__(**kwargs)

        # todo request additional pins for daughter carrier-specific functionality functionality. However, leave out ASIC and application specifics. Try and keep 'generic'. This will be practice for loki 1v0...
        # todo add device drivers and hook them to power events for application and peripherals (VREG)

    def _gen_paramtree_clk(self):
        original_tree = super(LokiCarrier_TEBF0808_MERCURY, self)

        # todo this is a proof of concept that is pointless, remove it eventually. More useful for exposing functionality only available for this device, like stepping freqs etc
        original_tree['drivername'] = 'si5344'

