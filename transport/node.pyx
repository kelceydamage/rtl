#!python
#cython: language_level=3, cdivision=True
###boundscheck=False, wraparound=False //(Disabled by default)
# ------------------------------------------------------------------------ 79->
# Author: Kelcey Damage
# Cython: 0.28+
# Doc
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Doc
# ------------------------------------------------------------------------ 79->
# Dependancies:
#                   zmq
#                   lmdb
#                   tasks
#                   common
#                   numpy
#                   libcpp.string
#                   libcpp.uint_fast16_t
#
# Imports
# ------------------------------------------------------------------------ 79->

# Python imports
import zmq
import lmdb
from os import getpid
from tasks import *
from numpy import frombuffer
from subprocess import check_output
from common.datatypes cimport Envelope
from transport.conf.configuration import TASK_WORKERS
from transport.conf.configuration import CACHE_PATH
from transport.conf.configuration import CACHE_MAP_SIZE
from transport.conf.configuration import RELAY_ADDR
from transport.conf.configuration import RELAY_SEND
from transport.conf.configuration import RELAY_RECV
from transport.conf.configuration import CACHE_LISTEN
from transport.conf.configuration import CACHE_RECV

# Cython imports
cimport cython
from numpy cimport ndarray
from libcpp.string cimport string
from libc.stdint cimport uint_fast16_t

# Globals
# ------------------------------------------------------------------------ 79->

VERSION = '2.0a'

# Classes
# ------------------------------------------------------------------------ 79->


cdef class Node:
    """
    NAME:           Node

    DESCRIPTION:    Base class for transport nodes.

    METHODS:        .recv()
                    Receive sealed envelop from relay and returns an Envelope()
                    object.

                    .send(envelope)
                    Sends a sealed envelope to the relay.

                    .start()
                    Starts the node and begins requesting sealed envelopes.
    """

    def __init__(self):
        self.pid = getpid()
        self._context = zmq.Context()
        self.version = VERSION.encode()
        self.header = 'NODE-{0}'.format(self.pid).encode()
        command = ['cat', '/proc/sys/kernel/random/boot_id']
        self.domain_id = check_output(command).decode().rstrip('\n').encode()
        self.envelope = Envelope()

    cdef void recv(self):
        self.envelope.load(self.recv_socket.recv_multipart(), unseal=True)

    cdef void send(self):
        self.send_socket.send_multipart(self.envelope.seal())

    cpdef void start(self):
        while True:
            self.recv()
            if self.envelope.get_lifespan() > 0:
                self.run()
            self.send()


cdef class TaskNode(Node):
    """
    NAME:           TaskNode

    DESCRIPTION:    A task variant of the node, whose role is to execute
                    functions from the registry.

    METHODS:        .run(envelope)
                    Run a specific function from the registry. Which function
                    is determined by the state of the pipeline.
    """

    def __init__(self, functions=''):
        super(TaskNode, self).__init__()
        self.header = 'TASK-{0}'.format(self.pid).encode()
        with open('var/run/{0}'.format(self.header.decode()), 'w+') as f:
            f.write(str(self.pid))
        self.recv_socket = self._context.socket(zmq.PULL)
        self.send_socket = self._context.socket(zmq.PUSH)
        pull_uri = 'tcp://{0}:{1}'.format(RELAY_ADDR, RELAY_SEND)
        push_uri = 'tcp://{0}:{1}'.format(RELAY_ADDR, RELAY_RECV)
        self.recv_socket.connect(pull_uri)
        self.send_socket.connect(push_uri)
        self.functions = functions

    cpdef void run(self):
        cdef:
            ndarray r
            str func = self.functions[self.envelope.meta['tasks'][0]]
            Exception msg

        r = frombuffer(self.envelope.data).reshape(
            self.envelope.get_length(), 
            self.envelope.get_shape()
            )
        try:
            r = eval(func)(self.envelope.meta['kwargs'], r)
        except Exception as e:
            msg = Exception(
                'TASK-EVAL: {0}, {1}'.format(
                    self.envelope['completed'][-1], e
                    )
                )
            print(msg)
            raise msg
        else:
            self.envelope.consume()
        self.envelope.set_data(r)


cdef class CacheNode(Node):
    """
    NAME:           CacheNode

    DESCRIPTION:    A cache variant of the node, whose role is to initialize
                    the cache databse.

    METHODS:        .load_database()
                    Initialize the lmdb database environment.
    """

    def __init__(self, functions=''):
        super(CacheNode, self).__init__()
        self.header = 'CACHE-{0}'.format(self.pid).encode()
        with open('var/run/{0}'.format(self.header.decode()), 'w+') as f:
            f.write(str(self.pid))
        self.recv_socket = self._context.socket(zmq.ROUTER)
        router_uri = 'tcp://{0}:{1}'.format(CACHE_LISTEN, CACHE_RECV)
        self.recv_socket.bind(router_uri)
        self.load_database()

    cpdef void load_database(self):
        self.lmdb = lmdb.Environment(
            path=CACHE_PATH,
            map_size=CACHE_MAP_SIZE,
            subdir=True,
            readonly=False,
            metasync=True,
            # map_async=True,
            sync=True,
            writemap=True,
            readahead=True,
            max_readers=TASK_WORKERS+2,
            max_dbs=0,
            max_spare_txns=TASK_WORKERS+2,
            lock=True,
            create=True
        )


# Functions
# ------------------------------------------------------------------------ 79->

# Main
# ------------------------------------------------------------------------ 79->