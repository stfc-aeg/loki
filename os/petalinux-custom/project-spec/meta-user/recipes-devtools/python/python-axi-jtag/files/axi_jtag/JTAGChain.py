from .tap_controller import tap_controller
from .utils import get_bin_string
import math

class JTAGChain():

    def __init__(self, devices: list) -> None:
        self.devices = devices
        self.total_ir_length = 0
        self.total_devices = len(devices)
        self.tap_controller = tap_controller("/dev/uio0")

        for device in self.devices:
            device.set_chain(self)
            self.total_ir_length += device.ir_length
    
    def shift_ir(self, jtag_device, instruction: str) -> None:
        device_index = self.get_device_index(jtag_device)
        tdi_string = self.construct_tdi(device_index, instruction)

        # Convert string to bytearray
        byte_array = bytearray(int(tdi_string[i:i+8], 2) for i in range(0, len(tdi_string), 8))
        self.tap_controller.shift_ir(byte_array, self.total_ir_length)
    
    def shift_dr(self, jtag_device, reg_length: int, value: str) -> str:
        total_bits_to_shift = self.total_devices + (reg_length - 1)

        if value != "0":
            device_index = self.get_device_index(jtag_device)
            tdi_string = self.construct_tdi(device_index, value)

            # Convert string to bytearray
            byte_array = bytearray(int(tdi_string[i:i+8], 2) for i in range(0, len(tdi_string), 8))
            output = self.tap_controller.shift_dr(byte_array, total_bits_to_shift)
        else:
            # Shift through more bits than needed to guarantee all bits are shifted out
            output = self.tap_controller.shift_dr(bytearray([0b00000000] * ((total_bits_to_shift + 8) // 8)), total_bits_to_shift)

        device_index = self.get_device_index(jtag_device)

        if total_bits_to_shift <= 32:
            if output[-1][0] == 0:
                return "0" * output[-1][1]
            
            return get_bin_string(output[-1])
        else:
            bin_string_array = []
            for i in range(1, (math.ceil(total_bits_to_shift / 32) + 1)):
                bin_string_array.append(output[-i])
            
            # Strip bits to discard devices in bypass
            front_bits_to_strip = 0 + device_index
            end_bits_to_strip = self.total_devices - (device_index + 1)

            bin_string = get_bin_string(bin_string_array)

            if end_bits_to_strip == 0:
                return bin_string[front_bits_to_strip:]
            else:
                return bin_string[front_bits_to_strip:-end_bits_to_strip]
    
    def construct_tdi(self, target_index: int, instruction: str) -> str:
        tdi = ""
        for device in self.devices:
            if self.devices[target_index] == device:
                tdi += instruction
            else:
                # Put other devices in BYPASS
                tdi += "1" * device.ir_length

        return tdi
    
    def read_all_id_codes(self) -> None:
        self.tap_controller.read_id_codes()
    
    def move_into_state(self, state: str) -> None:
        self.tap_controller.go_to_state(state)
    
    def get_device_index(self, jtag_device) -> int:
        device_index = 0
        for device in self.devices:
            if device == jtag_device:
                break
            device_index += 1
        
        return device_index
    
    def reset_state_machine(self):
        self.tap_controller.reset()