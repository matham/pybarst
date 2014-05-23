
include "../barst_defines.pxi"
include "../inline_funcs.pxi"

from pybarst.ftdi._ftdi cimport FTDIDevice, FTDISettings


cdef class SerializerSettings(FTDISettings):
    cdef public DWORD num_boards
    '''
    The number of serial to parallel boards in a daisy chain fashion
    that are connected. You can connect many of these serial to
    parallel boards in series, so that with only 3 lines you can
    control many digital pins, even though each such device only
    controls 8 pins directly. It is assumed by the software that each
    such device controls 8 lines.
    '''
    cdef public DWORD clock_size
    '''
    The number of clock cycles of the FTDI channel with pre-set
    baud rate to use for a single clock cycle communication with the
    device. The FTDI channel uses a pre-computed baud rate according
    to all the devices connected to the channel. E.g. if it computes
    to 1 MHz, each clock length is 1 us. If this is too fast for the
    device, we can increase the value, e.g. in the case above, a value
    of 2 for this parameter will result of 2 us clock lengths.
    '''
    cdef public unsigned char clock_bit
    '''
    The pin to which the clock line of the serial to parallel device is
    connected at the FTDI channel. Typically between 0 - 7.
    '''
    cdef public unsigned char data_bit
    '''
    The pin to which the data line of the serial to parallel device is
    connected at the FTDI channel. Typically between 0 - 7.
    '''
    cdef public unsigned char latch_bit
    '''
    The pin to which the latch line of the serial to parallel device is
    connected at the FTDI channel. Typically between 0 - 7.
    '''
    cdef public int continuous
    '''
    Whether, when reading, we should continuously read and send data
    back to the client. This is only used for a input device
    (`output` is `False`). When `True`,  a single call to
    :meth:`FTDISerializerIn.read` after the device is activated will
    start the server reading the device continuously and sending the
    data back to this client. This will result in a high sampling rate
    of the device. If it's `False`, each call to
    :meth:`FTDISerializerIn.read` will trigger a new read resulting in
    a possibly slower reading rate.
    '''
    cdef public int output
    '''
    If the device connected is output device (74HC595) or a input
    device (74HC589). If True, a :class:`FTDISerializerOut` will be
    created, otherwise a :class:`FTDISerializerIn` will be created
    by the :class:`FTDIChannel`.
    '''


cdef class FTDISerializer(FTDIDevice):
    cdef SValveInit serial_settings


cdef class FTDISerializerIn(FTDISerializer):
    cpdef object read(FTDISerializerIn self)


cdef class FTDISerializerOut(FTDISerializer):
    cpdef object write(FTDISerializerOut self, object set_high=*,
                       object set_low=*)


cdef class PinSettings(FTDISettings):
    cdef public unsigned short num_bytes
    '''
    The number of bytes that will be read from the USB bus for each read
    request. The bytes will be read at the
    :attr:`~pybarst.ftdi.FTDIChannel.chan_baudrate` of the channel. When the
    device is an output device, this determines the maximum number of bytes
    that can be written at once with the channel's
    :attr:`~pybarst.ftdi.FTDIChannel.chan_baudrate`.
    '''
    cdef public unsigned char bitmask
    '''
    The pins that are active for this device, either as input or output
    depending on the pin type. The high bits will be the active pins for this
    device.
    '''
    cdef public unsigned char init_val
    '''
    If this is an output device, what the initial values (high/low) of the
    active pins will be.
    '''
    cdef public int continuous
    '''
    Whether, when reading, we should continuously read and send data
    back to the client. This is only used for a input device
    (`output` is `False`). When `True`,  a single call to
    :meth:`FTDIPin.read` after the device is activated will
    start the server reading the device continuously and sending the
    data back to this client. This will result in a high sampling rate
    of the device. If it's `False`, each call to
    :meth:`FTDIPin.read` will trigger a new read resulting in a possibly slower
    reading rate.
    '''
    cdef public int output
    '''
    If the active pins of this device are inputs or outputs. If True, a
    :class:`FTDIPinOut` will be created, otherwise a :class:`FTDIPinIn` will
    be created by the :class:`FTDIChannel`.
    '''


cdef class FTDIPin(FTDIDevice):
    cdef SPinInit pin_settings


cdef class FTDIPinIn(FTDIPin):
    cpdef object read(FTDIPinIn self)


cdef class FTDIPinOut(FTDIPin):
    cpdef object write(FTDIPinOut self, object data=*,
                       object buff_mask=*, object buffer=*)
