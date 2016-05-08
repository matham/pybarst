'''
Creation of a channel or server instance does not result in extra process
communication. However, instance methods does, and may therefore take
significant time before the method returns.

The point is that the channel exists on the server, so deleting a client
instance will not delete the channel from the server, even if no client is
connected to the server.


Typical usage
--------------

you open and close with open_channel, close client/server.
'''

__all__ = ('BarstPipe', 'BarstServer', 'BarstChannel')

import os
import subprocess
import time
import itertools

from pybarst.core.exception import BarstException
from pybarst.core import default_server_timeout
from pybarst import __min_barst_version__, dep_bins

cdef extern from "stdlib.h":
    void* malloc(size_t)
    void free(void *)


cdef DWORD default_timeout = default_server_timeout
cdef DWORD min_barst_version = __min_barst_version__
cdef int SW_HIDE = 0
cdef DWORD DETACHED_PROCESS = 0x00000008

cdef dict manager_map = {'ftdi': eFTDIMan, 'rtv': eRTVMan,
                         'serial': eSerialMan, 'mcdaq': eMCDAQMan}


cdef class BarstPipe(object):
    '''
    An abstract class that provides the client / server communication
    functionality. This base class should not be instantiated directly.

    :Parameters:

        `pipe_name`: bytes
            The name of the pipe used for client / server communication.
            Examples are `\\\\\\\\.\\\\pipe\\\\TestPipe` for a local pipe named
            `TestPipe` or `\\\\\\\\Jace\\\\pipe\\\\TestPipe` for a pipe named
            `TestPipe` on a remote computer named `Jace`.
        `timeout`: int
            The duration (in ms) to wait before returning with a timeout when
            opening the pipe. If zero or None, it defaults to
            :attr:`pybarst.core.default_server_timeout` in ms. Defaults to
            None.
    '''

    def __init__(BarstPipe self, pipe_name='', timeout=None, **kwargs):
        pass

    def __cinit__(BarstPipe self, pipe_name='', timeout=None, **kwargs):
        self.pipe_name = tencode(pipe_name)
        if not timeout or timeout < 0:
            self.timeout = default_timeout
        else:
            self.timeout = timeout

    cdef inline HANDLE open_pipe(BarstPipe self, str access) except NULL:
        '''
        Create and initializes a handle to the pipe.

        :Parameters:

            `access`: str
                The access level. Can be `r`, `w`, `rw`, or `wr`.
        '''
        cdef int res = 0
        cdef DWORD mode = PIPE_READMODE_MESSAGE | PIPE_WAIT
        cdef const char *name = self.pipe_name
        cdef DWORD dw_access
        cdef HANDLE pipe

        if access == 'w':
            dw_access = GENERIC_WRITE
        elif access == 'r':
            dw_access = GENERIC_READ
        elif access == 'rw':
            dw_access = GENERIC_READ | GENERIC_WRITE
        elif access == 'wr':
            dw_access = GENERIC_READ | GENERIC_WRITE
        else:
            raise BarstException(BAD_INPUT_PARAMS, 'Got unknown permission')

        with nogil:
            pipe = CreateFileA(name, dw_access, 0, NULL, OPEN_EXISTING, 0,
                               NULL)
            if (pipe == INVALID_HANDLE_VALUE and
                GetLastError() == ERROR_PIPE_BUSY and self.timeout):
                if not WaitNamedPipeA(name, self.timeout):
                    res = WIN_ERROR(GetLastError())
                else:    # try again
                    pipe = CreateFileA(name, dw_access, 0, NULL, OPEN_EXISTING,
                                       0, NULL)
                    if pipe == INVALID_HANDLE_VALUE:
                        res = WIN_ERROR(GetLastError())
            elif pipe == INVALID_HANDLE_VALUE:
                res = WIN_ERROR(GetLastError())

            if (not res) and not SetNamedPipeHandleState(pipe, &mode, NULL,
                                                         NULL):
                res = WIN_ERROR(GetLastError())
                CloseHandle(pipe)
        if res:
            raise BarstException(res,
                msg='Could not open the pipe to server {}'.format(name))
        return pipe

    cdef inline int write_read(BarstPipe self, HANDLE pipe, DWORD write_size,
                               void *msg, DWORD *read_size, void *read_msg):
        '''
        Writes (reads) to a pipe handle previously opened with
        :meth:`open_pipe`. If `read_msg` is `NULL`, reading is skipped.
        '''
        cdef DWORD n
        with nogil:
            if (not WriteFile(pipe, msg, write_size, &n, NULL) or
                n != write_size):
                return WIN_ERROR(GetLastError())
            if read_msg != NULL and not ReadFile(pipe, read_msg, read_size[0],
                                                 read_size, NULL):
                return WIN_ERROR(GetLastError())
        return 0

    cdef inline void close_handle(BarstPipe self, HANDLE pipe):
        '''
        Closes a pipe handle previously opened with :meth:`open_pipe`.
        '''
        if pipe != INVALID_HANDLE_VALUE and pipe != NULL:
            CloseHandle(pipe)


