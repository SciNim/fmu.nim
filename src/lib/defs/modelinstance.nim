import definitions, parameters
import std/[macros, tables]
import options


type
  #[
  typedef void      (*fmi2CallbackLogger)        (
    fmi2ComponentEnvironment, 
    fmi2String, 
    fmi2Status, 
    fmi2String, 
    fmi2String, ...);

  ]#   
  fmi2CallbackLogger*  = proc( c: fmi2ComponentEnvironment,
                               instanceName: fmi2String,
                               status: fmi2Status,
                               category: fmi2String, 
                               message: fmi2String) {.varargs.}
  fmi2CallbackAllocateMemory* = proc(a1: cuint, a2: cuint) 
  fmi2CallbackFreeMemory*  = proc(a1: pointer) 
  fmi2StepFinished*  = proc(a1: fmi2ComponentEnvironment, a2: fmi2Status) 

{.push exportc, dynlib, cdecl.}
type
  fmi2CallbackFunctions* = ref object 
    logger*: fmi2CallbackLogger
    allocateMemory*: fmi2CallbackAllocateMemory
    freeMemory*: fmi2CallbackFreeMemory
    stepFinished*: fmi2StepFinished
    componentEnvironment*: fmi2ComponentEnvironment

type
  FmuObj* = object of RootObj
    id*: string
    guid*: string
    #outFile*: string
    #params*:seq[Param] 
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



# type
#   ModelInstance* = object of FmuObj
#     #id*: string         # <-- NEW
#     #params*:seq[Param]  # <--- TODO: esto debería reemplazar a los siguientes.
#     integerAddr*: seq[ptr int]  # Esta es la nueva alternativa
#     boolAddr*: seq[ptr bool]    # Esta es la nueva alternativa    
#     realAddr*: seq[ptr float]   # Esta es la nueva alternativa
#     stringAddr*: seq[ptr string]

   

#     isPositive*: seq[fmi2Boolean]




# type
#   ModelInstanceRef* = ref ModelInstance
{.pop.}

#proc `=destroy`*(o: var ModelInstance) {.exportc,dynlib.} =
#  echo "destroyed"

# proc `$`*(o: ModelInstanceRef):string =
#   result = "ref ModelInstance:"
#   #result &= &"\n- r: {o.r}"
#   #result &= &"\n- i: {o.i}"
#   #result &= &"\n- b: {o.b}"
#   #result &= &"\n- s: {o.s}"
#   result &= &"\n- isPositive: {o.isPositive}"
#   result &= &"\n- time: {o.time}"
#   result &= "\n"


 

# template add*(comp: ModelInstanceRef; value:int) {.dirty.} =
#   #proc setStartValues*(comp: ModelInstanceRef) =    
#   #  ## used to initialize the variables (integers are stored in the seq `comp.i`)
#     #comp.i &= 1.fmi2Integer
#     `value` = value
#     #echo value.astToStr, ": ", value
#     #if typeof(value) is int:
#     comp.integerAddr.add( addr(value) )
#     #comp.params &= Param(name:value.astToStr, kind: tInteger)


# macro init2*(args: varargs[typed]) =
#   ## creates the setStartValues functions.
#   ## Initializes and populates the model instance
#   var body = nnkStmtList.newTree()

#   #var nIntegers: int
#   for arg in args:
#     var id = newIdentNode(arg.strVal)

#     # int case
#     if arg.getType.typeKind == ntyInt:
#       #nIntegers += 1
#       let argVal = arg.getImpl[2].intVal.int
#       body.add quote do:
#         `id` = `argVal`
#         comp.integerAddr.add( addr(`id`) )

#     # bool case
#     elif arg.getType.typeKind == ntyBool:
#       let argVal = arg.getImpl[2].boolVal.bool
#       body.add quote do:
#         `id` = `argVal`
#         comp.boolAddr.add( addr(`id`) )

#     # real case
#     elif arg.getType.typeKind == ntyFloat:
#       var argVal:float
#       var flag = false
#       #echo repr arg.getImpl[2].kind
#       case arg.getImpl[2].kind
#       of nnkFloatLit:  # The initialization is defined
#         argVal = arg.getImpl[2].floatVal.float
#         flag = true
#       #of nnkEmpty:     # Not initialized
#       #  echo "nok"
#       else:
#         discard

#       body.add quote do:
#         if `flag`:
#           `id` = `argVal`  # We do this only for initialization
#         comp.realAddr.add( addr(`id`) )  # We define this for all floats
        
