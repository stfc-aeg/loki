import json
import os
import re

class InstructionFileNotProvidedException(Exception):
    """
    Exception for when an instruction name is provided, but no
    instructions file has been provided
    """
    def __init__(self, message):
        self.message = message
        super().__init__(self.message)

class GenericDevice():

    def __init__(self, ir_length: int, instructions_file: str=None):
        self.ir_length = ir_length
        self.instructions_file = instructions_file

        if self.instructions_file:
            base_dir = os.path.dirname(os.path.abspath(__file__))
            instructions_file_path = os.path.join(base_dir, "device_instructions", self.instructions_file)
            with open(instructions_file_path) as json_file:
                self.instructions = json.load(json_file)
    
    def set_chain(self, chain):
        self.chain = chain
    
    def shift_ir(self, instruction: str):
        if not re.search("[a-zA-Z]", instruction):
            instruction_code = instruction
        else:
            if not self.instructions:
                raise InstructionFileNotProvidedException(
                    "No instructions file provided, please provide one or provide the instruction code"
                    )
            
            instruction_code = self.instructions[instruction]

        self.chain.shift_ir(self, instruction_code)