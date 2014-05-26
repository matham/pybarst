
include '../barst_defines.pxi'
include '../inline_funcs.pxi'


cdef class BarstPipe(object):
    cdef public DWORD timeout
    '''
    The amount of time to wait when connecting to the server before a
    timeout occurs. Defaults to :attr:`pybarst.core.default_server_timeout` ms.
    '''
    cdef public bytes pipe_name
    '''
    The name of the pipe used to communicate with the server for the
    channel. See :class:`BarstPipe` description. This is read only and is set
    by the channel.

    .. note::
        Unicode is currently not supported.
    '''

    cdef inline HANDLE open_pipe(BarstPipe self, str access) except NULL
    cdef inline int write_read(BarstPipe self, HANDLE pipe, DWORD write_size,
                                   void *msg, DWORD *read_size, void *read_msg)
    cdef inline void close_handle(BarstPipe self, HANDLE pipe)


cdef class BarstServer(BarstPipe):
    cdef public dict managers
    '''
    A dictionary containing the managers currently open in the server.
    Read only. See :meth:`get_manager`. :attr:`managers` is a dict, defaults
    to `{}`. Read only.

    For example, after the FTDI manager is opened::

        >>> server.open_server()
        >>> server.get_manager('ftdi')
        >>> print(server.managers)
        {'ftdi': {'version': 197127L, 'chan': 0, 'chan_id': 'FTDIMan'}}

    For each manager, the values in the dict are:

        `version`: the version of that manager's driver.
        `chan`: the channel number of the manager in the server.
        `chan_id`: the string ID given to that manager by barst.
    '''
    cdef public object barst_path
    '''
    The full path to the Barst binary. When the server doesn't exist,
    we launch a server instance using this binary when :meth:`open_server` is
    called. :attr:`barst_path` is a string, defaults to `''`.
    '''
    cdef public object curr_dir
    '''
    When we launch the binary at :attr:`barst_path` which creates the
    server, :attr:`curr_dir` is the directory used by the binray as the current
    directory.
    '''
    cdef public DWORD write_size
    '''
    The maximum buffer size used by the client for writing to the server's
    main pipe. The default value should be large enough for all the messages,
    however, if there errors indicating that the whole messages was not
    written, this value should be increased.

    .. note::
        The value only affects the server's main pipe, not the pipes of the
        individual channels. This parameter is only used when the server is
        launched by the client, not when the server already exists.
    '''
    cdef public DWORD read_size
    '''
    The maximum buffer size used by the client for reading from the
    server's main pipe. The default value should be large enough for all the
    messages, however, if there errors indicating that the whole messages was
    not read, this value should be increased.

    .. note::
        The value only affects the server's main pipe, not the pipes of the
        individual channels. This parameter is only used when the server is
        launched by the client, not when the server already exists.
    '''
    cdef public long long max_server_size
    '''
    The maximum number of bytes that the server can queue to send to clients
    at any time. If `-1`, it's unlimited. There are many channels which
    when requested, the server will continuously send data to clients, e.g.
    RTV channels. When `-1`, if the client never reads, the server will still
    continuously queue more data, exhausting its RAM after some time. Using
    this value, once the server has exceeded this many bytes in its queue, new
    data waiting to be sent will simply be discarded.

    .. note::
        This is a global server wide value. That is, the write queues of all
        the channels are combined when checking if the size is too large.
        Therefore, once exceeded, no channel will be able to send data to a
        client until the client resolves the waiting data. Also, while some
        channels will resume sending data once the value is not exceeded
        anymore, other channels might disable their pipes. So once exceeded,
        the server should be thought of as being in a unrecoverable error
        state.
    '''
    cdef public int connected
    '''
    Whether the instance opened it's connection with the server. If False,
    :meth:`open_server` must be called. Closing the server sets this to False.
    Read only.
    '''

    cpdef object open_server(BarstServer self)
    cpdef object close_server(BarstServer self)
    cpdef DWORD get_version(BarstServer self) except *
    cpdef object get_manager(BarstServer self, str manager)
    cpdef object close_manager(BarstServer self, str manager)
    cpdef object clock(BarstServer self)

    cdef DWORD _get_man_version(BarstServer self, int chan) except *
    cdef object _get_man_ID(BarstServer self, int chan)


cdef class BarstChannel(BarstPipe):
    # each channel type has corresponding ctype struct(s) for settings
    cdef public int chan
    '''
    The channel number of this channel in the server. For example, an FTDI
    channel is one channel among many in the FTDI manager - each channel
    gets a channel number. Read only.
    '''
    cdef public int parent_chan
    '''
    The channel number of this channel's parent, e.g. if this is a FTDI
    channel then it's parent channel is the FTDI manager and this value will
    represent the FTDI manager's channel number in the server. Read only.
    '''
    cdef public str barst_chan_type
    '''
    The string ID given to the channel type by barst. Each channel type
    has a unique string assigned by barst. Read only.
    '''
    cdef public BarstServer server
    '''
    A :class:`BarstServer` instance in which this channel exists / will
    exist.
    '''
    cdef public int connected
    '''
    Whether the instance opened it's connection with the server. If False,
    :meth:`open_channel` must be called. Closing the channel sets this to
    False. Read only.
    '''
    cdef HANDLE pipe

    cpdef object open_channel(BarstChannel self)
    cpdef object close_channel_server(BarstChannel self)
    cpdef object close_channel_client(BarstChannel self)
    cpdef object set_state(BarstChannel self, int state, object flush=*)
    cpdef object cancel_read(BarstChannel self, flush=*)
    #cpdef object is_active(BarstChannel self)

    cdef object _cancel_read(BarstChannel self, HANDLE *pipe, flush=*,
                             int parent_pipe=*)
    cdef object _set_state(BarstChannel self, int state, HANDLE pipe=*,
                           int chan=*, object flush=*)
