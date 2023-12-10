import definitions, parameters
import std/[macros, tables]
import options

{.push exportc, dynlib, cdecl.}
type

  fmi2CallbackLogger*        = proc( c: fmi2ComponentEnvironment,
                                     instanceName: fmi2String,
                                     status: fmi2Status,
                                     category: fmi2String, 
                                     message: fmi2String) {.varargs, cdecl.}
  fmi2CallbackAllocateMemory* = proc(nobj: cuint, size: cuint) {.cdecl.}
  fmi2CallbackFreeMemory*  = proc(obj: pointer) {.cdecl.}
  fmi2StepFinished*  = proc(componentEnvironment: fmi2ComponentEnvironment, 
                            status: fmi2Status) {.cdecl.}
  
  fmi2CallbackFunctions*  {.byref.} = object 
    logger*: fmi2CallbackLogger
    allocateMemory*: fmi2CallbackAllocateMemory
    freeMemory*: fmi2CallbackFreeMemory
    stepFinished*: fmi2StepFinished
    componentEnvironment*: fmi2ComponentEnvironment 

type
  FmuObj* = object of RootObj
    id*: string
    guid*: string
    parameters*:OrderedTable[string, Param]
    sourceFiles*: seq[string]
    docFiles*:seq[string]
    icon*:string
    nEventIndicators*:int

    time*: fmi2Real

    state*: ModelState    
    states*:seq[int]  

    eventInfo*: fmi2EventInfo

    `type`*: fmi2Type
    instanceName*: fmi2String  # Yo me lo cargaba

    logCategories*: set[LoggingCategories] # bit fields

    functions*: fmi2CallbackFunctions
    componentEnvironment*: fmi2ComponentEnvironment
    loggingOn*: fmi2Boolean

    isDirtyValues*: fmi2Boolean

    isNewEventIteration*: fmi2Boolean

    nimFile*:string # Stores the filename of the model
    # values
    nIntegers*:int = 0
    nFloats*:int   = 0    
    nBooleans*:int = 0
    nStrings*:int  = 0
    
    reals*:seq[string]    = @[]
    integers*:seq[string] = @[]
    booleans*:seq[string] = @[]
    strings*:seq[string]  = @[]

    # functions
    #calculateValues*: proc(obj: FmuObj) 

  FmuRef* = ref FmuObj

  Fmu* = concept x 
    x of FmuRef

{.pop.}


proc getReal*(fmu: FmuRef; n:int):float =
  fmu.parameters[fmu.reals[n]].valueR
  #fmu.parameters[name].startI = some(val)

proc setReal*[I:int|fmi2ValueReference](fmu: FmuRef; n:I; value:float) =
  fmu.parameters[fmu.reals[n]].valueR = value

proc setInteger*[I:int|fmi2ValueReference](fmu: FmuRef; n:I; value:int) =
  fmu.parameters[fmu.integers[n]].valueI = value

proc getInteger*[I:int|fmi2ValueReference](fmu: FmuRef; n:I): int =
  fmu.parameters[fmu.integers[n]].valueI


proc getBoolean*[I:int|fmi2ValueReference](fmu: FmuRef; n:I): bool =
  fmu.parameters[fmu.booleans[n]].valueB


proc setBoolean*[I:int|fmi2ValueReference](fmu: FmuRef; n:I; value:bool) =
  fmu.parameters[fmu.booleans[n]].valueB = value  

proc getString*[I:int|fmi2ValueReference](fmu: FmuRef; n:I): string =
  fmu.parameters[fmu.strings[n]].valueS


# Adding parameters to the model
proc addFloat*(fmu:FmuRef; name:string):Param {.discardable.} =
  fmu.parameters[name] = Param(kind: tReal)
  fmu.reals &= name
  fmu.parameters[name].idx = fmu.reals.len - 1
  # Defaults
  fmu.parameters[name].initial = iUnset
  return fmu.parameters[name]

proc addInteger*(fmu:FmuRef; name:string):Param {.discardable.} =
  fmu.parameters[name] = Param(kind: tInteger)
  fmu.integers &= name
  fmu.parameters[name].idx = fmu.integers.len - 1
  # Defaults
  fmu.parameters[name].initial = iUnset
  return fmu.parameters[name]  

proc addBoolean*(fmu:FmuRef; name:string):Param {.discardable.} =
  fmu.parameters[name] = Param(kind: tBoolean)
  fmu.booleans &= name
  fmu.parameters[name].idx = fmu.booleans.len - 1
  # Defaults
  fmu.parameters[name].initial = iUnset
  return fmu.parameters[name] 

proc addString*(fmu:FmuRef; name:string):Param {.discardable.}  =
  fmu.parameters[name] = Param(kind: tString)
  fmu.strings &= name
  fmu.parameters[name].idx = fmu.strings.len - 1
  # Defaults
  fmu.parameters[name].initial = iUnset
  return fmu.parameters[name] 

# Setting causality
proc setParameter*(p: Param):Param {.discardable.} =
  ##[
  Independent parameter(a data value that is constant during the simulation and
  is provided by the environment and cannot be used in connections).

  variability must be "fixed"or "tunable". initial must be exactor not present
  (meaning exact).
  ]##  
  p.causality = cParameter
  return p

proc setCalculatedParameter*(p: Param):Param {.discardable.} =
  ##[
  A data value that is constant during the simulation and is computed during
  initialization or when tunable parameters change.
  variability must be "fixed"or "tunable". initialmust be "approx",
  "calculated"or not present (meaning calculated).
  ]##  
  p.causality = cCalculatedParameter
  return p


