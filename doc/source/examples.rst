
PyBarst Examples
=================


See `pybarst/tests/` for more tests/examples.

FTDI Channel Examples
----------------------

FTDI pin device
++++++++++++++++

A example of writing and reading back from the pins::

    >>> from pybarst.core.server import BarstServer
    >>> from pybarst.ftdi import FTDIChannel
    >>> from pybarst.ftdi.switch import PinSettings

    >>> server = BarstServer(barst_path=the_path, pipe_name='\\\\.\\pipe\\TestPipe')
    >>> server.open_server()
    >>> print(server.get_manager('ftdi'))
    {'version': 197127L, 'chan': 0, 'chan_id': 'FTDIMan'}

    >>> # create setting instance for each peripheral device we want
    >>> # Reads all pins on the port
    >>> ft_in = PinSettings(bitmask=0b11111111, output=False)
    >>> # Write only pins 0-3 on the port and initialize it to 0b00001010
    >>> ft_out = PinSettings(bitmask=0b00001111, init_val=0b00001010, output=True)

    >>> # FT2232H connected, using channel A of it. We also connected pint 0 to 7,
    >>> # and pin 1 to 6
    >>> ftdi = FTDIChannel(channels=[ft_in, ft_out], server=server, desc='Birch Board rev1 A')

    >>> # create the channel. channels is the list of created peripherals
    >>> channels = ftdi.open_channel(alloc=True)
    >>> ft_in, ft_out = channels

    >>> # we need to open and activate each peripheral
    >>> ft_in.open_channel()
    >>> ft_in.set_state(True)
    >>> ft_out.open_channel()
    >>> ft_out.set_state(True)

    >>> # we should now read the initial value with which the channel was initialized
    >>> t, val = ft_in.read()
    >>> print('{}, 0b{:08b}'.format(t, val[0]))
    242.037815454, 0b01111010
    >>> # now write an inverted pattern
    >>> print(ft_out.write(buff_mask=0xFF, buffer=[0b00000101]))
    242.293944272
    >>> t, val = ft_in.read()
    >>> print('{}, 0b{:08b}'.format(t, val[0]))
    242.54987969, 0b10110101

    >>> # deactivate and close the channel
    >>> ft_in.set_state(False)
    >>> ft_out.set_state(False)
    >>> ftdi.close_channel_server()


A example of writing and reading back from the pins using **2 clients** at the
same time. Starting after creation of the server above::

    >>> # Reads all pins on the port
    >>> ft_in = PinSettings(bitmask=0b11111111, output=False)
    >>> # Writes pins 0-3 on the port
    >>> ft_out = PinSettings(bitmask=0b00001111, init_val=0b00001010, output=True)

    >>> # FT2232H connected, using channel A of it. We also connected pint 0 to 7,
    >>> # and pin 1 to 6
    >>> ftdi = FTDIChannel(channels=[ft_in, ft_out], server=server, desc='Birch Board rev1 A')

    >>> # create a second client for it, the devices will be auto filled in from the
    >>> # server when opening it
    >>> ftdi2 = FTDIChannel(channels=[], server=server, desc='Birch Board rev1 A')

    >>> # create the channel from client 1.
    >>> ft_in1, ft_out1 = ftdi.open_channel(alloc=True)
    >>> # the channel should now exist on the server, so open it client 2
    >>> ft_in2, ft_out2 = ftdi.open_channel()

    >>> # we need to open each peripheral for each client, but we activate it only once
    >>> ft_in1.open_channel()
    >>> ft_in2.open_channel()
    >>> ft_in1.set_state(True)
    >>> ft_out1.open_channel()
    >>> ft_out2.open_channel()
    >>> ft_out2.set_state(True)

    >>> # we should now read the initial value with which the channel was initialized
    >>> t, val = ft_in1.read()
    >>> print('{}, 0b{:08b}'.format(t, val[0]))
    2.15769243403, 0b01111010
    >>> # now invert the pattern using client 2 and read it back with clients 1 and 2
    >>> print(ft_out2.write(buff_mask=0xFF, buffer=[0b00000101]))
    2.4131564684
    >>> t, val = ft_in1.read()
    >>> print('{}, 0b{:08b}'.format(t, val[0]))
    2.66907053519, 0b10110101
    >>> t, val = ft_in2.read()
    >>> print('{}, 0b{:08b}'.format(t, val[0]))
    2.92512010446, 0b10110101

    >>> # now invert the pattern again client 1 and read it back with clients 1 and 2
    >>> print(ft_out1.write(buff_mask=0xFF, buffer=[0b00001010]))
    2.92619673316
    >>> t, val = ft_in1.read()
    >>> print('{}, 0b{:08b}'.format(t, val[0]))
    2.92721505473, 0b01111010
    >>> t, val = ft_in2.read()
    >>> print('{}, 0b{:08b}'.format(t, val[0]))
    2.92826499355, 0b01111010

    >>> # deactivate using one client (doesn't matter which) because state is global and close the channel
    >>> ft_in2.set_state(False)
    >>> ft_out1.set_state(False)
    >>> ftdi.close_channel_server()


