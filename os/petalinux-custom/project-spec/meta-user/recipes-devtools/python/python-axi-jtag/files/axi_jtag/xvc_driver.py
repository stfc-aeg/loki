from uio.utils import fix_ctypes_struct
from uio.device import Uio
import ctypes
from ctypes import c_uint32
from .firmware_utils import get_uio_path_from_address, get_uio_addresses

# Register offsets
# LENGTH_REG_OFFSET = 0x0
# TMS_REG_OFFSET = 0x4
# TDI_REG_OFFSET = 0x8
# TDO_REG_OFFSET = 0xC
# CONTROL_REG_OFFSET = 0x10

@fix_ctypes_struct
class _xvc_driver_Cfg(ctypes.Structure):
    _fields_ = [
        ("LENGTH_REG", c_uint32),
        ("TMS_REG", c_uint32),
        ("TDI_REG", c_uint32),
        ("TDO_REG", c_uint32),
        ("CONTROL_REG", c_uint32)
    ]

class ByteLengthMismatchException(Exception):
    """
    Exception for when the 2 bytearray inputs are not the same length
    """
    def __init__(self, message: str) -> None:
        self.message = message
        super().__init__(self.message)
    
class xvc_driver():
    def __init__(self, path_or_address: str) -> None:
        """
        Initialise a new XVC driver.

        Args:
            path_or_address:    Either a path to the UIO device (e.g. /dev/uio0) or the memory
                                address at which the device is found, as either an integer or
                                string starting with '0x'.
        """
        # If an address is given, determine the path from it
        if isinstance(path_or_address, str) and path_or_address.startswith('/dev/'):
            path = path_or_address
        else:
            path = get_uio_path_from_address(path_or_address)

        self._uio_device = Uio(path)
        if 'debug_bridge' not in str(self._uio_device.syspath):
            raise RuntimeError(
                'UIO device at {}({}) is not a debug_bridge: {}. Available: {}'.format(
                    path_or_address, path, self._uio_device.syspath, get_uio_addresses(True, 'debug_bridge')
                ))

        self.cfg = self._uio_device.map(_xvc_driver_Cfg)
        self.tdo_output = []
        
    def transfer_bits(self, tms_array: bytearray, tdi_array: bytearray, num_bits) -> None:
        
        if len(tms_array) != len(tdi_array):
            raise ByteLengthMismatchException(f"Byte arrays must be the same length. TMS: {len(tms_array)}. TDI: {len(tdi_array)}")
        
        current_bit = 0
        while (current_bit < num_bits):
            shift_num_bits = min(32, num_bits - current_bit)
            
            byte_start = current_bit // 8
            byte_end = (current_bit + shift_num_bits + 7) // 8
            
            tms_chunk = tms_array[byte_start:byte_end]
            tdi_chunk = tdi_array[byte_start:byte_end][::-1]
            
            self.cfg.LENGTH_REG = shift_num_bits
            
            # Perform shift and add output to the list
            tdo_val = self.xil_xvc_shift_bits(tms_chunk, tdi_chunk)
            tdo_string = bin(tdo_val)[2:]
            relevant_tdo_val = int(tdo_string[-shift_num_bits:], 2)
            self.tdo_output.append((relevant_tdo_val, shift_num_bits))
            
            current_bit += shift_num_bits
        
    def xil_xvc_shift_bits(self, tms_bits: bytes, tdi_bits: bytes) -> int:
        tms_value = int.from_bytes(tms_bits, "little")
        tdi_value = int.from_bytes(tdi_bits, "little")
        
        c_uint32(tms_value)
        c_uint32(tdi_value)
        
        # Set TMS bits
        self.cfg.TMS_REG = tms_value
        
        # set TDI bits and shift data out
        self.cfg.TDI_REG = tdi_value
        
        # Read control register
        control_reg_data = self.cfg.CONTROL_REG
        
        # Enable shift operation in control register
        write_reg_data = control_reg_data | 0x01
        
        # Write control register
        self.cfg.CONTROL_REG = write_reg_data
        
        count = 100
        while (count):
            control_reg_data = self.cfg.CONTROL_REG
            if ((control_reg_data & 0b1) == 0):
                break
            count -= 1
        
        if (count == 0):
            print("XVC transaction timed out")
        
        tdo_bits = self.cfg.TDO_REG
            
        return tdo_bits

        