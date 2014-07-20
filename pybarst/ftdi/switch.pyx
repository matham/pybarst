'''
FTDI Switch
============

The FTDI switch module controls digital switching devices that are connected to
a FTDI digital port. These devices could be the FTDI digital input and output
pins themselves, or digital input and output devices connected and controlled
by the FTDI digital pins.
'''

_all__ = ('SerializerSettings', 'FTDISerializer', 'FTDISerializerIn',
          'FTDISerializerOut', 'PinSettings', 'FTDIPin', 'FTDIPinIn',
          'FTDIPinOut')


cdef extern from "stdlib.h" nogil:
    void *malloc(size_t)
    void free(void *)
cdef extern from "string.h":
    void *memcpy(void *, const void *, size_t)
    void *memset (void *, int, size_t)


from pybarst.core.exception import BarstException


cdef class SerializerSettings(FTDISettings):
    '''
    The settings for a serial to parallel type output / input device
    connected to the the FTDI channel. Examples are the 74HC595 for output
    and 74HC589 for input.

    These devices are controlled as serial devices by the controlling system
    but read / write as parallel ports. They are controlled by 3 digital lines;
    a clock line, a latch line, and a data line. The clock line is used to
    clock in / out the data and the latch line is used to perform a
    read / write from the pins of the device. To control such a device,
    you only need to indicate which pins on the FTDI digital port are connected
    to the clock, latch and data lines.

    Although these devices are controlled without only 3 digital lines, each
    of these device typically controls 8 digital input or output lines.
    Therefore, with only 3 lines connected to the FTDI port, once can control
    many more digital ports.

    When an instance of this class is passed to a
    :class:`~pybarst.ftdi.FTDIChannel` in the `channels` parameter, it will
    create a :class:`FTDISerializerIn` or
    :class:`FTDISerializerOut` in :attr:`~pybarst.ftdi.FTDIChannel.devices`,
    depending on the value of the :attr:`output` parameter.

    :Parameters:

        `clock_bit`: unsigned char
            The pin to which the clock line of the serial to parallel device is
            connected at the FTDI channel. Typically between 0 - 7.
        `data_bit`: unsigned char
            The pin to which the data line of the serial to parallel device is
            connected at the FTDI channel. Typically between 0 - 7.
        `latch_bit`: unsigned char
            The pin to which the latch line of the serial to parallel device is
            connected at the FTDI channel. Typically between 0 - 7.
        `num_boards`: int
            The number of serial to parallel boards in a daisy chain fashion
            that are connected. You can connect many of these serial to
            parallel boards in series, so that with only 3 lines you can
            control many digital pins, even though each such device only
            controls 8 pins directly. It is assumed by the software that each
            such device controls 8 lines.

            Defaults to 1.
        `clock_size`: int
            The number of clock cycles of the FTDI channel with pre-set
            baud rate to use for a single clock cycle communication with the
            device. The FTDI channel uses a pre-computed baud rate according
            to all the devices connected to the channel. E.g. if it computes
            to 1 MHz, each clock length is 1 us. If this is too fast for the
            device, we can increase the value, e.g. in the case above, a value
            of 2 for this parameter will result of 2 us clock lengths.

            Defaults to 1, which satisfies the typical requirements if these
            devices.
        `continuous`: bool
            Whether, when reading, we should continuously read and send data
            back to the client. This is only used for a input device
            (`output` is `False`). When `True`,  a single call to
            :meth:`FTDISerializerIn.read` after the device is activated will
            start the server reading the device continuously and sending the
            data back to this client. This will result in a high sampling rate
            of the device. If it's `False`, each call to
            :meth:`FTDISerializerIn.read` will trigger a new read resulting in
            a much slower reading rate.

            Defaults to `False`.
        `output`: bool
            If the device connected is output device (74HC595) or a input
            device (74HC589). If True, a :class:`FTDISerializerOut` will be
            created, otherwise a :class:`FTDISerializerIn` will be created
            by the :class:`~pybarst.ftdi.FTDIChannel`.

            Defaults to `False`.
    '''

    def __init__(SerializerSettings self, clock_bit, data_bit, latch_bit,
                 num_boards=1, clock_size=1, continuous=False, output=False,
                 **kwargs):
        self.num_boards = num_boards
        self.clock_size = clock_size
        self.clock_bit = clock_bit
        self.data_bit = data_bit
        self.latch_bit = latch_bit
        self.continuous = continuous
        self.output = output

    cdef DWORD copy_settings(SerializerSettings self, void *buffer,
                             DWORD size) except 0:
        cdef SBase *pbase
        cdef SValveInit *settings

        if buffer == NULL:
            return sizeof(SBase) + sizeof(SValveInit)
        elif size < sizeof(SBase) + sizeof(SValveInit):
            raise BarstException(BAD_INPUT_PARAMS)

        pbase = <SBase *>buffer
        settings = <SValveInit *>(<char *>buffer + sizeof(SBase))
        if self.output:
            pbase.eType = eFTDIMultiWriteInit
        else:
            pbase.eType = eFTDIMultiReadInit
        pbase.dwSize = sizeof(SValveInit) + sizeof(SBase)
        settings.dwBoards = self.num_boards
        settings.dwClkPerData = self.clock_size
        settings.ucClk = self.clock_bit
        settings.ucData = self.data_bit
        settings.ucLatch = self.latch_bit
        settings.bContinuous = self.continuous
        return sizeof(SBase) + sizeof(SValveInit)

    cdef object get_device_class(SerializerSettings self):
        return FTDISerializerOut if self.output else FTDISerializerIn


