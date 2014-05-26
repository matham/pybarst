

__all__ = ('FTDISettings', 'FTDIChannel', 'FTDIDevice')

cdef extern from "stdlib.h" nogil:
    void *malloc(size_t)
    void free(void *)
cdef extern from "string.h":
    void *memcpy(void *, const void *, size_t)
    void *memset (void *, int, size_t)


from pybarst.core.exception import BarstException
from pybarst.core import join as barst_join


cdef dict dictify_ft_info(FT_DEVICE_LIST_INFO_NODE_OS *ft_info):
    return {'is_open': ft_info.Flags & 1, 'is_high_speed': ft_info.Flags & 2,
            'is_full_speed': not (ft_info.Flags & 2), 'dev_type': ft_info.Type,
            'dev_id': ft_info.ID, 'dev_loc': ft_info.LocId,
            'dev_serial': str(ft_info.SerialNumber),
            'dev_description': str(ft_info.Description)}


cdef class FTDISettings(object):
    '''
    Base class for the settings describing FTDI devices connected to a FTDI
    channel. This class is never created directly.

    A FTDI channel can control multiple devices connected to its digital pins
    at the same time. Therefore, when a FTDI channel is created, a list of
    settings describing each connected device must be supplied to the
    constructor and is then used by the channel to create the channel and
    sub-devices for each device connected to the channel. This is the base
    class for these settings. :class:`~pybarst.ftdi.adc.ADCSettings` is an
    example of a settings class.

    See :class:`FTDIChannel` for more details.
    '''

    cdef DWORD copy_settings(FTDISettings self, void *buffer,
                             DWORD size) except 0:
        return 0

    cdef object get_device_class(FTDISettings self):
        return None


