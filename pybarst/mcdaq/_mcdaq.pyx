

__all__ = ('MCDAQChannel', )

cdef extern from "stdlib.h" nogil:
    void *malloc(size_t)
    void free(void *)
cdef extern from "string.h":
    void *memcpy(void *, const void *, size_t)
    void *memset (void *, int, size_t)


from pybarst.core.exception import BarstException
from pybarst.core import join as barst_join


cdef class MCDAQChannel(BarstChannel):
    '''
    An Measurement Computing interface channel.

    A Measurement Computing DAQ channel controls a single Measurement Computing
    DAQ device. See module description for details.

    :Parameters:

        `chan`: int
            The channel number of the device. Before an MC DAQ device can be
            used, one has to load it and assign a channel number to it using
            InstaCal. Using a particular channel number here, will select
            which DAQ device to read / write to.
        `server`: :class:`~pybarst.core.BarstServer`
            An instance of a server through which this channel is opened.
        `direction`: str
            Whether this channel can read, write, or do both. See
            :attr:`direction`. Defaults to `'rw'`.
        `init_val`: unsigned short
            If this this channel can write, the value to initialize the channel
            with after it's created. See :attr:`init_val`. Defaults to `0`.
        `continuous`: str
            If this channel can read, whether when reading from it, data will
            be sent back to the client continuously. See :attr:`continuous`.
            Defaults to `False`.

        For example with a Switch & Sense 8/8 connected and enumerated as
        port 0::

            >>> # open the channel, which supports both input / output
            >>> daq = MCDAQChannel(chan=0, server=server, direction='rw', \
init_val=0)
            >>> # create it on the server
            >>> daq.open_channel()
            >>> print(daq)
            <pybarst.mcdaq._mcdaq.MCDAQChannel object at 0x02269EF8>
            >>> # now read the port
            >>> print(daq.read())
            (4.913095627208118, 0)
            >>> # all ports at the input are low
            >>> # now set output line 1 to high
            >>> print(daq.write(mask=0x00FF, value=0x0002))
            4.91410123958
    '''

    def __init__(MCDAQChannel self, int chan, BarstServer server,
                 direction='rw', init_val=0, continuous=False, **kwargs):
        pass

    def __cinit__(MCDAQChannel self, int chan, BarstServer server,
                  direction='rw', init_val=0, continuous=False, **kwargs):
        self.direction = direction
        self.init_val = init_val
        self.continuous = continuous
        self.chan = chan
        self.server = server
        self.read_pipe = NULL
        self.reading = 0
        memset(&self.daq_init, 0, sizeof(SChanInitMCDAQ))

    cpdef object open_channel(MCDAQChannel self):
        '''
        Opens the, possibly existing, channel on the server and connects the
        client to it. If the channel already exists, a new client connection
        will be opened to the channel.

        See :meth:`~pybarst.core.server.BarstChannel.open_channel` for more
        details.

        .. note::
            If the channel already exists on the server, the settings used to
            initialize this client, e.g. :attr:`direction` will be overwritten
            by their values received from the existing server channel.
        '''
        cdef int man_chan, res, pos = 0
        cdef HANDLE pipe
        cdef DWORD read_size = (2 * sizeof(SBaseOut) + sizeof(SBase) +
                                sizeof(SChanInitMCDAQ))
        cdef void *phead_out
        cdef void *phead_in
        cdef SBaseIn *pbase
        cdef SChanInitMCDAQ chan_init
        self.close_channel_client()
        cdef dict dir = {'r': 0, 'w': 1, 'rw': 2, 'wr': 2}

        if self.direction not in dir:
            raise BarstException(msg='The channel direction, {}, is invalid '
                'allowed values are {}'.format(self.direction, dir.keys()))

        memset(&chan_init, 0, sizeof(SChanInitMCDAQ))
        chan_init.ucDirection = dir[self.direction]
        chan_init.usInitialVal = self.init_val
        chan_init.bContinuous = self.continuous

        self.reading = 0
        man_chan = self.server.get_manager('mcdaq')['chan']
        self.parent_chan = man_chan
        pipe = self.server.open_pipe('rw')
        self.pipe_name = bytes(barst_join(self.server.pipe_name,
            bytes(man_chan), bytes(self.chan)))

        phead_out = malloc(2 * sizeof(SBaseIn) + sizeof(SBase) +
                           sizeof(SChanInitMCDAQ))
        phead_in = malloc(read_size)
        if phead_out == NULL or phead_in == NULL:
            CloseHandle(pipe)
            free(phead_out)
            free(phead_in)
            raise BarstException(NO_SYS_RESOURCE)

        pbase = <SBaseIn *>phead_out
        pbase.dwSize = (2 * sizeof(SBaseIn) + sizeof(SBase) +
                        sizeof(SChanInitMCDAQ))
        pbase.eType = ePassOn
        pbase.nChan = man_chan
        pbase.nError = 0
        pbase += 1
        pbase.dwSize = (sizeof(SBaseIn) + sizeof(SBase) +
                        sizeof(SChanInitMCDAQ))
        pbase.eType = eSet
        pbase.nChan = self.chan
        pbase.nError = 0
        pbase += 1
        pbase.dwSize = sizeof(SChanInitMCDAQ) + sizeof(SBase)
        pbase.eType = eMCDAQChanInit
        memcpy(<char *>pbase + sizeof(SBase), &chan_init,
               sizeof(SChanInitMCDAQ))

        # create the channel on the server
        res = self.server.write_read(pipe, 2 * sizeof(SBaseIn) +
        sizeof(SBase) + sizeof(SChanInitMCDAQ), phead_out, &read_size,
        phead_in)
        if not res:
            if ((read_size == sizeof(SBaseIn) or
                 read_size == sizeof(SBaseOut)) and
                (<SBaseIn *>phead_in).dwSize == read_size and
                (<SBaseIn *>phead_in).nError):
                res = (<SBaseIn *>phead_in).nError
            elif (not (read_size == sizeof(SBaseOut) and
                       (<SBaseIn *>phead_in).dwSize == read_size and
                       (<SBaseIn *>phead_in).eType == eResponseExL)):
                res = NO_CHAN

        if res and res != ALREADY_OPEN:
            free(phead_in)
            free(phead_out)
            CloseHandle(pipe)
            raise BarstException(res)

        # now get the channel info and initialize things
        pbase = <SBaseIn *>phead_out
        pbase.dwSize = 2 * sizeof(SBaseIn)
        pbase.eType = ePassOn
        pbase.nChan = man_chan
        pbase.nError = 0
        pbase += 1
        pbase.dwSize = sizeof(SBaseIn)
        pbase.eType = eQuery
        pbase.nChan = self.chan
        pbase.nError = 0
        read_size = (2 * sizeof(SBaseOut) + sizeof(SBase) +
                     sizeof(SChanInitMCDAQ))
        res = self.server.write_read(pipe, 2 * sizeof(SBaseIn), phead_out,
                                     &read_size, phead_in)
        # parse the returned info
        while pos < read_size:
            if ((<SBaseIn *>(<char *>phead_in + pos)).dwSize <= read_size - pos and
                (<SBaseIn *>(<char *>phead_in + pos)).dwSize >= sizeof(SBaseOut) and
                (<SBase *>(<char *>phead_in + pos)).eType == eResponseEx):
                self.barst_chan_type = (<SBaseOut *>(<char *>phead_in + pos)).szName
                pos += sizeof(SBaseOut)
            elif ((<SBaseIn *>(<char *>phead_in + pos)).dwSize <= read_size - pos and
                (<SBaseIn *>(<char *>phead_in + pos)).dwSize >= sizeof(SBaseOut) and
                (<SBase *>(<char *>phead_in + pos)).eType == eResponseExL):
                #self.timer = (<SBaseOut *>(<char *>phead_in + pos)).llLargeInteger
                pos += sizeof(SBaseOut)
            elif ((<SBase *>(<char *>phead_in + pos)).dwSize <= read_size - pos and
                (<SBase *>(<char *>phead_in + pos)).dwSize == sizeof(SBase) +
                sizeof(SChanInitMCDAQ) and
                (<SBase *>(<char *>phead_in + pos)).eType == eMCDAQChanInit):
                self.daq_init = (<SChanInitMCDAQ *>(<char *>phead_in + pos +
                    sizeof(SBase)))[0]
                self.init_val = self.daq_init.usInitialVal
                self.continuous = self.daq_init.bContinuous
                self.direction = {v: k for k, v in dir.iteritems()}[
                self.daq_init.ucDirection]
                pos += sizeof(SBase) + sizeof(SChanInitMCDAQ)
            else:
                res = UNEXPECTED_READ
                break

        free(phead_in)
        free(phead_out)
        CloseHandle(pipe)
        if res:
            raise BarstException(res)

        self.pipe = self.open_pipe('rw')
        self.read_pipe = self.open_pipe('rw')
        BarstChannel.open_channel(self)

    cpdef close_channel_client(MCDAQChannel self):
        '''
        See :meth:`~pybarst.core.server.BarstChannel.close_channel_client` for
        details.
        '''
        self.close_handle(self.read_pipe)
        self.read_pipe = NULL
        BarstChannel.close_channel_client(self)

    cpdef object write(MCDAQChannel self, unsigned short mask,
                       unsigned short value):
        '''
        Tells the server to update the states of some digital pins on the DAQ
        device.

        Before this method can be called, :meth:`FTDIPin.open_channel` must be
        called.

        :Parameters:
            `mask`: unsigned short (16-bit)
                The mask which controls which port's state will be changed by
                `value`. E.g. a value of 0b01000001 means that
                only pin 0, and pin 6 can be changed by `value`, all the other
                lines will remain unchanged no matter their value in `value`.
            `value`: unsigned short (16-bit)
                The 16-bit value which will be written to the port controlled
                by this channel according to the `mask` mask. Only bits which
                have a high value in `mask` will be changed by the values
                in `value`, the others will remain the same.

                Each element in `buffer` is similar to `data` 's, `value`
                parameter. A high value for the corresponding pin will set the
                pin high, and low otherwise.

        :returns:
            float. The server time,
            :meth:`pybarst.core.server.BarstServer.clock`, when the data was
            written.

        For example::

            >>> # set the lines 0-3 to high
            >>> print(daq.write(mask=0x00FF, value=0x000F))
            3.58502208323
            >>> # set only line 0 low, the remaining lines are unchanged
            >>> print(daq.write(mask=0x0001, value=0x0000))
            3.58652372654
        '''
        cdef DWORD write_size = (sizeof(SBaseIn) + sizeof(SBase) +
                                 sizeof(SMCDAQWData))
        cdef DWORD read_size = sizeof(SBaseOut)
        cdef SMCDAQWData daq_data
        cdef SBaseIn *pbase_write = <SBaseIn *>malloc(write_size)
        cdef SBaseOut base_read
        if pbase_write == NULL:
            raise BarstException(NO_SYS_RESOURCE)

        daq_data.usValue = value
        daq_data.usBitSelect = mask
        pbase_write.dwSize = write_size
        pbase_write.eType = eData
        pbase_write.nChan = self.chan
        pbase_write.nError = 0
        (<SBase *>(<char *>pbase_write +
                   sizeof(SBaseIn))).dwSize = write_size - sizeof(SBaseIn)
        (<SBase *>(<char *>pbase_write +
                   sizeof(SBaseIn))).eType = eMCDAQWriteData
        (<SMCDAQWData *>(<char *>pbase_write + sizeof(SBaseIn) +
                         sizeof(SBase)))[0] = daq_data

        res = self.write_read(self.pipe, write_size, pbase_write, &read_size,
                              &base_read)
        if not res:
            if ((read_size != sizeof(SBaseOut) and
                 read_size != sizeof(SBaseIn)) or
                (read_size == sizeof(SBaseIn) and
                 not base_read.sBaseIn.nError) or
                (read_size == sizeof(SBaseOut) and
                 base_read.sBaseIn.eType != eResponseExD)):
                res = UNEXPECTED_READ
            else:
                res = base_read.sBaseIn.nError

        free(pbase_write)
        if res:
            raise BarstException(res)

        return base_read.dDouble

    cpdef object read(MCDAQChannel self):
        '''
        Requests the server to read the states of the pins of the DAQ device.
        This method will wait until the server sends data, or an error
        message, thereby tying up this thread.

        If :attr:`continuous` is `False`, each call triggers
        the server to read from the device which is then sent to the client. If
        :attr:`continuous` is `True`, after the first call
        to :meth:`read` the server will continuously read from the device and
        send the results back to the client. This means that if the client
        doesn't call :meth:`read` frequently enough data will accumulate in the
        pipe. Also, the data returned might have been acquired before the
        current :meth:`read` was called.

        To cancel a read request while the read is still waiting, from another
        thread you must call
        :meth:`~pybarst.core.server.BarstChannel.close_channel_client`, or
        :meth:`~pybarst.core.server.BarstChannel.close_channel_server`, or just
        delete the server, which will cause this method to return with an
        error.

        When :attr:`continuous` is `True`, a more gentle way of canceling a
        read request while not currently waiting in :meth:`read`, is to call
        :meth:`cancel_read` which will cause a subsequent read operation to
        return with an error, but will not delete/close the channel. However,
        once :meth:`read` returns with an error, a further call to :meth:`read`
        will cause the reading to start again. See those methods for more
        details.

        Before this method can be called, :meth:`open_channel` must be
        called.

        :returns:
            2-tuple of (`time`, `data`). `time` is the time that the data was
            read in server time, :meth:`pybarst.core.server.BarstServer.clock`.
            `data` is a unsigned short (16-bit) value indicating the states of
            each pin of the input port. See class description.

        For example::

            >>> print(daq.read())
            (3.5920170227303707, 15)
            >>> # input lines 0-3 are high
        '''
        cdef DWORD read_size = sizeof(SBaseOut) + sizeof(SBaseIn)
        cdef DWORD read_size_out = read_size
        cdef int res = 0
        cdef SBaseOut *pbase
        cdef unsigned short val = 0
        cdef tuple result

        if (not self.daq_init.bContinuous) or not self.reading:
            self._send_trigger()
            if self.daq_init.bContinuous:
                self.reading = 1

        pbase = <SBaseOut *>malloc(read_size)
        if pbase == NULL:
            raise BarstException(NO_SYS_RESOURCE)

        with nogil:
            r = ReadFile(self.read_pipe, pbase, read_size, &read_size_out,
                         NULL)
        if not r:
            res = WIN_ERROR(GetLastError())
            free(pbase)
            raise BarstException(res)
        if ((read_size_out != sizeof(SBaseIn) and
             read_size_out != sizeof(SBaseOut) and
             read_size_out != read_size) or
            ((read_size_out == sizeof(SBaseIn) or
              read_size_out == sizeof(SBaseOut)) and
             not pbase.sBaseIn.nError and
             pbase.sBaseIn.eType != eCancelReadRequest) or
            (read_size_out == read_size and
             not pbase.sBaseIn.nError and
             pbase.sBaseIn.eType != eCancelReadRequest and
             (pbase.sBaseIn.eType != eResponseExD or
              (<SBaseIn *>(<char *>pbase +
                         sizeof(SBaseOut))).eType != eData))):
            res = UNEXPECTED_READ
        elif pbase.sBaseIn.nError:
            res = pbase.sBaseIn.nError
        elif pbase.sBaseIn.eType == eCancelReadRequest:
            res = DEVICE_CLOSING
        if res:
            self.reading = 0
            free(pbase)
            raise BarstException(res)

        val = <unsigned short>(<SBaseIn *>(<char *>pbase + sizeof(SBaseOut))).dwInfo
        result = (pbase.dDouble, val)
        free(pbase)
        return result

    cdef inline object _send_trigger(MCDAQChannel self):
        cdef SBaseIn base_out
        cdef int res
        cdef DWORD read_size = 0

        base_out.dwSize = sizeof(SBaseIn)
        base_out.eType = eTrigger
        base_out.nChan = self.chan
        base_out.nError = 0
        res = self.write_read(self.read_pipe, sizeof(SBaseIn), &base_out,
                              &read_size, NULL)

        if res:
            raise BarstException(res)

    cpdef object cancel_read(MCDAQChannel self, flush=False):
        '''
        See :meth:`~pybarst.core.server.BarstChannel.cancel_read` for details.

        This method is only callable when :attr:`continuous` is `True`.

        .. note::
            When `flush` is `False`, the server will continue sending data that
            has already been queued, but it will not add new data to the queue.
            After the last valid read, :meth:`read` will return with an error
            indicating there's no new data coming. After that error, a further
            call to :meth:`read` will cause a new read request and data will
            start coming again.

            If `flush` is `True`, the server will discard all data waiting to
            be sent, and the client will not receive the final error message
            when calling :meth:`read`. Instead, a subsequent call to
            :meth:`read` will cause a new read request to be sent to the server
            and data will start coming again.
        '''
        if self.reading:
            self._cancel_read(&self.read_pipe, flush, 0)
            if flush:
                self.reading = 0

    cpdef object set_state(MCDAQChannel self, int state, flush=False):
        '''
        See :meth:`~pybarst.core.server.BarstChannel.set_state` for details.

        .. note::
            For a Measurement Computing  DAQ channel, this method doesn't do
            anything, since after creation, the state of the channel on the
            server is always active.
        '''
        pass
