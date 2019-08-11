#!/usr/bin/env python
# ------------------------------------------------------------------------ 79->
# Author: ${name=Kelcey Damage}
# Python: 3.5+
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
"""
Dependancies:
    rtl.transport
    rtl.common
    multiprocessing
    argparse
    time
    os

"""
# Imports
# ------------------------------------------------------------------------ 79->
import os
import argparse
import time
from multiprocessing import Process
from rtl.transport.registry import import_tasks
from rtl.transport.node import TaskNode
from rtl.transport.node import PlotNode
from rtl.transport.relay import Relay
from rtl.transport.conf import configuration as conf
from rtl.common.print_helpers import Colours
from rtl.common.logger import log


# Globals
# ------------------------------------------------------------------------ 79->
RUNDIR = os.path.expanduser(conf.PIDFILES)
COLOURS = Colours()
NODES = {
    'relay': Relay,
    'task': TaskNode,
    'plot': PlotNode
}
COUNTS = {
    'relay': 1,
    'task': conf.TASK_WORKERS,
    'plot': conf.PLOT_WORKERS
}


# Classes
# ------------------------------------------------------------------------ 79->
class StartError(Exception):
    """Micro-service failed to start"""

    def __init__(self, error):
        super(StartError, self).__init__()
        self.error = error


# Functions
# ------------------------------------------------------------------------ 79->
def embedded_parser():
    """Parser as a function for better test cases

    Returns:
        argparser args

    """
    parser = argparse.ArgumentParser(prog="Task Engine")
    group = parser.add_argument_group('Extras')
    group.add_argument(
        '-m',
        "--meta",
        action="store_true",
        default=False,
        help="Print meta header"
        )
    group.add_argument(
        '-n',
        "--no-server",
        action="store_true",
        default=False,
        help="do not start server loop"
        )
    return parser.parse_known_args()[0]


def print_meta(functions):
    """Print the loaded tasks to the console.

    Args:
        functions (dict): The dict of task modules the platform has loaded
            into memory and stored as a reference.

    Returns:
        bool: True for testing.

    """
    print('-' * 79)
    print('REGISTERED-TASKS:')
    print('-' * 79)
    for key in functions.keys():
        print(' {0}{1}__{2} {3}{4}{2}'.format(
            COLOURS.BCYAN,
            COLOURS.BLACK,
            COLOURS.ENDC,
            COLOURS.LIGHTBLUE,
            key
            ))
    print('-' * 79)
    return True


def launcher():
    """Main loop for lanching services.

    Returns:
        bool: True if all services launched successfully, False otherwise.

    """
    for service in COUNTS:
        log('Launching {0}'.format(service.upper()))
        success = launch(NODES[service], COUNTS[service])
    return success


def launch(service_class, count):
    """Call startNode on each service and check for exceptions.

    Args:
        service (str): The short name for the micro-service to be started.

    Returns:
        bool: True if all services launched successfully, False otherwise.

    """
    try:
        start_node(service_class, count)
    except StartError:
        return False
    return True


def start_node(service_class, count):
    """Start a subprocess for each micro-service

    Args:
        service (str): The short name for the micro-service to be started.

    """
    if count == 0:
        raise StartError('Invalid count, can not launch 0 services')
    for _ in range(count):
        process = Process(
            target=service_wrapper,
            args=[service_class]
        )
        process.daemon = True
        process.start()


def service_wrapper(service_class):
    """Call start on the the service inside the process.

    Args:
        service_class (class): The reference to the class to be started in this
            subprocess.

    Raise:
        StartError: if service failes to start.

    """
    try:
        service_class().start()
    except Exception as error:
        raise StartError(error)


def main(args):
    """Main function and entrypoint

    Args:
        server (bool): Default to true, pass False for tests.

    Returns:
        bool: True if code completes without error, and in test mode.

    """
    pid = os.getpid()
    functions = import_tasks(conf.TASK_LIB)
    if args.meta:
        print_meta(functions)
        exit(1)
    if not launcher():
        print('Failed to launch one or more micro-services')
        exit(1)
    print('Starting RTL')
    with open('{0}{1}-{2}'.format(RUNDIR, 'master', pid), 'w+') as file:
        file.write(str(pid))
    if args.no_server:
        print('hit')
        return True
    while True:
        time.sleep(1000)


# Main
# ------------------------------------------------------------------------ 79->
if __name__ == '__main__':  # pragma: no cover
    main(embedded_parser())
