
include "../barst_defines.pxi"
include "../inline_funcs.pxi"

from pybarst.core.server cimport BarstChannel, BarstServer


cdef class FTDISettings(object):

    cdef DWORD copy_settings(FTDISettings self, void *buffer,
                             DWORD size) except 0
    cdef object get_device_class(FTDISettings self)


cdef class FTDIChannel(BarstChannel):
    cdef SChanInitFTDI ft_init
    cdef FT_DEVICE_LIST_INFO_NODE_OS ft_info
    cdef list channels
    cdef object serial
    cdef object desc

    cdef public list devices
    '''
    A list of :class:`FTDIDevice` instances which control the devices
    connected to this FTDI channel. Each device is a peripheral device
    connected to the channel, e.g. an ADC, a serial to parallel converter etc.
    Read only.

    ::

        >>> server = BarstServer(barst_path=path,
        ... pipe_name=r'\\.\pipe\TestPipe')
        >>> server.open_server()
        >>> server.get_manager('ftdi')
        {'ftdi': {'version': 197127L, 'chan': 0, 'chan_id': 'FTDIMan'}}
        # open the channel with two pin devices, one input the other output
        >>> read = PinSettings(num_bytes=1, bitmask=0xFF, continuous=False,
        ... output=False)
        >>> write = PinSettings(num_bytes=1, bitmask=0x0F, continuous=False,
        ... init_val=0xFF, output=True)
        # open the channel using its description
        >>> ft = FTDIChannel(channels=[read, write], server=server,
        ... desc='Birch Board rev1 A')
        >>> ft.open_channel(alloc=True)
        >>> ft.devices
        [<pybarst.ftdi.switch.FTDIPinIn object at 0x05338D30>,
        <pybarst.ftdi.switch.FTDIPinOut object at 0x05338DB0>]

    '''

    cdef public unsigned char is_open
    '''
    Describes whether the FTDI driver has opened this channel. Read only.
    This does not indicate whether the server has this channel open, just
    if the driver had it open the last time we checked.
    '''
    cdef public char is_high_speed
    '''
    Describes whether the FTDI channel is a high speed FTDI device. Read
    only.
    '''
    cdef public unsigned char is_full_speed
    '''
    Describes whether the FTDI channel is a full speed FTDI device. Read
    only.
    '''
    cdef public DWORD dev_type
    '''
    The device type code given by the FTDI driver for this FTDI device.
    Read only.

    For example::

        >>> ft.dev_type
        6
    '''
    cdef public DWORD dev_id
    '''
    The ID of this FTDI device.
    Read only.

    For example::

        >>> ft.dev_id
        67330064
    '''
    cdef public DWORD dev_loc
    '''
    The location on the USB bus where this FTDI device is connected to.
    Read only.

    For example::

        >>> ft.dev_loc
        29217
    '''
    cdef public str dev_serial
    '''
    The Serial number of this device. Read only.

    For example::

        >>> ft.dev_serial
        FTWR60CBA

    .. note::
        For FTDI devices that embed 2 channels in a single device, e.g. the
        FT2232H, the device still has a single serial number. So to identify
        the channel in question, either an A or B is appended to the serial
        number.
    '''
    cdef public str dev_description
    '''
    The description of the device. FTDI devices can be opened by their
    serial numbers and description strings. Read only.

    For example::

        >>> ft.dev_description
        Birch Board rev1 A

    .. note::
        For FTDI devices that embed 2 channels in a single device, e.g. the
        FT2232H, the device still has a single description. So to identify the
        channel in question, either an A or B is appended to the description.
    '''

    cdef public DWORD chan_min_buff_in
    '''
    Debug information. Describes the number of bytes allocated for the
    pipe for writing to the server. Read only.
    '''
    cdef public DWORD chan_min_buff_out
    '''
    Debug information. Describes the number of bytes allocated for the
    pipe for reading from the server. Read only.
    '''
    cdef public DWORD chan_baudrate
    '''
    Debug information. Describes the baud rate used when the FTDI device
    was opened. Read only.
    '''

    cdef object _populate_settings(FTDIChannel self)


cdef class FTDIDevice(BarstChannel):
    cdef SInitPeriphFT ft_periph
    cdef public FTDISettings settings
    '''
    The :class:`FTDISettings` derived class holding the settings for this
    peripheral device. Each device type has its corresponding
    :class:`FTDISettings` class. Read only.
    '''
    cdef public FTDIChannel parent
    '''
    The :class:`FTDIChannel` instance to which this device belongs to.
    Read only.
    '''
    cdef public DWORD ft_write_buff_size
    '''
    Debug information. The maximum number of bytes written / read
    by the FTDI hardware buffer. The actual read / write buffer size
    can change as different devices become active / inactive according to their
    :attr:`ft_read_device_size` and :attr:`ft_write_device_size` , however
    this is the maximum size, which occurs when all the channel's devices are
    active. Read only.
    '''
    cdef public DWORD ft_read_device_size
    '''
    Debug information. The minimum number of bytes required to by this
    device to read from the FTDI hardware buffer. The actual size is the
    maximum of all the devices connected to the channel. Read only.
    '''
    cdef public DWORD ft_write_device_size
    '''
    Debug information. The minimum number of bytes required to by this
    device to write to the FTDI hardware buffer. The actual size is the maximum
    of all the devices connected to the channel. Read only.
    '''
    cdef public DWORD ft_device_baud
    '''
    The maximum baud rate this device can handle. The channels baud rate
    is the minimum of all its devices. Read only.

    For example::

        >>> write.ft_device_baud
        200000
    '''
    cdef public unsigned char ft_device_mode
    '''
    The mode required of this device (whether sync or async bit bang). If
    both are available we use async. Otherwise, we use the mode supported by
    all the devices. Read only.
    '''
    cdef public unsigned char ft_device_bitmask
    '''
    The 8-bit bitmask indicating which ports are outputs (1) for this
    channel. Read only.

    For example::

        >>> '0b{:08b}'.format(write.ft_device_bitmask)
        0b00001111
    '''

    cdef int running

    cdef object _send_trigger(FTDIDevice self)
