
__all__ = ('join', 'default_server_timeout', 'BarstException')


from pybarst.core.exception import BarstException

default_server_timeout = 2000
'''
The default time a pipe waits when trying to open a connection to the
server before returning a timeout error.
'''


def join(*args):
    '''
    Joins a pipe name with a sub-channel number to derive the pipe name
    used by the sub-channel. The function is typically not used by the user
    and is mostly for internal use.

    ::

        >>> join('\\\\.\\pipe\\TestPipe', '0', '10')
        \\\\.\\pipe\\TestPipe:0:10
    '''
    return ':'.join(args)
