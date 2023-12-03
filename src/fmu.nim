#import system, std/[os, osproc, strformat]
#import std/[options] # strformat, 
#export options
#import lib/fmu/[folder, compress, xml]
#export model
#export model, folder, compress, xml

import lib/defs/[definitions, masks, modelinstance, parameters]
export definitions, masks, modelinstance, parameters

# import lib/fmu/[model]
# export model


template model*(fmu:FmuRef, body:untyped) {.dirty.} =
  ## organize the code, keeping the required includes at the end

  {.push exportc, dynlib.}

  body

  {.pop.}

  fmu.nimFile = instantiationInfo().filename
  include lib/functions/modelexchange
  include lib/functions/cosimulation
  include lib/functions/common
  include lib/functions/setters
  include lib/functions/instantiate 
  genFmi2Instantiate(fmu)   
  include lib/functions/freeinstance
  include lib/functions/debuglogging    
  include lib/functions/getters
  include lib/functions/enquire


    # ------- FMU BUILDER----------------------------------------
    # The following is only compiled if called as main module
  when isMainModule and not compileOption("app", "lib"):
    import lib/fmubuilder
    
    #myModel.genFmu2(m.outFile, callingFile)
    fmu.exportFmu()
