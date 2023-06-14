#import system, std/[os, osproc, strformat]
import std/strformat
import lib/fmu/[model, folder, compress]
export model, folder, compress

import lib/defs/[definitions, masks, modelinstance, parameters]
export definitions, masks, modelinstance, parameters

template model*(guid:string; body:untyped) {.dirty.} =
    ## organize the code, keeping the required includes at the end
    #const
      #MODEL_GUID* = guid

    template testGUID* =
      if not ($fmuGUID == guid ): #strcmp(fmuGUID, MODEL_GUID)) {
          functions.logger( functions.componentEnvironment, 
                            instanceName, fmi2Error, "error".fmi2String,
                            fmt"fmi2Instantiate: Wrong GUID {$fmuGUID}. Expected {guid}.".fmi2String)
          return nil
      
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


