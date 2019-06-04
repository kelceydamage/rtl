#!/usr/bin/env python3
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
#
# Imports
# ------------------------------------------------------------------------ 79->
import numpy as np
from common.task import Task

# Globals
# ------------------------------------------------------------------------ 79->

# Classes
# ------------------------------------------------------------------------ 79->
class Difference(Task):

    def __init__(self, kwargs, content):
        super(Difference, self).__init__(kwargs, content)
        self.ndata.setflags(write=1)

    def difference(self):
        for o in self.operations:
            pass
        return self


# Functions
# ------------------------------------------------------------------------ 79->
def task_difference(kwargs, contents):
    Task = Average(
        kwargs['task_difference'],
        contents
    )
    return Task.difference().getContents()

# Main
# ------------------------------------------------------------------------ 79->