cdef class FTDISerializer(FTDIDevice):
    '''
    The base for the serial to parallel type devices. See
    :class:`SerializerSettings` for details on this type of device.
    '''

    cpdef object open_channel(FTDISerializer self):
        '''
        See :meth:`~pybarst.core.server.BarstChannel.open_channel` for details.
        '''
        cdef DWORD read_size, pos = 0
        cdef int res
        cdef SBaseIn *pbase
        cdef char *pbase_out
        cdef SValveInit *multi_init = NULL
        cdef SInitPeriphFT *ft_init = NULL
        FTDIDevice.open_channel(self)

        read_size = (sizeof(SBaseOut) + 2 * sizeof(SBase) + sizeof(SValveInit)
                     + sizeof(SInitPeriphFT))
        pbase = <SBaseIn *>malloc(sizeof(SBaseIn))
        pbase_out = <char *>malloc(max(read_size, MIN_BUFF_OUT))
        if (pbase == NULL or pbase_out == NULL):
            free(pbase)
            free(pbase_out)
            raise BarstException(NO_SYS_RESOURCE)

        pbase.dwSize = sizeof(SBaseIn)
        pbase.eType = eQuery
        pbase.nChan = self.chan
        pbase.nError = 0
        res = self.write_read(self.pipe, sizeof(SBaseIn), pbase,
                              &read_size, pbase_out)
        if not res:
            if (read_size == sizeof(SBaseIn) and
                pbase_out.dwSize == sizeof(SBaseIn) and pbase_out.nError):
                res = pbase_out.nError
        free(pbase)
        if res:
            free(pbase_out)
            raise BarstException(res)

        while pos < read_size:
            if ((<SBaseIn *>(pbase_out + pos)).dwSize <= read_size - pos and
                (<SBaseIn *>(pbase_out + pos)).dwSize >= sizeof(SBaseOut) and
                (<SBase *>(pbase_out + pos)).eType == eResponseEx):
                self.barst_chan_type = str((<SBaseOut *>(pbase_out +
                                                         pos)).szName)
                pos += sizeof(SBaseOut)
            elif ((<SBase *>(pbase_out + pos)).dwSize <= read_size - pos and
                  (<SBase *>(pbase_out + pos)).dwSize == sizeof(SBase) +
                  sizeof(SInitPeriphFT) and
                  (<SBase *>(pbase_out + pos)).eType == eFTDIPeriphInit):
                ft_init = <SInitPeriphFT *>(pbase_out + pos + sizeof(SBase))
                pos += sizeof(SBase) + sizeof(SInitPeriphFT)
            elif ((<SBase *>(pbase_out + pos)).dwSize <= read_size - pos and
                  (<SBase *>(pbase_out + pos)).dwSize == sizeof(SBase) +
                  sizeof(SValveInit) and
                  ((<SBase *>(pbase_out + pos)).eType == eFTDIMultiReadInit or
                   (<SBase *>(pbase_out + pos)).eType == eFTDIMultiWriteInit)):
                multi_init = <SValveInit *>(pbase_out + pos + sizeof(SBase))
                pos += sizeof(SBase) + sizeof(SValveInit)
            elif pos == read_size:
                break
            else:
                res = UNEXPECTED_READ
                break

        if multi_init == NULL or ft_init == NULL:
            res = UNEXPECTED_READ
        if res:
            free(pbase_out)
            raise BarstException(res)

        self.ft_periph = ft_init[0]
        self.serial_settings = multi_init[0]
        self.ft_write_buff_size = self.ft_periph.dwBuff
        self.ft_read_device_size = self.ft_periph.dwMinSizeR
        self.ft_write_device_size = self.ft_periph.dwMinSizeW
        self.ft_device_baud = self.ft_periph.dwMaxBaud
        self.ft_device_mode = self.ft_periph.ucBitMode
        self.ft_device_bitmask = self.ft_periph.ucBitOutput

        self.settings = SerializerSettings(num_boards=multi_init.dwBoards,
        clock_size=multi_init.dwClkPerData, clock_bit=multi_init.ucClk,
        data_bit=multi_init.ucData, latch_bit=multi_init.ucLatch,
        continuous=multi_init.bContinuous,
        output=self.barst_chan_type == 'MltWBrd')
        free(pbase_out)