cdef class BarstServer(BarstPipe):
    '''
    The server class that controls and provides client based access to a
    remote server. A Barst server provides access to devices connected
    to the server's system. Using a server client, a client can open,
    read/write, and close those channels in the server.

    If the pipe name used to communicate with the server is local and
    a server with that name has not been created, a new server instance will
    be created on this system.

    Multiple clients may connect safely to a single server. However, the
    server's main pipe is single threaded, therefore, reading and writing to it
    can only be done by a single client at any time. So while a client is
    e.g. creating a new channel, other clients cannot create other channels.
    Once a channel is created, the channel gets its own pipe. A channel pipe is
    fully multithreaded allowing many clients to communicate with the channel
    at any time. See individual channels, e.g.
    :class:`~pybarst.ftdi.FTDIChannel` for details.

    A server can control different device types. Before each device type can
    be created, a manager for it must be created on the server. For example, to
    create a serial port channel, one first creates the server's serial manager
    using :meth:`get_manager`. Then, using the manager one can create new
    serial channels. Typically, when a new channel instance is created, its
    manager is automatically created first. As mentioned, each new channel
    created gets its own pipe, leaving the server's main pipe for channel
    creation/deletion.

    :Parameters:

        `barst_path`: str
            The full path to the Barst executable. It only needs to be provided
            when the server is local and has not been created yet. If None, we
            look for the executable in :attr:`pybarst.dep_bins` and then in
            `Program Files\\\\Barst\\\\` (or the
            x86 program files if the server is 32-bit). Defaults
            to None. See :attr:`barst_path` for details.
        `curr_dir`: str
            The working directory of the server. See :attr:`curr_dir` for
            details. Defaults to None.
        `write_size`: int
            The size of the buffer used to write to the server's main pipe.
            If None it defaults to 1024 bytes. Defaults to None. See
            :attr:`write_size` for details.
        `read_size`: int
            The size of the buffer used to read from the server's main pipe.
            If None it defaults to 1024 bytes. Defaults to None. See
            :attr:`read_size` for details.
        `max_server_size`: 64-bit integer
            The maximum number of bytes that the server can queue to send to
            clients at any time, if not `-1`. Defaults to `-1`. See
            :attr:`max_server_size`.

        .. warning::

            In cases where messages to/from the server's main pipe are larger
            than 1024 bytes, the buffer sizes should be enlarged. Windows might
            return an error saying that all data could not be read if the
            buffer is too small. Channel pipe are guaranteed to be large
            enough to hold the data required for reading/writing, only the
            server's main pipe size can not be predicted.
    '''

    def __init__(BarstServer self, barst_path=None, curr_dir=None,
                 write_size=None, read_size=None, max_server_size=-1,
                 **kwargs):
        pass

    def __cinit__(BarstServer self, barst_path=None, curr_dir=None,
                  write_size=None, read_size=None, max_server_size=-1,
                  **kwargs):
        self.barst_path = barst_path
        self.curr_dir = curr_dir
        self.write_size = max(max(MIN_BUFF_IN, write_size if write_size else
                                  MIN_BUFF_IN), 1024)
        self.read_size = max(max(MIN_BUFF_OUT, read_size if read_size else
                                 MIN_BUFF_OUT), 1024)
        self.managers = {}
        self.connected = 0
        self.max_server_size = max_server_size

    cpdef object open_server(BarstServer self):
        '''
        Opens the server with the settings specified when creating the
        :class:`BarstServer` instance. If a server with this pipe name doesn't
        exist yet, one will be created, provided the pipe is local and
        :attr:`barst_path` was provided.
        '''
        cdef HANDLE pipe
        cdef DWORD version = 0
        self.managers = {}

        pipe = CreateFileA(self.pipe_name, GENERIC_WRITE | GENERIC_READ, 0,
                           NULL, OPEN_EXISTING, 0, NULL)
        if pipe != INVALID_HANDLE_VALUE or GetLastError() == ERROR_PIPE_BUSY:
            if pipe != INVALID_HANDLE_VALUE:
                self.close_handle(pipe)
            return

        if not self.pipe_name.startswith('\\\\.\\'):
            raise BarstException(NO_CHAN, 'Could not open pipe "{}", and '
            "could also not create it because the pipe name is not local".
            format(self.pipe_name))

        if not self.barst_path:
            bins = dep_bins[:]
            if 'ProgramFiles' in os.environ:
                bins.append(os.path.join(os.environ['ProgramFiles'], 'Barst'))
            fnames = ['barst.exe', 'barst32.exe', 'barst64.exe',
                      'Barst.exe', 'Barst32.exe', 'Barst64.exe']
            for b, f in itertools.product(bins, fnames):
                p = os.path.join(b, f)
                if os.path.isfile(p):
                    self.barst_path = p
                    break
        if not self.barst_path:
            raise BarstException(BAD_INPUT_PARAMS,
            "Barst path not provided or Barst was not found")

        if (not self.curr_dir) and self.barst_path:
            self.curr_dir = os.path.split(self.barst_path)[0]

        command_line = [self.barst_path, self.pipe_name, str(self.write_size),
                        str(self.read_size), str(self.max_server_size)]
        info = subprocess.STARTUPINFO()
        info.dwFlags |= subprocess.STARTF_USESHOWWINDOW
        info.wShowWindow = SW_HIDE
        subprocess.Popen(command_line, cwd=self.curr_dir, startupinfo=info,
                         close_fds=True, creationflags=DETACHED_PROCESS)

        t_start = time.clock()
        while time.clock() - t_start < self.timeout:
            try:
                version = self.get_version()
                break
            except BarstException:
                time.sleep(0.05)
        if not version:
            raise BarstException(TIMED_OUT,
            'Timed out waiting to verify the server\'s pipe "{}"'.
            format(self.pipe_name))
        if version < min_barst_version:
            raise BarstException(msg='Barst version, {}, is less than the '
            'minimum version, {}'.format(version, min_barst_version))
        self.connected = 1

    cpdef object close_server(BarstServer self):
        '''
        Notifies the server to shut down.

        Shuts down the server and all its open managers and channels.
        Afterwards, the server process should have closed. To open
        the server again, call :meth:`open_server`.
        '''
        cdef HANDLE pipe
        cdef SBaseIn base
        self.connected = 0
        cdef DWORD t
        pipe = self.open_pipe('w')

        base.dwSize = sizeof(SBaseIn)
        base.eType = eDelete
        base.nChan = -1  # -1 tells barst itself to close
        base.nError = 0
        self.write_read(pipe, sizeof(SBaseIn), &base, NULL, NULL)
        self.close_handle(pipe)
        self.managers = {}

        t_start = time.clock()
        while time.clock() - t_start < self.timeout:
            try:
                t = self.get_version()
                time.sleep(0.05)
            except BarstException:
                return
        raise BarstException(msg="Could not close the server")

    cpdef DWORD get_version(BarstServer self) except *:
        '''
        Returns Barst's version.

        :Returns:
            int. The version in the form where e.g. 10000 means 1.00.00.
        '''
        cdef DWORD version = 0
        cdef int res
        cdef HANDLE pipe = self.open_pipe('rw')
        cdef SBaseIn base
        cdef SBaseIn *pbase
        cdef DWORD read_size = MIN_BUFF_OUT

        base.dwSize = sizeof(SBaseIn)
        base.eType = eVersion
        base.nChan = -1
        base.nError = 0
        pbase = <SBaseIn *>malloc(MIN_BUFF_OUT)
        if pbase == NULL:
            self.close_handle(pipe)
            raise BarstException(NO_SYS_RESOURCE)
        res = self.write_read(pipe, sizeof(SBaseIn), &base, &read_size, pbase)
        if not res:
            if (read_size == sizeof(SBaseIn) and (not pbase.nError) and
                pbase.eType == eVersion):
                version = pbase.dwInfo
            elif read_size == sizeof(SBaseIn) and pbase.nError:
                res = pbase.nError
            else:
                res = UNEXPECTED_READ

        free(pbase)
        self.close_handle(pipe)
        if res:
            raise BarstException(res)
        return version

    cpdef object get_manager(BarstServer self, str manager):
        '''
        Creates a manager in the server if it has not been created yet.

        As described in the class description, a server is constructed
        from a single main pipe through which you create managers which
        in turn manage and create specific channels, e.g. a serial port
        channel. Once the manager is created, we can create channels using that
        driver. By default, creating a channel will automatically create its
        manager.

        For example::

            >>> server = BarstServer(barst_path=r'path_to_barst',
            ... pipe_name=r'\\\\.\\pipe\\TestPipe')
            >>> print(server)
            <pybarst.barst_core.BarstServer object at 0x02C77F30>
            >>> print(server.get_version())
            20000
            >>> print(server.get_manager('ftdi'))
            {'version': 197127L, 'chan': 0, 'chan_id': 'FTDIMan'}

        :Parameters:
            `manager`: str
                The name of the manager to create. Can be one of `'ftdi'`,
                `'rtv'`, `'serial'`, or `'mcdaq'`.

        :Returns:
            a dict describing the manager. See :attr:`managers`.
        '''
        cdef EQueryType man
        cdef HANDLE pipe
        cdef int res, chan = -1
        cdef SBaseIn base
        cdef SBaseIn *pbase
        cdef DWORD read_size = MIN_BUFF_OUT

        if manager not in manager_map:
            raise BarstException(msg='Unrecognized Barst manager {}. '
            'Accepted values are {}'.format(manager, manager_map.keys()))
        if manager in self.managers:
            return self.managers[manager]

        pipe = self.open_pipe('rw')

        base.dwSize = sizeof(SBaseIn)
        base.eType = eSet
        base.eType2 = manager_map[manager]
        base.nError = 0
        pbase = <SBaseIn *>malloc(MIN_BUFF_OUT)
        if pbase == NULL:
            self.close_handle(pipe)
            raise BarstException(NO_SYS_RESOURCE)

        res = self.write_read(pipe, sizeof(SBaseIn), &base, &read_size, pbase)
        if not res:
            if read_size == sizeof(SBaseIn):
                chan = pbase.nChan
                res = pbase.nError
            else:
                res = UNEXPECTED_READ

        free(pbase)
        self.close_handle(pipe)
        if res and res != ALREADY_OPEN:
            raise BarstException(res)
        self.managers[manager] = {'chan': chan,
                                  'version': self._get_man_version(chan),
                                  'chan_id': self._get_man_ID(chan)}
        return self.managers[manager]

    cpdef object close_manager(BarstServer self, str manager):
        '''
        Closes a manager. If the manager has not been created yet by this
        instance of the server's client, we will create the manager and then
        close it. The reason is that another client elsewhere could have
        created the manager, even if it has not been created locally. So we
        need to ensure we close it on the server.

        If the manager had any open channels, those channels will also be
        closed by the server.
        '''
        cdef int chan, res
        cdef HANDLE pipe
        cdef SBaseIn *pbase
        cdef void *phead_in
        cdef DWORD read_size = sizeof(SBaseIn)

        if manager not in manager_map:
            raise BarstException(msg='Unrecognized Barst manager "{}". '
            'Accepted values are {}'.format(manager, manager_map.keys()))
        if manager not in self.managers:
            self.get_manager(manager)
        chan = self.managers[manager]['chan']

        pipe = self.open_pipe('rw')

        pbase = <SBaseIn *>malloc(sizeof(SBaseIn))
        phead_in = malloc(sizeof(SBaseIn))
        if pbase == NULL or phead_in == NULL:
            self.close_handle(pipe)
            free(pbase)
            free(phead_in)
            raise BarstException(NO_SYS_RESOURCE)
        pbase.dwSize = sizeof(SBaseIn)
        pbase.eType = eDelete
        pbase.nChan = chan
        pbase.nError = 0
        res = self.write_read(pipe, sizeof(SBaseIn), pbase, &read_size,
                              phead_in)
        if not res:
            if read_size != sizeof(SBaseIn):
                res = UNEXPECTED_READ
            else:
                res = (<SBaseIn *>phead_in).nError

        free(phead_in)
        free(pbase)
        self.close_handle(pipe)
        del self.managers[manager]
        if res:
            raise BarstException(res)

    cdef DWORD _get_man_version(BarstServer self, int chan) except *:
        '''
        Gets the version of the specified manager channel.
        '''
        cdef DWORD version = 0
        cdef HANDLE pipe
        cdef int res
        cdef SBaseIn *pbase_write
        cdef SBaseIn *pbase
        cdef DWORD read_size = sizeof(SBaseIn)

        pipe = self.open_pipe('rw')

        pbase_write = <SBaseIn *>malloc(2 * sizeof(SBaseIn))
        pbase = <SBaseIn *>malloc(sizeof(SBaseIn))
        if pbase == NULL or pbase_write == NULL:
            self.close_handle(pipe)
            free(pbase_write)
            free(pbase)
            raise BarstException(NO_SYS_RESOURCE)

        pbase_write.dwSize = 2 * sizeof(SBaseIn)
        pbase_write.eType = ePassOn
        pbase_write.nChan = chan
        pbase_write.nError = 0
        (<SBaseIn *>(<char *>pbase_write + sizeof(SBaseIn))).dwSize = sizeof(SBaseIn)
        (<SBaseIn *>(<char *>pbase_write + sizeof(SBaseIn))).eType = eVersion
        (<SBaseIn *>(<char *>pbase_write + sizeof(SBaseIn))).nChan = -1
        (<SBaseIn *>(<char *>pbase_write + sizeof(SBaseIn))).nError = 0

        res = self.write_read(pipe, 2 * sizeof(SBaseIn), pbase_write,
                              &read_size, pbase)
        if not res:
            if (read_size == sizeof(SBaseIn) and (not pbase.nError) and
                pbase.eType == eVersion):
                version = pbase.dwInfo
            elif read_size == sizeof(SBaseIn) and pbase.nError:
                res = pbase.nError
            else:
                res = UNEXPECTED_READ

        free(pbase_write)
        free(pbase)
        self.close_handle(pipe)
        if res:
            raise BarstException(res)
        return version

    cdef object _get_man_ID(BarstServer self, int chan):
        '''
        Returns the Barst 8-char string id of the manager.
        '''
        cdef HANDLE pipe
        cdef int res
        cdef SBaseIn base
        cdef SBaseOut *pbase
        cdef DWORD read_size = MIN_BUFF_OUT

        pipe = self.open_pipe('rw')

        base.dwSize = sizeof(SBaseIn)
        base.eType = eQuery
        base.nChan = chan
        base.nError = 0
        pbase = <SBaseOut *>malloc(MIN_BUFF_OUT)
        if pbase == NULL:
            self.close_handle(pipe)
            raise BarstException(NO_SYS_RESOURCE)

        res = self.write_read(pipe, sizeof(SBaseIn), &base, &read_size, pbase)
        if not res:
            if (read_size >= sizeof(SBaseOut) and
                pbase.sBaseIn.eType == eResponseEx and
                not pbase.sBaseIn.nError):
                man_id = str(pbase.szName)
            elif ((read_size == sizeof(SBaseIn) or
                   read_size == sizeof(SBaseOut)) and
                  pbase.sBaseIn.nError):
                res = pbase.sBaseIn.nError
            else:
                res = UNEXPECTED_READ

        free(pbase)
        self.close_handle(pipe)
        if res:
            raise BarstException(res)
        return man_id

    cpdef object clock(BarstServer self):
        '''
        Returns the current server time using a high precision clock on the
        server.

        The server has a single global high precision clock that it uses
        for time stamping data. All channels pass some data from/to the server.
        For example, the :class:`~pybarst.mcdaq.MCDAQChannel` channel can read
        and write to the channel. Each read/write is time stamped by the server
        with the time it occurred. This method returns the current time as
        measured using that clock.

        :returns:
            a 2-tuple of (`server_time`, `utc_time`).

            `server_time`: double
                The current server time measured using the high precision
                clock. This clock starts running when the server is created.
                This is the clock used to time stamp data sent by the server.
            `utc_time`: double
                The current utc time measured by the server's system. This
                clock is much less precise/accurate. By calling this many
                times, one can correlate time between the server time, utc
                time, and the time of a clients system. For example, one can
                call it repeatedly to try to find on average what time on a
                clients system corresponds to a particular time stamp of the
                server.

                The value represents the number of second that has passed since
                12:00 A.M. January 1, 1601 Coordinated Universal Time (UTC).
                This is commonly called Windows file time
                (http://msdn.microsoft.com/en-us/library/windows/desktop/\
ms724284%28v=vs.85%29.aspx).

        For example::

            >>> import time
            >>> server = BarstServer(barst_path=path, \
pipe_name=r'\\\\.\\pipe\\TestPipe')
            >>> server.open_server()
            >>> print(server.clock())
            (0.027729689422222512, 13045704696.357197)
            >>> print(server.clock())
            (0.02788367253417604, 13045704696.357197)
            >>> time.sleep(1.5)
            >>> print(server.clock())
            (1.528171928919753, 13045704697.857283)
        '''
        cdef HANDLE pipe
        cdef int res
        cdef SBaseIn base
        cdef SBaseIn *pbase
        cdef DWORD read_size = (sizeof(SBaseIn) + sizeof(SBase) +
                                sizeof(SPerfTime))

        pipe = self.open_pipe('rw')

        base.dwSize = sizeof(SBaseIn)
        base.eType = eQuery
        base.nChan = -1
        base.nError = 0
        pbase = <SBaseIn *>malloc(read_size)
        if pbase == NULL:
            self.close_handle(pipe)
            raise BarstException(NO_SYS_RESOURCE)

        res = self.write_read(pipe, sizeof(SBaseIn), &base, &read_size, pbase)
        ret = None
        if not res:
            if (read_size == sizeof(SBaseIn) + sizeof(SBase) +
                sizeof(SPerfTime) and pbase.eType == eQuery and
                not pbase.nError and
                (<SBase *>(<char *>pbase + sizeof(SBaseIn))).eType ==
                eServerTime):
                ret = ((<SPerfTime *>(<char *>pbase + sizeof(SBaseIn) +
                                      sizeof(SBase))).dRelativeTime,
                       (<SPerfTime *>(<char *>pbase + sizeof(SBaseIn) +
                                      sizeof(SBase))).dUTCTime)
            elif ((read_size == sizeof(SBaseIn) or
                   read_size == sizeof(SBaseOut)) and
                  pbase.nError):
                res = pbase.nError
            else:
                res = UNEXPECTED_READ

        free(pbase)
        self.close_handle(pipe)
        if res:
            raise BarstException(res)
        return ret


