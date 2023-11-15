import std/macros
import options#, xmltree, strformat

type
  ParamType* = enum
    tInteger, tReal, tBoolean, tString

  Causality* = enum
    cParameter,
      ##[
      Independent parameter(a data value that is constant during the simulation and
      is provided by the environment and cannot be used in connections).

      variability must be "fixed"or "tunable". initial must be exactor not present
      (meaning exact).
      ]##
    cCalculatedParameter,
      ##[
      A data value that is constant during the simulation and is computed during
      initialization or when tunable parameters change.
      variability must be "fixed"or "tunable". initialmust be "approx",
      "calculated"or not present (meaning calculated).
      ]##
    cInput,
      ##[
      The variable value can be provided from another modelor slave. It is not
      allowed to define initial.
      ]##
    cOutput,
      ##[
      The variable value can be used by another modelor slave. The algebraic
      relationship to the inputs is defined via thedependenciesattribute of
      <fmiModelDescription><ModelStructure><Outputs><Unknown>.
      ]##
    cLocal,
      ##[
      Local variable that is calculated from other variables or is a
      continuous-time state(see section2.2.8). It is not allowed to use the
      variable value in another modelor slave.
      ]##
    cIndependent,
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

  Variability* = enum
    vConstant,
      ##[
      "constant": The value of the variable never changes.
      ]##
    vFixed,
      ##[
      "fixed": The value of the variable is fixedafter initialization, in other
      words,after fmi2ExitInitializationModewas calledthe variable value
      does notchange anymore.
      ]##
    vTunable,
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
    vDiscrete,
      ##[
      "discrete": ModelExchange: The value of the variable is constant between
      external and internalevents(= time, state, step events defined implicitly
      in the FMU).Co-Simulation: By convention, the variable is from a “real”
      sampled data system and its value is only changed at Communication Points
      (also inside the slave).
      ]##
    vContinuous,
      ##[
      "continuous": Only a variable of type = “Real”
      can be “continuous”. ModelExchange: No restrictions on value changes.
      Co-Simulation: By convention, the variable is from a differential
      ]##

  Initial* = enum
    iUnset, # I have invented this as default
    iExact,
      ##[
      The variable is initialized with the start value(provided under Real,
      Integer, Boolean, Stringor Enumeration)
      ]##
    iApprox,
      ##[
      The variable is an iteration variable of an algebraic loop and the
      iteration at initialization starts with the startvalue.
      ]##
    iCalculated
      ##[
      The variable is calculated from other variables during initialization.
      It is not allowed to provide a "start" value.
      ]##


  ParamObj* = object
    name*: string
    idx*: int
    causality*: Causality
    variability*: Variability
    initial*: Initial
    description*: string
    canHandleMultipleSetPerTimeInstant*: Option[string]    
    case kind*:ParamType
    of tReal:
      #addressR*: ptr float
      startR*: Option[float]
      derivative*: Option[uint]
      reinit*: Option[bool]
    of tInteger:
      valI*: int
      #addressI*: ptr int
      startI*: Option[int]  # Initial value
    of tBoolean:
      #addressB*: ptr bool
      startB*: Option[bool]
    of tString:
      #addressS*: ptr string
      startS*: Option[string]

  Param* = ref ParamObj


#[
proc get*(r:Param):XmlNode =
  var att:seq[(string,string)]
  if r.name == "":
    quit("`name` needs to contain a string", QuitFailure)
  att.add ("name", r.name)

  #if r.valueReference == 0.uint:
  #  quit("`valueReference` needs to be >0", QuitFailure)
  att.add ("valueReference", fmt"{r.idx}")

  if r.description.isSome:
    att.add ("description", r.description.get)
  if r.causality.isSome:
    att.add ("causality", $r.causality.get)
  if r.variability.isSome:
    att.add ("variability", $r.variability.get)
  if r.initial.isSome:
    att.add ("initial", $r.initial.get)
  if r.canHandleMultipleSetPerTimeInstant.isSome:
    att.add ("canHandleMultipleSetPerTimeInstant", r.canHandleMultipleSetPerTimeInstant.get) 

  let attributes = att.toXmlAttributes

  var children:seq[XmlNode]
  case r.kind
  of tReal:
    children.add get(r.childReal)
  of tInteger:
    children.add get(r.childInteger)
  of tBoolean:
    children.add get(r.childBoolean)
  of tString:
    children.add get(r.childString)
  of tEnumeration:
    children.add get(r.childEnumeration)
  
  return newXmlTree("ScalarVariable",children, attributes)
]#

