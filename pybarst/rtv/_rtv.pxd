
include "../barst_defines.pxi"
include "../inline_funcs.pxi"

from pybarst.core.server cimport BarstChannel, BarstServer


cdef class RTVChannel(BarstChannel):
    cdef SChanInitRTV rtv_init
    cdef int active_state

    cdef public str video_fmt
    '''
    The video format that the RTV driver should use to capture the video. This
    parameter determines the size of the video being captured. In all cases the
    frame rate is approximately 30, provided the system has enough resources
    to process them.

    Possible values are: `full_NTSC` for 640x480, `full_PAL` for 768x576,
    `CIF_NTSC` for 320x240, `CIF_PAL` for 384x288, `QCIF_NTSC` for 160x120,
    and `QCIF_PAL` for 192x144.
    '''
    cdef public str frame_fmt
    '''
    Selects the image format in which the frames are returned by the
    driver. Can be one of `rgb16` (rgb565le in ffmpeg), `gray` (gray in
    ffmpeg), `rgb15` (rgb555le in ffmpeg), `rgb24` (rgb24 in ffmpeg), `rgb32`
    (rgba in ffmpeg), `rgb8`, `raw8x`, or `yuy24:2:2`. `rgb8`, `raw8x`, and
    `yuy24:2:2` are not tested.
    '''
    cdef public unsigned char brightness
    '''
    The brightness of the acquired images.
    '''
    cdef public unsigned char hue
    '''
    The hue of the acquired images.
    '''
    cdef public unsigned char u_saturation
    '''
    The chroma (U) of the acquired images.
    '''
    cdef public unsigned char v_saturation
    '''
    The chroma (V) of the acquired images.
    '''
    cdef public unsigned char luma_contrast
    '''
    The luma of the acquired images.
    '''
    cdef public unsigned char luma_filt
    '''
    Whether the luma notch filter is enabled (black and white, True) or
    disabled (color, False).
    '''
    cdef public int lossless
    '''
    If this is true, then every frame acquired by the server will be sent to
    the client. This ensures that no frame is missed. However, if the client
    doesn't read them quickly enough, a lot of RAM will be used up quickly due
    to the space required to hold them in RAM while it's waiting to be sent to
    the client.

    If it's false, a frame will only be sent if no other frame is waiting to
    be sent. So when we queue a frame, as long as the client has not read this
    frame, no other frame will be queued for sending.
    '''

    cdef public int width
    '''
    The width of the images returned by the server. This is automatically set
    and is read only.
    '''
    cdef public int height
    '''
    The height of the images returned by the server. This is automatically set
    and is read only.
    '''
    cdef public unsigned char bpp
    '''
    The average bytes per pixel for the images returned by the server. This is
    automatically set and is read only.
    '''
    cdef public DWORD buffer_size
    '''
    The size of the buffer, in bytes, required to hold a single image given
    the current settings. This is automatically set by the server and is read
    only.
    '''

    cpdef object read(RTVChannel self)
