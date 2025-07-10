import json
import os

class GenericDevice():

    def __init__(self, ir_length: int, instructions_file: str):
        self.ir_length = ir_length

        base_dir = os.path.dirname(os.path.abspath(__file__))
        instructions_file_path = os.path.join(base_dir, "device_instructions", instructions_file)
        with open(instructions_file_path) as json_file:
            self.instructions = json.load(json_file)
    
    def set_chain(self, chain):
        self.chain = chain
    
    def shift_ir(self, instruction: str):
        self.chain.shift_ir(self, self.instructions[instruction])