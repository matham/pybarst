'''
FTDI ADC device
================

The FTDI ADC module controls an CPL ADC device connected to the FTDI
channel's digital pins. You can connect multiple ADC devices in parallel to
different pins, and they can be configured to be connected to a variable
number of channel pins.
'''


__all__ = ('ADCSettings', 'ADCData', 'FTDIADC')


cdef extern from "stdlib.h" nogil:
    void *malloc(size_t)
    void free(void *)
cdef extern from "string.h":
    void *memcpy(void *, const void *, size_t)
    void *memset (void *, int, size_t)


from cpython.array cimport array, clone
from cython cimport view as cyview
from pybarst.core.exception import BarstException


cdef dict adc_range = {'0, 5': 3, '0, 10': 1, '-5, 5': 2, '-10, 10': 0}
cdef dict adc_range_inv = {v: k for k, v in adc_range.iteritems()}


cdef class ADCSettings(FTDISettings):
    '''
    The settings for a CPL ADC device connected to the the FTDI channel.

    When an instance of this class is passed to a
    :class:`~pybasrt.ftdi.FTDIChannel` in the `channels` parameter, it will
    create a :class:`FTDIADC` in :attr:`~pybarst.ftdi.FTDIChannel.devices`.

    This settings class indicates and controls how the device is connected
    to the FTDI bus as well as the settings used to configure the ADC device.

    :Parameters:

        `hw_buff_size`: float
            The buffer size of the USB device. See :attr:`hw_buff_size`.
            Defaults to 25.
        `transfer_size`: int
            The number of data points for the server to accumulate before
            sending it to the client. See :attr:`transfer_size`. Effectively
            this controls how often data is sent to the client. E.g. if the
            sampling rate is 1000Hz and this value is 500, then 500 data point
            will be sent at once, or data will be sent to the client twice per
            second. Defaults to `100`.
        `clock_bit`: int
            The pin connected to the ADC clock pin. Ssee :attr:`clock_bit`.
        `lowest_bit`: int
            The lowest data pin connected to the ADC device. See
            :attr:`lowest_bit`.
        `num_bits`: int
            The number of data pins connected to the ADC device. See
            :attr:`num_bits`.
        `chop`: bool
            Whether chopping (hardware sampling smoothing) is enabled. See
            :attr:`chop`. Defaults to `True`.
        `chan1`: bool
            Whether channel 1 of the ADC device is enabled and sampled. Each
            ADC device has two channels, either or both of which can be
            enabled. See :attr:`chan1`. Defaults to `False`.
        `chan2`: bool
            Whether channel 2 of the ADC device is enabled and sampled. Each
            ADC device has two channels, either or both of which can be
            enabled. See :attr:`chan2`. Defaults to `False`.
        `input_range`: str
            The voltage input range supported by the ADC device. See
            :attr:`input_range`. Defaults to `'-10, 10'`.
        `data_width`: int
            The bit depth of the ADC data points; either 16 or 24. See
            :attr:`data_width`. Defaults to `16`.
        `reverse`: bool
            Whether the data pins of the ADC device are connected in the
            reverse order compared to the FTDI USB bus. See :attr:`reverse`.
            Defaults to `False`.
        `sampling_rate`: float
            The sampling rate that should be used by the ADC device for
            each channel. See :attr:`sampling_rate`. If `None`, it'll use
            `rate_filter` filter instead. Defaults to `None`. Note, the device
            will try to find to closest sampling rate possible, which
            is not likely to be equal to `sampling_rate`.
        `rate_filter`: int
            The sampling rate code used by the device to set the sampling rate.
            See :attr:`rate_filter`. If `None`, it'll use `sampling_rate`
            filter instead. Defaults to `None`. This controls the actual
            sampling rate, and the `sampling_rate` parameter, if supplied, gets
            first converted to `rate_filter` internally.
        `crystal_freq`: float
            The frequency of the crystal on the ADC device. Defaults to
            6000000.

    .. note::
        The settings can not be changed after they have been passed to the
        constructor. I.e. setting the properties directly might result in
        incorrect states.
    '''

    def __init__(ADCSettings self, clock_bit, lowest_bit, num_bits,
                 sampling_rate=None, chan1=False, chan2=False, hw_buff_size=25,
                 transfer_size=100, chop=True, input_range='-10, 10',
                 data_width=16, reverse=False, rate_filter=None,
                 double crystal_freq=6000000., **kwargs):
        cdef unsigned char mutltiplier, constant, bottom, fw, twin = 1

        self.hw_buff_size = hw_buff_size
        self.transfer_size = transfer_size
        self.clock_bit = clock_bit
        self.lowest_bit = lowest_bit
        self.num_bits = num_bits
        self.chop = chop
        self.chan1 = chan1
        self.chan2 = chan2
        if not self.chan1 and not self.chan2:
            raise BarstException(msg='At least one channel must be active')
        if input_range in adc_range:
            self.input_range = adc_range[input_range]
        else:
            raise BarstException(msg='The ADC input range, {}, is invalid. '
            'Acceptable values are {}'.format(input_range, adc_range.keys()))
        self.input_range_str = input_range
        self.data_width = data_width
        if self.data_width != 16 and self.data_width != 24:
            raise BarstException(msg='data_width, {}, is invalid. Possible '
            'values are 16, or 24'.format(data_width))
        self.reverse = reverse

        if self.chop:
            mutltiplier = 128
            bottom = 2
            if self.chan1 and self.chan2:
                constant = 249
                twin = 2
            else:
                constant = 248
        else:
            mutltiplier = 64
            bottom = 3
            if self.chan1 and self.chan2:
                constant = 207
                twin = 2
            else:
                constant = 206
        self.max_rate = crystal_freq / <double>(twin * (bottom * mutltiplier +
                                                        constant))
        self.min_rate = crystal_freq / <double>(twin * (127 * mutltiplier +
                                                        constant))

        if sampling_rate is not None:
            self.sampling_rate = sampling_rate
            self.rate_filter = round(crystal_freq / <double>(twin *
                sampling_rate * mutltiplier) - constant / <double>mutltiplier)
        elif rate_filter is not None:
            self.rate_filter = rate_filter
            self.sampling_rate = crystal_freq / <double>(twin *
                (self.rate_filter * mutltiplier + constant))
        else:
            raise BarstException(msg='Either rate_filter or sampling_rate '
                                 'must be specified')

        if (self.sampling_rate < self.min_rate or
            self.sampling_rate > self.max_rate):
            raise BarstException(msg='Sampling rate, {:f} Hz, is out of range '
            '[{:f} Hz, {:f} Hz] for current configuration.'.format(
            self.sampling_rate, self.min_rate, self.max_rate))

    cdef DWORD copy_settings(ADCSettings self, void *buffer,
                             DWORD size) except 0:
        cdef SBase *pbase
        cdef SADCInit *settings

        if buffer == NULL:
            return sizeof(SBase) + sizeof(SADCInit)
        elif size < sizeof(SBase) + sizeof(SADCInit):
            raise BarstException(BAD_INPUT_PARAMS)

        pbase = <SBase *>buffer
        settings = <SADCInit *>(<char *>buffer + sizeof(SBase))
        pbase.eType = eFTDIADCInit
        pbase.dwSize = sizeof(SADCInit) + sizeof(SBase)
        settings.fUSBBuffToUse = self.hw_buff_size
        settings.dwDataPerTrans = self.transfer_size
        settings.ucClk = self.clock_bit
        settings.ucLowestDataBit = self.lowest_bit
        settings.ucDataBits = self.num_bits - 2
        settings.bChop = self.chop
        settings.bChan1 = self.chan1
        settings.bChan2 = self.chan2
        settings.ucInputRange = self.input_range
        settings.ucBitsPerData = self.data_width
        settings.bStatusReg = True
        settings.bReverseBytes = self.reverse
        settings.bConfigureADC = True
        settings.ucRateFilter = self.rate_filter
        return sizeof(SBase) + sizeof(SADCInit)

    cdef object get_device_class(ADCSettings self):
        return FTDIADC


