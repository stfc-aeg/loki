from register_controller import RegisterController, Field, MultiField

simulated_regs = {
    0: 0x1234,
    1: 0xBBBB,
}

def outer_read(self, address, length):
    outbuffer = []
    for i in range(length):
        outbuffer.append(simulated_regs[address+i])
    print('SYSTEM READ ADDRESS {}, {} words: {}'.format(hex(address), length, [hex(x) for x in outbuffer]))
    return outbuffer

def outer_write(self, address, values):
    for i in range(len(values)):
        simulated_regs[address+i] = values[i]
    print('SYSTEM WRITE ADDRESS {} with {}'.format(hex(address), [hex(x) for x in values]))

con = RegisterController(
    func_readreg = lambda address, length: outer_read(None, address, length),
    func_writereg = lambda address, values: outer_write(None, address, values),
    word_width_bits=16,
)

con.add_register(0, 0)
con.add_register(1, 0)

basicfield = Field(con, 'basic', 'basic field', 0x00, 7, 4)
basicfield2 = Field(con, 'basic2', 'basic field 2', 0x00, 3, 4)

assert(con.get_field('basic').read() == 0x3)
assert(con.get_field('basic2').read() == 0x4)

spanningfield = Field(con, 'spn', 'spanning field', 0x00, 3, 8)

assert(con.get_field('spn').read() == 0x4b)

con.get_field('basic').write(0xA)
assert(simulated_regs[0] & 0x00F0 == 0x00A0)
assert(con.get_field('basic').read() == 0xA)

con.get_field('spn').write(0xBD)
assert(simulated_regs[0] & 0xF == 0xB and simulated_regs[1] & 0xF000 == 0xD000)
assert(con.get_field('spn').read() == 0xBD)
