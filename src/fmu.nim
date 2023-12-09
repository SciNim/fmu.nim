import lib/defs/[definitions, masks, modelinstance, parameters]
export definitions, masks, modelinstance, parameters


import lib/fmu/[model, fmubuilder]
export fmubuilder, model

import std/logging

var consoleLogger* = newConsoleLogger(fmtStr="[$time] - $levelname: ")




