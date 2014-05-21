
PyBarst Examples
=================


See `pybarst/tests/` for more tests/examples.


Serial Port Examples
--------------------

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

A more complex example using two clients open simultaneously::

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
