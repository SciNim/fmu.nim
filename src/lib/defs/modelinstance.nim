import definitions
{.push exportc, dynlib,cdecl.}

type
  fmi2CallbackLogger*  = proc( a1: fmi2ComponentEnvironment,
                               a2: fmi2String,
                               a3: fmi2Status,
                               a4: fmi2String, a5: fmi2String) 
  fmi2CallbackAllocateMemory* = proc(a1: cuint, a2: cuint) #{.cdecl.}
  fmi2CallbackFreeMemory*  = proc(a1: pointer) #{.cdecl.}
  fmi2StepFinished*  = proc(a1: fmi2ComponentEnvironment, a2: fmi2Status) #{.cdecl.}


  fmi2CallbackFunctions* = ref object #{.impfmuTemplate, bycopy.} = object
    logger*: fmi2CallbackLogger
    allocateMemory*: fmi2CallbackAllocateMemory
    freeMemory*: fmi2CallbackFreeMemory
    stepFinished*: fmi2StepFinished
    componentEnvironment*: fmi2ComponentEnvironment

  #fmi2CallbackFunctions* = pointer

type
  ModelInstanceObj* = object
    r*: ptr UncheckedArray[fmi2Real]
    i*: ptr UncheckedArray[fmi2Integer] 
    b*: ptr UncheckedArray[fmi2Boolean]
    s*: ptr UncheckedArray[fmi2String]
    isPositive*: ptr UncheckedArray[fmi2Boolean]
    time*: fmi2Real
    instanceName*: fmi2String
    `type`*: fmi2Type
    GUID*: fmi2String
    functions*: fmi2CallbackFunctions
    loggingOn*: fmi2Boolean
    logCategories*: array[4, fmi2Boolean]  # FIXME: NUMBER_OF_CATEGORIES
    componentEnvironment*: fmi2ComponentEnvironment
    state*: ModelState
    eventInfo*: fmi2EventInfo
    isDirtyValues*: fmi2Boolean
    isNewEventIteration*: fmi2Boolean

  ModelInstance* = ref ModelInstanceObj
{.pop.}