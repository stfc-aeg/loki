import json
import os
import re
from typing import List, Optional
from .JTAGReg import JTAGReg

class InvalidConfigException(Exception):
    """
    Exception for when there is an issue with the provided
    device configuration file
    """
    def __init__(self, message):
        self.message = message
        super().__init__(self.message)

class InvalidInstructionException(Exception):
    """
    Exception for when an instruction name is provided, but no
    instructions have been provided in the configuration file
    """
    def __init__(self, message):
        self.message = message
        super().__init__(self.message)

class GenericDevice():
    def __init__(self, config_file_name: str) -> None:
        self.device_config_file_name = config_file_name
        self.instructions = None
        self.register_info = None
        self.registers = []
        self.last_instruction = ""
        self.bsr_len = None

        base_dir = os.path.dirname(os.path.abspath(__file__))
        instructions_file_path = os.path.join(base_dir, "device_config", self.device_config_file_name)
        with open(instructions_file_path) as json_file:
            file = json.load(json_file)

            if not "ir_length" in file:
                raise InvalidConfigException(
                    "An instruction register length must be specified in the configuration file"
                    )

            self.ir_length = file["ir_length"]

            if "instructions" in file:
                self.instructions = file["instructions"]

            if "registers" in file:
                self.register_info = file["registers"]
                self.registers = [JTAGReg.parse_reg(reg) for reg in self.register_info]

            if "bsr_length" in file:
                self.bsr_len = file["bsr_length"]

    def set_chain(self, chain) -> None:
        self.chain = chain
    
    def shift_ir(self, instruction: str) -> None:
        # If the instruction contains a letter, it is a name from the config file
        if not re.search("[a-zA-Z]", instruction):
            instruction_code = instruction
        else:
            if not self.instructions:
                raise InvalidInstructionException(f"No instructions provided in the configuration file")

            if not instruction in self.instructions:
                raise InvalidInstructionException(
                    f"Instruction: {instruction} has not been defined in {self.device_config_file_name}"
                    )
            
            instruction_code = self.instructions[instruction]
        
            self.last_instruction = instruction

        self.chain.shift_ir(self, instruction_code)
    
    def shift_dr(self, value: Optional[str]="0", length: Optional[int]=None) -> str:
        if self.last_instruction:
            reg = self.get_register(self.last_instruction)

            return self.chain.shift_dr(self, reg.total_bit_length, value)
        
        # If the instruction is not linked to a register, a length must be provided so the correct
        # number of bits can be shifted in
        if length:
            return self.chain.shift_dr(self, length, value)
        else:
            raise RuntimeError("No length provided, please provide a length to shift into the data register")

    def get_all_registers(self) -> List[JTAGReg]:
        return self.registers
    
    def get_register(self, name: str) -> JTAGReg:
        regs = list(filter(lambda reg: name == reg.get_name(), self.registers))
        
        if not regs:
            raise RuntimeError(f"No register named {name} found")

        return regs[0]
    
    def get_reg_field_value(self, reg_name: str, field_name: str):
        reg = self.get_register(reg_name)

        return reg.get_field_value(field_name, self)

    def update_reg_field_value(self, reg_name: str, field_name: str, value: str):
        reg = self.get_register(reg_name)

        reg.update_field(field_name, value, self)
    
    def read_reg(self, reg_name: str):
        reg = self.get_register(reg_name)

        return reg.read(self)
    
    def update_reg(self, reg_name: str, bits: str):
        reg = self.get_register(reg_name)

        reg.update(self, bits)
    
    def get_bsr_length(self):
        return self.bsr_len
    
    def boundary_scan(self, tdi: str, read_instruction_name: str):
        if not self.bsr_len:
            raise InvalidConfigException(
                f"The length of the boundary scan register has not been defined in {self.device_config_file_name}"
                )
        
        if not self.instructions:
            raise InvalidInstructionException(f"No instructions provided in the configuration file")
        
        if len(tdi) != self.bsr_len:
            raise ValueError(
                "The TDI to be shifted through the DR must be the same length as the boundary scan register"
                )

        self.chain.reset_state_machine()

        # Shift in the boundary scan instruction
        self.chain.shift_ir(self, self.instructions[read_instruction_name])
        self.chain.move_into_state("update_ir")

        # Read the data out of the boundary scan register
        self.chain.shift_dr(self, self.bsr_len, tdi)
        self.chain.move_into_state("update_dr")

        output = self.chain.shift_dr(self, self.bsr_len, '0' * self.bsr_len)

        return output