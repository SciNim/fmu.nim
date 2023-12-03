import definitions, parameters
import std/[macros, tables]
import options

{.push exportc, dynlib, cdecl.}
type
  fmi2CallbackLogger*  = proc( a1: fmi2ComponentEnvironment,
                               a2: fmi2String,
                               a3: fmi2Status,
                               a4: fmi2String, 
                               a5: fmi2String,
                               a6: varargs[fmi2String]) 
  fmi2CallbackAllocateMemory* = proc(a1: cuint, a2: cuint) #{.cdecl.}
  fmi2CallbackFreeMemory*  = proc(a1: pointer) #{.cdecl.}
  fmi2StepFinished*  = proc(a1: fmi2ComponentEnvironment, a2: fmi2Status) #{.cdecl.}


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
    outFile*: string
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

proc `[]`*(fmu:FmuRef; name:string): int =
  fmu.parameters[name].startI.get

proc `[]=`*(fmu:FmuRef; name:string; val:int) =
  fmu.parameters[name].startI = some(val)

proc getIntegersNumber*(fmu:FmuRef): int =
  result = 0
  for p in fmu.parameters.values:
    if p.kind == tInteger:
      result += 1

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