proc setInput*(p: Param):Param {.discardable.} =
  ##[
  The variable value can be provided from another modelor slave. It is not
  allowed to define initial.
  ]##  
  p.causality = cInput
  return p


proc setOutput*(p: Param):Param {.discardable.} =
  ##[
  The variable value can be used by another modelor slave. The algebraic
  relationship to the inputs is defined via thedependenciesattribute of
  <fmiModelDescription><ModelStructure><Outputs><Unknown>.
  ]##  
  p.causality = cOutput
  return p

proc setLocal*(p:Param):Param {.discardable.} =
  ##[
  Local variable that is calculated from other variables or is a
  continuous-time state(see section2.2.8). It is not allowed to use the
  variable value in another modelor slave.
  ]##
  p.causality = cLocal
  return p


proc setIndependent*(p:Param):Param {.discardable.} =
  ##[
  The independent variable (usually “time”). All variables are a function
  of this independent variable. variabilitymust be "continuous". At mostone
  ScalarVariableof an FMU canbe defined as "independent". If no variable is
  defined as "independent", it is implicitly present with name = "time" and
  unit = "s". If one variable is defined as "independent", it must be defined
  as "Real"without a"start"attribute.It is not allowed to call function
  fmi2SetRealon an "independent"variable. Instead, its value isinitialized
  with fmi2SetupExperimentand after initialization set by fmi2SetTime for
  ModelExchange and by arguments currentCommunicationPointand
  communicationStepSizeof fmi2DoStepfor CoSimulation.
  [The actual value can be inquired withfmi2GetReal.]
  ]##
  p.causality = cIndependent
  return p

# Setting variability
proc setConstant*(p:Param):Param {.discardable.} =
  ## "constant": The value of the variable never changes.
  p.variability = vConstant
  return p


proc setFixed*(p:Param):Param {.discardable.} =
  ##[
  "fixed": The value of the variable is fixedafter initialization, in other
  words,after fmi2ExitInitializationModewas calledthe variable value
  does notchange anymore.
  ]##
  p.variability = vFixed
  return p


proc setTunable*(p:Param):Param {.discardable.}  =
  ##[
  "tunable": The value of the variable is constant between external
  events(ModelExchange) and between Communication Points(Co-Simulation) due
  to changing variables with causality = "parameter" or "input" and
  variability = "tunable". Whenever a parameter or inputsignal with
  variability = "tunable" changes, an event is triggered externally
  (ModelExchange),or the change is performed at the next Communication
  Point (Co-Simulation) and the variables with variability = "tunable" and
  causality = "calculatedParameter"or "output"must be newly computed.
  ]##  
  p.variability = vTunable
  return p


proc setDiscrete*(p:Param):Param {.discardable.} =
  ##[
  "discrete": ModelExchange: The value of the variable is constant between
  external and internalevents(= time, state, step events defined implicitly
  in the FMU).Co-Simulation: By convention, the variable is from a “real”
  sampled data system and its value is only changed at Communication Points
  (also inside the slave).
  ]##  
  p.variability = vDiscrete
  return p


proc setContinuous*(p:Param):Param {.discardable.} =
  ##[
  "continuous": Only a variable of type = “Real”
  can be “continuous”. ModelExchange: No restrictions on value changes.
  Co-Simulation: By convention, the variable is from a differential
  ]##  
  p.variability = vContinuous
  return p

# Set initial
proc setUnset*(p:Param):Param {.discardable.} =
  # I have invented this as default
  p.initial = iUnset  # default
  return p


proc setExact*(p:Param):Param {.discardable.}=
  ##[
  The variable is initialized with the start value(provided under Real,
  Integer, Boolean, String or Enumeration)
  ]##
  p.initial = iExact
  return p

proc setApprox*(p:Param):Param {.discardable.} =
  ##[
  The variable is an iteration variable of an algebraic loop and the
  iteration at initialization starts with the startvalue.
  ]##
  p.initial = iApprox
  return p


proc setCalculated*(p:Param):Param {.discardable.} =
  ##[
  The variable is calculated from other variables during initialization.
  It is not allowed to provide a "start" value.
  ]##
  p.initial = iCalculated
  return p


# Description
proc setDescription*(p:Param; description: string):Param {.discardable.} =
  p.description = description
  return p



# 
proc `[]`*(fmu:FmuRef; name:string): Param =
  ## getting a parameter from the model
  fmu.parameters[name]

proc getReal*(fmu:FmuRef; name:string):float =
  return fmu.parameters[name].valueR

proc `+`*(p:Param; value:int):int =
  return p.valueI + value

proc `-`*(p:Param; value:int):int =
  return p.valueI - value

proc `*`*(p:Param; value:int):int =
  return p.valueI * value

proc `/`*(p:Param; value:int):int =
  return (p.valueI / value).int

proc `==`*(p:Param; value:int):bool =
  return p.valueI == value

proc `+=`*(p:Param; value:int) =
  p.valueI = p.valueI + value

# FIXME: ------------------------------------- 


# Setter
proc `[]=`*(fmu:FmuRef; name:string; value:int) =
  fmu.parameters[name].valueI = value

proc `[]=`*(fmu:FmuRef; name:string; value:float) =
  fmu.parameters[name].valueR = value

proc `[]=`*(fmu:FmuRef; name:string; value:bool) =
  fmu.parameters[name].valueB = value

proc `[]=`*(fmu:FmuRef; name:string; value:string) =
  fmu.parameters[name].valueS = value

# proc `[]`*(fmu:FmuRef; name:string): int =
#   fmu.parameters[name].startI.get

# proc `[]=`*(fmu:FmuRef; name:string; val:int) =
#   fmu.parameters[name].startI = some(val)