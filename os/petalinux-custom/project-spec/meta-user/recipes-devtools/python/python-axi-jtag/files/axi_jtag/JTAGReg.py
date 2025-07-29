from .JTAGField import JTAGField
from typing import List

class FieldDoesNotExistException(Exception):
    """
    An exception for when a field is attempted to be accessed,
    but the field does not exist in this register
    """
    def __init__(self, message) -> None:
        self.message = message
        super().__init__(self.message)

class JTAGReg():
    def __init__(self, name: str, address: int, fields: List[JTAGField]) -> None:
        self.name = name
        self.address = address
        self.fields = fields
        self.total_bit_length = 0

        for field in self.fields:
            self.total_bit_length += field.bit_length
    
    def get_total_bit_length(self) -> int:
        return self.total_bit_length
    
    def get_name(self) -> str:
        return self.name
    
    def get_address(self) -> int:
        return self.address
    
    @staticmethod
    def parse_reg(reg: dict):
        name = reg["name"]
        address = reg["address"]
        fields = JTAGField.parse_fields(reg["fields"])

        return JTAGReg(name, address, fields)

    def get_field_value(self, field_name: str, device):
        field_to_read = None
        
        prev_bits = 0
        for field in self.fields:
            if field.get_name() == field_name:
                field_to_read = field
                break
            prev_bits += field.get_bit_length()
        
        if field_to_read is None:
            raise FieldDoesNotExistException(
                f"Field named {field_name} is not defined in register {self.get_name()}"
                )
        
        start_bit = prev_bits
        end_bit = start_bit + field_to_read.get_bit_length()

        output = self.update(device, "0")

        field_value = output[::-1][start_bit:end_bit]

        print(f"{field_to_read.get_name()}: {field_value}")

    def update(self, device, bits: str):
        device.shift_ir(self.name)

        return device.shift_dr(bits)