cdef class ADCData(object):
    '''
    A data object returned by the ADC client after a read from the server. Each
    instance holds the most recently read data from the server for both channel
    1 and / or 2. The class returns both the raw and actual voltage data points
    as well other information about the data. See the class attributes.

    This class is not instantiated by the user, but is returned by
    :meth:`FTDIADC.read`.
    '''

    cdef init(ADCData self, SADCData *header, double multiplier,
              double subtractend, double divisor):
        self.chan1_raw = None
        self.chan2_raw = None
        self.chan1_data = None
        self.chan2_data = None
        cdef DWORD i
        cdef DWORD *data = <DWORD *>(<char *>header + sizeof(SADCData))
        cdef cyview.array arr

        if header.dwCount1:
            arr = cyview.array(
                shape=(header.dwCount1, ), itemsize=sizeof(DWORD), format="L",
                mode="c", allocate_buffer=True)
            memcpy(arr.data, data, header.dwCount1 * sizeof(DWORD))
            self.chan1_raw = array('L', arr)
            arr = cyview.array(
                shape=(header.dwCount1, ), itemsize=sizeof(double), format="d",
                mode="c", allocate_buffer=True)
            for i in range(header.dwCount1):
                (<double *>arr.data)[i] = (data[i] / divisor) *\
                multiplier - subtractend
            self.chan1_data = array('d', arr)

        data += header.dwChan2Start
        if header.dwCount2:
            arr = cyview.array(
                shape=(header.dwCount2, ), itemsize=sizeof(DWORD), format="L",
                mode="c", allocate_buffer=True)
            memcpy(arr.data, data, header.dwCount2 * sizeof(DWORD))
            self.chan2_raw = array('L', arr)
            arr = cyview.array(
                shape=(header.dwCount2, ), itemsize=sizeof(double), format="d",
                mode="c", allocate_buffer=True)
            for i in range(header.dwCount2):
                (<double *>arr.data)[i] = (data[i] / divisor) *\
                multiplier - subtractend
            self.chan2_data = array('d', arr)

        self.chan1_ts_idx = header.dwChan1S
        self.chan2_ts_idx = header.dwChan2S
        self.count = header.dwPos
        self.rate = header.fDataRate
        self.fullness = header.fSpaceFull
        self.ts = header.dStartTime
        self.chan1_oor = header.ucError & 0x01 != 0
        self.chan2_oor = header.ucError & 0x10 != 0
        self.noref = header.ucError & 0x44 != 0
        self.bad_count = header.sDataBase.nError & 0xFFFF
        self.overflow_count = (header.sDataBase.nError >> 16) & 0xFFFF