FTDI Serial to Parallel device
+++++++++++++++++++++++++++++++


A example of writing to a serial to parallel output peripheral device connected
to the FTDI channel::

    >>> from pybarst.core.server import BarstServer
    >>> from pybarst.ftdi import FTDIChannel
    >>> from pybarst.ftdi.switch import SerializerSettings

    >>> server = BarstServer(barst_path=the_path, pipe_name='\\\\.\\pipe\\TestPipe')
    >>> server.open_server()
    >>> print(server.get_manager('ftdi'))
    {'version': 197127L, 'chan': 0, 'chan_id': 'FTDIMan'}

    >>> # this is a serial to parallel type device connected to the FTDI port,
    >>> # there are two such boards daisy chained, so we control 16 output lines
    >>> ft_out = SerializerSettings(clock_bit=0, data_bit=1, latch_bit=2, num_boards=2, output=True)
    >>> # FT2232H connected, using channel A of it.
    >>> ftdi = FTDIChannel(channels=[ft_out], server=server, desc='Birch Board rev1 A')

    >>> # create the channel and open the peripheral and activate it
    >>> ft_out, = ftdi.open_channel(alloc=True)
    >>> print(ft_out)
    <pybarst.ftdi.switch.FTDISerializerOut object at 0x0277C3B0>
    >>> ft_out.open_channel()
    >>> ft_out.set_state(True)

    >>> # now set line 9 to low and lines 0, 4 to high.
    >>> print(ft_out.write(set_low=[9], set_high=[0, 4]))
    30.7473420986
    >>> # now set line 6 to low and line 8 to high.
    >>> print(ft_out.write(set_low=[6], set_high=[8]))
    31.0028566384

    >>> # deactivate and close
    >>> ft_out.set_state(False)
    >>> ftdi.close_channel_server()


A example of reading from a serial to parallel input peripheral device
connected to the FTDI channel::

    >>> from pybarst.core.server import BarstServer
    >>> from pybarst.ftdi import FTDIChannel
    >>> from pybarst.ftdi.switch import SerializerSettings

    >>> server = BarstServer(barst_path=the_path, pipe_name='\\\\.\\pipe\\TestPipe')
    >>> server.open_server()
    >>> print(server.get_manager('ftdi'))
    {'version': 197127L, 'chan': 0, 'chan_id': 'FTDIMan'}

    >>> # this is a serial to parallel type device connected to the FTDI port,
    >>> # there one such board connected, so we read 8 lines
    >>> ft_in = SerializerSettings(clock_bit=0, data_bit=1, latch_bit=2, num_boards=1, output=False)
    >>> # FT2232H connected, using channel A of it.
    >>> ftdi = FTDIChannel(channels=[ft_in], server=server, desc='Birch Board rev1 A')

    >>> # create the channel and open the peripheral and activate it
    >>> ft_in, = ftdi.open_channel(alloc=True)
    >>> print(ft_in)
    <pybarst.ftdi.switch.FTDISerializerIn object at 0x0277C3B0>
    >>> ft_in.open_channel()
    >>> ft_in.set_state(True)

    >>> # now read it
    >>> print(ft_in.read())
    (1.8761614203943533, [False, False, True, False, False, False, True, False])

    >>> # deactivate using and close
    >>> ft_in.set_state(False)
    >>> ftdi.close_channel_server()
    >>> server.close_server()


