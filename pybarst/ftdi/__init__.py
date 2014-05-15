'''
The Barst FTDI interface. An FTDI channel is a FT device, e.g. the FT2232H
which has one or more ports on the device. Each port has a number of digital
input / output lines that can be controlled independently.

When a FTDI channel is created, we describe the devices connected to these
ports, which could anything from a ADC, to a serial / parallel converter to
simple digital input / output pins. The :class:`FTDISettings` sub-classes
are used to initialize these devices.
'''

__all__ = ('FTDISettings', 'FTDIChannel', 'FTDIDevice')

from pybarst.ftdi._ftdi import FTDIChannel, FTDIDevice, FTDISettings
