from .tap_controller import tap_controller

class JTAGChain():

    def __init__(self, devices: list):
        self.devices = devices
        self.total_ir_length = 0
        self.tap_controller = tap_controller("/dev/uio0")

        for device in self.devices:
            device.set_chain(self)
            self.total_ir_length += device.ir_length
    
    def shift_ir(self, jtag_device, instruction: str):
        device_index = 0
        for device in self.devices:
            if device == jtag_device:
                break
            device_index += 1
        tdi_string = self.construct_tdi(device_index, instruction)

        # Convert string to bytearray
        byte_array = bytearray(int(tdi_string[i:i+8], 2) for i in range(0, len(tdi_string), 8))
        self.tap_controller.shift_ir(byte_array, self.total_ir_length)
    
    def shift_dr(self):
        total_bits_to_shift = len(self.devices) + 31

        # Shift through more bits than needed to guarantee all bits are shifted out
        self.tap_controller.shift_dr(bytearray([0b00000000] * ((total_bits_to_shift + 8) // 8)), total_bits_to_shift)
    
    def construct_tdi(self, target_index: int, instruction: str):
        tdi = ""
        for device in self.devices:
            if self.devices[target_index] == device:
                tdi += instruction
            else:
                # Put other devices in BYPASS
                tdi += "1" * device.ir_length

        return tdi
    
    def read_all_id_codes(self):
        self.tap_controller.read_id_codes()