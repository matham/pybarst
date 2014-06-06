'''
PyBarst
========


This project provides a python interface to the Barst server project.
Barst is a server which provides access to commonly used hardware in the lab,
e.g. FTDI USB devices, RTV cameras, serial ports etc.

Typically, there's a single server instance, on a local or remote computer.
Through this interface you make requests to the server, e.g. for it to create
channels, configure them, and read / write to them.


Multi-threading
-----------------
Within a instance, devices are not multi-threaded. However, they are
safe across instances.


.. note::
    When specifying parameters in constructors of classes defined in this
    project, always specify them as keywords arguments, not positional
    arguments.
'''


__version__ = '2.1-dev'

__min_barst_version__ = 20000
