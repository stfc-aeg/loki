class JTAGField():
    def __init__(self, name: str, bit_length: int) -> None:
        self.name = name
        self.bit_length = bit_length
    
    @staticmethod
    def parse_fields(fields: list):
        parsed_fields = []

        for field in fields:
            name = field["name"]
            bit_length = field["bit_length"]

            parsed_fields.append(JTAGField(name, bit_length))

        return parsed_fields

    def get_name(self) -> str:
        return self.name
    
    def get_bit_length(self) -> int:
        return self.bit_length