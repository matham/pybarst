''' The PyBarst exception module.
'''

__all__ = ('BarstException', )


include '../barst_defines.pxi'


from cpython.ref cimport PyObject

cdef extern from "Python.h":
    PyObject* PyString_FromString(const char *v)


cdef dict err_codes = {BAD_INPUT_PARAMS: 'Bad inputs', NO_SYS_RESOURCE:
     'Out of system resources',
    ALREADY_OPEN: 'Channel already open (not an error)',
    SIZE_MISSMATCH: 'internal size error; message size mismatch',
    INVALID_CHANN: 'Invalid channel requested', UNKWN_ERROR:
    'Unknown error', DRIVER_ERROR: 'Low level driver failed',
    DEVICE_CLOSING: 'Device is closing, no more data will be sent',
    INVALID_DEVICE:
    'You tried to create or access an unrecognized channel/device',
    INACTIVE_DEVICE: 'You tried to perform an action on a inactive channel',
    INVALID_COMMAND:
    'Command not understood, or command is invalid in this state',
    UNEXPECTED_READ: 'A message was received unexpectedly',
    NO_CHAN:
    'Channel could not be created, was not provided, or was not available',
    BUFF_TOO_SMALL:
    'Buffer too small, or we tried to write passed the buffer end',
    NOT_FOUND: 'Library or object not found',
    TIMED_OUT: 'Timed out while waiting',
    INVALID_MAN: 'Invalid manager channel',
    RW_FAILED: 'Read/write error',
    LIBRARY_ERROR: "Couldn't load library"}
''' Barst's error codes.
'''


class BarstException(Exception):
    '''
    Barst exception class. Accepts Barst error codes and/or error messages.
    It converts Barst error codes to messages where possible.

    :Parameters:
        `value`: int
            a `Barst` error code. Can be zero if only `msg` is provided.
        `msg`: str
            a (optional) error message.

    **Error codes**

    Error code values can arise from multiple sources, therefore, each source
    of error codes gets it's own range as defined below.

    =========    ==========================================================
    Range        Meaning
    =========    ==========================================================
    1 - 100      Barst native codes.
    101 - 200    FTDI error codes
    201 - 500    RTV error codes
    1001 - ?     Windows error codes.
    =========    ==========================================================

    The error codes Barst returns is in this range. This class attempts to
    convert the code into an error messages as well as convert the mapped code
    back into it's original code (i.e. the inverse of the table above).

    '''

    error_value = 0
    '''
    The actual barst error code. Defaults to zero.
    '''
    error_source = ''
    '''
    The source of the error. This can be e.g. `Barst` itself, or one of the
    channels, like `FTDI`, `RTV`, etc.
    '''

    def __init__(self, int value=0, msg='', **kwargs):
        cdef LPSTR win_msg
        cdef DWORD res

        result = ''
        source = ''

        if not value:
            source = 'Barst'
        elif 0 < value <= 100:
            if value in err_codes:
                result = err_codes[value]
            else:
                result = 'Unknown error code'
            source = 'Barst'
        elif 100 < value <= 200:
            source = 'FTDI'
            value -= 100
        elif 200 < value <= 500:
            source = 'RTV'
            value = 200 - value
        elif value > 1000:
            res = FormatMessageA(FORMAT_MESSAGE_ALLOCATE_BUFFER |
                FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
                NULL, <DWORD>(value - 1000), 0, <LPSTR>&win_msg, 0, NULL)
            if res:
                result = <object>PyString_FromString(win_msg)
                LocalFree(win_msg)
            else:
                result = 'Unknown Windows error code'
            source = 'Windows'
            value -= 1000
        else:
            result = 'Unknown error code'
            source = 'Barst'

        if msg:
            if value:
                result = '{}: {} [{}, error code {}]'.format(source, msg,
                                                             result, value)
            else:
                result = '{}: {}'.format(source, msg)
        else:
            result = '{}: {}, error code {}'.format(source, result, value)
        self.error_source = source
        self.error_value = value
        super(BarstException, self).__init__(self, result, **kwargs)
