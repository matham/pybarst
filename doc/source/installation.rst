Installation
=============

.. _requirements:

Requirements
--------------

Since PyBarst is a python client, no drivers are required to be
installed on the system. However, drivers need to be installed on the system
that runs the server.

PyBarst
++++++++

To use PyBarst, the following software is required:

#.  Python. Although it should work with version 3 of python, it has only been
    tested with Python 2.7.
#.  A C++ compiler. It has been tested only with the MinGW G++ compiler.
    The compiler needs to be in the system path so that we can find it
    when compiling.
#.  The Barst server header file, ``cpl defs.h``. By default, the system looks
    for this file in ``C:\Program Files\Barst\api`` (or
    ``C:\Program Files (x86)\Barst\api`` if running from 32 bit python).
    However, the path to the file can be specified by setting the environmental
    variable ``BARST_INCLUDE``, to that path.

Although it has only been tested on Windows, PyBarst should be to run on any
system that runs python.

Barst Server
+++++++++++++

PyBarst is only a client to a Barst server. To run a Barst server, one
simply launches the pre-compiled Barst exe file directly with the proper
parameters or one can launch it from PyBarst. The Barst server itself, however,
only runs on Windows from XP and above.


Installing it
-------------

.. _install-pybarst:

PyBarst
++++++++

PyBarst is written in python using cython. Cython is a project that converts
python code to c. Therefore, before using PyBarst one must compile it with
cython and a c compiler. Luckily, if a c compiler is installed on your
system it should all be automatically compiled.

First, you can download PyBarst directly from github using::

    git clone https://github.com/matham/pybarst.git pybarst

if you have git installed. Or getting the zip directly at
https://github.com/matham/pybarst/archive/master.zip and extracting it.

Once it's downloaded, from the command line you change the current directory
to the folder where PyBarst is extracted and run::

    python setup.py install

This will compile and and install PyBarst to your preinstalled python path.
Alternatively, to just compile PyBarst and not install it to Python, from
the command line while in that folder type ``make`` or ``make force``.

.. _install-barst:

Barst
++++++

To install Barst, simply copy the Barst.exe file to your desired location,
a good path is ``C:\Program Files\Barst\`` for the 64-bit version and
``C:\Program Files (x86)\Barst\`` for the 32-bit version.

To run the server
you can either provide the path to PyBarst in :class:`~pybarst.core.BarstServer`
and have PyBarst launch it if it's local, or manually start it from the command
line by typing::

    start "" "C:\Program Files\Barst\Barst.exe" "\\.\pipe\PipeName" 1024 1024 -1

Where ``C:\Program Files\Barst\Barst.exe`` is the full path to Barst and
``PipeName`` is the pipe name that this server will have.

Alternatively, you can create a file called ``autostart.bat`` and in it put::

    @ECHO OFF
    start "" "C:\Program Files\Barst\Barst.exe" "\\.\pipe\PipeName" 1024 1024 -1

Running this file will start the Barst server.

Furthermore, you can place this ``autostart.bat`` file in this path:
``%AppData%\Microsoft\Windows\Start Menu\Programs\Startup\`` and Windows
will automatically launch the server whenever Windows starts.

Drivers
++++++++

In order to be able to create channels of specific types, the drivers for
those channels must be installed on the system running the Barst server.
See the individual PyBarst channels for their requirements.

Testing
--------

All channels come with tests that can be run on them. You can find them under
``pybarst/tests/``. To run them, make sure that the hardware is connected as
described in that file, and then just run it with ``python filename.py``.
