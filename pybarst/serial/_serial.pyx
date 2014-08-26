
__all__ = ('SerialChannel', )

cdef extern from "stdlib.h" nogil:
    void *malloc(size_t)
    void free(void *)
cdef extern from "string.h":
    void *memcpy(void *, const void *, size_t)
    void *memset (void *, int, size_t)


from cpython.array cimport array, clone
from pybarst.core.exception import BarstException
from pybarst.core import join as barst_join


cdef dict _parity = {'even': 2, 'odd': 1, 'mark': 3, 'none': 0, 'space': 4}


cdef class SerialChannel(BarstChannel):
    '''
    A serial port interface channel.

    A serial port channel controls a single serial port.

    :Parameters:

        `server`: :class:`~pybarst.core.BarstServer`
            An instance of a server through which this channel is opened.
        `port_name`: bytes
            The name of the port this channel controls. See :attr:`port_name`.
        `max_write`: unsigned int
            The maximum number of bytes written to the port. See
            :attr:`max_write`.
        `max_read`: unsigned int
            The maximum number of bytes read from the port. See
            :attr:`max_read`.
        `baud_rate`: unsigned int
            The baud rate to use for the port. See :attr:`baud_rate`. Defaults
            to 9600.
        `stop_bits`: float
            The number of stop bits to use. See :attr:`stop_bits`. Defaults to
            `1`.
        `parity`: str
            The parity scheme to use. See :attr:`parity`. Defaults to 'none'.
        `byte_size`: unsigned char
            The number of bits in the bytes transmitted and received. See
            :attr:`byte_size`. Defaults to 8.

    In the following example, a loopback cable was connected to the com3
    serial port::

        >>> # open the com3 port and read/write a maximum of 32 chars.
        >>> serial = SerialChannel(server=server, port_name='COM3', \
max_write=32, max_read=32)
        >>> serial.open_channel()
        >>> print serial
        <pybarst.serial._serial.SerialChannel object at 0x024C06F0>
        >>> print serial.write(value='cheesecake and fries.', timeout=10000)
        (0.0525455800455579, 21)
        >>> print serial.read(read_len=21, timeout=10000)
        (0.056576697876712934, 'cheesecake and fries.')
        >>> print serial.write(value='apples.', timeout=10000)
        (0.06754473171193724, 7)
        >>> print serial.read(read_len=7, timeout=10000)
        (0.07514634606696861, 'apples.')
    '''

    def __init__(SerialChannel self, BarstServer server, port_name, max_write,
                 max_read, baud_rate=9600, stop_bits=1, parity='none',
                 byte_size=8, **kwargs):
        pass

    def __cinit__(SerialChannel self, BarstServer server, port_name, max_write,
                  max_read, baud_rate=9600, stop_bits=1, parity='none',
                  byte_size=8, **kwargs):
        self.server = server
        self.port_name = port_name
        self.max_write = max_write
        self.max_read = max_read
        self.baud_rate = baud_rate
        self.stop_bits = stop_bits
        self.parity = parity
        self.byte_size = byte_size
        memset(&self.serial_init, 0, sizeof(SChanInitSerial))

    cpdef object open_channel(SerialChannel self):
        '''
        Opens the, possibly existing, channel on the server and connects the
        client to it. If the channel already exists, a new client connection
        will be opened to the channel.

        See :meth:`~pybarst.core.server.BarstChannel.open_channel` for more
        details.

        .. note::
            If the channel already exists on the server, the settings used to
            initialize this client, e.g. :attr:`parity` will be overwritten
            by their values received from the existing server channel.
        '''
        cdef int man_chan, res, pos = 0
        cdef HANDLE pipe
        cdef DWORD read_size = (2 * sizeof(SBaseOut) + sizeof(SBase) +
                                sizeof(SChanInitSerial))
        cdef void *phead_out
        cdef void *phead_in
        cdef SBaseIn *pbase
        cdef SChanInitSerial chan_init
        self.close_channel_client()

        if len(self.port_name) >= SERIAL_MAX_LENGTH:
            raise BarstException(msg='The port name, {} is longer than the '
                'allowed length, {}'.format(self.port_name, SERIAL_MAX_LENGTH))

        if (self.stop_bits != 1 and self.stop_bits != 1.5 and
            self.stop_bits != 2):
            raise BarstException(msg='The number of stop bit, {}, is not 1, '
                                 '1.5, or 2'.format(self.stop_bits))

        if self.byte_size > 8 or self.byte_size < 4:
            raise BarstException(msg='The byte size, {}, is not within the '
                                 'accepted range'.format(self.byte_size))

        if self.parity not in _parity:
            raise BarstException(msg='The parity, {}, is invalid. Acceptable '
            'values are {}'.format(self.parity, _parity.keys()))

        memset(&chan_init, 0, sizeof(SChanInitSerial))
        memcpy(chan_init.szPortName, <char *>self.port_name,
               len(self.port_name))
        chan_init.dwMaxStrWrite = self.max_write
        chan_init.dwMaxStrRead = self.max_read
        chan_init.dwBaudRate = self.baud_rate
        chan_init.ucStopBits = (0 if self.stop_bits == 1 else
                                (1 if self.stop_bits == 1.5 else 2))
        chan_init.ucParity = _parity[self.parity]
        chan_init.ucByteSize = self.byte_size

        man_chan = self.server.get_manager('serial')['chan']
        self.parent_chan = man_chan
        pipe = self.server.open_pipe('rw')

        phead_out = malloc(2 * sizeof(SBaseIn) + sizeof(SBase) +
                           sizeof(SChanInitSerial))
        phead_in = malloc(read_size)
        if phead_out == NULL or phead_in == NULL:
            CloseHandle(pipe)
            free(phead_out)
            free(phead_in)
            raise BarstException(NO_SYS_RESOURCE)

        pbase = <SBaseIn *>phead_out
        pbase.dwSize = (2 * sizeof(SBaseIn) + sizeof(SBase) +
                        sizeof(SChanInitSerial))
        pbase.eType = ePassOn
        pbase.nChan = man_chan
        pbase.nError = 0
        pbase += 1
        pbase.dwSize = (sizeof(SBaseIn) + sizeof(SBase) +
                        sizeof(SChanInitSerial))
        pbase.eType = eSet
        pbase.nChan = -1
        pbase.nError = 0
        pbase += 1
        pbase.dwSize = sizeof(SChanInitSerial) + sizeof(SBase)
        pbase.eType = eSerialChanInit
        memcpy(<char *>pbase + sizeof(SBase), &chan_init,
               sizeof(SChanInitSerial))

        # create the channel on the server
        res = self.server.write_read(pipe, 2 * sizeof(SBaseIn) +
        sizeof(SBase) + sizeof(SChanInitSerial), phead_out, &read_size,
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
        self.chan = (<SBaseIn *>phead_in).nChan
        self.pipe_name = bytes(barst_join(self.server.pipe_name,
            bytes(man_chan), bytes(self.chan)))

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
                     sizeof(SChanInitSerial))
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
                sizeof(SChanInitSerial) and
                (<SBase *>(<char *>phead_in + pos)).eType == eSerialChanInit):
                self.serial_init = (<SChanInitSerial *>(<char *>phead_in + pos +
                    sizeof(SBase)))[0]
                self.port_name = bytes(self.serial_init.szPortName)
                self.max_write = self.serial_init.dwMaxStrWrite
                self.max_read = self.serial_init.dwMaxStrRead
                self.baud_rate = self.serial_init.dwBaudRate
                self.stop_bits = (1 if self.serial_init.ucStopBits == 0 else
                                  (1.5 if self.serial_init.ucStopBits == 1
                                   else 2))
                self.parity = {v: k for k, v in _parity.iteritems()}[
                self.serial_init.ucParity]
                self.byte_size = self.serial_init.ucByteSize
                pos += sizeof(SBase) + sizeof(SChanInitSerial)
            else:
                res = UNEXPECTED_READ
                break

        free(phead_in)
        free(phead_out)
        CloseHandle(pipe)
        if res:
            raise BarstException(res)
        else:
            self.pipe = self.open_pipe('rw')

        BarstChannel.open_channel(self)

    cpdef object write(SerialChannel self, bytes value, timeout=0):
        '''
        Requests the server to write `value` to the serial port.

        The write request is initiated when this method is called and it waits
        until it finishes writing, it times out, or it returns an error.
        To terminate the waiting client, from another thread you must call
        :meth:`~pybarst.core.BarstChannel.close_channel_client`, or just close
        the channel or server, which will cause this method to return with an
        error.

        Before this method can be called, :meth:`open_channel` must be called.

        :Parameters:

            `value`: bytes
                The byte string to write to the port. The length of the bytes
                instance cannot exceed :attr:`max_write`.
            `timeout`: unsigned int
                The amount of time, in ms, the server should wait to finish the
                write request before returning with a timeout error. If zero,
                it won't time out. Defaults to `0`.

        :returns:
            2-tuple of (`time`, `length`). `time` is the time that the data was
            finished writing in channel time,
            :meth:`~pybarst.core.BarstServer.clock`.
            `length` is the number of bytes actually written.

        For example::

            >>> print serial.write(value='cheesecake and fries.', \
timeout=10000)
            (0.0525455800455579, 21)
            >>> print serial.write(value='apples.', timeout=10000)
            (0.06754473171193724, 7)
        '''
        cdef DWORD write_size = (sizeof(SBaseIn) + sizeof(SBase) +
                                 sizeof(SSerialData) + len(value))
        cdef DWORD read_size = (sizeof(SBaseOut) + sizeof(SBase) +
                                sizeof(SSerialData))
        cdef SSerialData ser_data
        cdef double t
        cdef int amount_wrote
        cdef SBaseIn *pbase_write= <SBaseIn *>malloc(write_size)
        cdef SBaseOut *pbase_read= <SBaseOut *>malloc(read_size)
        if pbase_write == NULL or pbase_read == NULL:
            free(pbase_write)
            free(pbase_read)
            raise BarstException(NO_SYS_RESOURCE)

        if <DWORD>len(value) > self.max_write:
            raise BarstException(msg='The length of the string to write, {} '
            'is longer than the maximum write size indicated, {}'.
            format(len(value), self.max_write))

        ser_data.dwSize = len(value)
        ser_data.dwTimeout = timeout
        ser_data.cStop = 0
        ser_data.bStop = 0
        pbase_write.dwSize = write_size
        pbase_write.eType = eData
        pbase_write.nChan = self.chan
        pbase_write.nError = 0
        (<SBase *>(<char *>pbase_write +
                   sizeof(SBaseIn))).dwSize = write_size - sizeof(SBaseIn)
        (<SBase *>(<char *>pbase_write +
                   sizeof(SBaseIn))).eType = eSerialWriteData
        memcpy(<char *>pbase_write + sizeof(SBaseIn) + sizeof(SBase),
               &ser_data, sizeof(SSerialData))
        memcpy(<char *>pbase_write + sizeof(SBaseIn) + sizeof(SBase) +
               sizeof(SSerialData), <char *>value, len(value))

        res = self.write_read(self.pipe, write_size, pbase_write, &read_size,
                              pbase_read)
        if not res:
            if ((read_size != sizeof(SBaseOut) and
                 read_size != sizeof(SBaseIn) and
                 read_size != sizeof(SBaseOut) + sizeof(SBase) +
                 sizeof(SSerialData)) or ((read_size == sizeof(SBaseIn) or
                                           read_size == sizeof(SBaseOut)) and
                                          not pbase_read.sBaseIn.nError) or
                (read_size == sizeof(SBaseOut) + sizeof(SBase) +
                 sizeof(SSerialData) and
                 (pbase_read.sBaseIn.eType != eResponseExD or
                  (<SBase *>(<char *>pbase_read +
                             sizeof(SBaseOut))).eType != eSerialWriteData))):
                res = UNEXPECTED_READ
            else:
                res = pbase_read.sBaseIn.nError
        if res:
            free(pbase_write)
            free(pbase_read)
            raise BarstException(res)

        t = pbase_read.dDouble
        amount_wrote = (<SSerialData *>(<char *>pbase_read + sizeof(SBaseOut)
                                        + sizeof(SBase))).dwSize
        free(pbase_write)
        free(pbase_read)

        return t, amount_wrote

    cpdef object read(SerialChannel self, DWORD read_len, timeout=0,
                      bytes stop_char=b''):
        '''
        Requests the server to read from the serial port and send the data back
        to *this* client. When multiple clients are connected simultaneously,
        and each requests a read, their read requests are performed in the
        order on which they were received.

        The read request is initiated when this method is called and it waits
        until the server sends data back, returns an error, or times out.
        To terminate the waiting client, from another thread you must call
        :meth:`~pybarst.core.BarstChannel.close_channel_client`, or just close
        the channel or server, which will cause this method to return with an
        error.

        Before this method can be called, :meth:`open_channel` must be called`.

        :Parameters:

            `read_len`: int
                The number of bytes to read from the port. The value cannot
                exceed :attr:`max_read`.
            `timeout`: unsigned int
                The amount of time, in ms, the server should wait to finish the
                read request before returning. If zero, it won't time out.
                Defaults to `0`. After the timeout, if `read_len` chars was not
                read, the method just returns the data read and does not raise
                and exception.
            `stop_char`: single character bytes object
                The character on which to finish the read, even if it's less
                than `read_len`. When the server reads this character the
                read is completed and whatever read is returned. If `stop_char`
                is the empty string, `''`, then the server doesn't send data
                back until `read_len` bytes have been read, or it timed out.
                Defaults to the empty string, `''`.

        :returns:
            2-tuple of (`time`, `data`). `time` is the time that the data was
            finished reading in channel time,
            :meth:`~pybarst.core.BarstServer.clock`.
            `data` is a bytes instance containing the data read.

        For example, with a loopback cable connected to com3::

            >>> print serial.write(value='cheesecake and fries.', \
timeout=10000)
            (0.0524498444040303, 21)
            >>> # here we read the exact number of chars written.
            >>> print serial.read(read_len=21, timeout=10000)
            (0.05645847628379451, 'cheesecake and fries.')

            >>> print serial.write(value='apples with oranges.', timeout=10000)
            (0.08144922638106329, 20)
            >>> # we read more than the number of chars written, forcing us \
to time out
            >>> print serial.read(read_len=32, timeout=10000)
            (10.087937104749782, 'apples with oranges.')

            >>> print serial.write(value='apples with oranges.', timeout=10000)
            (10.114267472435971, 20)
            >>> # we read less than the number of chars written only \
returning those chars
            >>> print serial.read(read_len=7, timeout=10000)
            (10.116678238982054, 'apples ')
            >>> # now we read the rest
            >>> print serial.read(read_len=13, timeout=10000)
            (10.118474730219688, 'with oranges.')

            >>> print serial.write(value='apples with oranges.', timeout=10000)
            (10.144263390895098, 20)
            >>> # we read less than the number of chars written only \
returning those chars
            >>> print serial.read(read_len=7, timeout=10000)
            (10.146677223707279, 'apples ')
            >>> # now write even more
            >>> print serial.write(value='apples.', timeout=10000)
            (10.159265949523808, 7)
            >>> # in this read, everything we haven't read is returned
            >>> print serial.read(read_len=32, timeout=10000)
            (20.167324778223787, 'with oranges.apples.')

            >>> print serial.write(value='apples with oranges.', timeout=10000)
            (20.193081413453278, 20)
            >>> # we read more than the number of chars written, but becuase \
of the stop
            >>> # char, it doesn't wait to timeout, but returns everything it \
read when it
            >>> # hit the stop char, which here was a few more chars of the \
text written
            >>> print serial.read(read_len=32, timeout=10000, stop_char='o')
            (20.19520872073334, 'apples with oran')
            >>> # now finish up the read
            >>> print serial.read(read_len=32, timeout=10000)
            (30.198723343074974, 'ges.')

        .. note::
            When the method returns it might return up to a `read_len`
            character bytes string. Even if it times out or we hit the
            `stop_char` in the middle of the string, when specified, if the
            server already read less than or `read_len` characters, it returns
            them all.
        '''
        cdef int res = 0, r
        cdef SSerialData ser_data
        cdef DWORD read_size = (sizeof(SBaseOut) + sizeof(SBase) +
                                sizeof(SSerialData) + sizeof(char) * read_len)
        cdef DWORD write_size = (sizeof(SBaseIn) + sizeof(SBase) +
                                 sizeof(SSerialData))
        cdef SBaseIn *pbase_out = <SBaseIn *>malloc(write_size)
        cdef SBaseOut *pbase_in = <SBaseOut *>malloc(read_size)
        cdef bytes read_val
        cdef double t
        if pbase_out == NULL or pbase_in == NULL:
            free(pbase_out)
            free(pbase_in)
            raise BarstException(NO_SYS_RESOURCE)

        if read_len > self.max_read:
            raise BarstException(msg='The length of the string to read, {} '
            'is longer than the maximum read size indicated, {}'.
            format(read_len, self.max_read))

        ser_data.dwSize = read_len
        ser_data.dwTimeout = timeout
        ser_data.cStop = 0
        ser_data.bStop = 0
        if stop_char:
            ser_data.cStop = ord(stop_char)
            ser_data.bStop = 1
        pbase_out.dwSize = write_size
        pbase_out.eType = eTrigger
        pbase_out.nChan = self.chan
        pbase_out.nError = 0
        (<SBase *>(<char *>pbase_out +
                   sizeof(SBaseIn))).dwSize = write_size - sizeof(SBaseIn)
        (<SBase *>(<char* >pbase_out +
                   sizeof(SBaseIn))).eType = eSerialReadData
        memcpy(<char *>pbase_out + sizeof(SBaseIn) + sizeof(SBase), &ser_data,
               sizeof(SSerialData))

        res = self.write_read(self.pipe, write_size, pbase_out, &read_size,
                              pbase_in)
        if not res:
            if ((read_size != sizeof(SBaseOut) and
                 read_size != sizeof(SBaseIn) and
                read_size < sizeof(SBaseOut) + sizeof(SBase) +
                sizeof(SSerialData)) or
                ((read_size == sizeof(SBaseIn) or
                  read_size == sizeof(SBaseOut)) and
                 not pbase_in.sBaseIn.nError) or
                (read_size >= sizeof(SBaseOut) + sizeof(SBase) +
                 sizeof(SSerialData) and
                 (pbase_in.sBaseIn.eType != eResponseExD or
                  ((<SBase *>(<char *>pbase_in + sizeof(SBaseOut))).eType !=
                   eSerialReadData) or
                  (<SSerialData *>(<char *>pbase_in + sizeof(SBaseOut) +
                                   sizeof(SBase))).dwSize > ser_data.dwSize or
                  (read_size != sizeof(SBaseOut) + sizeof(SBase) +
                   sizeof(SSerialData) + sizeof(char) *
                   (<SSerialData *>(<char *>pbase_in + sizeof(SBaseOut) +
                                    sizeof(SBase))).dwSize)))):
                res = UNEXPECTED_READ
            elif read_size == sizeof(SBaseIn) or read_size == sizeof(SBaseOut):
                res = pbase_in.sBaseIn.nError
        if res:
            free(pbase_out)
            free(pbase_in)
            raise BarstException(res)

        res = pbase_in.sBaseIn.nError
        t = pbase_in.dDouble
        ser_data = (<SSerialData *>(<char *>pbase_in +
                                    sizeof(SBaseOut) + sizeof(SBase)))[0]
        read_val = (<char *>pbase_in + sizeof(SBaseOut) + sizeof(SBase)
        + sizeof(SSerialData))[:ser_data.dwSize]
        free(pbase_out)
        free(pbase_in)

        return t, read_val

    cpdef object set_state(SerialChannel self, int state, flush=False):
        '''
        See :meth:`~pybarst.core.server.BarstChannel.set_state` for details.

        .. note::
            For the serial channel, this method doesn't do anything, since
            after creation, the state of the channel on the server is always
            active.
        '''
        pass