FTDI ADC device
++++++++++++++++


A example of reading from an ADC device::

    >>> print()


RTV Channel Examples
---------------------

A simple example::

    >>> from pybarst.core.server import BarstServer
    >>> from pybarst.rtv import RTVChannel

    >>> server = BarstServer(barst_path=the_path, pipe_name='\\\\.\\pipe\\TestPipe')
    >>> server.open_server()
    >>> print(server.get_manager('rtv'))
    {'version': 1080L, 'chan': 1, 'chan_id': 'RTVMan'}

    >>> # for the code below, there should be a RTV-4 like device connected, with
    >>> # a port 0 available
    >>> rtv = RTVChannel(server=server, chan=0, video_fmt='full_NTSC', frame_fmt='rgb24', lossless=False)
    >>> rtv.open_channel()
    >>> rtv.set_state(state=True)

    >>> # data is a buffer containing the raw image data
    >>> time, data = rtv.read()
    >>> print(time, len(data), rtv.buffer_size)
    (12865.015067682945, 921600, 921600L)
    >>> time, data = rtv.read()
    >>> print(time, len(data), rtv.buffer_size)
    (12865.048412758983, 921600, 921600L)
    >>> # remove any data queued, otherwise read will return any waiting data
    >>> rtv.set_state(state=False, flush=True)

    >>> # activate again
    >>> rtv.set_state(state=True)
    >>> time, data = rtv.read()
    >>> print(time, len(data), rtv.buffer_size)
    (12865.281985012041, 921600, 921600L)
    >>> rtv.close_channel_server()


Serial Port Examples
---------------------

A simple example::

    >>> from pybarst.core.server import BarstServer
    >>> from pybarst.serial import SerialChannel

    >>> server = BarstServer(barst_path=the_path, pipe_name='\\\\.\\pipe\\TestPipe')
    >>> server.open_server()
    >>> print(server.get_manager('serial'))
    {'version': 498139398L, 'chan': 0, 'chan_id': 'SerMan'}

    >>> # for this example, COM3 should have a loopback cable connected to it.
    >>> serial = SerialChannel(server=server, port_name='COM3', max_write=32, max_read=32)
    >>> serial.open_channel()

    >>> time, val = serial.write(value='How are you today?', timeout=10000)
    >>> print(time, val)
    (1931.5567431509603, 18)
    >>> # read the exact number of chars written.
    >>> time, val = serial.read(read_len=len('How are you today?'), timeout=10000)
    >>> print(time, val)
    (1931.5607736011307, 'How are you today?')

    >>> serial.close_channel_server()

