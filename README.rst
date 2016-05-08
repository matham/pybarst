PyBarst is a python bindings for the Barst client API.

This project provides a python interface to the Barst server project.
Barst is a server which provides access to commonly used hardware in the lab,
e.g. FTDI USB devices, RTV cameras, serial ports etc.

The wheels come with the Barst executable and therefore does not need
to be installed separately. The path to the executable can be found in
`pybarst.dep_bins`.

For more information: http://matham.github.io/pybarst/index.html

To install https://matham.github.io/pybarst/installation.html

.. image:: https://ci.appveyor.com/api/projects/status/q9om4pu4og1kkdut/branch/master?svg=true
    :target: https://ci.appveyor.com/project/matham/pybarst/branch/master
    :alt: Appveyor status

.. image:: https://img.shields.io/pypi/pyversions/pybarst.svg
    :target: https://pypi.python.org/pypi/pybarst/
    :alt: Supported Python versions

.. image:: https://img.shields.io/pypi/v/pybarst.svg
    :target: https://pypi.python.org/pypi/pybarst/
    :alt: Latest Version on PyPI

Usage example
-------------

Starting a server::

    >>> # create a local server instance with a pipe named TestPipe. Since not
    >>> # provided, the executable is searched for in pybarst.dep_bins and in
    >>> # Program Files.
    >>> server = BarstServer(pipe_name=r'\\.\pipe\TestPipe')
    >>> # now actually create the server and start it running
    >>> server.open_server()
    >>> # Connect to a server running on remote computer named PC_Name using a pipe named TestPipe
    >>> server2 = BarstServer(pipe_name=r'\\PC_Name\pipe\TestPipe')
    >>> # now open the connection to the remote server
    >>> server2.open_server()

Get the current server time::

    >>> server.clock()
    (1.5206475727928106, 13045896424.049448)

An example using the RTV-4 video card::

    >>> from pybarst.core.server import BarstServer
    >>> from pybarst.rtv import RTVChannel

    >>> server = BarstServer(pipe_name=r'\\.\pipe\TestPipe')
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

A example using the windows serial port::

    >>> from pybarst.core.server import BarstServer
    >>> from pybarst.serial import SerialChannel

    >>> server = BarstServer(pipe_name=r'\\.\pipe\TestPipe')
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
