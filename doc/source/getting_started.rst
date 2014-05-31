Getting Started
================

PyBarst is a python client interface to a Barst server. A Barst server controls
various hardware connected to the system, e.g. RTV cameras, serial port channels,
Measurement Computing devices, and FTDI channels and their peripherals.

To use PyBarst, first, you must meet the :ref:`requirements`. Then, you may
install the :ref:`install-barst` server and the :ref:`install-pybarst` python
module. Once installed, you can use the PyBarst clients to create, configure,
read/write, and close these various channels on the server. Some channels
support connecting multiple clients to a single channel, while others don't.

After it's installed, you can look at the :ref:`pybarst-examples` for examples
on how to use the various channels. You can find the complete documentation at
:ref:`pybarst-api`.

Following is a simple example for creating and running a channel::

    >>> from pybarst.core.server import BarstServer
    >>> from pybarst.mcdaq import MCDAQChannel

    >>> # create a server instance on the local computer with a pipe named TestPipe
    >>> server = BarstServer(barst_path=r'C:\Program Files\Barst\Barst.exe',
    ... pipe_name=r'\\.\pipe\TestPipe')
    >>> # now actually launch the server instance
    >>> server.open_server()

    >>> # create the MC DAQ manager on the server, checking the drivers can be found
    >>> server.get_manager('mcdaq')

    >>> # open a daq device enumerated in InstaCal at chan 0
    >>> daq = MCDAQChannel(chan=0, server=server)
    >>> # now open the channel on the server
    >>> daq.open_channel()

    >>> # read the input port
    >>> print(daq.read())
    (4.198078126514167, 0)
    >>> # write to the output port, set the lowest 4 lines high
    >>> print(daq.write(mask=0x00FF, value=0x000F))
    4.2000482891

    >>> # close the channel on the server, and shut down the server
    >>> daq.close_channel_server()
    >>> server.close_server()
