#! /usr/bin/env python3
"""Setup for compiling and installing raspi-rtl"""
import platform
import numpy
import zmq
from setuptools import setup
from distutils.extension import Extension


C_OPTIONS = {
    'gpu': False,
}

if 'tegra' in platform.release():
    C_OPTIONS['gpu'] = True

print('Generate config.pxi')
with open('config.pxi', 'w') as fd:
    for k, v in C_OPTIONS.items():
        fd.write('DEF %s = %d\n' % (k.upper(), int(v)))

USE_CYTHON = True

EXT = '.pyx' if USE_CYTHON else '.c'

PYX_FILES = [
    "rtl.common.datatypes",
    "rtl.common.encoding",
    "rtl.common.print_helpers",
    "rtl.common.normalization",
    "rtl.common.regression",
    "rtl.common.transform",
    "rtl.common.task",
    "rtl.transport.relay",
    "rtl.transport.node",
    "rtl.transport.dispatch"
]

EXTENSIONS = []
for i in PYX_FILES:
    EXTENSIONS.append(
        Extension(
            i,
            sources=['{0}{1}'.format(i.replace('.', '/'), EXT)],
            extra_compile_args=['-std=c++11'],
            language="c++"
            )
        )

if USE_CYTHON:
    from Cython.Build import cythonize
    import Cython
    Cython.Compiler.Options.annotate = True
    Cython.Compiler.Options.warning_errors = True
    Cython.Compiler.Options.convert_range = True
    Cython.Compiler.Options.cache_builtins = True
    Cython.Compiler.Options.gcc_branch_hints = True
    Cython.Compiler.Options.embed = False
    EXTENSIONS = cythonize(EXTENSIONS)

setup(
    name='raspi-rtl',
    version='3.0.0.dev1',
    description='Raspi Transport Layer 3',
    author='Kelcey Jamison-Damage',
    author_email='',
    url='https://github.com/kelceydamage/rtl.git',
    download_url='https://github.com/kelceydamage/rtl.git',
    license='http://www.apache.org/licenses/LICENSE-2.0',
    install_requires=[
        "zmq",
        "pyzmq",
        "lmdb",
        "cbor",
        "numpy",
        "cython",
        "sklearn",
        "bokeh"
        # "cupy" for systems with nvcc and CUDA
    ],
    py_modules=[
        'rtl.main',
        'rtl.transport.cache',
        'rtl.transport.registry',
        'rtl.transport.conf.configuration',
        'rtl.common.logger',
        'rtl.tasks.null'
    ],
    packages=[],
    ext_modules=EXTENSIONS,
    include_dirs=[
        numpy.get_include(),
        zmq.get_includes()
    ],
    scripts=[
        'rtl/transport/bin/raspi-rtl',
    ]
)
