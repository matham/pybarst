
See http://matham.github.io/pybarst/index.html for complete documentation.

This project provides a python interface to the Barst server project.
Barst is a server which provides access to commonly used hardware in the lab,
e.g. FTDI USB devices, RTV cameras, serial ports etc.

Typically, there's a single server instance, on a local or remote computer.
Through this interface you make requests to the server, e.g. for it to create
channels, configure them, and read / write to them.


Installation
============

To install, clone the repo and run make / make force which will run the
cython and c/c++ compilers. In order for the compilation to complete
successfully cython and the c/c++ compiler must know the path to the
barst public headers. You can provide that path with the `BARST_INCLUDE`
environmental variables, e.g. `set BARST_INCLUDE=path_to_headers` on windows.
By default, the program also looks for the headers in
`\ProgramFiles\Barst\api`.
