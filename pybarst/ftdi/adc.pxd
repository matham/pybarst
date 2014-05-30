
include "../barst_defines.pxi"
include "../inline_funcs.pxi"

from pybarst.ftdi._ftdi cimport FTDIDevice, FTDISettings
from cpython.array cimport array


cdef class ADCSettings(FTDISettings):
    cdef public float hw_buff_size
    '''
    When The FTDI channel is communicating with the peripheral ADC device we
    continuously read/write to it. The larger the buffer we write/read at once
    the faster it performs. For instance, for fastest communication we would
    write in buffer multiples of the maximum buffer size. Because each FTDI
    channel can be used for multiple peripherals devices, if we were to write
    in multiples of the maximum buffer size then although it'd be most
    efficient for the ADC device, during this write/read other devices of this
    channel will have to wait until we are finished writing the buffer and
    before move on to the next buffer to be able to update their device. This
    means, the larger the buffer the more we have to wait between writes to
    other devices and the longer we have to wait between to update a device.
    :attr:`hw_buff_size` tells us the percentage (0-100) of the maximum buffer
    to use for ADC read / write. The smaller this is, the faster other devices
    will be able to update, but might reduce the ADC bit rate which could be
    unsuited at higher ADC sampling rates.
    '''
    cdef public DWORD transfer_size
    '''
    This parameter allows you to control over how often the ADC sends data read
    back to the client. The server will wait until :attr:`transfer_size` data
    points for each channel (if two channels are active) has been accumulated
    and than sends :attr:`transfer_size` (for each channel) data points to the
    client.
    '''
    cdef public unsigned char clock_bit
    '''
    The pin to which the clock line of the ADC device is connected at the FTDI
    channel. Typically between 0 - 7.
    '''
    cdef public unsigned char lowest_bit
    '''
    Defines which pins on the FTDI USB bus are data pins. The data pins are
    connected to the FTDI bus starting from pin number :attr:`lowest_bit` until
    :attr:`lowest_bit` + :attr:`num_bits`.
    '''
    cdef public unsigned char num_bits
    '''
    Indicates the number of pins on the FTDI bus that are connected to the ADC
    data port. Range is [2, 8]. See :attr:`lowest_bit`.
    '''
    cdef public unsigned char chop
    '''
    Indicates whether chopping mode (noise reduction) should be active on the
    ADC device. It typically lowers the sampling rate when enabled.
    '''
    cdef public unsigned char chan1
    '''
    Indicates whether channel 1 should be active and read and send back data.
    '''
    cdef public unsigned char chan2
    '''
    Indicates whether channel 2 should be active and read and send back data.
    '''
    cdef public unsigned char input_range
    '''
    The internal Barst code the correspond to the :attr:`input_range_str`
    string.
    '''
    cdef public str input_range_str
    '''
    The voltage input range that the device should accept. Can be one of 4
    strings: `'0, 5'`, `'0, 10'`, `'-5, 5'`, or `'-10, 10'`. For a particular
    setting, voltage outside its range will show as error.
    '''
    cdef public unsigned char data_width
    '''
    The bit depth of each data point read by the ADC device. Acceptable values
    are either `16`, or `24`.
    '''
    cdef public unsigned char reverse
    '''
    Indicates how the ADC is connected to the FTDI USB bus. If True, indicates
    that the data pins on the USB bus are flipped relative to the pins on the
    ADC device; e.g. pin 7 connects to pin 0 etc. If False the pins on the USB
    bus and ADC device go in the same direction; e.g. pin 2 is connected to
    pin 5, pin 3 to pin 6 etc.
    '''
    cdef public double sampling_rate
    '''
    The sampling rate used by the ADC device for each channel. The value
    controls both channels. The available sampling rates is a function of all
    the other device options.
    '''
    cdef public double min_rate
    '''
    Indicates the lowest possible sampling rate possible for the current device
    settings.
    '''
    cdef public double max_rate
    '''
    Indicates the highest possible sampling rate possible for the current
    device settings.
    '''
    cdef public unsigned char rate_filter
    '''
    The internal code indicating the current sampling rate of the device.
    '''