#     # string case
#     elif arg.getType.typeKind == ntyString:
#       let argVal = arg.getImpl[2].strVal
#       body.add quote do:
#         `id` = `argVal`
#         comp.stringAddr.add( addr(`id`) )

#   result = quote do:
#     #NUMBER_OF_INTEGERS = `nIntegers`    
#     proc setStartValues*(comp {.inject.}: ModelInstanceRef) = 
#       `body`
#       comp.states = myModel.states  # FIXME: copies the states from the other model here.



# macro setStates*(args: varargs[typed]) =
#   #[
#     This macro converts things like:

#       var counter:int = 1
#       init(counter)
    
#     into:

#       var counter:int = 1
#       NUMBER_OF_INTEGERS = 1
#       proc setStartValues(comp: ModelInstanceRef) {.exportc, dynlib.} =
#         counter = 1
#         add(comp.integerAddr, addr(counter))      
#   ]#
#   var body = nnkStmtList.newTree()

#   #var nIntegers: int
#   for arg in args:
#     var id = newIdentNode(arg.strVal)

#     # int case
#     if arg.getType.typeKind == ntyInt:
#       #nIntegers += 1
#       let argVal = arg.getImpl[2].intVal.int
#       body.add quote do:
#         `id` = `argVal`
#         comp.integerAddr.add( addr(`id`) )

#     # bool case
#     elif arg.getType.typeKind == ntyBool:
#       let argVal = arg.getImpl[2].boolVal.bool
#       body.add quote do:
#         `id` = `argVal`
#         comp.boolAddr.add( addr(`id`) )

#     # real case
#     elif arg.getType.typeKind == ntyFloat:
#       let argVal = arg.getImpl[2].floatVal.float
#       body.add quote do:
#         `id` = `argVal`
#         comp.realAddr.add( addr(`id`) )


#   result = quote do:
#     #NUMBER_OF_INTEGERS = `nIntegers`    
#     proc setStates*(comp {.inject.}: ModelInstanceRef) = 
#       discard
#       `body`

# ]#

# proc `[]`*(fmu:FmuRef; name:string): int =
#   fmu.parameters[name].startI.get

# proc `[]=`*(fmu:FmuRef; name:string; val:int) =
#   fmu.parameters[name].startI = some(val)

# proc getIntegersNumber*(fmu:FmuRef): int =
#   result = 0
#   for p in fmu.parameters.values:
#     if p.kind == tInteger:
#       result += 1

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
proc addFloat*(fmu:FmuRef; name:string) =
  fmu.parameters[name] = Param(kind: tReal)
  fmu.reals &= name
  fmu.parameters[name].idx = fmu.reals.len - 1
  # Defaults
  fmu.parameters[name].initial = iUnset

proc addInteger*(fmu:FmuRef; name:string) =
  fmu.parameters[name] = Param(kind: tInteger)
  fmu.integers &= name
  fmu.parameters[name].idx = fmu.integers.len - 1
  # Defaults
  fmu.parameters[name].initial = iUnset

proc addBoolean*(fmu:FmuRef; name:string) =
  fmu.parameters[name] = Param(kind: tBoolean)
  fmu.booleans &= name
  fmu.parameters[name].idx = fmu.booleans.len - 1
  # Defaults
  fmu.parameters[name].initial = iUnset

proc addString*(fmu:FmuRef; name:string) =
  fmu.parameters[name] = Param(kind: tString)
  fmu.strings &= name
  fmu.parameters[name].idx = fmu.strings.len - 1
  # Defaults
  fmu.parameters[name].initial = iUnset

# Setting causality
proc setParameter*(fmu:FmuRef; name:string) =
  ##[
  Independent parameter(a data value that is constant during the simulation and
  is provided by the environment and cannot be used in connections).

  variability must be "fixed"or "tunable". initial must be exactor not present
  (meaning exact).
  ]##  
  fmu.parameters[name].causality = cParameter

proc setCalculatedParameter*(fmu:FmuRef; name:string) =
  ##[
  A data value that is constant during the simulation and is computed during
  initialization or when tunable parameters change.
  variability must be "fixed"or "tunable". initialmust be "approx",
  "calculated"or not present (meaning calculated).
  ]##  
  fmu.parameters[name].causality = cCalculatedParameter