cdef class FTDIChannel(BarstChannel):
    '''
    An FTDI channel.

    An FTDI channel describes a single FTDI device, e.g. a FT2232H or a
    FT232R. Each FTDI device has one or more peripheral devices connected to
    it. For example, an ADC board could be interfaced with a PC through the
    digital port on a FT232R. Similarly, you can read/write directly to the
    pins of the FTDI channel.

    :Parameters:
        `channels`: list
            A list of instances of :class:`FTDISettings` derived classes
            each describing a peripheral device connected to the FTDI port.
            For each :class:`FTDISettings` instance, a corresponding
            :class:`FTDIDevice` derived class instance (in the same order as
            in this list)
            will be created and stored in :attr:`devices`. See :attr:`devices`.
            Similarly, for each created :class:`FTDIDevice` instance,
            :attr:`FTDIDevice.settings` stores the settings with which the
            device was created.

            .. note::
                If this channel already exists on the server, e.g. if a
                previous client created the channel and now a second client
                created this channel instance and wants to connect to it.
                Then this list will be ignored and instead the list of devices
                will be created from the existing channel on the server,
                ensuring the devices created are consistent across clients that
                open them.
        `server`: :class:`~pybarst.core.server.BarstServer`
            An instance of a server through which this channel is opened.
        `serial`: bytes
            The serial number used to identify the device to open.
            Either the `serial` number or the device description, `desc`, must
            be provided. See :attr:`dev_serial` for more details.
        `desc`: bytes
            The descriptions used to identify the device to open.
            Either the `serial` number or the device description, `desc`, must
            be provided. See :attr:`dev_description` for more details.
    '''

    def __init__(FTDIChannel self, list channels, BarstServer server,
                  bytes serial=None, bytes desc=None, **kwargs):
        pass

    def __cinit__(FTDIChannel self, list channels, BarstServer server,
                  bytes serial=None, bytes desc=None, **kwargs):
        self.server = server
        self.serial = serial
        self.desc = desc
        self.channels = channels[:]
        self.devices = []
        self.is_open = 0
        self.is_high_speed = 0
        self.is_full_speed = 0
        self.dev_type = 0
        self.dev_id = 0
        self.dev_loc = 0
        self.dev_serial = ''
        self.dev_description = ''
        self.chan_min_buff_in = 0
        self.chan_min_buff_out = 0
        self.chan_baudrate = 0

    cpdef object open_channel(FTDIChannel self, alloc=False):
        '''
        See :meth:`~pybarst.core.server.BarstChannel.open_channel`.

        Every time this method is called, :attr:`devices` is updated with a new
        list of devices. Therefore, any references to the devices that were on
        the list previously must be updated to the new devices. If the channel
        already exists on the server, the devices list will be created from
        the devices which initially created the channel, other :attr:`devices`
        will be used to create the channel.

        :Parameters:

            `alloc`: bool
                Whether we should create the channel on the server if the
                channel doesn't already exist. If False and the channel doesn't
                exist yet on the server, an error will be raised. Otherwise,
                the channel will be created automatically. Defaults to False.

        For example::

            >>> # create a channel with a read and write pin device
            >>> read = PinSettings(num_bytes=1, bitmask=0xFF,\
 continuous=False, output=False)
            >>> write = PinSettings(num_bytes=1, bitmask=0x0F,\
 continuous=False, init_val=0xFF, output=True)
            >>> ft = FTDIChannel(channels=[read, write], server=server,\
 desc='Birch Board rev1 A')
            >>> # create the channel on the server
            >>> ft.open_channel(alloc=True)
            [<pybarst.ftdi.switch.FTDIPinIn object at 0x05328EB0>,\
 <pybarst.ftdi.switch.FTDIPinOut object at 0x05328F30>]
            >>> # close the connection between the client
            >>> ft.close_channel_client()
            >>> # the channel is still open, but no client is connected
            >>> ft.connected
            0
            >>> # now connect the client again to the exiting channel
            >>> ft.open_channel()
            [<pybarst.ftdi.switch.FTDIPinIn object at 0x054BF230>,\
 <pybarst.ftdi.switch.FTDIPinOut object at 0x054BF2B0>]
            >>> # now delete the channel from the server
            >>> ft.close_channel_server()
            >>> # re-create the channel on the server
            >>> ft.open_channel(alloc=True)
            [<pybarst.ftdi.switch.FTDIPinIn object at 0x052F8EB0>,\
 <pybarst.ftdi.switch.FTDIPinOut object at 0x052F8F30>]

        In the above example, we created a channel and then
        closed / opened / deleted / and re-created the channel from a single
        instance. Similarly, you can create multiple :class:`FTDIChannel`
        instances corresponding to the same physical device and do similar
        operations on each instance independently. However, calling
        :math:`~pybarst.core.server.BarstChannel.close_channel_server` will
        delete the channel on the server, and all the clients connected will
        raise exceptions when trying to communicate with it. To resolve it,
        for each instance you'll have to call :meth:`open_channel` to recover
        the connection to the channel.
        '''
        cdef int man_chan, res
        cdef HANDLE pipe
        cdef DWORD read_size, bytes_count = 0, settings_size = 0
        cdef void *phead_out
        cdef void *phead_in
        cdef void *settings_buff
        cdef SBaseIn *pbase
        cdef SBaseOut *pbase_out
        cdef FT_DEVICE_LIST_INFO_NODE_OS *ft_dev_info = NULL
        cdef int i = 0, chan = -1    # i is position in list
        cdef int found = 0
        cdef SChanInitFTDI *init_struct
        cdef object chan_class
        cdef list dev_list = []
        cdef FTDISettings device
        cdef str msg = ''
        self.close_channel_client()

        if not self.desc and not self.serial:
            raise BarstException(msg='FTDI channel serial and description not'
                                 ' provided, at least one must be provided')

        man_chan = self.server.get_manager('ftdi')['chan']
        self.parent_chan = man_chan
        pipe = self.server.open_pipe('rw')

        # we need to query to get a list of devices connected
        for device in self.channels:
            bytes_count += device.copy_settings(NULL, 0)
        # max 25 ftdi devices
        read_size = 25 * (sizeof(SBaseOut) + 2 * sizeof(SBase) +
                       sizeof(FT_DEVICE_LIST_INFO_NODE_OS) +
                       sizeof(SChanInitFTDI))
        phead_out = malloc(2 * sizeof(SBaseIn) + sizeof(SBase) +
                           sizeof(SChanInitFTDI) + bytes_count)
        phead_in = malloc(max(read_size, MIN_BUFF_OUT))
        if (phead_out == NULL or phead_in == NULL):
            CloseHandle(pipe)
            free(phead_out)
            free(phead_in)
            raise BarstException(NO_SYS_RESOURCE)

        pbase = <SBaseIn *>phead_out
        pbase.dwSize = 2 * sizeof(SBaseIn)
        pbase.eType = ePassOn    # pass on to ftdi manager
        pbase.nChan = man_chan
        pbase.nError = 0
        pbase += 1
        pbase.dwSize = sizeof(SBaseIn)
        pbase.eType = eQuery
        pbase.nChan = -1    # request info on all the USB connected devices
        pbase.nError = 0
        res = self.server.write_read(pipe, 2 * sizeof(SBaseIn), phead_out,
                                     &read_size, phead_in)
        if not res:
            if (read_size == sizeof(SBaseIn) and
                (<SBaseIn *>phead_in).dwSize == sizeof(SBaseIn) and
                (<SBaseIn *>phead_in).nError):
                res = (<SBaseIn *>phead_in).nError
            elif (read_size < sizeof(SBaseIn) + sizeof(SBaseOut) +
                  sizeof(SBase) + sizeof(FT_DEVICE_LIST_INFO_NODE_OS)):
                msg = 'No FTDI device detected'
                res = NO_CHAN
        if res:
            CloseHandle(pipe)
            free(phead_out)
            free(phead_in)
            raise BarstException(res, msg=msg)

        '''now we should have list of devices, each having a SBaseOut struct
        followed by SBase followed by FT_DEVICE_LIST_INFO_NODE (and followed by
        SBase and SChanInitFTDI if the channel is open in the manager). We know
        if it's open because opened channels have bActive true in SBaseOut
        (and nChan != -1). If a channel isn't open we can open it after this
        call by using the location in the list in which it occured. If the
        channel is open, we can address it only by its channel number.
        NOTE, the list number for unopened channels are valid only until the
        next query call.'''
        pbase_out = <SBaseOut *>(<char *>phead_in + sizeof(SBaseIn))
        while <char *>pbase_out < <char *>phead_in + read_size:
            if (pbase_out.sBaseIn.dwSize >= sizeof(SBaseOut) + sizeof(SBase) +
                sizeof(FT_DEVICE_LIST_INFO_NODE_OS) and
                pbase_out.sBaseIn.eType == eResponseEx and
                (<SBase *>(<char *>pbase_out + sizeof(SBaseOut))).eType ==
                eFTDIChan):
                ft_dev_info = <FT_DEVICE_LIST_INFO_NODE_OS *>(<char *>pbase_out
                    + sizeof(SBaseOut) + sizeof(SBase))
            elif (pbase_out.sBaseIn.dwSize >= 2 * sizeof(SBaseOut) + 2 *
                  sizeof(SBase) + sizeof(FT_DEVICE_LIST_INFO_NODE_OS) +
                  sizeof(SChanInitFTDI) and
                  pbase_out.sBaseIn.eType == eResponseEx and
                  (<SBase *>(<char *>pbase_out + 2 *
                             sizeof(SBaseOut))).eType == eFTDIChan):
                ft_dev_info = <FT_DEVICE_LIST_INFO_NODE_OS *>(<char *>pbase_out
                    + 2 * sizeof(SBaseOut) + sizeof(SBase))
            else:
                res = UNEXPECTED_READ
                break
            found = (self.desc and
                     bytes(ft_dev_info.Description) == self.desc)
            found = found or (self.serial and
                bytes(ft_dev_info.SerialNumber) == self.serial)
            dev_list.append(dictify_ft_info(ft_dev_info))
            if found:
                self.ft_info = ft_dev_info[0]
                chan = pbase_out.sBaseIn.nChan
                break
            i += 1
            pbase_out = <SBaseOut *>(<char *>pbase_out +
                                     pbase_out.sBaseIn.dwSize)

        if not found:    # didn't find matching device
            res = NO_CHAN
        if chan >= 0 and not res:    # channel was already open
            self.chan = chan
            res = ALREADY_OPEN
        if not res and not alloc:
            CloseHandle(pipe)
            free(phead_out)
            free(phead_in)
            raise BarstException(msg='Channel is not open and alloc is False.')

        if not res:
            # now we need to open the device
            pbase = <SBaseIn *>phead_out
            pbase.dwSize = (2 * sizeof(SBaseIn) + sizeof(SBase) +
                            sizeof(SChanInitFTDI) + bytes_count)
            pbase.eType = ePassOn
            pbase.nChan = man_chan
            pbase.nError = 0
            pbase += 1
            pbase.dwSize = (sizeof(SBaseIn) + sizeof(SBase) +
                            sizeof(SChanInitFTDI) + bytes_count)
            pbase.eType = eSet
            pbase.nChan = i
            pbase.nError = 0
            pbase += 1
            pbase.dwSize = sizeof(SChanInitFTDI) + sizeof(SBase)
            pbase.eType = eFTDIChanInit
            init_struct = <SChanInitFTDI *>(<char *>pbase + sizeof(SBase))
            init_struct.dwBuffIn = 0
            init_struct.dwBuffOut = 0
            init_struct.dwBaud = 0
            init_struct += 1
            settings_buff = init_struct
            memset(settings_buff, 0, bytes_count)
            for device in self.channels:
                settings_size += device.copy_settings(<char *>settings_buff +
                settings_size, bytes_count - settings_size)

            read_size = sizeof(SBaseOut)
            res = self.write_read(pipe, 2 * sizeof(SBaseIn) + sizeof(SBase) +
                sizeof(SChanInitFTDI) + bytes_count, phead_out, &read_size,
                phead_in)
            if not res:
                if ((read_size == sizeof(SBaseIn) or read_size ==
                     sizeof(SBaseOut)) and
                    (<SBaseIn *>phead_in).dwSize == read_size and
                    (<SBaseIn *>phead_in).nError):
                    res = (<SBaseIn *>phead_in).nError
                elif (read_size != sizeof(SBaseOut) or
                      (<SBaseIn *>phead_in).dwSize != sizeof(SBaseOut) or
                      (<SBaseIn *>phead_in).eType != eResponseExL):
                    res = NO_CHAN
            if not res:
                self.chan = (<SBaseOut *>phead_in).sBaseIn.nChan

        free(phead_in)
        free(phead_out)
        CloseHandle(pipe)
        if res and res != ALREADY_OPEN:
            raise BarstException(res, msg='FTDI devices found:\n'.
                                 format('\n'.join(map(str, dev_list))))

        self.pipe_name = barst_join(self.server.pipe_name, bytes(man_chan),
                                    bytes(self.chan))
        self._populate_settings()
        BarstChannel.open_channel(self)
        return self.devices[:]

    cdef object _populate_settings(FTDIChannel self):
        '''
        Fills in the channel settings and creates the devices for the
        channel.
        '''
        cdef int res, i = 0
        cdef HANDLE pipe
        cdef DWORD read_size, pos = 0
        cdef void *phead_in
        cdef SBaseIn *pbase
        cdef char *pbase_out
        cdef FT_DEVICE_LIST_INFO_NODE_OS *ft_dev_info = NULL
        cdef SChanInitFTDI *ft_init = NULL
        self.devices = []
        cdef str dev_code
        cdef dict dev_dict
        cdef str msg = ''
        from pybarst.ftdi.switch import (FTDISerializerIn, FTDISerializerOut,
                                         FTDIPinIn, FTDIPinOut)
        from pybarst.ftdi.adc import FTDIADC
        dev_dict = {'ADCBrd': FTDIADC, 'MltWBrd': FTDISerializerOut,
                    'MltRBrd': FTDISerializerIn, 'PinWBrd': FTDIPinOut,
                    'PinRBrd': FTDIPinIn}

        # request the info for the channel
        pipe = self.open_pipe('rw')
        read_size = (2 * sizeof(SBaseOut) + 2 * sizeof(SBase) +
        sizeof(FT_DEVICE_LIST_INFO_NODE_OS) + sizeof(SChanInitFTDI))
        pbase = <SBaseIn *>malloc(sizeof(SBaseIn))
        pbase_out = <char *>malloc(max(read_size, MIN_BUFF_OUT))
        if (pbase == NULL or pbase_out == NULL):
            CloseHandle(pipe)
            free(pbase)
            free(pbase_out)
            raise BarstException(NO_SYS_RESOURCE)

        pbase.dwSize = sizeof(SBaseIn)
        pbase.eType = eQuery
        pbase.nChan = -1
        pbase.nError = 0
        res = self.write_read(pipe, sizeof(SBaseIn), pbase, &read_size,
                              pbase_out)
        if not res:
            if (read_size == sizeof(SBaseIn) and
                (<SBaseIn *>pbase_out).dwSize == sizeof(SBaseIn) and
                (<SBaseIn *>pbase_out).nError):
                res = (<SBaseIn *>pbase_out).nError
        if res:
            CloseHandle(pipe)
            free(pbase)
            free(pbase_out)
            raise BarstException(res)

        # parse the returned info
        while pos < read_size:
            if ((<SBaseIn *>(pbase_out + pos)).dwSize <= read_size - pos and
                (<SBaseIn *>(pbase_out + pos)).dwSize >= sizeof(SBaseOut) and
                (<SBase *>(pbase_out + pos)).eType == eResponseEx):
                self.barst_chan_type = (<SBaseOut *>(pbase_out + pos)).szName
                pos += sizeof(SBaseOut)
            elif ((<SBaseIn *>(pbase_out + pos)).dwSize <= read_size - pos and
                (<SBaseIn *>(pbase_out + pos)).dwSize >= sizeof(SBaseOut) and
                (<SBase *>(pbase_out + pos)).eType == eResponseExL):
                pos += sizeof(SBaseOut)
            elif ((<SBase *>(pbase_out + pos)).dwSize <= read_size - pos and
                (<SBase *>(pbase_out + pos)).dwSize == sizeof(SBase) +
                sizeof(SChanInitFTDI) and
                (<SBase *>(pbase_out + pos)).eType == eFTDIChanInit):
                ft_init = <SChanInitFTDI *>(pbase_out + pos + sizeof(SBase))
                pos += sizeof(SBase) + sizeof(SChanInitFTDI)
            elif ((<SBase *>(pbase_out + pos)).dwSize <= read_size - pos and
                (<SBase *>(pbase_out + pos)).dwSize == sizeof(SBase) +
                sizeof(FT_DEVICE_LIST_INFO_NODE_OS) and
                (<SBase *>(pbase_out + pos)).eType == eFTDIChan):
                ft_dev_info = <FT_DEVICE_LIST_INFO_NODE_OS *>(pbase_out + pos +
                                                              sizeof(SBase))
                pos += sizeof(SBase) + sizeof(FT_DEVICE_LIST_INFO_NODE_OS)
            elif pos == read_size:
                break
            else:
                res = UNEXPECTED_READ
                break


        if ft_dev_info == NULL or ft_init == NULL:
            res = UNEXPECTED_READ
        if res:
            CloseHandle(pipe)
            free(pbase)
            free(pbase_out)
            raise BarstException(res)
        self.ft_init = ft_init[0]
        self.ft_info = ft_dev_info[0]
        for k, v in dictify_ft_info(ft_dev_info).iteritems():
            setattr(self, k, v)
        self.chan_min_buff_in = ft_init.dwBuffIn
        self.chan_min_buff_out = ft_init.dwBuffOut
        self.chan_baudrate = ft_init.dwBaud

        # now get the devices info and create them
        self.channels = []
        while 1:
            pbase.nChan = i
            read_size = MIN_BUFF_OUT
            pos = 0
            res = self.write_read(pipe, sizeof(SBaseIn), pbase, &read_size,
                                  pbase_out)
            if not res:
                if (read_size == sizeof(SBaseIn) and
                    (<SBaseIn *>pbase_out).dwSize == sizeof(SBaseIn) and
                    (<SBaseIn *>pbase_out).nError):
                    res = (<SBaseIn *>pbase_out).nError
            if res:
                break

            if ((<SBaseIn *>pbase_out).dwSize <= read_size and
                (<SBaseIn *>pbase_out).dwSize >= sizeof(SBaseOut) and
                (<SBase *>pbase_out).eType == eResponseEx):
                dev_code = (<SBaseOut *>(pbase_out + pos)).szName
            else:
                res = UNEXPECTED_READ
                break

            if dev_code not in dev_dict:
                res = 0
                msg = 'Did not recognize FTDI device "{}"'.format(dev_code)
                break

            self.devices.append(dev_dict[dev_code](pipe_name=self.pipe_name,
                                                   chan=i, parent=self))
            self.devices[-1].open_channel()
            self.devices[-1].close_channel_client()
            self.channels.append(self.devices[-1].settings)
            i += 1

        CloseHandle(pipe)
        free(pbase)
        free(pbase_out)
        if res and res != INVALID_CHANN:
            raise BarstException(res, msg=msg)

    cpdef object set_state(FTDIChannel self, int state, flush=False):
        '''
        Because an FTDI channel is composed of peripheral devices, setting the
        :class:`FTDIChannel` itself to inactive/active has no meaning.
        Therefore, this method doesn't do anything. Instead, you should set
        the state of the :class:`FTDIDevice` instances of the channel.
        '''
        pass


