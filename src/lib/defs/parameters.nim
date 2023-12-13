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
      Integer, Boolean, String or Enumeration)
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


  ParamObj = object
    name*: string
    idx*: int
    causality*: Causality
    variability*: Variability
    initial*: Initial
    description*: string
    canHandleMultipleSetPerTimeInstant*: Option[string] 
    case kind*:ParamType
    of tReal:
      valueR*: float
      startR*: Option[float]
      derivative*: Option[uint]
      reinit*: bool = false
      state*: bool = false
      min*: Option[float]
      max*: Option[float]
    of tInteger:
      valueI*: int
      startI*: Option[int]  # Initial value
    of tBoolean:
      valueB*: bool
      startB*: Option[bool]
    of tString:
      valueS*:string
      startS*: Option[string]

  Param* = ref ParamObj