cdef class FTDISerializerIn(FTDISerializer):
    '''
    Controls a serial to parallel (74HC589) input device connected to the
    :class:`~pybarst.ftdi.FTDIChannel`. See :class:`SerializerSettings` for
    details on this device type.

    For example::

        >>> # create a settings class for the input device which has 2 74HC589
        >>> # connected in a daisy chain fashion.
        >>> settings = SerializerSettings(clock_bit=2, data_bit=3,\
 latch_bit=6, num_boards=2, output=False)
        >>> # now create the channel
        >>> ft = FTDIChannel(channels=[settings], server=server,\
 desc='Birch Board rev1 A')
        >>> dev = ft.open_channel(alloc=True)[0]
        >>> print dev
        <pybarst.ftdi.switch.FTDISerializerIn object at 0x05288D30>
        >>> # open the channel for this client
        >>> dev.open_channel()
        >>> # set the global state of the device to active so we can read it
        >>> dev.set_state(True)
        >>> print dev.read()
        (7.350556310186866, [True, False, True, True, False, True, True, True,\
 True, True, False, True, True, True, True, False])
        >>> print dev.read()
        (18.6506180676803, [True, False, False, True, False, True, False,\
 True, True, False, True, True, True, True, False, False])
    '''

    cpdef object read(FTDISerializerIn self):
        ''' Requests the server to read from the serial to parallel input
        device. This method will wait until the server sends data or an error
        message, thereby tying up this thread.

        If :attr:`SerializerSettings.continuous` is `False`, each call triggers
        the server to read from the device which is then sent to the client. If
        :attr:`SerializerSettings.continuous` is `True`, after the first call
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

        A more gentle way of canceling a read request while not currently
        waiting in :meth:`read`, is to call
        :meth:`~pybarst.core.server.BarstChannel.set_state` to set it inactive,
        or :meth:`cancel_read`, both of which will cause the next read
        operation to return with an error, but will not delete/close the
        channel. For the latter method, once :meth:`read` returned with an
        error, a further call to :meth:`read` will cause the reading to start
        again. See those methods for more details.

        Before this method can be called, :meth:`FTDISerializer.open_channel`
        must be called and the device must be set to active with
        :meth:`~pybarst.core.server.BarstChannel.set_state`.

        :returns:
            2-tuple of (`time`, `data`). `time` is the time that the data was
            read in server time,
            :meth:`pybarst.core.server.BarstServer.clock`.
            `data` is a list of size 8 * :attr:`SerializerSettings.num_boards`,
            where each element corresponds (True / False) to the state of the
            corresponding pin on the 75HC589.

            The order in the list is for the lowest element, 0, to represent
            the closest (farthest)? port in the device.
        '''
        cdef DWORD read_size = (sizeof(SBaseOut) + sizeof(SBase) +
            self.serial_settings.dwBoards * 8 * sizeof(char))
        cdef DWORD read_size_out = read_size, i
        cdef int res = 0
        cdef SBaseOut *pbase
        cdef list vals = [False, ] * (<int>self.serial_settings.dwBoards * 8)
        cdef int r
        cdef char *states
        cdef tuple result

        '''
        This is only important for continuous mode.
        The logic is that running is set to zero when activating/inactivating,
        and when opening the channel. So to do a read, we always have to
        trigger. So if we're inactive/bad state, the server will return an
        error. If there's no error in response to the trigger, then we can
        assume the device is active and WILL send data. Once in this state,
        we're guaranteed that the server will always send data back, and if
        it becomes inactive, all the waiting read pipes will get a
        device closing error response at which point we set running to zero.
        this ensures that whenever we do a read without triggering, there's
        always something that will be sent back to us, and that the pipe will
        not hang waiting forever.
        '''
        if (not self.serial_settings.bContinuous) or not self.running:
            self._send_trigger()
            if self.serial_settings.bContinuous:
                self.running = 1

        pbase = <SBaseOut *>malloc(read_size)
        if pbase == NULL:
            raise BarstException(NO_SYS_RESOURCE)

        with nogil:
            r = ReadFile(self.pipe, pbase, read_size, &read_size_out, NULL)
        if not r:
            res = WIN_ERROR(GetLastError())
            free(pbase)
            raise BarstException(res)

        if ((read_size_out != sizeof(SBaseIn) and
             read_size_out != sizeof(SBaseOut) and
             read_size_out != read_size) or
            ((read_size_out == sizeof(SBaseIn) or
              read_size_out == sizeof(SBaseOut)) and
             (not pbase.sBaseIn.nError) and
             pbase.sBaseIn.eType != eCancelReadRequest) or
            (read_size_out == read_size and
             (not pbase.sBaseIn.nError) and
             pbase.sBaseIn.eType != eCancelReadRequest and
             (pbase.sBaseIn.eType != eResponseExD or
              (<SBase *>(<char *>pbase +
                         sizeof(SBaseOut))).eType != eFTDIMultiReadData))):
            res = UNEXPECTED_READ
        elif pbase.sBaseIn.nError:
            res = pbase.sBaseIn.nError
        elif pbase.sBaseIn.eType == eCancelReadRequest:
            res = DEVICE_CLOSING
        if res:
            self.running = 0
            free(pbase)
            raise BarstException(res)

        states = <char *>pbase + sizeof(SBaseOut) + sizeof(SBase)
        for i in range(self.serial_settings.dwBoards * 8):
            vals[i] = states[i] != 0
        result = (pbase.dDouble, vals)
        free(pbase)
        return result

    cpdef object cancel_read(FTDISerializerIn self, flush=False):
        '''
        See :meth:`~pybarst.core.server.BarstChannel.cancel_read` for details.

        This method is only callable when :attr:`SerializerSettings.continuous`
        is `True`.

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
        if self.running:
            self._cancel_read(&self.pipe, flush, 1)
            if flush:
                self.running = 0


cdef class FTDISerializerOut(FTDISerializer):
    '''
    Controls a serial to parallel (74HC595) output device connected to the
    :class:`~pybarst.ftdi.FTDIChannel`. See :class:`SerializerSettings` for
    details on that device type.

    For example::

        >>> # create a settings class for the output device which has 2 74HC595
        >>> # connected in a daisy chain fashion.
        >>> settings = SerializerSettings(clock_bit=2, data_bit=3,\
 latch_bit=6, num_boards=2, output=True)
        >>> # now create the channel
        >>> ft = FTDIChannel(channels=[settings], server=server,\
 desc='Birch Board rev1 A')
        >>> dev = ft.open_channel(alloc=True)[0]
        >>> print dev
        <pybarst.ftdi.switch.FTDISerializerOut object at 0x0277C830>
        >>> # open the channel for this client
        >>> dev.open_channel()
        >>> # set the global state of the device to active so we can write
        >>> dev.set_state(True)
        >>> # set the states of pins 0, 5, 15, 8 of the 595 to high, and the
        >>> # pins 3, 9 to low. The states of the other pins remain unchanged.
        >>> dev.write(set_high=[0, 5, 15, 8], set_low=[3, 9])
        0.01900274788
        # now set pins 2, 1 to high and pins 5, 14 to low.
        >>> print dev.write(set_high=[2, 1], set_low=[5, 14])
        0.0191407167483
    '''

    cpdef object write(FTDISerializerOut self, object set_high=[],
                       object set_low=[]):
        '''
        Tells the server to update the states of some pins on the 74HC595.
        Indices not listed in `set_high` or `set_low` remain unchanged.

        Before this method can be called,
        :meth:`FTDISerializer.open_channel` must be called
        and the device must be set to active with
        :meth:`~pybarst.core.server.BarstChannel.set_state`.

        :Parameters:

            `set_high`: list
                A list of the pin indices to set to high. Each element in the
                list must be less than
                8 * :attr:`SerializerSettings.num_boards`. The indices start at
                0. Defaults to `[]`.
            `set_low`: list
                A list of the pin indices to set to low. Each element in the
                list must be less than
                8 * :attr:`SerializerSettings.num_boards`. The indices start at
                0. Defaults to `[]`.

        :returns:
            float. The server time,
            :meth:`pybarst.core.server.BarstServer.clock`, when the data was
            written.
        '''
        cdef SBaseIn *pbase
        cdef SBaseIn *pbase_out
        cdef SValveData *states
        cdef unsigned short idx
        cdef DWORD write_size = (2 * sizeof(SBaseIn) + sizeof(SBase) +
            sizeof(SValveData) * (len(set_high) + len(set_low)))
        cdef DWORD read_size = sizeof(SBaseOut)
        cdef SBaseOut base_read
        cdef int res

        if (not set_high) and not set_low:
            raise BarstException(
                msg='You have not provided any data to write.')
        pbase_out = <SBaseIn *>malloc(write_size)
        if pbase_out == NULL:
            raise BarstException(NO_SYS_RESOURCE)
        memset(pbase_out, 0, write_size)

        pbase = pbase_out
        pbase.dwSize = write_size
        pbase.eType = ePassOn
        pbase.nChan = self.chan
        pbase.nError = 0
        pbase += 1
        pbase.dwSize = write_size - sizeof(SBaseIn)
        pbase.eType = eData
        pbase.nChan = -1
        pbase.nError = 0
        pbase += 1
        pbase.dwSize = write_size - 2 * sizeof(SBaseIn)
        pbase.eType = eFTDIMultiWriteData

        states = <SValveData *>(<char *>pbase_out + sizeof(SBase) +
                                2 * sizeof(SBaseIn))
        for idx in set_low:
            states.usIndex = idx
            states += 1
        for idx in set_high:
            states.usIndex = idx
            states.bValue = True
            states += 1

        res = self.write_read(self.pipe, write_size, pbase_out, &read_size,
                              &base_read);
        if not res:
            if ((read_size != sizeof(SBaseOut) and
                 read_size != sizeof(SBaseIn)) or
                ((read_size == sizeof(SBaseIn) or
                  base_read.sBaseIn.eType != eResponseExD) and
                 not base_read.sBaseIn.nError)):
                res = UNEXPECTED_READ
            else:
                res = base_read.sBaseIn.nError
        free(pbase_out)
        if res:
            raise BarstException(res)
        return base_read.dDouble


cdef class PinSettings(FTDISettings):

    '''
    The settings class for reading and writing directly to the FTDI digital
    pins. Each FTDI channel has digital pins which can be set as output or
    input and can then be read from or written to independently.

    When an instance of this class is passed to a
    :class:`~pybarst.ftdi.FTDIChannel` in the `channels` parameter, it will
    create a :class:`FTDIPinIn` or :class:`FTDIPinOut` in
    :attr:`~pybarst.ftdi.FTDIChannel.devices`, depending on the value of the
    :attr:`output` parameter.

    :Parameters:

        `num_bytes`: unsigned short
            The number of bytes that will be read from the USB bus for each
            read request at the :attr:`~pybarst.ftdi.FTDIChannel.chan_baudrate`
            of the channel. When the device is an output device, this
            determines the maximum number of bytes that can be written at once
            with the channel's :attr:`~pybarst.ftdi.FTDIChannel.chan_baudrate`.
        `bitmask`: unsigned char
            A bit-mask of the pins that are active for this device, either as
            input or output depending on the pin type. The high bits will be
            the active pins for this device. E.g. if it's `0b01000100` and this
            is a output device, it means that pins 2, and 6 are output pins and
            are controlled by this device. The other pins will not be under
            the device's control.

            .. note::
                Both a :class:`FTDIPinIn` and :class:`FTDIPinOut` device
                can control the same pin, in which case the pin will function
                as output, but the :class:`FTDIPinIn` will also be able to read
                that pin.
        `init_val`: unsigned char
            If this is an output device, it sets the initial values (high/low)
            of the device's active pins, otherwise it's ignored. For example
            if pins 1, and 5 are under control of the device, and the value is
            0b01001011, then pin 1 will be initialized to high and pin 5 to
            low.
        `continuous`: bool
            Whether, when reading, we should continuously read and send data
            back to the client. This is only used for a input device (`output`
            is `False`). When `True`,  a single call to :meth:`FTDIPin.read`
            after the device is activated will start the server reading the
            device continuously and sending the data back to this client. This
            will result in a potentially higher sampling rate of the device. If
            it's `False`, each call to :meth:`FTDIPin.read` will trigger a new
            read resulting in a possibly slower reading rate.
        `output`: bool
            If the active pins of this device are inputs or outputs. If True, a
            :class:`FTDIPinOut` will be created, otherwise a :class:`FTDIPinIn`
            will be created by the :class:`~pybarst.ftdi.FTDIChannel`.
    '''

    def __init__(PinSettings self, bitmask, num_bytes=1, init_val=0,
                 continuous=False, output=False, **kwargs):
        self.num_bytes = num_bytes
        self.bitmask = bitmask
        self.init_val = init_val
        self.continuous = continuous
        self.output = output

    cdef DWORD copy_settings(PinSettings self, void *buffer,
                             DWORD size) except 0:
        cdef SBase *pbase
        cdef SPinInit *settings

        if buffer == NULL:
            return sizeof(SBase) + sizeof(SPinInit)
        elif size < sizeof(SBase) + sizeof(SPinInit):
            raise BarstException(BAD_INPUT_PARAMS)

        pbase = <SBase *>buffer
        settings = <SPinInit *>(<char *>buffer + sizeof(SBase))

        if self.output:
            pbase.eType = eFTDIPinWriteInit
        else:
            pbase.eType = eFTDIPinReadInit
        pbase.dwSize = sizeof(SPinInit) + sizeof(SBase)
        settings.usBytesUsed = self.num_bytes
        settings.ucActivePins = self.bitmask
        settings.ucInitialVal = self.init_val
        settings.bContinuous = self.continuous
        return sizeof(SBase) + sizeof(SPinInit)

    cdef object get_device_class(PinSettings self):
        return FTDIPinOut if self.output else FTDIPinIn


cdef class FTDIPin(FTDIDevice):
    '''
    The base for the devices that directly control the states of the pins
    of the FTDI channels. See :class:`PinSettings` for details on this type of
    device.
    '''

    cpdef object open_channel(FTDIPin self):
        '''
        See :meth:`~pybarst.core.server.BarstChannel.open_channel` for details.
        '''
        cdef DWORD read_size, pos = 0
        cdef int res
        cdef SBaseIn *pbase
        cdef char *pbase_out
        cdef SPinInit *pin_init = NULL
        cdef SInitPeriphFT *ft_init = NULL
        FTDIDevice.open_channel(self)

        read_size = (sizeof(SBaseOut) + 2 * sizeof(SBase) + sizeof(SPinInit) +
                     sizeof(SInitPeriphFT))
        pbase = <SBaseIn *>malloc(sizeof(SBaseIn))
        pbase_out = <char *>malloc(max(read_size, MIN_BUFF_OUT))
        if (pbase == NULL or pbase_out == NULL):
            free(pbase)
            free(pbase_out)
            raise BarstException(NO_SYS_RESOURCE)

        pbase.dwSize = sizeof(SBaseIn)
        pbase.eType = eQuery
        pbase.nChan = self.chan
        pbase.nError = 0
        res = self.write_read(self.pipe, sizeof(SBaseIn), pbase, &read_size,
                              pbase_out)
        if not res:
            if (read_size == sizeof(SBaseIn) and
                pbase_out.dwSize == sizeof(SBaseIn) and pbase_out.nError):
                res = pbase_out.nError
        free(pbase)
        if res:
            free(pbase_out)
            raise BarstException(res)

        while pos < read_size:
            if ((<SBaseIn *>(pbase_out + pos)).dwSize <= read_size - pos and
                (<SBaseIn *>(pbase_out + pos)).dwSize >= sizeof(SBaseOut) and
                (<SBase *>(pbase_out + pos)).eType == eResponseEx):
                self.barst_chan_type = str((<SBaseOut *>(pbase_out +
                                                         pos)).szName)
                pos += sizeof(SBaseOut)
            elif ((<SBase *>(pbase_out + pos)).dwSize <= read_size - pos and
                  (<SBase *>(pbase_out + pos)).dwSize == sizeof(SBase) +
                  sizeof(SInitPeriphFT) and
                  (<SBase *>(pbase_out + pos)).eType == eFTDIPeriphInit):
                ft_init = <SInitPeriphFT *>(pbase_out + pos + sizeof(SBase))
                pos += sizeof(SBase) + sizeof(SInitPeriphFT)
            elif ((<SBase *>(pbase_out + pos)).dwSize <= read_size - pos and
                  (<SBase *>(pbase_out + pos)).dwSize == sizeof(SBase) +
                  sizeof(SPinInit) and
                  ((<SBase *>(pbase_out + pos)).eType == eFTDIPinReadInit or
                   (<SBase *>(pbase_out + pos)).eType == eFTDIPinWriteInit)):
                pin_init = <SPinInit *>(pbase_out + pos + sizeof(SBase))
                pos += sizeof(SBase) + sizeof(SPinInit)
            elif pos == read_size:
                break
            else:
                res = UNEXPECTED_READ
                break

        if pin_init == NULL or ft_init == NULL:
            res = UNEXPECTED_READ
        if res:
            free(pbase_out)
            raise BarstException(res)

        self.ft_periph = ft_init[0]
        self.pin_settings = pin_init[0]
        self.ft_write_buff_size = self.ft_periph.dwBuff
        self.ft_read_device_size = self.ft_periph.dwMinSizeR
        self.ft_write_device_size = self.ft_periph.dwMinSizeW
        self.ft_device_baud = self.ft_periph.dwMaxBaud
        self.ft_device_mode = self.ft_periph.ucBitMode
        self.ft_device_bitmask = self.ft_periph.ucBitOutput

        self.settings = PinSettings(num_bytes=pin_init.usBytesUsed,
        bitmask=pin_init.ucActivePins, init_val=pin_init.ucInitialVal,
        continuous=pin_init.bContinuous,
        output=self.barst_chan_type == 'PinWBrd')
        free(pbase_out)


cdef class FTDIPinIn(FTDIPin):
    '''
    Reads the states of the digital pins on the FTDI channel controlled by
    :class:`~pybarst.ftdi.FTDIChannel`. See :class:`PinSettings` for
    details on the device type.

    For example::

        >>> # create a settings class to read 2 byte slices from the FTDI \
