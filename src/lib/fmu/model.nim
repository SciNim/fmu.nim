import std/[os,osproc, strformat]
import ../defs/[definitions, modelinstance, parameters]

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




