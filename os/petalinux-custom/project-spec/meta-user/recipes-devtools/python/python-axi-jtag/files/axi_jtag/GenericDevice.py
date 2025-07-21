import json
import os
import re
from typing import List, Optional
from .JTAGReg import JTAGReg

class InvalidInstructionException(Exception):
    """
    Exception for when an instruction name is provided, but no
    instructions file has been provided
    """
    def __init__(self, message):
        self.message = message
        super().__init__(self.message)

class GenericDevice():

    def __init__(self, ir_length: int, config_file: Optional[str]=None) -> None:
        self.ir_length = ir_length
        self.instructions_file = config_file
        self.instructions = None
        self.register_info = None
        self.registers = []
        self.last_instruction = ""

        if self.instructions_file:
            base_dir = os.path.dirname(os.path.abspath(__file__))
            instructions_file_path = os.path.join(base_dir, "device_config", self.instructions_file)
            with open(instructions_file_path) as json_file:
                file = json.load(json_file)
                self.instructions = file["instructions"]
                self.register_info = file["registers"]
            
            self.registers = [JTAGReg.parse_reg(reg) for reg in self.register_info]

    def set_chain(self, chain) -> None:
        self.chain = chain
    
    def shift_ir(self, instruction: str) -> None:
        if not re.search("[a-zA-Z]", instruction):
            instruction_code = instruction
        else:
            if not self.instructions:
                raise InvalidInstructionException(
                    "No instructions file provided, please provide one or provide the instruction code"
                    )
            
            if not instruction in self.instructions:
                raise InvalidInstructionException(f"Instruction: {instruction} has not been defined in {self.instructions_file}")
            
            instruction_code = self.instructions[instruction]
        
        self.last_instruction = instruction

        self.chain.shift_ir(self, instruction_code)
    
    def shift_dr(self, value: Optional[int]=0) -> str:
        reg = self.get_register(self.last_instruction)

        return self.chain.shift_dr(self, reg.total_bit_length, value)

    def get_all_registers(self) -> List[JTAGReg]:
        return self.registers
    
    def get_register(self, name: str) -> JTAGReg:
        regs = list(filter(lambda reg: name == reg.get_name(), self.registers))

        return regs[0]
    
    def get_reg_field_value(self, reg_name: str, field_name: str):
        reg = self.get_register(reg_name)
        return reg.get_field_value(field_name, self)
    
    def update_reg(self, reg_name: str, value: int):
        reg = self.get_register(reg_name)

        reg.update(self, value)