cdef class ADCData(object):
    cdef public array chan1_raw
    '''
    An array containing the raw un-scaled 16 or 24 bit raw unsigned int data
    acquired for channel 1. If this channel is disabled, it defaults to `None`.

    For example::

        >>> print data.chan1_raw
        array('L', [32763L, 32763L, 32763L, 32763L, 32763L, 32763L, 32763L, \
32763L, 32763L, 32763L])
    '''
    cdef public array chan2_raw
    '''
    An array containing the raw un-scaled 16 or 24 bit raw unsigned int data
    acquired for channel 2. If this channel is disabled, it defaults to `None`.

    For example::

        >>> print data.chan2_raw
        array('L', [32764L, 32765L, 32765L, 32765L, 32765L, 32765L, 32765L, \
32765L, 32765L])
    '''
    cdef public array chan1_data
    '''
    An array of doubles containing the scaled data from channel 1. Each data
    point is the actual voltage sampled at the ADC channel port and has been
    scaled appropriately to be within the :attr:`ADCSettings.input_range_str`
    range.

    For example::

        >>> print data.chan1_data
        array('d', [-0.00152587890625, -0.00152587890625, -0.00152587890625, \
-0.00152587890625, -0.00152587890625, -0.00152587890625, -0.00152587890625, \
-0.00152587890625, -0.00152587890625, -0.00152587890625])
    '''
    cdef public array chan2_data
    '''
    An array of doubles containing the scaled data from channel 2. Each data
    point is the actual voltage sampled at the ADC channel port and has been
    scaled appropriately to be within the :attr:`ADCSettings.input_range_str`
    range.

    For example::

        >>> print data.chan2_data
        array('d', [-0.001220703125, -0.00091552734375, -0.00091552734375, \
-0.00091552734375, -0.00091552734375, -0.00091552734375, -0.00091552734375, \
-0.00091552734375, -0.00091552734375])
    '''

    cdef public DWORD chan1_ts_idx
    '''
    Each read operation by the USB from the ADC device gets time stamped after
    the read (uncertainty of the time stamp is a few ms, depending on the USB
    communication uncertainty). The time stamp is associated with a particular
    data point within the array since that data point would have been the first
    data point read in the next USB read. This time stamp is recorded in
    :attr:`ts`. This parameter tells you the index of this data point within
    :attr:`chan1_raw` and :attr:`chan1_data` for channel 1. E.g. a value of 10
    indicates that data point 10 in :attr:`chan1_data` was taken at about
    :attr:`ts`.

    Because the data in one USB read can be broken down and sent in multiple
    packets based on the :attr:`ADCSettings.transfer_size` setting. If this
    packet doesn't have a data point that was time stamped, :attr:`ts` is zero.

    Because data points are time stamped by the system clock regularly, it can
    be used to compare with the ADC clock (which is the number of data points
    of this channel received, multiplied by the sampling rate).

    For example::

        >>> print data.chan1_ts_idx
        10
    '''
    cdef public DWORD chan2_ts_idx
    '''
    The index in :attr:`chan2_data` that approximately corresponds with
    :attr:`ts`. See :attr:`chan1_ts_idx`.

    For example::

        >>> print data.chan2_ts_idx
        9
    '''
    cdef public double ts
    '''
    The time stamp, in server time
    :meth:`~pybarst.core.server.BarstServer.clock`
    that the :attr:`chan1_ts_idx` and :attr:`chan2_ts_idx` data points were
    approximately taken. See :attr:`chan1_ts_idx`.

    For example::

        >>> print data.ts
        5.7277356845
    '''
    cdef public DWORD count
    '''
    The packet number of this instance. Everytime the server sends data to the
    client (every time :meth:`FTDIADC.read` is called) the internal index gets
    incremented and stored here. This allows us to recognize if a data packet
    is missing, since this index should be a continuous value.

    For example::

        >>> print data.count
        44
    '''

    cdef public float rate
    '''
    Debug information. With every packet, the server also computes the
    estimated sampling rate at which the data was taken. It should be close to
    :attr:`ADCSettings.sampling_rate`.

    For example, the sampling rate was set to 1000Hz::

        >>> print data.rate
        1187.5
    '''
    cdef public float fullness
    '''
    As mentioned in :attr:`ADCSettings.hw_buff_size`, we can select different
    sizes for the buffer length that is written to the FTDI USB device at once.
    If it is too small, than most of the buffer read would be full with ADC
    data. If it's very large, then it should be mostly empty because it's more
    efficient. This parameter tells you the percentage of the read buffer that
    was filled with ADC data.

    If this parameter is close to 100, that means the device is close to
    losing data because the buffer might be too small or the USB clock too slow
    to be able to read the data fast enough. So you should increase the buffer
    size or set a smaller sampling rate.

    For example::

        >>> print data.fullness
        0.0122897801921
    '''
    cdef public char chan1_oor
    '''
    A bool indicating whether the voltage sensed on channel 1 is outside the
    range defined when creating the channel,
    :attr:`ADCSettings.input_range_str`.
    '''
    cdef public char chan2_oor
    '''
    A bool indicating whether the voltage sensed on channel 2 is outside the
    range defined when creating the channel,
    :attr:`ADCSettings.input_range_str`.
    '''
    cdef public char noref
    '''
    A bool indicating whether the hardware voltage reference on the ADC device
    is not detected. A value of True indicates a hardware error.
    '''
    cdef public short bad_count
    '''
    A value indicating the number of times for this packet that invalid data
    was read by the USB from the ADC device. None-zero values might indicate
    connection or hardware issues.
    '''
    cdef public short overflow_count
    '''
    Indicates the number of times data was skipped while reading the ADC
    device. For example, if the ADC is operating at a very high sampling rate
    and the FTDI USB channel is too slow, then data might simply be lost. If
    none-zero, this indicates the number of times it happened.
    '''

    cdef init(ADCData self, SADCData *header, double multiplier,
              double subtractend, double divisor)

cdef class FTDIADC(FTDIDevice):
    cdef double multiplier
    cdef double subtractend
    cdef double divisor
    cdef SADCInit adc_settings

    cpdef object read(FTDIADC self)
