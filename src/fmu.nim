#import system, std/[os, osproc, strformat]
#import std/[options] # strformat, 
#export options
#import lib/fmu/[folder, compress, xml]
#export model
#export model, folder, compress, xml

import lib/defs/[definitions, masks, modelinstance, parameters]
export definitions, masks, modelinstance, parameters

template model2*(id,guid, outFile, callingFile: string; 
                 myModel: ModelInstanceRef; 
                 body:untyped) {.dirty.} =
    ## organize the code, keeping the required includes at the end

    {.push exportc, dynlib.}

    body

    {.pop.}

    # FIXME---
    #var NUMBER_OF_INTEGERS*, NUMBER_OF_REALS*, NUMBER_OF_BOOLEANS*, NUMBER_OF_STRINGS*:int = 0
    #var NUMBER_OF_REALS*, NUMBER_OF_BOOLEANS*, NUMBER_OF_STRINGS*:int = 0
    var NUMBER_OF_STRINGS*:int = 0    
    var NUMBER_OF_STATES* {.compileTime.}:int = 0
    var NUMBER_OF_EVENT_INDICATORS*{.compileTime.}:int = 0

    for p in myModel.params:
      var nReals, nBooleans, nStrings: int
      case p.kind
      of tInteger:
        #NUMBER_OF_INTEGERS += 1
        discard
      of tReal:
        #nReals += 1
        discard
      of tBoolean:
        #nBooleans += 1
        discard
      of tString:
        nStrings += 1
    # ----
    #NUMBER_OF_INTEGERS = myModel.integerAddr.len


    include lib/functions/modelexchange
    include lib/functions/cosimulation
    include lib/functions/common
    include lib/functions/setters
    include lib/functions/instantiate    
    include lib/functions/freeinstance
    include lib/functions/debuglogging    
    include lib/functions/getters
    include lib/functions/enquire


    # ------- FMU BUILDER----------------------------------------
    # The following is only compiled if called as main module
    when isMainModule and not compileOption("app", "lib"):
      import lib/fmubuilder
      
      myModel.genFmu2(outFile, callingFile)

template model*(id,guid, outFile: string; body:untyped) {.dirty.} =
  #var NUMBER_OF_INTEGERS*:int
  # needed in order to know the filename calling `genFmu`
  let pos = instantiationInfo() # https://nim-lang.org/docs/system.html#instantiationInfo%2Cint
  var myModel* = ModelInstanceRef(id: `id`, guid: `guid`)  
  model2(id, guid, outFile, pos.filename, myModel, body)