A more complex example using two clients to read and write simultaneously to
a single port::

    >>> server = BarstServer(barst_path=the_path, pipe_name='\\\\.\\pipe\\TestPipe')
    >>> server.open_server()
    >>> print(server.get_manager('serial'))
    {'version': 498139398L, 'chan': 0, 'chan_id': 'SerMan'}

    >>> # for this example, COM3 should have a loopback cable connected to it.
    >>> serial1 = SerialChannel(server=server, port_name='COM3', max_write=32, max_read=32)
    >>> serial2 = SerialChannel(server=server, port_name='COM3', max_write=32, max_read=32)
    >>> serial1.open_channel()
    >>> serial2.open_channel()

    >>> # read and write from the same client
    >>> time, val = serial1.write(value='How are you today?', timeout=10000)
    >>> print(time, val)
    (2362.7382840980176, 18)
    >>> time, val = serial1.read(read_len=len('How are you today?'), timeout=10000)
    >>> print(time, val)
    >>> (2362.7413268664427, 'How are you today?')

    >>> # now write using client 1
    >>> time, val = serial1.write(value="I'm fine. How about you?", timeout=10000)
    >>> print(time, val)
    (2362.7702830786507, 24)
    >>> # and read it using client 2
    >>> time, val = serial2.read(read_len=len("I'm fine. How about you?"), timeout=10000)
    >>> print(time, val)
    (2362.7743261346245, "I'm fine. How about you?")

    >>> # only close the client now, otherwise when closing the channel on the
    >>> # server with serial2, the channel would not exists causing an error.
    >>> serial1.close_channel_client()
    >>> # now delete the channel from the server as well
    >>> serial2.close_channel_server()


Measurement Computing DAQ Examples
-----------------------------------

A simple example of writing and reading a DAQ device::

    >>> from pybarst.core.server import BarstServer
    >>> from pybarst.mcdaq import MCDAQChannel

    >>> server = BarstServer(barst_path=the_path, pipe_name='\\\\.\\pipe\\TestPipe')
    >>> server.open_server()
    >>> print(server.get_manager('mcdaq'))
    {'version': 50000L, 'chan': 0, 'chan_id': 'DAQMan'}

    >>> # open a daq device enumerated in InstaCal at chan 0. Assume the device
    >>> # supports both reading and writing
    >>> daq = MCDAQChannel(chan=0, server=server, direction='rw', init_val=0)
    >>> # open the channel on the server
    >>> daq.open_channel()
    >>> print(daq)
    <pybarst.mcdaq._mcdaq.MCDAQChannel object at 0x02269EA0>

    >>> # read the input port
    >>> print(daq.read())
    (4.198078126514167, 0)
    >>> # write to the output port, set the lowest 4 lines high
    >>> print(daq.write(mask=0x00FF, value=0x000F))
    4.2000482891
    >>> # set the lowest line to low and leave the other lines unchanged
    >>> print(daq.write(mask=0x0001, value=0x0000))
    4.20168009947

    >>> # close the channel on the server
    >>> daq.close_channel_server()

A more complex example using **2 clients** to read and write simultaneously to
a single device. Starting with server of the last example::

    >>> # open a daq device enumerated in InstaCal at chan 0. Assume the device
    >>> # supports both reading and writing
    >>> daq = MCDAQChannel(chan=0, server=server, direction='rw', init_val=0)
    >>> # open the channel on the server
    >>> daq.open_channel()
    >>> print(daq)
    <pybarst.mcdaq._mcdaq.MCDAQChannel object at 0x02269EF8>

    >>> # open another client to the same device. The devices settings will be
    >>> # automatically initialized from the values of the first client that created the channel
    >>> daq2 = MCDAQChannel(chan=0, server=server)
    >>> daq2.open_channel()
    >>> print(daq2)
    <pybarst.mcdaq._mcdaq.MCDAQChannel object at 0x02269F50>

    >>> # read the input port with clients 1 and 2
    >>> print(daq.read())
    (5.088585868374414, 0)
    >>> print(daq2.read())
    (5.096653351575884, 0)

    >>> # write to the output port with client 1
    >>> print(daq.write(mask=0x00FF, value=0x000F))
    5.09761174246
    >>> # now with client 2
    >>> print(daq2.write(mask=0x0001, value=0x0000))
    5.09911174329

    >>> # close the channel on the server using client 1
    >>> daq.close_channel_server()
    >>> # for client 2, we now only have to close the local connection since client 1
    >>> # already deleted the channel from the server
    >>> daq2.close_channel_client()
