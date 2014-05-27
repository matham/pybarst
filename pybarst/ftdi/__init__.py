'''
FTDI Channel
============

The Barst FTDI interface. An FTDI channel is a FT device, e.g. the FT2232H
which has one or more ports on the device. Each port has a number of digital
input / output lines that can be controlled independently.

When a FTDI channel is created, we describe the devices connected to these
ports, which could anything from a ADC, to a serial / parallel converter to
simple digital input / output pins. The :class:`FTDISettings` sub-classes
are used to initialize these devices.

Driver requirements
--------------------

In order to create ftdi channels, the ftdi D2XX drivers
(http://www.ftdichip.com/Drivers/D2XX.htm) must be installed. In
particular, the server dynamically loads the `ftd2xx.dll` dll from the
system path. The server automatically loads the 64 or 32-bit version,
depending on whether the server is 32 or 64-bit.

If driver errors arise, either, the driver is not installed, an older version
of the driver is installed, or the incorrect 64/32-bit version is installed.


Typical usage
--------------

The FTDI channel is different than other channels. For the
:class:`FTDIChannel`, instead of operating on the channel directly, one
initializes the channel with :class:`FTDISettings` derived classes
indicating which *peripheral* :class:`FTDIDevice` derived devices are
connected to the :class:`FTDIChannel`, and those :class:`FTDIDevice` devices
are manipulated, not the :class:`FTDIChannel` itself.

So typically, a client creates a :class:`FTDIChannel` and passes it a list
of :class:`FTDISettings` indicating which peripherals are connected to the
:class:`FTDIChannel`. Then, the client calls :meth:`FTDIChannel.open_channel`
on it, which creates the channel and all its peripherals on the server
as well as in the clients :attr:`FTDIChannel.devices`.
At that point, other clients can create :class:`FTDIChannel` instances,
which will automatically have their peripherals initialized.

When created, the peripherals themselves are not yet open, so each client
has to call :meth:`~pybarst.core.server.BarstChannel.open_channel` on the
peripherals it wants to communicate with first. Following that, a client
can set the global state to active/inactive with
:meth:`~pybarst.core.server.BarstChannel.set_state` and then start
reading/writing to them. Some peripherals support multiple clients reading
and/or writing  to them at the same time, while others don't. Some
devices support modes where the server continuously reads and sends back
data to all the clients that subscribed to the channel.

When a client wants to stop getting data, it can call
:meth:`~pybarst.core.server.BarstChannel.set_state` to just deactivate the
channel, or :meth:`~pybarst.core.server.BarstChannel.close_channel_server` to
delete the channel from the server altogether, or,
:meth:`~pybarst.core.server.BarstChannel.close_channel_client` to just close
the connection for this client, while leaving the channel's state on the
server unchanged.

Finally, some peripherals support the
:meth:`~pybarst.core.server.BarstChannel.cancel_read` method, to cancel
a continuous read triggered by this client.

.. warning::
    An FTDI channel supports the activation and deactivation of its
    peripherals independently of each other. When a peripheral is activated,
    the FTDI channel may change it hardware settings to run as efficiently as
    possible. As a consequence, the state of the internal buffers may
    be interrupted. In particular, it's not recommended to change the state
    of any peripheral while an :class:`~pybarst.ftdi.adc.FTDIADC` is actively
    sampling because it will disrupt the device.
'''

__all__ = ('FTDISettings', 'FTDIChannel', 'FTDIDevice')

from pybarst.ftdi._ftdi import FTDIChannel, FTDIDevice, FTDISettings
