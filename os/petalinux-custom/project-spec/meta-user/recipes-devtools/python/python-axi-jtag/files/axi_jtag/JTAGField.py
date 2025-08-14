from typing import List

class JTAGField():
    def __init__(self, name: str, bit_length: int, reversed: bool, subfields: List) -> None:
        self.name = name
        self.bit_length = bit_length
        self.reversed = reversed
        self.subfields = subfields
    
    @staticmethod
    def parse_fields(fields: List[dict]):
        parsed_fields = []

        for field in fields:
            name = field["name"]
            bit_length = field["bit_length"]

            reversed = field.get("reversed", False)
            
            if "subfields" in field.keys():
                subfields = JTAGField.parse_fields(field["subfields"])
            else:
                subfields = []

            parsed_fields.append(JTAGField(name, bit_length, reversed, subfields))

        return parsed_fields

    def get_name(self) -> str:
        return self.name
    
    def get_bit_length(self) -> int:
        return self.bit_length
    
    def get_reversed(self) -> bool:
        return self.reversed
    
    def get_subfields(self) -> list:
        return self.subfields