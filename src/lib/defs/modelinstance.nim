import definitions, parameters
import std/[strformat, options]
import std/macros
{.push exportc, dynlib, cdecl.}

#[
  if status == fmi2Error or status == fmi2Fatal or isCategoryLogged(instance, categoryIndex).bool:
    instance.functions.logger(instance.functions.componentEnvironment, # fmi2ComponentEnvironment
                              instance.instanceName, # fmi2String
                              status, # fmi2Status
                              logCategoriesNames[categoryIndex].fmi2String, # fmi2String
                              message.fmi2String, # fmi2String
                              args ) # FIXME  # varargs[fmi2String]
]#

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


  fmi2CallbackFunctions* = ref object #{.impfmuTemplate, bycopy.} = object
    logger*: fmi2CallbackLogger
    allocateMemory*: fmi2CallbackAllocateMemory
    freeMemory*: fmi2CallbackFreeMemory
    stepFinished*: fmi2StepFinished
    componentEnvironment*: fmi2ComponentEnvironment

  #fmi2CallbackFunctions* = pointer

type
  ModelInstance* = object
    id*: string         # <-- NEW
    params*:seq[Param]  # <--- TODO: esto debería reemplazar a los siguientes.
    integerAddr*: seq[ptr int]
    r*: seq[fmi2Real]
    i*: seq[fmi2Integer]
    b*: seq[fmi2Boolean]
    s*: seq[fmi2String]
    isPositive*: seq[fmi2Boolean]
    time*: fmi2Real
    instanceName*: fmi2String
    `type`*: fmi2Type
    guid*: string   # <-- Modified
    functions*: fmi2CallbackFunctions
    loggingOn*: fmi2Boolean
    logCategories*: array[4, fmi2Boolean]  # FIXME: NUMBER_OF_CATEGORIES
    componentEnvironment*: fmi2ComponentEnvironment
    state*: ModelState
    eventInfo*: fmi2EventInfo
    isDirtyValues*: fmi2Boolean
    isNewEventIteration*: fmi2Boolean

    nEventIndicators*:int # <-- NEW




type
  ModelInstanceRef* = ref ModelInstance
{.pop.}

#proc `=destroy`*(o: var ModelInstance) {.exportc,dynlib.} =
#  echo "destroyed"

proc `$`*(o: ModelInstanceRef):string =
  result = "ref ModelInstance:"
  result &= &"\n- r: {o.r}"
  result &= &"\n- i: {o.i}"
  result &= &"\n- b: {o.b}"
  result &= &"\n- s: {o.s}"
  result &= &"\n- isPositive: {o.isPositive}"
  result &= &"\n- time: {o.time}"
  result &= "\n"


 

template add*(comp: ModelInstanceRef; value:int) {.dirty.} =
  #proc setStartValues*(comp: ModelInstanceRef) =    
  #  ## used to initialize the variables (integers are stored in the seq `comp.i`)
    #comp.i &= 1.fmi2Integer
    `value` = value
    #echo value.astToStr, ": ", value
    #if typeof(value) is int:
    comp.integerAddr.add( addr(value) )
    #comp.params &= Param(name:value.astToStr, kind: tInteger)

template add2*(value:int) {.dirty.} =
  #proc setStartValues*(comp: ModelInstanceRef) =    
  #  ## used to initialize the variables (integers are stored in the seq `comp.i`)
    #comp.i &= 1.fmi2Integer
    #`value` = value
    #echo value.astToStr, ": ", value
    #if typeof(value) is int:
    #comp.integerAddr.add( addr(value) )
    #comp.params &= Param(name:value.astToStr, kind: tInteger)
    #mixin myModel
    #echo typeof(`value`)
    echo value.astToStr, " ------> ", value
    myModel.params &= Param(name:value.astToStr, kind: tInteger, startI: some(value)) 

#[
macro addParam*(arg: typed) =
  #[
    This macro converts things like:
      
      var counter:int = 1
      init(counter)
    
    into:

      var counter:int = 1
      NUMBER_OF_INTEGERS = 1
      proc setStartValues(comp: ModelInstanceRef) {.exportc, dynlib.} =
        counter = 1
        add(comp.integerAddr, addr(counter))      
  ]#
  var body = nnkStmtList.newTree()

  #var names:seq[string]
  var nIntegers: int
  for arg in args:
    #names &= arg.strVal
    var id = newIdentNode(arg.strVal)

    # int case
    if arg.getType.typeKind == ntyInt:
      nIntegers += 1
      let argVal = arg.getImpl[2].intVal.int
      #var comp: ModelInstanceRef
      body.add quote do:
        `id` = `argVal`
        comp.integerAddr.add( addr(`id`) )

  result = quote do:
    NUMBER_OF_INTEGERS = `nIntegers`    
    proc setStartValues*(comp {.inject.}: ModelInstanceRef) = 
      `body`
]#