cdef class BarstChannel(BarstPipe):
    '''
    An abstract representation class of a client connected to a channel on
    the server. This class is never instantiated directly.

    See derived classes, e.g. :class:`~pybarst.rtv.RTVChannel` for examples.

    The class provides methods commonly used by the client classes.
    '''

    def __cinit__(BarstChannel self, **kwargs):
        self.chan = -1
        self.parent_chan = -1
        self.pipe = NULL
        self.server = None
        self.barst_chan_type = ''
        self.connected = 0

    def __dealloc__(BarstChannel self):
        self.close_channel_client()

    cpdef object open_channel(BarstChannel self):
        '''
        Opens the client's connection to this channel on the server. If the
        channel doesn't exist yet it creates it first, otherwise it just opens
        a new client for the channel.

        Before any other operations can be done on the channel, this method
        must be called.

        All channels are designed such that when the class instance is created,
        no client/server communication occurs. Then, to actually create/open
        the channel, this method must be called.

        Similarly, after closing a channel with
        :meth:`close_channel_server` or :meth:`close_channel_client` one can
        recreate or reopen the client's connection to the channel using this
        method.
        '''
        self.connected = 1

    cpdef object close_channel_server(BarstChannel self):
        '''
        Closes the channel on the server. This deletes the channel from the
        server. Therefore any other clients that may be connected to the
        channel will return an error when they try to communicate with it after
        this method has been called.

        This method internally also calls :meth:`close_channel_client`.

        To only close the connection of this client without affecting the state
        of the channel on the server, call :meth:`close_channel_client`.
        '''
        cdef int man_chan = self.parent_chan
        cdef HANDLE pipe = self.server.open_pipe('rw')
        cdef SBaseIn *pbase
        cdef DWORD read_size = sizeof(SBaseIn)
        cdef int res
        cdef void* phead_out = malloc(2 * sizeof(SBaseIn))
        cdef void* phead_in = malloc(sizeof(SBaseIn))
        self.close_channel_client()

        self.close_handle(self.pipe)
        self.pipe = NULL
        if phead_out == NULL or phead_in == NULL:
            self.close_handle(pipe)
            free(phead_out)
            free(phead_in)
            raise BarstException(NO_SYS_RESOURCE)

        pbase = <SBaseIn *>phead_out
        pbase.dwSize = 2 * sizeof(SBaseIn)
        pbase.eType = ePassOn
        pbase.nChan = man_chan
        pbase.nError = 0
        pbase += 1
        pbase.dwSize = sizeof(SBaseIn)
        pbase.eType = eDelete
        pbase.nChan = self.chan
        pbase.nError = 0
        res = self.server.write_read(pipe, 2 * sizeof(SBaseIn), phead_out,
                                     &read_size, phead_in)
        if not res:
            if read_size != sizeof(SBaseIn):
                res = UNEXPECTED_READ
            else:
                res = (<SBaseIn *>phead_in).nError
        free(phead_in)
        free(phead_out)
        self.close_handle(pipe)
        if res:
            raise BarstException(res)

    cpdef close_channel_client(BarstChannel self):
        '''
        Closes this client's connection to the channel without
        affecting the channel on the server. Other clients are not affected
        by this.

        After this is called, the channel will still exist on the server, but
        this instance won't be connected to it. Therefore, calling other
        channel methods will likely raise an exception until
        :meth:`open_channel` is called again.

        If a class method, e.g. a read or write operation got stuck
        communicating with the server, calling this method from another thread
        will force the waiting method to return, possibly with an error.
        '''
        self.close_handle(self.pipe)
        self.pipe = NULL
        self.connected = 0

    cdef object _set_state(BarstChannel self, int state, HANDLE pipe=NULL,
                           int chan=-1, flush=False):
        '''
        Sets the state of the channel.
        '''
        cdef SBaseIn base, base_read
        cdef int res
        cdef HANDLE local_pipe
        cdef DWORD read_size = sizeof(SBaseIn)
        cdef EQueryType query_type = eNone

        if pipe == NULL:
            local_pipe = self.open_pipe('rw')
        else:
            local_pipe = pipe

        base.dwSize = sizeof(SBaseIn)
        if state:
            query_type = eActivate
        else:
            query_type = eInactivate
        base.eType = query_type
        base.nChan = chan
        base.nError = 0
        res = self.write_read(local_pipe, sizeof(SBaseIn), &base, &read_size,
                              &base_read)

        if not res:
            if read_size != sizeof(SBaseIn) or (base_read.eType != query_type
                                                and not base_read.nError):
                res = UNEXPECTED_READ
            else:
                res = base_read.nError
        if pipe == NULL:
            self.close_handle(local_pipe)
        if res:
            raise BarstException(res)

        if not state and flush:
            self.close_handle(self.pipe)
            self.pipe = self.open_pipe('rw')

    cpdef object set_state(BarstChannel self, int state, object flush=False):
        '''
        Sets the state of the channel to active or inactive (True or False).
        The activation state of a channel is global, and therefore affects
        all the clients of a channel.

        For most channels, after the channel is created on the server with
        :meth:`open_channel`, before you can read/write to it, the channel
        must be activated. Because the state is global, once activated, further
        clients opening the channel will already be in a activate state.

        Similarly, to stop an active channel from reading or writing data, you
        set the channel into an inactive state. Typically, the channel uses
        less resource when inactive because e.g. sampling is disabled etc. so
        it is preferred to deactivate channels that are not used. Again, once
        deactivated, the channel will be inactive for all the clients.

        When deactivating, all the read or write requests being performed
        will be canceled. Also, reading or writing data to an inactive channel
        will result in an error. Typically, one sets the state to
        active/inactive in cycles as they are needed.

        :Parameters:

            `state`: bool
                The state to set the channel in. Can be either True for
                activation and False for inactivation.
            `flush`: bool
                Whether any data waiting to be sent, or read by the client
                will be discarded. This forces a disconnection and
                reconnection with the server for this client.

                Typically, this is only used for channels that continuously
                send data back to clients, e.g.
                :class:`~pybarst.rtv.RTVChannel`. Always, when deactivating,
                the server will not queue any new data to be sent to a client.
                However, the server might have already queued data to be sent
                to the client. This parameter controls whether that data will
                sill be sent.

                If `flush` is `False`, that data will be available to the
                client when it calls read, until the server has no more data
                available and read will return an error. For channels that
                support that, the channel will only be considered inactive
                after the last read once that error is raised.

                If `flush` is `True`, then all data waiting to be sent will
                be discarded. In addition, the channel will instantly become
                inactive. If the channel is in a read or write, then that
                method will return with an exception.

                `flush` is only used when `state` is `False`. `flush` defaults
                to `False`.

                See :meth:`cancel_read` for an alternative method to cancel
                ongoing server reads.
        '''
        return self._set_state(state, pipe=NULL, chan=-1, flush=flush)

    cdef object _cancel_read(BarstChannel self, HANDLE *pipe, flush=False,
                             int parent_pipe=0):
        '''
        All the devices that support it, you send the cancel request from the
        same pipe that has scheduled the reading. Then, the user can read
        parent pipe is if this is a sub-parent channel.
        '''
        cdef SBaseIn *base_write = <SBaseIn *>malloc(2 * sizeof(SBaseIn))
        cdef int res
        cdef DWORD read_size = 0
        if base_write == NULL:
            raise BarstException(NO_SYS_RESOURCE)

        if parent_pipe:
            base_write.dwSize = 2 * sizeof(SBaseIn)
            base_write.eType = ePassOn
            base_write.nChan = self.parent_chan
            (<SBaseIn *>(<char *>base_write + sizeof(SBaseIn))).dwSize = sizeof(SBaseIn)
            (<SBaseIn *>(<char *>base_write + sizeof(SBaseIn))).eType = eCancelReadRequest
            (<SBaseIn *>(<char *>base_write + sizeof(SBaseIn))).nChan = self.chan
            (<SBaseIn *>(<char *>base_write + sizeof(SBaseIn))).nError = 0
        else:
            base_write.dwSize = sizeof(SBaseIn)
            base_write.eType = eCancelReadRequest
            base_write.nChan = self.chan

        base_write.nError = 0
        res = self.write_read(pipe[0],
        (2 * sizeof(SBaseIn)) if parent_pipe else sizeof(SBaseIn),
        base_write, &read_size, NULL)

        free(base_write)
        if res:
            raise BarstException(res)

        if flush:
            self.close_handle(pipe[0])
            pipe[0] = self.open_pipe('rw')

    cpdef object cancel_read(BarstChannel self, flush=False):
        '''
        Cancels a continuous read.

        This method is only implemented for for the classes that indicate that
        e.g. :class:`~pybarst.mcdaq.MCDAQChannel`. For other classes, it
        doesn't do anything.

        Some classes offer an option where the server continuously sends data
        read back to the client. For those classes, one can stop the read
        operation by setting the state to inactive with :meth:`set_state`,
        which will affect all the clients connected, or by calling this
        method. With this method, the read operation is only canceled for this
        client.

        :Parameters:

            `flush`: bool
                Whether any data already waiting to be read by the client
                will be discarded. This forces a disconnection and
                reconnection with the server for this client. `flush` defaults
                to `False`.

                After canceling, the server will not queue any new data to be
                sent to the client. However, the server might have already
                queued data to be sent to the client. This parameter controls
                whether that data will sill be sent.

                If `flush` is `False`, that data will be available to the
                client when it calls read, until the server has no more data
                available and read will then return an error once. Calling read
                after the error, will trigger the server to start sending new
                data again.

                If `flush` is `True`, then all data waiting to be sent will
                be discarded. In addition, no error will be raised upon a
                subsequent call to read, but instead it will trigger the server
                to start sending data to the client again.

        .. note::
            Calling this method while a read operation is not ongoing may
            result in an exception.
        '''
        pass
