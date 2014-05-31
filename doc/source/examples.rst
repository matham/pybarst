.. _pybarst-examples:

PyBarst Examples
=================

For more example see the tests in `pybarst/tests/`.

Server Examples
----------------

Using a server::

    >>> # create a local server instance with a pipe named TestPipe
    >>> server = BarstServer(barst_path=r'C:\Program Files\Barst\Barst.exe',
    ... pipe_name=r'\\.\pipe\TestPipe')
    >>> # now actually create the server and start it running
    >>> server.open_server()
    >>> # Connect to a server running on remote computer named PC_Name using a pipe named TestPipe
    >>> server2 = BarstServer(barst_path='', pipe_name=r'\\PC_Name\pipe\TestPipe')
    >>> # now open the connection to the remote server
    >>> server2.open_server()

Get the current server time::

    >>> server.clock()
    (1.5206475727928106, 13045896424.049448)

Creating managers::

    >>> print(server.get_manager('ftdi'))
    {'version': 197127L, 'chan': 0, 'chan_id': 'FTDIMan'}
    >>> print(server.get_manager('serial'))
    {'version': 498139398L, 'chan': 1, 'chan_id': 'SerMan'}
    >>> print(server.get_manager('mcdaq'))
    {'version': 50000L, 'chan': 2, 'chan_id': 'DAQMan'}
    >>> print(server.managers)
    {'serial': {'version': 498139398L, 'chan': 1, 'chan_id': 'SerMan'},
    'mcdaq': {'version': 50000L, 'chan': 2, 'chan_id': 'DAQMan'},
    'ftdi': {'version': 197127L, 'chan': 0, 'chan_id': 'FTDIMan'}}

Closing managers and the server::

    >>> # now close the ftdi manager
    >>> server.close_manager('ftdi')
    >>> # now shut down the server
    >>> server.close_server()


FTDI Channel Examples
----------------------

FTDI pin device
++++++++++++++++

A example of writing and reading back from the pins::

    >>> from pybarst.core.server import BarstServer
    >>> from pybarst.ftdi import FTDIChannel
    >>> from pybarst.ftdi.switch import PinSettings

    >>> server = BarstServer(barst_path=the_path, pipe_name=r'\\.\pipe\TestPipe')
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

    >>> server = BarstServer(barst_path=the_path, pipe_name=r'\\.\pipe\TestPipe')
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

    >>> server = BarstServer(barst_path=the_path, pipe_name=r'\\.\pipe\TestPipe')
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


For the following examples, the ADC clock line was connected to pin 7 of the FTDI
channel and the ADC data lines 1-7 were connected to pins 0-6 of the channel
in their parallel direction.

From the ADC's point of view at least data lines
6, and 7 must be used. One can then further connect data lines below 6, e.g.
connecting lines 4-7 will result in 4 data lines, connecting lines 5-7 will
only use 3 data lines. The number of data lines connected determine how
quickly data is sent, because if 7 data lines are connected, it will send
data at a faster rate than when only 2 data lines are connected.

On the FTDI channel, the ADC data lines must be connected in a block, e.g. ADC
data lines 5-7 can be connected at pins 2-4, at pins 5-7 etc. The ADC clock line
must also be connected to any of the FTDI pins, which in the examples below
happens to be at pin 7.

Since ADC data lines 1-7 are connected to to FTDI pins 0-6, we can use some or
all of the the 1-7 ADC data lines. I.e. we can send between 2-7 data bits at a
time.

