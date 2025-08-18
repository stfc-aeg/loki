import glob
import sys

if sys.version_info >= (3, 9):
    from functools import cache
    cache_if_avaiable = cache
else:
    def cache_if_avaiable(func):
        return func  # no-op decorator

@cache_if_avaiable
def get_uio_device_info():
    """
    Return a dictionary of UIO device names, and their corresponding addresses and IP names.

    This information is all extracted from the sysfs, and therefore is not specific to py-uio.
    """
    uio_names = [path.split('/')[-1] for path in glob.glob('/sys/class/uio/uio*')]

    uio_info = {}
    for uio_name in uio_names:
        uio_info[uio_name] = {}
        try:
            with open(f'/sys/class/uio/{uio_name}/maps/map0/addr') as info:
                address_string = "".join(c for c in info.read() if c.isalnum())
                uio_info[uio_name]['address_int'] = int(address_string, 0)
                uio_info[uio_name]['address_hex'] = address_string
        except Exception:
            # If we can't decode or access the file, just skip over it
            continue

        try:
            with open(f'/sys/class/uio/{uio_name}/maps/map0/name') as info:
                uio_info[uio_name]['ip_name'] = info.read().strip().split('@')[0]
        except Exception:
            # If we can't decode or access the file, just skip over it
            continue

    return uio_info

@cache_if_avaiable
def get_uio_addresses(hex=False, ip_name=None):
    """
    Simply return all addresses linked with UIO devices.

    Args:
        hex:        If True, return a string hex value rather than int.
        ip_name:    (optional) Limit to addresses that match a given IP name.
    """
    uio_info = get_uio_device_info()
    addresses = []
    for uio_name in uio_info.keys():
        if ip_name is None or uio_info[uio_name]['ip_name'] == ip_name:
            addresses.append(uio_info[uio_name]['address_hex' if hex else 'address_int'])
    return addresses

@cache_if_avaiable
def get_uio_path_from_address(address):
    """
    Attempt to parse a hex address as a string, or integer address to find a valid UIO number.

    Args:
        address:        The address to search for as a string starting with 0x, or an int.

    Returns:
        The full UIO path to the corresponding UIO device, or None if it was not found
    """

    if not isinstance(address, int):
        if isinstance(address, str):
            if address.startswith('0x'):
                address = int(address, 0)
            else:
                raise TypeError('Did not understand address {} (string does not start with 0x)'.format(address))
        else:
            raise TypeError('Did not understand address {} (type {}; not an integer or string)'.format(address, type(address)))

    uio_info = get_uio_device_info()
    for uio_name in uio_info.keys():
        if uio_info[uio_name]['address_int']  == address:
            return '/dev/' + uio_name

    raise ValueError('Address {} could not be linked to a UIO device (valid addresses: {})'.format(
        hex(address), get_uio_addresses(),
    ))