channel. Only the pins 0 - 3 will be read.
        >>> settings = PinSettings(num_bytes=2, bitmask=0x0F, \
continuous=False, output=False)
        >>> # now create the channel
        >>> ft = FTDIChannel(channels=[settings], server=server, \
desc='Birch Board rev1 A')
        >>> dev = ft.open_channel(alloc=True)[0]
        >>> print dev
        <pybarst.ftdi.switch.FTDIPinIn object at 0x0277C830>
        >>> # open the channel for this client
        dev.open_channel()
        >>> # set the global state of the device to active so we can read it
        >>> dev.set_state(True)
        >>> time, (byte1, byte2) = dev.read()
        >>> print 'time: {}, byte1: 0b{:08b}, byte2: 0b{:08b}'.format(time, \
byte1, byte2)
        time: 1.25523419394, byte1: 0b00001011, byte2: 0b00001011
        >>> time, (byte1, byte2) = dev.read()
        >>> print 'time: {}, byte1: 0b{:08b}, byte2: 0b{:08b}'.format(time, \
byte1, byte2)
        time: 1.25621763275, byte1: 0b00001100, byte2: 0b00001100

    In the last read above, it returned `0b00001100`, which means that pins
    0, and 1 are low and pins 2, and 3 are high. Pins 4 - 7 are not under the
    control of the device, so they always return 0.

    The reason for being able to read more than one byte at once (2 in the
    example above) is to enable reading the states very quickly, i.e. at the
    device's baud rate. E.g. if the baud rate has a clock rate of 1MHz,
    the bytes are read 2 us apart, vs having to trigger repeatedly which might
    result in reading them ms apart.
    '''

    cpdef object read(FTDIPinIn self):
        '''
        Requests the server to read the pins from the FTDI channel. This method
        will wait until the server sends data, or an error
        message, thereby tying up this thread.

        If :attr:`PinSettings.continuous` is `False`, each call triggers
        the server to read from the device which is then sent to the client. If
        :attr:`PinSettings.continuous` is `True`, after the first call
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

        A more gentle way of canceling a read request while not currently
        waiting in :meth:`read`, is to call
        :meth:`~pybarst.core.server.BarstChannel.set_state` to set it inactive,
        or :meth:`cancel_read`, both of which will cause the next read
        operation to return with an error, but will not delete/close the
        channel. For the latter method, once :meth:`read` returned with an
        error, a further call to :meth:`read` will cause the reading to start
        again. See those methods for more details.

        Before this method can be called, :meth:`FTDIPin.open_channel` must be
        called and the device must be set to active with
        :meth:`~pybarst.core.server.BarstChannel.set_state`.

        :returns:
            2-tuple of (`time`, `data`). `time` is the time that the data was
            read in server time, :meth:`pybarst.core.server.BarstServer.clock`.
            `data` is a list of size :attr:`PinSettings.num_bytes`,
            where each element corresponds to a bit field of the states of the
            pins. See class description.
        '''
        cdef DWORD read_size = (sizeof(SBaseOut) + sizeof(SBase) +
            self.pin_settings.usBytesUsed * sizeof(char))
        cdef DWORD read_size_out = read_size
        cdef int res = 0
        cdef SBaseOut *pbase
        cdef list vals = [0, ] * self.pin_settings.usBytesUsed
        cdef int i, r
        cdef unsigned char *states
        cdef tuple result

        if (not self.pin_settings.bContinuous) or not self.running:
            self._send_trigger()
            if self.pin_settings.bContinuous:
                self.running = 1

        pbase = <SBaseOut *>malloc(read_size)
        if pbase == NULL:
            raise BarstException(NO_SYS_RESOURCE)

        with nogil:
            r = ReadFile(self.pipe, pbase, read_size, &read_size_out, NULL)
        if not r:
            res = WIN_ERROR(GetLastError())
            free(pbase)
            raise BarstException(res)
        if ((read_size_out != sizeof(SBaseIn) and
             read_size_out != sizeof(SBaseOut) and
             read_size_out != read_size) or
            ((read_size_out == sizeof(SBaseIn) or
              read_size_out == sizeof(SBaseOut)) and
             (not pbase.sBaseIn.nError) and
             pbase.sBaseIn.eType != eCancelReadRequest) or
            (read_size_out == read_size and
             (not pbase.sBaseIn.nError) and
             pbase.sBaseIn.eType != eCancelReadRequest and
             (pbase.sBaseIn.eType != eResponseExD or
              (<SBase *>(<char *>pbase +
                         sizeof(SBaseOut))).eType != eFTDIPinRDataArray))):
            res = UNEXPECTED_READ
        elif pbase.sBaseIn.nError:
            res = pbase.sBaseIn.nError
        elif pbase.sBaseIn.eType == eCancelReadRequest:
            res = DEVICE_CLOSING
        if res:
            self.running = 0
            free(pbase)
            raise BarstException(res)

        states = <unsigned char *>pbase + sizeof(SBaseOut) + sizeof(SBase)
        for i in range(self.pin_settings.usBytesUsed):
            vals[i] = states[i]
        result = (pbase.dDouble, vals)
        free(pbase)
        return result

    cpdef object cancel_read(FTDIPinIn self, flush=False):
        '''
        See :meth:`FTDISerializerIn.cancel_read` for details.

        This method is only callable when :attr:`PinSettings.continuous` is
        `True`.
        '''
        if self.running:
            self._cancel_read(&self.pipe, flush, 1)
            if flush:
                self.running = 0


cdef class FTDIPinOut(FTDIPin):
    '''
    Sets the states of the pins on the FTDI channel controlled by
    :class:`~pybarst.ftdi.FTDIChannel`. See :class:`PinSettings` for
    details on the device type.

    For example::

        >>> # create a settings class to write 1 byte to the pins of the FTDI \
