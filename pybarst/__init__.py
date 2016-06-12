'''
PyBarst
=======

Multi-threading
-----------------
Within an instance, a pybarst device instance is not multi-thread safe.
However, they are safe across instances.


.. note::
    When specifying parameters in constructors of classes defined in this
    project, always specify them as keywords arguments, not positional
    arguments.
'''
import sys
import os
from os.path import join, isdir

__all__ = ('dep_bins', )

__version__ = '2.1-dev'

__min_barst_version__ = 20000

dep_bins = []
'''A list of paths to the binaries used by the library. It can be used during
packaging for including required binaries.

It is read only.
'''

_pybarst = join(sys.prefix, 'share', 'pybarst', 'bin')
if isdir(_pybarst):
    os.environ["PATH"] += os.pathsep + _pybarst
    dep_bins.append(_pybarst)