# macro addParam*(arg:typed) =
#   var id = newIdentNode(arg.strVal)
#   if arg.getType.typeKind == ntyInt:
#     let implementation = arg.getImpl
#     #if len
#     let argVal = 
    

#     result = quote do:
#       myModel.params &= Param(`id`, tInteger)
#     if arg


# macro init*() = #myModel:ModelInstanceRef ) =
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
#   #mixin myModel
#   var body = nnkStmtList.newTree()

#   var nIntegers: int
#   for param in myModel.params:
#     # integer case
#     if param.kind == tInteger:
#       nIntegers += 1
#       if param.startI.isSome:
#         var id = newIdentNode(param.name)
#         var argVal = startI.get
#         body.add quote do:
#           `id` = `argVal`
#           comp.integerAddr.add( addr(`id`) )

#   result = quote do:
#     NUMBER_OF_INTEGERS = `nIntegers`    
#     proc setStartValues*(comp {.inject.}: ModelInstanceRef) = 
#       `body`

macro init*(args: varargs[typed]) =
  #[
    This macro converts things like:

      var counter:int = 1
      init(counter)
    
    into:

      var counter:int = 1
      NUMBER_OF_INTEGERS = 1
      proc setStartValues(comp: ModelInstanceRef) {.exportc, dynlib.} =
        counter = 1
        add(comp.integerAddr, addr(counter))      
  ]#
  var body = nnkStmtList.newTree()

  var nIntegers: int
  for arg in args:
    var id = newIdentNode(arg.strVal)

    # int case
    if arg.getType.typeKind == ntyInt:
      nIntegers += 1
      let argVal = arg.getImpl[2].intVal.int
      body.add quote do:
        `id` = `argVal`
        comp.integerAddr.add( addr(`id`) )

  result = quote do:
    NUMBER_OF_INTEGERS = `nIntegers`    
    proc setStartValues*(comp {.inject.}: ModelInstanceRef) = 
      `body`

# https://github.com/mantielero/VapourSynth.nim/blob/b8ae20dadf9c5e3a2c98f3f556cb4cbdba959b63/src/vsmacros/filter.nim#L10
  
# macro init*(args: varargs[typed]) =
#   var nIntegers = 0 
#   result = nnkStmtList.newTree()

#   # 1. Function name
#   var newFunc = nnkProcDef.newTree()
#   newFunc.add(  nnkPostfix.newTree(
#       newIdentNode("*"),
#       newIdentNode("setStartValues")
#     ),
#     newEmptyNode(),
#     newEmptyNode()
#   )

#   # 2. Function arguments
#   var formalParams = nnkFormalParams.newTree()
#   formalParams.add newEmptyNode()

#   formalParams.add nnkIdentDefs.newTree(
#         newIdentNode("comp"),
#         newIdentNode("ModelInstanceRef"),
#         newEmptyNode()
#       )  

#   newFunc.add( formalParams, newEmptyNode(), newEmptyNode() )

#   # 3. Function body
#   var funcBody = nnkStmtList.newTree()
#   funcBody.add newEmptyNode()
#   funcBody.add newEmptyNode()

#   var body =  nnkStmtList.newTree()

#   for arg in args:
#     #names &= arg.strVal
#     let id = newIdentNode(arg.strVal)

#     # 3.1 Assignment

#     if arg.getType.typeKind == ntyInt:
#       nIntegers += 1
#       let argVal = arg.getImpl[2].intVal.int
#       body.add nnkAsgn.newTree(
#                 #newIdentNode("counter"),
#                 id,
#                 #newLit(1)
#                 newLit(argVal)
#               )

#       # 3.2 Add adress  
#       body.add   nnkInfix.newTree(
#                   newIdentNode("&="),
#                   nnkDotExpr.newTree(
#                       newIdentNode("comp"),
#                       newIdentNode("integerAddr") 
#                   ),
#                   nnkCall.newTree(
#                     newIdentNode("addr"),
#                     id 
#                   )
#                 )  

#   newFunc.add body

#   result.add quote do:
#     NUMBER_OF_INTEGERS = `nIntegers`

#   result.add  newFunc

#[
Direcciones futuras:

macro vras(arglist: varargs[untyped]) =
  echo argList.lispRepr()
  
vras(positional, test = 123):
  echo "ACtual body"
]#

#[
nnkStmtList.newTree(
  nnkVarSection.newTree(
    nnkIdentDefs.newTree(
      nnkPostfix.newTree(
        newIdentNode("*"),
        newIdentNode("counter")
      ),
      newIdentNode("int"),
      newLit(0)
    )
  )
)

]#

# macro param(name:string;typ:typedesc) =
#   echo name
#   echo repr typ

#[

param("counter", int, 
      output,
      exact,
      discrete,
      start = 1 )
  

  

]#

  # addParam(counter,
  #          variability = "discrete",
  #          causality = "output",
  #          initial   = "exact")
  #addParam( counter, output, exact )