#var params*:seq[Param]
#[
var paramsI*:seq[ParamI]
var paramsR*:seq[ParamR]
var paramsB*:seq[ParamB]
var paramsS*:seq[ParamS]
]#

var nParamsI{.compileTime.}: int = 0
var nParamsR{.compileTime.}: int = 0
var nParamsB{.compileTime.}: int = 0
var nParamsS{.compileTime.}: int = 0
#var numStates* {.compileTime.}:int = 0

macro param*( arg:typed; 
              causality: static[Causality]     = cLocal; 
              variability: static[Variability] = vContinuous;
              initial: static[Initial]         = iUnset ;
              description: static[string]      = "") =
  var nIntegers = 0
  var nReals    = 0
  var nBooleans = 0
  var nStrings  = 0

  ## tracks the characteristics of all the arguments
  result = nnkStmtList.newTree()
  # 1. Check that the first argument is a variable
  var impl = arg.getImpl

  # 1.1 check it is an identifier definition
  if impl.kind != nnkIdentDefs:
    raise newException(ValueError, "the first argument should be a variable defined like: var name:int = 1")

  # 1.2 the first element should be a symbol
  if impl[0].kind != nnkSym:
    raise newException(ValueError, "the first argument is a variable defined like: var name:int = 1")


  # 1.3 the second element should be the type; we want the type to be explicit
  if impl[1].kind == nnkEmpty:
    raise newException(ValueError, "it is mandatory to define the variable with its type: int, float, boolean or string")
  if impl[1].kind != nnkSym:
    raise newException(ValueError, "the first argument is variable defined like: var name:int = 1")
  

  # 3. Causality
  #param.causality = causality


  # 4. Variability
  #param.variability = variability

  # 5. Initial
  if causality in @[cInput, cIndependent] and initial != iUnset:
    raise newException(ValueError, """it is not allowed to provide a value for initial if causality = "input" or "independent"""")
  
  #if initial != iUnset:
  #  param.initial = initial
  #echo initial
  if initial == iExact and impl[2].kind == nnkEmpty:
    raise newException(ValueError, """= "exact": The variable is initialized with the start value (provided under Real, Integer, Boolean, String or Enumeration).""")

  if initial == iApprox and impl[2].kind == nnkEmpty:
    raise newException(ValueError, """= "approx": The variable is an iteration variable of an algebraic loop and the iteration at initialization starts with the start value.""")

  if initial == iCalculated and impl[2].kind != nnkEmpty:
    raise newException(ValueError, """= "calculated": The variable is calculated from other variables during initialization. It is not allowed to provide a “start” value.""")
  

  # 2. Processing depending on the type  # FIXME
  var name = impl[0].strVal
  #var param = Param(name: name)  

  result.add quote do:
    myModel.params.add Param( name: `name`, #kind: tInteger,
                              #startI: some(`value`),
                              causality: `causality`.Causality,
                              variability: `variability`.Variability,
                              initial: `initial`.Initial,
                              description: `description` )

  case impl[1].getType.typeKind 
  of ntyInt:  # 2.1 integer case
    result.add quote do:
      myModel.params[^1].idx = `nIntegers`
      myModel.params[^1].kind = tInteger

    nIntegers += 1
    
    if impl[2].kind == nnkIntLit:
      var value = impl[2].intVal.int
      result.add quote do:
        myModel.params[^1].startI = some(`value`)

    else:
      result.add quote do:
        myModel.params[^1].startI = none()
        #echo repr myModel.params[^1]
   

  else:
    raise newException(ValueError, "only variables typed: `int`, `float`, `bool` and `string` are supported")