proc setInput*(fmu:FmuRef; name:string) =
  ##[
  The variable value can be provided from another modelor slave. It is not
  allowed to define initial.
  ]##  
  fmu.parameters[name].causality = cInput

proc setOutput*(fmu:FmuRef; name:string) =
  ##[
  The variable value can be used by another modelor slave. The algebraic
  relationship to the inputs is defined via thedependenciesattribute of
  <fmiModelDescription><ModelStructure><Outputs><Unknown>.
  ]##  
  fmu.parameters[name].causality = cOutput

proc setLocal*(fmu:FmuRef; name:string) =
  ##[
  Local variable that is calculated from other variables or is a
  continuous-time state(see section2.2.8). It is not allowed to use the
  variable value in another modelor slave.
  ]##
  fmu.parameters[name].causality = cLocal

proc setIndependent*(fmu:FmuRef; name:string) =
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
  fmu.parameters[name].causality = cIndependent


# Setting variability
proc setConstant*(fmu:FmuRef; name:string) =
  ## "constant": The value of the variable never changes.
  fmu.parameters[name].variability = vConstant

proc setFixed*(fmu:FmuRef; name:string) =
  ##[
  "fixed": The value of the variable is fixedafter initialization, in other
  words,after fmi2ExitInitializationModewas calledthe variable value
  does notchange anymore.
  ]##
  fmu.parameters[name].variability = vFixed

proc setTunable*(fmu:FmuRef; name:string) =
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
  fmu.parameters[name].variability = vTunable

proc setDiscrete*(fmu:FmuRef; name:string) =
  ##[
  "discrete": ModelExchange: The value of the variable is constant between
  external and internalevents(= time, state, step events defined implicitly
  in the FMU).Co-Simulation: By convention, the variable is from a “real”
  sampled data system and its value is only changed at Communication Points
  (also inside the slave).
  ]##  
  fmu.parameters[name].variability = vDiscrete

proc setContinuous*(fmu:FmuRef; name:string) =
  ##[
  "continuous": Only a variable of type = “Real”
  can be “continuous”. ModelExchange: No restrictions on value changes.
  Co-Simulation: By convention, the variable is from a differential
  ]##  
  fmu.parameters[name].variability = vContinuous

# Set initial
proc setUnset*(fmu:FmuRef; name:string) =
  # I have invented this as default
  fmu.parameters[name].initial = iUnset  # default

proc setExact*(fmu:FmuRef; name:string) =
  ##[
  The variable is initialized with the start value(provided under Real,
  Integer, Boolean, String or Enumeration)
  ]##
  fmu.parameters[name].initial = iExact

proc setApprox*(fmu:FmuRef; name:string) =
  ##[
  The variable is an iteration variable of an algebraic loop and the
  iteration at initialization starts with the startvalue.
  ]##
  fmu.parameters[name].initial = iApprox


proc setCalculated*(fmu:FmuRef; name:string) =
  ##[
  The variable is calculated from other variables during initialization.
  It is not allowed to provide a "start" value.
  ]##
  fmu.parameters[name].initial = iCalculated


# Description
proc setDescription*(fmu:FmuRef; name, description: string) =
  fmu.parameters[name].description = description



# Getter
# template `[]`*(fmu:FmuRef; name:string) =
#   case `fmu`.parameters[name].kind
#   of tInteger:
#     `fmu`.parameters[name].valueI
#   else:
#     discard    
# proc `[]`*(fmu:FmuRef; name:string):int =
#   return fmu.parameters[name].valueI

# proc `[]`*(fmu:FmuRef; name:string):float =
#   return fmu.parameters[name].valueR

# proc `[]`*(fmu:FmuRef; name:string):auto =
#   var p = fmu.parameters[name]
#   if p.kind == tInteger:
#     return p.valueI
#   elif p.kind == tReal:
#     return p.valueR
#   # case p.kind
#   # of tInteger:
#   #   return p.valueI
#   # of tReal:
#   #   return p.valueR
#   #of tBoolean:
#   #  return p.valueB
#   #of tString:
#   #  return p.valueS
#   else:
#     echo "shit"

# proc getInteger*(fmu:FmuRef; name:string):int =
#   return fmu.parameters[name].valueI

# FIXME: ----- I DON'T LIKE THIS-------------- 
proc `[]`*(fmu:FmuRef; name:string): Param =
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
  return p.valueI / value

proc `==`*(p:Param; value:int):bool =
  return p.valueI == value
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