An example of sampling just one channel at 11k with 16-bit data points::

    >>> from pybarst.core.server import BarstServer
    >>> from pybarst.ftdi import FTDIChannel
    >>> from pybarst.ftdi.adc import ADCSettings

    >>> server = BarstServer(barst_path=r'C:\Program Files\Barst\Barst.exe',
    ... pipe_name=r'\\.\pipe\TestPipe')
    >>> server.open_server()
    >>> print(server.get_manager('ftdi'))
    {'version': 197127L, 'chan': 0, 'chan_id': 'FTDIMan'}

    >>> # send only 4 bits at a time, using only ADC data lines 4-7, connected to
    >>> # FTDI pins 3-6. Only one channel is enabled with a sampling rate of 11k
    >>> # the server sends 100 data points at a time. The ADC returned data points
    >>> # is 16 bits.
    >>> adc = ADCSettings(clock_bit=7, lowest_bit=3, num_bits=4, sampling_rate=11000,
    ... chan1=True, chan2=False, transfer_size=100, data_width=16)
    >>> # FT2232H connected, using channel B of it.
    >>> ftdi = FTDIChannel(channels=[adc], server=server, desc='Birch Board rev1 B')

    >>> # create the channel and open the adc peripheral and activate it
    >>> adc, = ftdi.open_channel(alloc=True)
    >>> print(adc)
    <pybarst.ftdi.adc.FTDIADC object at 0x021C8DF8>
    >>> # the actual sampling rate is not 11k, but the closest valid rate
    >>> print(adc.settings.sampling_rate)
    11904.7619048
    >>> adc.open_channel()
    >>> adc.set_state(True)

    # now read for bit and print the values of the last group read
    >>> for i in range(500):
    ...     d = adc.read()
    >>> # the voltage data is in chan1_data.
    >>> print('T: {:.4f}, Channel 1 len/value: {}, {:.4f}, raw {}-bit value: {}'
    ...       .format(d.ts, len(d.chan1_data), d.chan1_data[0],
    ...               adc.settings.data_width, d.chan1_raw[0]))
    T: 0.0000, Channel 1 len/value: 100, -0.0012, raw 16-bit value: 32764
    >>> # how full the FTDI read buffers were.
    >>> print('Fullness: {:.2f}%'.format(d.fullness)
    Fullness: 7.65%

    >>> # deactivate and close
    >>> adc.set_state(False)
    >>> ftdi.close_channel_server()
    >>> server.close_server()

As can be seen from the example, one can set the bit width of the sampled ADC
data points to 16 or 24-bit. One can set whether channel 1 or 2 or both are
active, the sampling rate of each channel, and other parameters.

There's one limiting factor on the settings; the USB has to be fast enough
to be able to communicate with the ADC device. This is reflected in the
fullness parameter as well as in the data points error parameters, e.g.
overflow. In particular, if the fullness is close to 100%, it is likely that the
USB cannot keep up and that data is lost.

Fullness is a function of the data rate, which is controlled by the combined
sampling rate of channels 1 and 2, the hw_buff_size value, the data width (16
or 24-bit) and the number of ADC data lines connected to the FTDI channel.
In the example above, fullness was 7.65%, which is fairly good. Following
is a table showing some example fullness values tested on Win7.

The top header row indicates the values of for ``hw_buff_size``. The second
header row indicates the sampling rate for channel 1, and the third header
row indicates the number of bits per ADC sample:

+-------+-------------------------------+----------------------------------+
| Buffer|        25                     |    100                           |
+-------+------------+------------------+-----------------+----------------+
|       |    499Hz   |11905Hz           |      499Hz      |  11905Hz       |
+-------+-----+------+---------+--------+--------+--------+--------+-------+
|# pins |  16 | 24   |   16    | 24     |    16  |24      |  16    |  24   |
+=======+=====+======+=========+========+========+========+========+=======+
|2      |0.63%| 0.84%|   15.99%|  20.68%|  0.62% |  0.82% |  14.79%| 19.64%|
+-------+-----+------+---------+--------+--------+--------+--------+-------+
|4      |0.31%| 0.43%|   7.55% |  10.06%|  0.31% |  0.41% |  7.38% |  9.85%|
+-------+-----+------+---------+--------+--------+--------+--------+-------+
|7      |0.18%| 0.24%|   4.29% |  5.72% |  0.18% |  0.24% |  4.19% |  5.62%|
+-------+-----+------+---------+--------+--------+--------+--------+-------+

As can be seen, the ``hw_buff_size`` doesn't have much an effect for this
device. Nonetheless, this value may be important for slower computers.

The ``hw_buff_size`` parameter becomes important when combining other
peripheral devices on a single channel with an ADC device. ``hw_buff_size``
is the buffer size used when writing to the USB bus. If the value is large
it is more efficient for the ADC because more data is sent at once, however, it
also means that other devices on the same channel which share the buffer will
have to wait for the buffer to be written before they can operate on the bus.
So with larger buffers, it takes more time between reads/writes.

Following is an example of the ``hw_buff_size`` effect on the reading rate of a
:class:`~pybarst.ftdi.FTDICahnnel` containing two peripherals, a
:class:`~pybarst.ftdi.adc.ADCCahnnel` and
:class:`~pybarst.ftdi.switch.FTDIPinIn`::

    >>> # the ADC peripheral send only 4 bits at a time, using only ADC data lines 4-7,
    >>> # connected to FTDI pins 3-6.
    >>> adc = ADCSettings(clock_bit=7, lowest_bit=3, num_bits=4, sampling_rate=11000,
    ...                   chan1=True, chan2=False, transfer_size=100, data_width=24,
    ...                   hw_buff_size=0)
    >>> # on the same channel use pin 0 as an input pin that we read directly
    >>> # do continuous read to read as fast as possible.
    >>> pin = PinSettings(bitmask=0x01, num_bytes=1, output=False, continuous=True)
    >>> # FT2232H connected, using channel B of it.
    >>> ftdi = FTDIChannel(channels=[adc, pin], server=server, desc='Birch Board rev1 B')

    >>> # create the channel and open the peripherals and activate them
    >>> adc, pin = ftdi.open_channel(alloc=True)
    >>> pin.open_channel()
    >>> pin.set_state(True)
    >>> adc.open_channel()
    >>> adc.set_state(True)

    >>> # This prints the current buffer size
    >>> print(pin.ft_write_buff_size)
    1530L

    >>> # read the adc device
    >>> adc.read()
    >>> # ...
    >>> # read the pin device
    >>> pin.read()
    >>> # ...
    >>> # now find the difference in time between the reads.
    >>> t, val = pin.read()
    >>> t2, val = pin.read()
    >>> print('Read rate: {:.2f} Hz'.format(1 / (t2 = t)))
    Read rate: 522.70 Hz

Following is a table showing the effect ``hw_buff_size`` on the read rate of
the pin device using the code above.

==================  ========================    ====================
``hw_buff_size``    ``ft_write_buff_size``      Reading rate (Hz)
==================  ========================    ====================
0                   1530L                       522.7
1                   1530L                       555.39
5                   3060L                       285.98
10                  6120L                       150.63
25                  16320L                      58.28
50                  32640L                      8.25
100                 65280L                      6.34
==================  ========================    ====================

As one can see, larger ``hw_buff_size`` decreases the rate. Therefore, it is
recommended that if other peripherals share the same channel with an ADC channel
that the ``hw_buff_size`` should be reduced to a lower value than the default of
25%. Also note, that a pin device on its own can achieve more than 1k reading
rate because on its own its ``ft_write_buff_size`` is 510L.




RTV Channel Examples
---------------------

A simple example::

    >>> from pybarst.core.server import BarstServer
    >>> from pybarst.rtv import RTVChannel

    >>> server = BarstServer(barst_path=the_path, pipe_name=r'\\.\pipe\TestPipe')
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

    >>> server = BarstServer(barst_path=the_path, pipe_name=r'\\.\pipe\TestPipe')
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

    >>> server = BarstServer(barst_path=the_path, pipe_name=r'\\.\pipe\TestPipe')
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

    >>> server = BarstServer(barst_path=the_path, pipe_name=r'\\.\pipe\TestPipe')
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
