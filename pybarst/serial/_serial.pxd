
include "../barst_defines.pxi"
include "../inline_funcs.pxi"

from pybarst.core.server cimport BarstChannel, BarstServer


cdef class SerialChannel(BarstChannel):
    cdef SChanInitSerial serial_init

    cdef public object port_name
    '''
    The name of the port this channel controls. E.g. COM1, COM5 etc.
    '''
    cdef public DWORD max_write
    '''
    The maximum number of bytes that will be written to the serial port
    at any time. I.e. the maximum length of the `value` parameter in
    :meth:`read`.
    '''
    cdef public DWORD max_read
    '''
    The maximum number of bytes that will be read from the serial port
    at any time. I.e. the maximum value of the `read_len` parameter in
    :meth:`write`.
    '''
    cdef public DWORD baud_rate
    '''
    The baud rate to use for the serial port when opening it.
    '''
    cdef public float stop_bits
    '''
    The number of stop bits to use. Can be one of 1, 1.5, or 2.
    '''
    cdef public object parity
    '''
    The parity scheme to use. Can be one of `'even'`, `'odd'`, `'mark'`,
    `'none'`, `'space'`.
    '''
    cdef public unsigned char byte_size
    '''
    The number of bits in the bytes transmitted and received. Can be between
    4 and 8, including 4 and 8.
    '''

    cpdef object write(SerialChannel self, object value, timeout=*)
    cpdef object read(SerialChannel self, DWORD read_len, timeout=*,
                      object stop_char=*)
