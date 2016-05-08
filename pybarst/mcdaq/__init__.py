'''
MCDAQ channel
===============

The Barst Measurement Computing DAQ device interface. A MC DAQ channel is a
interface to a MC DAQ device, such as a Switch & Sense 8/8 which has 8 input
channels and 8 output channels. See :class:`MCDAQChannel` for details.

This channel only supports MC DAQ devices that have ports that are permenataly
input and/or output, but not those in which a single port can be configured for
input or output.

For example, the Switch & Sense 8/8 has 8 input lines and 8 separate output
lines. There can be a maximum of 16 input and 16 output lines in a single
device. The state of each line can be controlled independently. However, not
all devices must have all 16 lines, e.g. the Switch & Sense 8/8 only has
8 input and 8 output lines.


Driver requirements
--------------------

In order to create MC DAQ channels, the MC InstaCal drivers
(http://www.mccdaq.com/daq-software/instacal.aspx) must be installed. In
particular, the server dynamically loads either `CBW32.dll` or `CBW64.dll`,
depending if the server is a 64-bit or 32-bit compiled binary, respectively
from the system path.

When installing from a wheel, the server comes with these dlls preinstalled.

If driver errors arise, either, the driver is not installed, an older version
of the driver is installed, or the incorrect 64/32-bit version is installed.
The dlls seem to be installed in `C:\Program Files\Measurement Computing\DAQ`.
If this path is not in the system path and the dlls fail to be loaded, one can
manually copy the dlls to the same folder as Barst.exe file, making it
available for Barst.

Finally, in order to be able to use a particular device, that device must
be loaded from `InstaCal` and assigned a channel number. Then channel number
is then used in :class:`MCDAQChannel` to create a :class:`MCDAQChannel` channel
controlling the device.


Typical usage
--------------

For the :class:`MCDAQChannel` channel, once a channel is created on the
server, it's always active. That means that there's no need to set the state
with :meth:`~pybarst.core.server.BarstChannel.set_state`.

Typically, a client creates a :class:`MCDAQChannel` and then calls
:meth:`MCDAQChannel.open_channel` on it to create the
channel on the server. Once created, the client can read and write to it
through the server using :meth:`MCDAQChannel.read` and
:meth:`MCDAQChannel.write`.

Other clients can do similarly; they create a new :class:`MCDAQChannel`
instance and then call :meth:`MCDAQChannel.open_channel` on it to open
a new connection to the existing channel. Those new clients can then read/write
to the channel as well.

Finally, existing clients can call
:meth:`~pybarst.core.server.BarstChannel.close_channel_client` to simply
close this client while leaving the channel on the server, or
:meth:`~pybarst.core.server.BarstChannel.close_channel_server` to delete
the channel from the server as well as for all the clients. If
:attr:`MCDAQChannel.continuous` is `True`, a client can also call
:meth:`MCDAQChannel.cancel_read` to cancel the continuous read triggered by
this client.
'''

__all__ = ('MCDAQChannel', )

from pybarst.mcdaq._mcdaq import MCDAQChannel
