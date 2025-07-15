def get_bin_string(bin):
    bin_string = ""
    for tdo_val, bits in bin:
        bin_string += f"{tdo_val & ((1 << bits) - 1):0{bits}b}"
    
    return bin_string