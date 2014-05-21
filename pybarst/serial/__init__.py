'''
Serial channel
===============

The Barst serial port interface. A serial channel is an interface to a serial
port, such as a RS232 or RS485 port. See :class:`~pybarst.serial.SerialChannel`
for details.
'''

__all__ = ('SerialChannel', )

from pybarst.serial._serial import SerialChannel
