#import system, std/[os, osproc, strformat]

import lib/fmu/[model, folder, compress]
export model, folder, compress

import lib/defs/[definitions, masks, modelinstance, parameters]
export definitions, masks, modelinstance, parameters

template myCode*(body:untyped) {.dirty.} =
    ## organize the code, keeping the required includes at the end
    {.push exportc, dynlib.}
    body
    {.pop.}

    include lib/functions/modelexchange
    include lib/functions/cosimulation
    include lib/functions/common
    include lib/functions/setters
    include lib/functions/others
    include lib/functions/getters
    include lib/functions/enquire


