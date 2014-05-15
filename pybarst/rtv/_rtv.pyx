
__all__ = ('RTVChannel', )

cdef extern from "stdlib.h" nogil:
    void *malloc(size_t)
    void free(void *)
cdef extern from "string.h":
    void *memcpy(void *, const void *, size_t)
    void *memset (void *, int, size_t)


from cpython.array cimport array, clone
from pybarst.core.exception import BarstException
from pybarst.core import join as barst_join


cdef dict video_fmts = {'full_NTSC': 0, 'full_PAL': 1, 'CIF_NTSC': 2,
                        'CIF_PAL': 3, 'QCIF_NTSC': 4, 'QCIF_PAL': 5}
cdef dict frame_fmts = {'rgb16': 0, 'gray': 1, 'rgb15': 2, 'rgb24': 3,
                        'rgb32': 4, 'rgb8': 5, 'raw8x': 6, 'yuy24:2:2': 7}


cdef class RTVChannel(BarstChannel):
    '''
    A RTV interface channel.

    A RTV channel controls a single RTV port which samples from a single
    camera.

    :Parameters:

        `chan`: int
            The channel number of the port. The RTV ports are assigned
            different channel numbers by the RTV driver. By using the proper
            channel number you can select which RTV channel to smaple from.
        `server`: :class:`~pybarst.core.BarstServer`
            An instance of a server through which this channel is opened.
        `video_fmt`: str
            The size of the videos captured. See :attr:`video_fmt`. Defaults to
            `'full_NTSC'`.
        `frame_fmt`: str
            The format of the images captured. See :attr:`frame_fmt`. Defaults
            to `'rgb24'`.
        `brightness`: unsigned char
            The brightness of the images captured. See :attr:`brightness`.
            Defaults to to `128`.
        `hue`: unsigned char
            The hue of the captured images. See :attr:`hue`. Defaults to `0`.
        `u_saturation`: unsigned char
            The chroma (U) of the images captured. See :attr:`u_saturation`.
            Defaults to `127`.
        `v_saturation`: unsigned char
            The chroma (V) of the images captured. See :attr:`v_saturation`.
            Defaults to `90`.
        `luma_contrast`: unsigned char
            The luma of the images captured. See :attr:`luma_contrast`.
            Defaults to `124`.
        `luma_filt`: unsigned char
            Whether the luma notch filter is enabled (black and white, True)
            or disabled (color, False). See :attr:`luma_filt`. Defaults to `0`.
        `lossless`: int
            Whether all frames should be sent to the client or if frames should
            only be sent when no other frames are waiting to be sent. See
            :attr:`lossless`. Defaults to `True`.

    For example::

        >>> # create a channel controlling port 0, returning rgb24 images of \
size 640x480.
        >>> rtv = RTVChannel(chan=0, server=server, video_fmt='full_NTSC', \
frame_fmt='rgb24', lossless=False)
        >>> rtv.open_channel()
        >>> print rtv
        <pybarst.rtv._rtv.RTVChannel object at 0x05676718>
        >>> # print the image and buffer size information
        >>> print rtv.width, rtv.height, rtv.bpp, rtv.buffer_size, rtv.width \
* rtv.height * rtv.bpp
        640 480 3 921600 921600
        >>> rtv.set_state(True)
        >>> # now read the first image
        >>> t, data = rtv.read()
        >>> # the size of the data should be the same as rtv.buffer_size
        >>> print t, len(data)
        0.0544582486987 921600

    .. note::
        For the RTV channel, the python client currently does not support
        reading from a channel that already has a client reading from it. I.e.
        each channel can only have its state set and read from by a single
        client at once.
    '''

    def __init__(RTVChannel self, int chan, BarstServer server,
                  video_fmt='full_NTSC', frame_fmt='rgb24',
                  unsigned char brightness=128, unsigned char hue=0,
                  unsigned char u_saturation=127,
                  unsigned char v_saturation=90,
                  unsigned char luma_contrast=124, unsigned char luma_filt=0,
                  int lossless=True, **kwargs):
        pass

    def __cinit__(RTVChannel self, int chan, BarstServer server,
                  video_fmt='full_NTSC', frame_fmt='rgb24',
                  unsigned char brightness=128, unsigned char hue=0,
                  unsigned char u_saturation=127,
                  unsigned char v_saturation=90,
                  unsigned char luma_contrast=124, unsigned char luma_filt=0,
                  int lossless=True, **kwargs):
        self.chan = chan
        self.server = server
        self.video_fmt = video_fmt
        self.frame_fmt = frame_fmt
        self.brightness = brightness
        self.hue = hue
        self.u_saturation = u_saturation
        self.v_saturation = v_saturation
        self.luma_contrast = luma_contrast
        self.luma_filt = luma_filt
        self.lossless = lossless
        memset(&self.timer, 0, sizeof(LARGE_INTEGER))
        memset(&self.rtv_init, 0, sizeof(SChanInitRTV))

    cpdef object open_channel(RTVChannel self):
        cdef int man_chan, res
        cdef HANDLE pipe
        cdef DWORD read_size = (sizeof(SBaseOut) + sizeof(SBase) +
                                sizeof(SChanInitRTV))
        cdef void *phead_out
        cdef void *phead_in
        cdef SBaseIn *pbase
        cdef SChanInitRTV chan_init
        self.close_channel_client()

        if self.chan < 0:
            raise BarstException(msg='Invalid RTV channel, {}, provided.'.
                             format(self.channel))
        if self.video_fmt not in video_fmts:
            raise BarstException(msg='Invalid video format {}. Acceptable '
            'formats are {}'.format(self.video_fmt, video_fmts.keys()))
        if self.frame_fmt not in frame_fmts:
            raise BarstException(msg='Invalid frame format {}. Acceptable '
            'formats are {}'.format(self.frame_fmt, frame_fmts.keys()))

        memset(&chan_init, 0, sizeof(SChanInitRTV))
        chan_init.ucBrightness = self.brightness
        chan_init.ucHue = self.hue
        chan_init.ucUSat = self.u_saturation
        chan_init.ucVSat = self.v_saturation
        chan_init.ucLumaContrast = self.luma_contrast
        chan_init.ucLumaFilt = not self.luma_filt
        chan_init.bLossless = self.lossless
        chan_init.ucColorFmt = frame_fmts[self.frame_fmt]
        chan_init.ucVideoFmt = video_fmts[self.video_fmt]

        man_chan = self.server.get_manager('rtv')['chan']
        self.parent_chan = man_chan
        self.pipe_name = bytes(barst_join(self.server.pipe_name,
                                          bytes(man_chan), bytes(self.chan)))
        pipe = self.server.open_pipe('rw')

        phead_out = malloc(2 * sizeof(SBaseIn) + sizeof(SBase) +
                           sizeof(SChanInitRTV))
        phead_in = malloc(read_size)
        if phead_out == NULL or phead_in == NULL:
            CloseHandle(pipe)
            free(phead_out)
            free(phead_in)
            raise BarstException(NO_SYS_RESOURCE)

        pbase = <SBaseIn *>phead_out
        pbase.dwSize = (2 * sizeof(SBaseIn) + sizeof(SBase) +
                        sizeof(SChanInitRTV))
        pbase.eType = ePassOn
        pbase.nChan = man_chan
        pbase.nError = 0
        pbase += 1
        pbase.dwSize = sizeof(SBaseIn) + sizeof(SBase) + sizeof(SChanInitRTV)
        pbase.eType = eSet
        pbase.nChan = self.chan
        pbase.nError = 0
        pbase += 1
        pbase.dwSize = sizeof(SChanInitRTV) + sizeof(SBase)
        pbase.eType = eRTVChanInit
        memcpy(<char *>pbase + sizeof(SBase), &chan_init, sizeof(SChanInitRTV))

        res = self.server.write_read(pipe, 2 * sizeof(SBaseIn) +
        sizeof(SBase) + sizeof(SChanInitRTV), phead_out, &read_size, phead_in)
        if not res:
            if ((read_size == sizeof(SBaseIn) or
                 read_size == sizeof(SBaseOut) or
                 read_size == sizeof(SBaseOut) + sizeof(SBase) +
                 sizeof(SChanInitRTV)) and
                (<SBaseIn *>phead_in).dwSize == read_size and
                (<SBaseIn *>phead_in).nError):
                res = (<SBaseIn *>phead_in).nError
            elif (not (read_size == sizeof(SBaseOut) + sizeof(SBase) +
                       sizeof(SChanInitRTV) and
                       (<SBaseIn *>phead_in).dwSize == read_size and
                       (<SBaseIn *>phead_in).eType == eResponseExL and
                       (<SBase *>(<char *>phead_in +
                                  sizeof(SBaseOut))).eType == eRTVChanInit)):
                res = NO_CHAN

        if not res:
            memcpy(&chan_init, <char *>phead_in + sizeof(SBaseOut) +
                   sizeof(SBase), sizeof(SChanInitRTV))
            self.rtv_init = chan_init
            self.width = self.rtv_init.nWidth
            self.height = self.rtv_init.nHeight
            self.bpp = self.rtv_init.ucBpp
            self.buffer_size = self.rtv_init.dwBuffSize
            self.brightness = self.rtv_init.ucBrightness
            self.hue = self.rtv_init.ucHue
            self.u_saturation = self.rtv_init.ucUSat
            self.v_saturation = self.rtv_init.ucVSat
            self.luma_contrast = self.rtv_init.ucLumaContrast
            self.luma_filt = not self.rtv_init.ucLumaFilt
            self.lossless = self.rtv_init.bLossless != 0
            self.frame_fmt = {v: k for k, v in frame_fmts.iteritems()}[
                self.rtv_init.ucColorFmt]
            self.video_fmt = {v: k for k, v in video_fmts.iteritems()}[
                self.rtv_init.ucVideoFmt]
            self.timer = (<SBaseOut *>phead_in).llLargeInteger
            self.pipe = self.open_pipe('rw')
        free(phead_in)
        free(phead_out)
        CloseHandle(pipe)
        if res:
            raise BarstException(res)

        BarstChannel.open_channel(self)

    cpdef object read(RTVChannel self):
        '''
        Requests the RTV server to start acquiring and sending back the images
        sampled from the camera connected to port controlled by this RTV
        Channel.

        This method will wait until the server sends data or an error
        message, tying up this thread. To cancel the read, from another
        thread you must call :attr:`close_channel_client`, or
        :attr:`close_channel_server`, or just close the the server,
        which will cause this method to return with an error.

        After :meth:`set_state` was called to activate the channel, the server
        will continuously read from the device and send the results back to the
        client. If :attr:`lossless` is `False`, the server will only send the
        most recent image, when no image is waiting to be sent.

        However, if :attr:`lossless` is `True`, then the server will
        continuously send back images to the server, no matter how many are
        still waiting to be sent. This means that if the client doesn't call
        :meth:`read` frequently enough data will accumulate in the pipe. Also,
        the data returned might have been acquired before :meth:`read` was
        called.

        Before this method can be called, :meth:`open_channel` must be called
        and the device must be set to active with :meth:`set_state`.

        If :attr:`PinSettings.lossless` is `True`, to stop the server
        from reading and sending data back to the client, set :meth:`set_state`
        to inactive for this device.

        :returns:
            2-tuple of (`time`, `data`). `time` is the time that the data was
            read in channel time, :meth:`~pybarst.core.BarstChannel.clock`.
            `data` is a python `array.array` of unsigned chars containing the
            raw image data as determined by the :attr:`video_fmt` and
            :attr:`frame_fmt` settings.

        For example, with :attr:`lossless` `False`::

            >>> # do a read
            >>> t, data = rtv.read()
            >>> print t, len(data)
            0.0704396276054 921600
            >>> # now stop reading for two seconds
            >>> time.sleep(2)
            >>> # resume reading. The first few frames will be old data.
            >>> print rtv.read()[0]
            0.103799921367
            >>> print rtv.read()[0]
            0.170531751867
            >>> print rtv.read()[0]
            2.53962433471

        .. note::
            When reading with :attr:`lossless` `False`, if waiting between
            between reads, the first 1 or 2 images read when resuming reading
            might be older images from when the reading initially stopped.
        '''
        cdef int res = 0, r
        cdef DWORD read_size = (self.rtv_init.dwBuffSize + sizeof(SBaseOut) +
                                sizeof(SBase))
        cdef SBaseOut *pbase = <SBaseOut *>malloc(read_size)
        cdef double time
        cdef array arr = None
        if pbase == NULL:
            raise BarstException(NO_SYS_RESOURCE)

        with nogil:
            r = ReadFile(self.pipe, pbase, read_size, &read_size, NULL)
        if not r:
            res = WIN_ERROR(GetLastError())
            free(pbase)
            raise BarstException(res)

        if ((read_size != sizeof(SBaseIn) and read_size != sizeof(SBaseOut) and
             read_size != self.rtv_init.dwBuffSize + sizeof(SBaseOut) +
             sizeof(SBase)) or ((read_size == sizeof(SBaseIn) or
              read_size == sizeof(SBaseOut)) and
             not pbase.sBaseIn.nError) or
            (read_size == self.rtv_init.dwBuffSize + sizeof(SBaseOut) +
             sizeof(SBase) and not pbase.sBaseIn.nError and
             (pbase.sBaseIn.eType != eResponseExD or
              (<SBase *>(<char *>pbase + sizeof(SBaseOut))).eType !=
              eRTVImageBuf))):
            res = UNEXPECTED_READ
        elif pbase.sBaseIn.nError:
            res = pbase.sBaseIn.nError
        if res:
            free(pbase)
            raise BarstException(res)

        time = pbase.dDouble
        arr = clone(array('B'), self.rtv_init.dwBuffSize * sizeof(char), False)
        memcpy(arr.data.as_chars, <char *>pbase + sizeof(SBaseOut) +
               sizeof(SBase), self.rtv_init.dwBuffSize * sizeof(char))

        free(pbase)
        return time, arr

    cpdef object set_state(RTVChannel self, int state):
        '''
        See :meth:`~pybarst.core.BarstChannel.set_state` for details.

        .. note::
            When the state is set to active, the RTV server will immediately
            start sending images back to the client, even before the first call
            to :meth:`read`. So a user should start calling :meth:`read` as
            soon as this method was called.
        '''
        return self._set_state(state, self.pipe, self.chan)
