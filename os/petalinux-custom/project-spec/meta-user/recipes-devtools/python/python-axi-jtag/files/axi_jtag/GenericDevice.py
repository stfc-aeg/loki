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
    def __init__(self, ir_length: int, config_file_name: Optional[str]=None) -> None:
        self.ir_length = ir_length
        self.device_config_file_name = config_file_name
        self.instructions = None
        self.register_info = None
        self.registers = []
        self.last_instruction = ""
        self.bsr_len = None

        if self.device_config_file_name:
            base_dir = os.path.dirname(os.path.abspath(__file__))
            instructions_file_path = os.path.join(base_dir, "device_config", self.device_config_file_name)
            with open(instructions_file_path) as json_file:
                file = json.load(json_file)
                self.instructions = file["instructions"]
                self.register_info = file["registers"]

                if "BSR_LENGTH" in file:
                    self.bsr_len = file["BSR_LENGTH"]
            
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
                raise InvalidInstructionException(
                    f"Instruction: {instruction} has not been defined in {self.device_config_file_name}"
                    )
            
            instruction_code = self.instructions[instruction]
        
        self.last_instruction = instruction

        self.chain.shift_ir(self, instruction_code)
    
    def shift_dr(self, value: Optional[str]="0") -> str:
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
    
    def update_reg(self, reg_name: str, bits: str):
        reg = self.get_register(reg_name)

        reg.update(self, bits)
    
    def boundary_scan_read(self, tdi: str):
        if not self.bsr_len:
            raise InvalidInstructionException(
                f"The length of the boundary scan register has not been defined in {self.device_config_file_name}"
                )
        
        if not self.instructions:
            raise InvalidInstructionException(f"No instruction file provided")
        
        if len(tdi) != self.bsr_len:
            raise ValueError(
                "The TDI to be shifted through the DR must be the same length as the boundary scan register"
                )

        self.chain.reset_state_machine()

        self.chain.shift_ir(self, self.instructions["SAMPLE"])
        self.chain.move_into_state("update_ir")

        self.chain.shift_dr(self, self.bsr_len, tdi)
        self.chain.move_into_state("update_dr")

        output = self.chain.shift_dr(self, self.bsr_len, '0' * self.bsr_len)

        return output