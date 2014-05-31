
See http://matham.github.io/pybarst/index.html for the complete documentation.

This project provides a python interface to the Barst server project.
Barst is a server which provides access to commonly used hardware in the lab,
e.g. FTDI USB devices, RTV cameras, serial ports etc.

Typically, there's a single server instance, on a local or remote computer.
Through this interface you make requests to the server, e.g. for it to create
channels, configure them, and read / write to them.