cdef class FTDIDevice(BarstChannel):
    '''
    An abstract class for the peripheral devices that can connect to an FTDI
    channel.

    You don't instantiate this class or it's derived classes, instead, it is
    instantiated by the :class:`FTDIChannel` in response to
    :class:`FTDISettings` instances in its `devices` parameter and is then
    stored in its :attr:`FTDIChannel.devices` attribute.

    :Parameters:

        `chan`: int
            The channel number assigned to this channel within the parent
            FTDI channel.
        `parent`: :class:`FTDIChannel`
            The :class:`FTDIChannel` of which this device is a peripheral
            device.
    '''

    def __init__(FTDIDevice self, int chan, FTDIChannel parent, **kwargs):
        pass

    def __cinit__(FTDIDevice self, int chan, FTDIChannel parent, **kwargs):
        self.chan = chan
        self.running = 0
        self.settings = None
        self.ft_write_buff_size = 0
        self.ft_read_device_size = 0
        self.ft_write_device_size = 0
        self.ft_device_baud = 0
        self.ft_device_mode = 0
        self.ft_device_bitmask = 0
        self.parent = parent

    cpdef object open_channel(FTDIDevice self):
        '''
        See :meth:`~pybarst.core.server.BarstChannel.open_channel` for details.

        Calling this method will open a new client for communication with
        the peripheral instance on the server.
        '''
        # Super must be called in inherited classes.
        self.close_channel_client()
        self.running = 0
        self.pipe = self.open_pipe('rw')
        self.parent_chan = self.parent.chan
        BarstChannel.open_channel(self)

    cpdef object close_channel_server(FTDIDevice self):
        '''
        See :meth:`~pybarst.core.server.BarstChannel.close_channel_server` for
        details. However, you cannot delete a FTDI peripheral device on
        the server, but instead have to delete the whole :class:`FTDIChannel`
        channel. Therefore, this method raises an exception when called.
        '''
        raise BarstException(msg='A FTDI peripheral device cannot be deleted '
        'from the server, you can only delete the whole channel')

    cpdef object set_state(FTDIDevice self, int state, flush=False):
        '''
        See :meth:`~pybarst.core.server.BarstChannel.set_state` for details.

        See the class description for the derived class for more details on
        how to manipulate state.
        '''
        cdef SBaseIn base, base_read
        cdef int nes
        cdef HANDLE pipe = self.open_pipe('rw')
        cdef DWORD read_size = sizeof(SBaseIn)
        cdef EQueryType base_type = eNone

        base.dwSize = sizeof(SBaseIn)
        if state or flush:
            self.running = 0
        if state:
            base_type = eActivate
        else:
            base_type = eInactivate
        base.eType = base_type
        base.nChan = self.chan
        base.nError = 0

        res = self.write_read(pipe, sizeof(SBaseIn), &base, &read_size,
                              &base_read)
        if not res:
            if read_size != sizeof(SBaseIn) or (base_read.eType != base_type
                                                and not base_read.nError):
                res = UNEXPECTED_READ
            else:
                res = base_read.nError
        CloseHandle(pipe)
        if res:
            raise BarstException(res)

    cdef object _send_trigger(FTDIDevice self):
        cdef SBaseIn *pbase_out = <SBaseIn *>malloc(2 * sizeof(SBaseIn))
        cdef SBaseIn *pbase
        cdef int res
        cdef DWORD read_size = 0
        if pbase_out == NULL:
            raise BarstException(NO_SYS_RESOURCE)

        pbase = pbase_out
        pbase.dwSize = 2 * sizeof(SBaseIn)
        pbase.eType = ePassOn
        pbase.nChan = self.chan
        pbase.nError = 0
        pbase += 1
        pbase.dwSize = sizeof(SBaseIn)
        pbase.eType = eTrigger
        pbase.nChan = -1
        pbase.nError = 0
        res = self.write_read(self.pipe, 2 * sizeof(SBaseIn), pbase_out,
                              &read_size, NULL)

        free(pbase_out)
        if res:
            raise BarstException(res)
