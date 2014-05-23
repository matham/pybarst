'''
RTV Channel
============

The Barst RTV interface. An RTV channel is a interface to a RTV camera sampling
device such as the RTV-24. See :class:`~pybarst.rtv.RTVChannel` for details.


Driver requirements
--------------------

In order to create RTV channels, the RTV WDM drivers must be installed. In
particular, the server dynamically loads the `AngeloRTV.dll` dll from the
system path. The server automatically loads the 64 or 32-bit version,
depending on whether the server is 32 or 64-bit.

If driver errors arise, either, the driver is not installed, an older version
of the driver is installed, or the incorrect 64/32-bit version is installed.


Typical usage
--------------

For the RTV channel, typically, the client creates a :class:`RTVChannel` and
then calls :meth:`RTVChannel.open_channel` on it to create the
channel on the server. Once created, no other client can connect to this
channel because RTV channels do not support connections to multiple clients.

After creation, the client must call :meth:`RTVChannel.set_state` to activate
the channel. Once activated, the server immediately starts sending data back to
the client, and the client should start calling :meth:`RTVChannel.read` to
get the data.

When a client wants to stop getting data, it can call
:meth:`RTVChannel.set_state` to just deactivate the channel, or
:meth:`~pybarst.core.server.BarstChannel.close_channel_server` to delete
the channel from the server altogether.
:meth:`~pybarst.core.server.BarstChannel.close_channel_client` is not
supported, and if it is called,
:meth:`~pybarst.core.server.BarstChannel.close_channel_server` will have to be
called before :meth:`RTVChannel.open_channel` can be called again.
'''

__all__ = ('RTVChannel', )

from pybarst.rtv._rtv import RTVChannel
