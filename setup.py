from setuptools import setup, find_packages
from setuptools.extension import Extension
import Cython.Compiler.Options
#Cython.Compiler.Options.annotate = True
from Cython.Distutils import build_ext
import os
from os.path import join, sep, dirname, basename, abspath, isdir
from os import listdir
import pybarst


includes = [join(os.environ["ProgramFiles"], 'Barst', 'api')]
if 'BARST_INCLUDE' in os.environ:
    includes.insert(0, os.environ['BARST_INCLUDE'])


sources = ['core/server.pyx',
           'core/exception.pyx',
           'ftdi/_ftdi.pyx',
           'ftdi/switch.pyx',
           'ftdi/adc.pyx',
           'rtv/_rtv.pyx',
           'serial/_serial.pyx',
           'mcdaq/_mcdaq.pyx'
           ]

dependencies = {
    'core/server.pyx': ['core/exception.pyx', 'core/server.pxd'],
    'ftdi/_ftdi.pyx': ['core/server.pyx', 'core/exception.pyx',
                      'ftdi/_ftdi.pxd'],
    'ftdi/switch.pyx': ['ftdi/_ftdi.pyx', 'core/exception.pyx',
                        'ftdi/switch.pxd'],
    'ftdi/adc.pyx': ['ftdi/_ftdi.pyx', 'core/exception.pyx',
                        'ftdi/adc.pxd'],
    'rtv/_rtv.pyx': ['core/server.pyx', 'core/exception.pyx', 'rtv/_rtv.pxd'],
    'serial/_serial.pyx': ['core/server.pyx', 'core/exception.pyx',
                           'serial/_serial.pxd'],
    'mcdaq/_mcdaq.pyx': ['core/server.pyx', 'core/exception.pyx',
                           'mcdaq/_mcdaq.pxd']}


def get_modulename_from_file(filename):
    filename = filename.replace(sep, '/')
    pyx = '.'.join(filename.split('.')[:-1])
    pyxl = pyx.split('/')
    while pyxl[0] != 'pybarst':
        pyxl.pop(0)
    if pyxl[1] == 'pybarst':
        pyxl.pop(0)
    return '.'.join(pyxl)


def expand(*args):
    return abspath(join(dirname(__file__), 'pybarst', *args))


def get_dependencies(name, deps=None):
    if deps is None:
        deps = []
    for dep in dependencies.get(name, []):
        if dep not in deps:
            deps.append(dep)
            get_dependencies(dep, deps)
    return deps


def resolve_dependencies(fn):
    deps = []
    get_dependencies(fn, deps)
    get_dependencies(fn.replace('.pyx', '.pxd'), deps)
    return [expand(x) for x in deps]


def get_extensions_from_sources(sources):
    ext_modules = []
    for pyx in sources:
        depends = resolve_dependencies(pyx)
        pyx = expand(pyx)
        module_name = get_modulename_from_file(pyx)
        ext_modules.append(Extension(module_name, [pyx], depends=depends,
                                     include_dirs=includes, language="c++"))
    return ext_modules

ext_modules = get_extensions_from_sources(sources)

for e in ext_modules:
    e.cython_directives = {'embedsignature': True,
                           'c_string_encoding': 'utf-8'}

with open('README.rst') as fh:
    long_description = fh.read()


def get_wheel_data():
    data = []
    bin = os.environ.get('PYBARST_BINARIES')
    if bin and isdir(bin):
        data.append(
            ('share/pybarst/bin', [join(bin, f) for f in listdir(bin)]))
    return data

setup(
    name='PyBarst',
    version=pybarst.__version__,
    author='Matthew Einhorn',
    author_email='moiein2000@gmail.com',
    license='MIT',
    description='An interface to Barst.',
    url='http://matham.github.io/pybarst/',
    long_description=long_description,
    classifiers=['License :: OSI Approved :: MIT License',
                 'Topic :: Scientific/Engineering',
                 'Topic :: System :: Hardware',
                 'Programming Language :: Python :: 2.7',
                 'Programming Language :: Python :: 3.3',
                 'Programming Language :: Python :: 3.4',
                 'Programming Language :: Python :: 3.5',
                 'Operating System :: Microsoft :: Windows',
                 'Intended Audience :: Developers'],
    ext_modules=ext_modules,
    data_files=get_wheel_data(),
    cmdclass={'build_ext': build_ext},
    packages=find_packages(),
    setup_requires=['cython']
    )
