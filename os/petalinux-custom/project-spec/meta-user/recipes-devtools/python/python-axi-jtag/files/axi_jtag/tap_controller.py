from .xvc_driver import xvc_driver
from collections import deque
from typing import List
from .utils import get_bin_string

TAP_STATES = [
    "test_logic_reset", "run_test_idle", "select_dr_scan", "capture_dr", "shift_dr", "exit1_dr", "pause_dr", "exit2_dr",
    "update_dr", "select_ir_scan", "capture_ir", "shift_ir", "exit1_ir", "pause_ir", "exit2_ir", "update_ir"
]

TAP_TRANSITIONS = {
    ("test_logic_reset", 0): "run_test_idle",
    ("test_logic_reset", 1): "test_logic_reset",
    ("run_test_idle", 0): "run_test_idle",
    ("run_test_idle", 1): "select_dr_scan",
    ("select_dr_scan", 0): "capture_dr",
    ("select_dr_scan", 1): "select_ir_scan",
    ("capture_dr", 0): "shift_dr",
    ("capture_dr", 1): "exit1_dr",
    ("shift_dr", 0): "shift_dr",
    ("shift_dr", 1): "exit1_dr",
    ("exit1_dr", 0): "pause_dr",
    ("exit1_dr", 1): "update_dr",
    ("pause_dr", 0): "pause_dr",
    ("pause_dr", 1): "exit2_dr",
    ("exit2_dr", 0): "shift_dr",
    ("exit2_dr", 1): "update_dr",
    ("update_dr", 0): "run_test_idle",
    ("update_dr", 1): "select_dr_scan",
    ("select_ir_scan", 0): "capture_ir",
    ("select_ir_scan", 1): "test_logic_reset",
    ("capture_ir", 0): "shift_ir",
    ("capture_ir", 1): "exit1_ir",
    ("shift_ir", 0): "shift_ir",
    ("shift_ir", 1): "exit1_ir",
    ("exit1_ir", 0): "pause_ir",
    ("exit1_ir", 1): "update_ir",
    ("pause_ir", 0): "pause_ir",
    ("pause_ir", 1): "exit2_ir",
    ("exit2_ir", 0): "shift_ir",
    ("exit2_ir", 1): "update_ir",
    ("update_ir", 0): "run_test_idle",
    ("update_ir", 1): "select_dr_scan"
}

class InvalidTAPStateException(Exception):
    """
    Exception for when an invalid TAP state is entered
    """
    def __init__(self, message):
        self.message = message
        super().__init__(self.message)

class tap_controller():
    def __init__(self, path):
        self.driver = xvc_driver(path)
        self.current_state = "test_logic_reset"
    
    def get_tms_sequence(self, to_state: str):
        from_state = self.current_state
        visited = []
        queue = deque()
        queue.append((from_state, []))
        
        while queue:
            state, seq = queue.popleft()
            
            if state not in visited:
                visited.append(state)
            
            if state == to_state:
                seq = list(reversed(seq))
                result = 0
                for bit in seq:
                    result = (result << 1) | bit
                return [result], len(seq)
            
            for tms in [0, 1]:
                next_state = TAP_TRANSITIONS.get((state, tms))
                if next_state and (next_state, seq + [tms]) not in visited:
                    queue.append((next_state, seq + [tms]))
    
    def reset(self) -> None:
        tms_bits = bytearray([0b11111111])
        tdi_bits = bytearray([0b00000000])
        
        self.driver.transfer_bits(tms_bits, tdi_bits, 8)
        self.current_state = "test_logic_reset"
    
    def shift_ir(self, tdi_bits: bytearray, num_bits: int) -> None:
        self.go_to_state("shift_ir") 
        num_bytes = len(tdi_bits)
        tms_bits = bytearray([0] * num_bytes)
        tdi_bits = tdi_bits[:num_bytes]
        
        if num_bits > 0:
            last_bit = num_bits - 1
            byte_index = last_bit // 8
            bit_index = last_bit % 8
            tms_bits[byte_index] |= (1 << bit_index)
            
        self.driver.transfer_bits(tms_bits, tdi_bits, num_bits)
        self.current_state = "exit1_ir"
    
    def shift_dr(self, tdi_bits: bytearray, num_bits: int):
        self.go_to_state("shift_dr")
        num_bytes = len(tdi_bits)
        tms_bits = bytearray([0] * num_bytes)
        tdi_bits = tdi_bits[:num_bytes]
        
        if num_bits > 0:
            last_bit = num_bits - 1
            byte_index = last_bit // 8
            bit_index = last_bit % 8
            tms_bits[byte_index] |= (1 << bit_index)
        
        self.driver.transfer_bits(tms_bits, tdi_bits, num_bits)
        self.current_state = "exit1_dr"

        return self.driver.tdo_output
    
    def go_to_state(self, state: str) -> None:
        if state not in TAP_STATES:
            raise InvalidTAPStateException(f"Invalid TAP state, please choose any of: {TAP_STATES}")
        tms_seq, length = self.get_tms_sequence(state)
        tms_bits = bytearray(tms_seq)
        tdi_bits = bytearray([0b00000])
        self.driver.transfer_bits(tms_bits, tdi_bits, length)
        self.current_state = state
    
    def read_id_codes(self) -> list:
        self.reset()
        self.shift_dr(bytearray([0b00000000] * 4), 32)
        
        id_code_count = 1
        while True:
            self.shift_dr(bytearray([0b00000000] * 4), 32)
            if self.driver.tdo_output[-1][0] == 0:
                break
            id_code_count += 1
            
        self.go_to_state("run_test_idle")
        
        id_code_end_index = (32 * id_code_count) + 9
        id_codes = get_bin_string(self.driver.tdo_output)[9:id_code_end_index]
        id_code_array = []
        
        for device in range(id_code_count):
            start_index = (device * 32) + (3 * (device + 1))
            end_index = start_index + 32
            print(f"Device {device + 1} ID Code: {hex(int(id_codes[start_index:end_index], 2))}")
            id_code_array.append(id_codes[start_index:end_index])
        
        return id_code_array
            
    def decode_id_code(self) -> None:
        id_codes = self.read_id_codes()
        for id_code in range(len(id_codes)):
            print(f"=== Device {id_code + 1} ===")
            print(f"Version: {hex(int(id_codes[id_code][:4], 2))}")
            print(f"Part Number: {hex(int(id_codes[id_code][4:20], 2))}")
            print(f"Manufacturer: {hex(int(id_codes[id_code][20:31], 2))}")