'''
Serial channel
===============

The Barst serial port interface. A serial channel is an interface to a serial
port, such as a RS232 or RS485 port. See :class:`~pybarst.serial.SerialChannel`
for details.


Typical usage
--------------

For the serial channel, once a channel is created on the server, it's always
active. That means that there's no need to set the state with
:meth:`~pybarst.core.server.BarstChannel.set_state`.

Typically, a client creates a :class:`SerialChannel` and then calls
:meth:`SerialChannel.open_channel` on it to create the
channel on the server. Once created, the client can read and write to it
through the server using :meth:`SerialChannel.read` and
:meth:`SerialChannel.write`.

Other clients can do similarly; they create a new :class:`SerialChannel`
instance and then call :meth:`SerialChannel.open_channel` on it to open
a new connection to the existing channel. Those new clients can then read/write
to the channel as well.

Finally, existing clients can call
:meth:`~pybarst.core.server.BarstChannel.close_channel_client` to simply
close this client while leaving the channel on the server, or
:meth:`~pybarst.core.server.BarstChannel.close_channel_server` to delete
the channel from the server as well as for all the clients.
'''

__all__ = ('SerialChannel', )

from pybarst.serial._serial import SerialChannel
