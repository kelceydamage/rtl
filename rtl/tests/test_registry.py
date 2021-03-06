#! /usr/bin/env python
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
"""Pytest module for testing the rtl.transport.registry module."""


# Imports
# ------------------------------------------------------------------------ 79->
from types import ModuleType
from rtl.transport.registry import import_tasks


# Functions
# ------------------------------------------------------------------------ 79->
def test_registry_valid_module():
    """Test importing module functions using a valid module name. Ensure a dict
    is returned with values of ModuleType.

    """
    result = import_tasks('rtl.tasks.*')
    assert isinstance(result, dict)
    assert isinstance(result[list(result.keys())[0]], ModuleType)


def test_registry_invalid_module():
    """Test importing module functions using an invalid module name. Ensure an
    empty dict is returned.

    """
    result = import_tasks('bob.*')
    assert isinstance(result, dict)
    assert not result


def test_registry_valid_path():
    """Test importing module functions using a valid path. Ensure a dict
    is returned with values of ModuleType.

    """
    result = import_tasks('rtl/tasks')
    assert isinstance(result, dict)
    assert isinstance(result[list(result.keys())[0]], ModuleType)


# Main
# ------------------------------------------------------------------------ 79->