channel. Only the pins 4 - 7 will be set by this device.
        >>> settings = PinSettings(bitmask=0xF0, init_val=0b01100000, \
output=True)
        >>> # now create the channel
        >>> ft = FTDIChannel(channels=[settings], server=server, \
desc='Birch Board rev1 A')
        >>> dev = ft.open_channel(alloc=True)[0]
        >>> print dev
        <pybarst.ftdi.switch.FTDIPinOut object at 0x0277C830>
        >>> # open the channel for this client
        >>> dev.open_channel()
        >>> # set the global state of the device to active so we can write
        >>> dev.set_state(True)
        # now set pins 4, and 5 to high
        >>> print dev.write(buff_mask=0xFF, buffer=[0b00110000])
        0.0107669098094
    '''

    cpdef object write(FTDIPinOut self, object data=[],
                       object buff_mask=None, object buffer=[]):
        '''
        Tells the server to update the states of some digital pins on the FTDI
        channel.

        Before this method can be called, :meth:`FTDIPin.open_channel` must be
        called and the device must be set to active with
        :meth:`~pybarst.core.server.BarstChannel.set_state`.

        There are two parameters by which data can be written, `data`, or
        alternatively `buff_mask` combined with `buffer`. In each case, you can
        specify which of the pins this device controls should be changed, as
        well as the exact values they should take. The total number of bytes
        written cannot exceed :attr:`PinSettings.num_bytes`.

        :Parameters:
            `data`: list
                `data` is a list of 3-tuples to be written. Each tuple has 3
                elements: (`repeat`, `value`, `mask`).

                `repeat`: int
                    The number of times this data point will be replicated,
                    i.e. if it's 5, the byte will be written 5 times in
                    succession.
                `value`: 8-bit int
                    The bit-mask to set the pins controlled by this device.
                    I.e. 0b01001000 will set pins 3 and 6 to high and the
                    remaining low.
                `mask`: 8-bit int
                    Indicates which pins to leave untouched (0), or update
                    according to `value` (1). For example, if `value` is
                    `0b01001000` and `mask` is `0b01110000`, then pins 0 - 3,
                    and 7 will remain unchanged, while pins 4, and 5 will be
                    set low and pin 6 will be set high.

                `data` defaults to an empty list, `[]`.
            `buffer`: list
                The elements in the list are 8-bit integers which will be
                written in order at the channel's
                :attr:`~pybarst.ftdi.FTDIChannel.chan_baudrate` according to
                the `buff_mask` mask. The `buff_mask` parameter functions
                similarly to the `data` 's, `mask` parameter. Only pins which
                have a high value in `buff_mask` will be changed by the values
                in `buffer`, the others will remain the same.

                Each element in `buffer` is similar to `data` 's, `value`
                parameter. A high value for the corresponding pin will set the
                pin high, and low otherwise.
            `buff_mask`: 8-bit int
                The mask which controls which pin's state will be changed by
                the elements in `buffer`. E.g. a value of 0b01000001 means that
                only pin 0, and pin 6 can be changed by `buffer`, all the other
                pins will remain unchanged no matter their value in `buffer`.

        :returns:
            float. The server time,
            :meth:`pybarst.core.server.BarstServer.clock`, when the data was
            written.

        .. note::
            Pins not controlled by this channel, will never be changed, no
            matter what their values were set here.

        For example::

            >>> # create a output device which controls pins 4 - 7. Initialize
            >>> # them to 0b01100000 (pins 5, 6 high, pins 4, 7 low).
            >>> write = PinSettings(bitmask=0xF0, init_val=0b01100000, \
output=True)
            >>> # create a reading device which will read the same pins
            >>> # controlled by the output device
            >>> read = PinSettings(bitmask=0xF0)
            >>> ft = FTDIChannel(channels=[read, write], server=server, \
desc='Birch Board rev1 A')
            >>> read, write = ft.open_channel(alloc=True)
            >>> print read, write
            <pybarst.ftdi.switch.FTDIPinIn object at 0x0277C830> \