cdef class FTDIADC(FTDIDevice):
    '''
    Controls an ADC device connected to the :class:`~pybarst.ftdi.FTDIChannel`.
    See :class:`ADCSettings` for details on this device type.

    For example::

        >>> # create a adc device with clock connected to pin 7, and 4 data
        >>> # lines at pins 3 - 6. The sampling rate is 1kHz. Both channels are
        >>> # active. Send back data to client at every 100 data points (10Hz)
        >>> settings = ADCSettings(clock_bit=7, lowest_bit=3, num_bits=4, \
sampling_rate=1000, chan1=True, chan2=True, hw_buff_size=25,transfer_size=100)
        >>> # create and open the channel
        >>> ft = FTDIChannel(channels=[settings], server=server, \
desc='Birch Board rev1 B')
        >>> adc = ft.open_channel(alloc=True)[0]
        >>> print adc
        <pybarst.ftdi.adc.FTDIADC object at 0x027984C8>
        >>> adc.open_channel()
        >>> adc.set_state(True)
        >>> data = adc.read()
        >>> print data
        <pybarst.ftdi.adc.ADCData object at 0x0278C6B8>
        >>> print data.chan1_data
        array('d', [-0.00152587890625, -0.00152587890625, -0.00152587890625, \
-0.00152587890625, -0.00152587890625, ..., -0.00152587890625])
        >>> print data.chan2_data
        array('d', [-0.00091552734375, -0.00091552734375, -0.00091552734375, \
-0.00091552734375, -0.00091552734375, ..., -0.00091552734375])
        >>> # the channel time stamp of the the data point at data.chan1_ts_idx
        >>> print data.ts
        7.34521248027
        >>> # the rate should be approximately at 1kHz +/ a few hundred Hz.
        >>> print data.rate
        1058.51062012
    '''

    cpdef object open_channel(FTDIADC self):
        '''
        See :meth:`~pybarst.core.server.BarstChannel.open_channel` for details.
        '''
        cdef int res
        cdef DWORD read_size, pos = 0
        cdef SBaseIn *pbase
        cdef char *pbase_out
        cdef SADCInit *adc_init = NULL
        cdef SInitPeriphFT *ft_init = NULL
        cdef unsigned char mutltiplier, constant, bottom, twin = 1
        FTDIDevice.open_channel(self)

        read_size = (sizeof(SBaseOut) + 2 * sizeof(SBase) +
                     sizeof(SADCInit) + sizeof(SInitPeriphFT))
        pbase = <SBaseIn *>malloc(sizeof(SBaseIn))
        pbase_out = <char *>malloc(max(read_size, MIN_BUFF_OUT))
        if pbase == NULL or pbase_out == NULL:
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
                sizeof(SADCInit) and
                (<SBase *>(pbase_out + pos)).eType == eFTDIADCInit):
                adc_init = <SADCInit *>(pbase_out + pos + sizeof(SBase))
                pos += sizeof(SBase) + sizeof(SADCInit)
            elif pos == read_size:
                break
            else:
                res = UNEXPECTED_READ
                break
        if adc_init == NULL or ft_init == NULL:
            res = UNEXPECTED_READ
        if res:
            free(pbase_out)
            raise BarstException(res)

        self.ft_periph = ft_init[0]
        self.adc_settings = adc_init[0]
        self.ft_write_buff_size = self.ft_periph.dwBuff
        self.ft_read_device_size = self.ft_periph.dwMinSizeR
        self.ft_write_device_size = self.ft_periph.dwMinSizeW
        self.ft_device_baud = self.ft_periph.dwMaxBaud
        self.ft_device_mode = self.ft_periph.ucBitMode
        self.ft_device_bitmask = self.ft_periph.ucBitOutput

        if self.adc_settings.ucInputRange == 0:
            self.multiplier = 20.
            self.subtractend = 10.
        elif self.adc_settings.ucInputRange == 1:
            self.multiplier = 10.
            self.subtractend = 0.
        elif self.adc_settings.ucInputRange == 2:
            self.multiplier = 10.
            self.subtractend = 5.
        else:
            self.multiplier = 5.
            self.subtractend = 0.
        self.divisor = 2 ** self.adc_settings.ucBitsPerData

        self.settings = ADCSettings(
        hw_buff_size=self.adc_settings.fUSBBuffToUse,
        transfer_size=self.adc_settings.dwDataPerTrans,
        clock_bit=self.adc_settings.ucClk,
        lowest_bit=self.adc_settings.ucLowestDataBit,
        num_bits=self.adc_settings.ucDataBits + 2,
        chop=self.adc_settings.bChop,
        chan1=self.adc_settings.bChan1,
        chan2=self.adc_settings.bChan2,
        input_range=adc_range_inv[self.adc_settings.ucInputRange],
        data_width=self.adc_settings.ucBitsPerData,
        reverse=self.adc_settings.bReverseBytes,
        rate_filter=self.adc_settings.ucRateFilter)

        free(pbase_out)

    def get_conversion_factors(FTDIADC self):
        '''Returns the factors used to scale the raw data into floating points.

        Returns a 3-tuple of bit-depth, multiplier, and subtractend.

        The formula is float = (raw / 2 ** bit_depth) * multiplier - subtractend.
        '''
        return self.adc_settings.ucBitsPerData, self.multiplier, self.subtractend

    cpdef object read(FTDIADC self):
        '''
        Requests the server to read and send the next available data from the
        ADC. This method will wait until the server sends data, or an error
        message, thereby tying up this thread. Depending on how often data is
        sent, this might take a while under error conditions.

        After the first call to :meth:`read` the server will continuously read
        from the device and send the results back to the client. This means
        that if the client doesn't call :meth:`read` frequently enough data
        will accumulate in the pipe.

        To cancel a read request while the read is still waiting, from another
        thread you must call
        :meth:`~pybarst.core.server.BarstChannel.close_channel_client`, or
        :meth:`~pybarst.core.server.BarstChannel.close_channel_server`, or just
        delete the server, which will cause this method to return with an
        error.

        A more gentle way of canceling a read request while not currently
        waiting in :meth:`read`, is to call
        :meth:`~pybarst.core.server.BarstChannel.set_state` to set it inactive,
        which will cause the next read operation to return with an error, but
        will not delete/close the channel. See that methods for more details.

        :returns:
            Each call to this method returns the next data read from the active
            channels in a :class:`ADCData` instance. As long as data points
            are not missing, the data returned from subsequent reads can be
            concatenated to get a continuous data stream at the device's
            sampling rate.

        .. warning::
            Before this method can be called, :meth:`open_channel` must be
            called and then device must be set to active using
            :meth:`~pybarst.core.server.BarstChannel.set_state`.

            :meth:`read` may/should be called immediately after
            :meth:`~pybarst.core.server.BarstChannel.set_state` is
            called activating this device. When the state is activated,
            the device immediately starts sampling the ADC port, however, data
            only begins to be sent back to the client after :meth:`read` is
            called the first time. So any data sampled before :meth:`read` is
            called for the first time is lost. Once :meth:`read` is called, if
            :meth:`read` is not called frequently enough, it just accumulates
            in the pipe, but does not get discarded.

        .. note::
            The error attributes of :class:`ADCData`
            (:attr:`ADCData.chan1_oor`, :attr:`ADCData.chan2_oor`,
            :attr:`ADCData.noref`, :attr:`ADCData.bad_count`,
            :attr:`ADCData.overflow_count`) should be checked for every
            returned instance to detect errors with the ADC device.

        .. note::
            Although multiple clients can simultaneously connect to the same
            FTDI channel, and FTDI peripheral devices; e.g. 2 clients instances
            can open the same ADC channel at the same time. Only one client is
            allowed to read at any time. That is after activation, once a
            client has called :meth:`read`, no other client is allowed to
            call :meth:`read` until the initial client set the state to
            inactive with :meth:`~pybarst.core.server.BarstChannel.set_state`.
            After that, any client can activate the state and call
            :meth:`read` again.
            ::
        '''
        cdef DWORD bytes_size, read_size
        cdef DWORD *data
        cdef int res = 0, i, r
        cdef int chan1 = self.adc_settings.bChan1
        cdef int chan2 = self.adc_settings.bChan2
        cdef SADCData *header
        cdef ADCData val
        cdef list out1, out2

        if not self.running:
            self._send_trigger()
            self.running = 1

        if chan1 and chan2:
            bytes_size = (sizeof(SADCData) +
                          self.adc_settings.dwDataPerTrans * sizeof(DWORD) * 2)
        else:
            bytes_size = (sizeof(SADCData) +
                          self.adc_settings.dwDataPerTrans * sizeof(DWORD))
        header = <SADCData *>malloc(bytes_size)
        if header == NULL:
            raise BarstException(NO_SYS_RESOURCE)

        read_size = bytes_size
        with nogil:
            r = ReadFile(self.pipe, header, bytes_size, &read_size, NULL)
        if not r:
            res = WIN_ERROR(GetLastError())
            free(header)
            raise BarstException(res)

        if ((read_size != sizeof(SBaseIn) and read_size != bytes_size) or
            (read_size == sizeof(SBaseIn) and not header.sDataBase.nError) or
            (read_size == bytes_size and header.sBase.eType != eADCData)):
            res = UNEXPECTED_READ
        elif read_size == sizeof(SBaseIn):
            res = header.sDataBase.nError
        elif bytes_size != read_size:
            # make sure buffer size match, value is always there, even if one
            # chan is inactive
            res = SIZE_MISSMATCH
        if res:
            self.running = 0
            free(header)
            raise BarstException(res)
        if (header.dwCount1 and not chan1) or (header.dwCount2 and not chan2):
            free(header)
            raise BarstException(BAD_INPUT_PARAMS, msg='Recieved data for a '
            'inactive channel: Channel 1 and 2 states are {}, {}. Count '
            'received for channel 1 and channel 2 are {}, {}'.format(chan1,
            chan2, header.dwCount1, header.dwCount2))

        val = ADCData()
        val.init(header, self.multiplier, self.subtractend, self.divisor)
        free(header)
        return val
