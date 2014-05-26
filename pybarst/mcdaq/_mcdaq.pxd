
include "../barst_defines.pxi"
include "../inline_funcs.pxi"

from pybarst.core.server cimport BarstChannel, BarstServer


cdef class MCDAQChannel(BarstChannel):
    cdef SChanInitMCDAQ daq_init
    cdef int reading
    cdef HANDLE read_pipe

    cdef public object direction
    '''
    Whether this channel can read, write, or do both. A single MC DAQ device
    can have both read and write ports. This attribute indicates if the
    device has a output port, a input port, or both. `'w'` means it only has
    an output port, `'r'` means it only has an input port, and `'rw'` or `'wr'`
    means that it has both a output and input port.
    '''
    cdef public unsigned short init_val
    '''
    What values (high/low) the output pins (if it supports output) will be set
    to when the channel is initially created on the server.
    '''
    cdef public int continuous
    '''
    Whether, when reading, the server should continuously read and send data
    back to the client. This is only used for a input device
    (:attr:`direction` contains `'r'`). When `True`, a single call to
    :meth:`read` after the channel is opened will start the server reading the
    device continuously and sending the data back to this client. This will
    result in a high sampling rate of the device. If it's `False`, each call to
    :meth:`read` will trigger a new read resulting in a possibly slower
    reading rate.
    '''

    cpdef object write(MCDAQChannel self, unsigned short mask,
                       unsigned short value)
    cpdef object read(MCDAQChannel self)

    cdef inline object _send_trigger(MCDAQChannel self)