<pybarst.ftdi.switch.FTDIPinOut object at 0x0277C930>
            >>> # open and activate all the channels
            >>> read.open_channel()
            >>> read.set_state(True)
            >>> write.open_channel()
            >>> write.set_state(True)
            >>> # read the current value, which should be the initialized one
            >>> t, (val, ) = read.read()
            >>> print 'read: {}, 0b{:08b}'.format(t, val)
            read: 1.34129473928, 0b01100000
            >>> # set the states of the pins
            >>> print 'wrote: {}, 0b00110000'.format(write.write\
(buff_mask=0xFF, buffer=[0b00110000]))
            wrote: 1.3422974773, 0b00110000
            >>> t, (val, ) = read.read()
            >>> print 'read: {}, 0b{:08b}'.format(t, val)
            read: 1.34305835919, 0b00110000
            >>> print 'wrote: {}, 0b10010000'.format(write.write\
(buff_mask=0xFF, buffer=[0b10010000]))
            wrote: 1.34394612316, 0b10010000
            >>> t, (val, ) = read.read()
            >>> print 'read: {}, 0b{:08b}'.format(t, val)
            read: 1.34467744028, 0b10010000
            >>> # using the mask, only pins 6 and 7 will be changed, the other
            >>> # pins will remain unchanged since they are 0 in buff_mask
            >>> print 'wrote: {}, 0b00110000'.format(write.write\
(buff_mask=0b11000000, buffer=[0b11000000]))
            wrote: 1.34564691796, 0b00110000
            >>> t, (val, ) = read.read()
            >>> print 'read: {}, 0b{:08b}'.format(t, val)
            read: 1.34642093973, 0b11010000
        '''
        cdef DWORD write_size, read_size = sizeof(SBaseOut)
        cdef SBaseOut base_read
        cdef SBaseIn *pbase
        cdef SBaseIn *pbase_out
        cdef int res, count = 0
        cdef unsigned short repeat
        cdef unsigned char val, mask
        cdef SPinWData *pin_data
        cdef unsigned char *pin_buff

        if buff_mask is None:
            write_size = (2 * sizeof(SBaseIn) + sizeof(SBase) +
                          sizeof(SPinWData) * len(data))
        else:
            write_size = (2 * sizeof(SBaseIn) + sizeof(SBase) +
                          sizeof(SPinWData) + sizeof(char) * len(buffer))

        if (not data) and ((buff_mask is None) or not buffer):
            raise BarstException(
                msg='You have not provided any data to write.')
        if data and (buff_mask is not None or buffer):
            raise BarstException(
                msg='You provided data both with data and buffer parameters.')
        pbase_out = <SBaseIn *>malloc(write_size)
        if pbase_out == NULL:
            raise BarstException(NO_SYS_RESOURCE)

        pbase = pbase_out
        pbase.dwSize = write_size
        pbase.eType = ePassOn
        pbase.nChan = self.chan
        pbase.nError = 0
        pbase += 1
        pbase.dwSize = write_size - sizeof(SBaseIn)
        pbase.eType = eData
        pbase.nChan = -1
        pbase.nError = 0
        pbase += 1
        pbase.dwSize = write_size - 2 * sizeof(SBaseIn)

        pin_data = <SPinWData *>(<char *>pbase + sizeof(SBase))
        if buff_mask is None:
            pbase.eType = eFTDIPinWDataArray
            for repeat, val, mask in data:
                pin_data.usRepeat = repeat
                pin_data.ucValue = val
                pin_data.ucPinSelect = mask
                pin_data += 1
                count += repeat
        else:
            pbase.eType = eFTDIPinWDataBufArray
            pin_data.usRepeat = len(buffer)
            pin_data.ucValue = 0
            pin_data.ucPinSelect = buff_mask
            pin_buff = <unsigned char *>(<char *>pin_data + sizeof(SPinWData))
            for val in buffer:
                pin_buff[0] = val
                pin_buff += 1
            count += len(buffer)
        if count > self.settings.num_bytes:
            free(pbase_out)
            raise BarstException(msg='Number of bytes to be written, {} '
            'is larger than num_bytes, {}'.format(count,
                                                  self.settings.num_bytes))

        res = self.write_read(self.pipe, write_size, pbase_out, &read_size,
                              &base_read)
        if not res:
            if ((read_size != sizeof(SBaseOut) and
                 read_size != sizeof(SBaseIn)) or
                ((read_size == sizeof(SBaseIn) or
                  base_read.sBaseIn.eType != eResponseExD) and
                 not base_read.sBaseIn.nError)):
                res = UNEXPECTED_READ
            else:
                res = base_read.sBaseIn.nError
        free(pbase_out)
        if res:
            raise BarstException(res)
        return base_read.dDouble
