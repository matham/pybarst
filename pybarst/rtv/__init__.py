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
'''

__all__ = ('RTVChannel', )

from pybarst.rtv._rtv import RTVChannel
