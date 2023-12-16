import ../defs/[definitions, modelinstance, masks]
import ../functions/helpers
import ../meta/filteredlog
import strformat


## ---------------------------------------------------------------------------
## Functions for FMI2 for Model Exchange
## ---------------------------------------------------------------------------
# Enter and exit the different modes

{.push exportc:"$1", dynlib, cdecl.}
proc fmi2EnterEventMode*(comp: FmuRef): fmi2Status =
    #var comp: ptr ModelInstance = cast[ptr ModelInstance](c)
    if invalidState(comp, "fmi2EnterEventMode", MASK_fmi2EnterEventMode):
        return fmi2Error
    filteredLog(comp, fmi2OK, fmiCall, "fmi2EnterEventMode".fmi2String)

    comp.state = modelEventMode
    comp.isNewEventIteration = fmi2True
    return fmi2OK


proc fmi2NewDiscreteStates*(comp: FmuRef;
                            eventInfo: ptr fmi2EventInfo): fmi2Status =
    var timeEvent = false
    if invalidState(comp, "fmi2NewDiscreteStates", MASK_fmi2NewDiscreteStates):
        return fmi2Error
    filteredLog(comp, fmi2OK, fmiCall, "fmi2NewDiscreteStates".fmi2String)

    comp.eventInfo.newDiscreteStatesNeeded = fmi2False
    comp.eventInfo.terminateSimulation = fmi2False
    comp.eventInfo.nominalsOfContinuousStatesChanged = fmi2False
    comp.eventInfo.valuesOfContinuousStatesChanged = fmi2False

    if (comp.eventInfo.nextEventTimeDefined > 0 and comp.eventInfo.nextEventTime <= comp.time):
        timeEvent = true


    #  useEventUpdate()
    when declared(eventUpdate):
      comp.eventUpdate(timeEvent)

    comp.isNewEventIteration = fmi2False

    # copy internal eventInfo of component to output eventInfo
    eventInfo.newDiscreteStatesNeeded = comp.eventInfo.newDiscreteStatesNeeded
    eventInfo.terminateSimulation = comp.eventInfo.terminateSimulation
    eventInfo.nominalsOfContinuousStatesChanged = comp.eventInfo.nominalsOfContinuousStatesChanged
    eventInfo.valuesOfContinuousStatesChanged = comp.eventInfo.valuesOfContinuousStatesChanged
    eventInfo.nextEventTimeDefined = comp.eventInfo.nextEventTimeDefined
    eventInfo.nextEventTime = comp.eventInfo.nextEventTime

    return fmi2OK


proc fmi2EnterContinuousTimeMode*(comp: FmuRef): fmi2Status =
    if invalidState(comp, "fmi2EnterContinuousTimeMode", MASK_fmi2EnterContinuousTimeMode):
        return fmi2Error
    filteredLog(comp, fmi2OK, fmiCall,"fmi2EnterContinuousTimeMode".fmi2String)

    comp.state = modelContinuousTimeMode
    return fmi2OK


proc fmi2CompletedIntegratorStep*(comp: FmuRef;
                                 noSetFMUStatePriorToCurrentPoint: fmi2Boolean;
                                 enterEventMode: ptr fmi2Boolean;
                                 terminateSimulation: ptr fmi2Boolean): fmi2Status = # {.exportc:"$1", cdecl, dynlib.}
    #var comp: ptr ModelInstance = cast[ptr ModelInstance](c)
    if invalidState(comp, "fmi2CompletedIntegratorStep", MASK_fmi2CompletedIntegratorStep):
        return fmi2Error
    if nullPointer(comp, "fmi2CompletedIntegratorStep", "enterEventMode", enterEventMode):
        return fmi2Error
    if nullPointer(comp, "fmi2CompletedIntegratorStep", "terminateSimulation", terminateSimulation):
        return fmi2Error
    filteredLog(comp, fmi2OK, fmiCall,"fmi2CompletedIntegratorStep".fmi2String)

    enterEventMode[] = fmi2False
    terminateSimulation[] = fmi2False
    return fmi2OK


# Providing independent variables and re-initialization of caching
proc fmi2SetTime*(comp: FmuRef; time: fmi2Real): fmi2Status = # {.exportc: "$1",dynlib,cdecl.}
    #var comp: ptr ModelInstance = cast[ptr ModelInstance](c)
    if invalidState(comp, "fmi2SetTime", MASK_fmi2SetTime):
        return fmi2Error
    filteredLog(comp, fmi2OK, fmiCall, "fmi2SetTime: time={time:%.16g}".fmi2String)
    comp.time = time
    return fmi2OK


proc fmi2SetContinuousStates*(comp: FmuRef; 
                              x: ptr fmi2Real; 
                              nx: csize_t): fmi2Status =
    if invalidState(comp, "fmi2SetContinuousStates", MASK_fmi2SetContinuousStates):
        return fmi2Error
    if invalidNumber(comp, "fmi2SetContinuousStates", "nx", nx, comp.states.len):
        return fmi2Error
    if nullPointer(comp, "fmi2SetContinuousStates", "x[]", x):
        return fmi2Error

    if comp.nStates > 0:
        for i in 0 ..< nx:
            var vr = comp.states[i] #vrStates[i]
            var key = comp.reals[vr]
            filteredLog(comp, fmi2OK, fmiCall, (&"fmi2SetContinuousStates: #r{vr}#={x[i].float}").fmi2String)
            #assert(vr.int < nReals)
            comp[key] = x[i].float
    return fmi2OK


# Evaluation of the model equations
# https://github.com/qtronic/fmusdk/blob/69cea51c40694bc5cab58edf84bd107149ac450b/fmu20/src/models/fmuTemplate.c#L856-L873
proc fmi2GetDerivatives*(comp: FmuRef; 
                         derivatives: ptr fmi2Real; 
                         nx: csize_t): fmi2Status =
    ## retrieve the derivatives of the continuous states.
    
    if invalidState(comp, "fmi2GetDerivatives", MASK_fmi2GetDerivatives):
        return fmi2Error
    if invalidNumber(comp, "fmi2GetDerivatives", "nx", nx, comp.states.len):
        return fmi2Error
    if nullPointer(comp, "fmi2GetDerivatives", "derivatives[]", derivatives):
        return fmi2Error
    
    when declared(getReal):
      if comp.nStates > 0:
        for i in 0 ..< nx:  # Number of derivatives
          var key = comp.derivatives[i]
        
          derivatives[i] = getReal(comp, key).fmi2Real
          #echo "i: ", i, "   key:", key, "   derivative: ", getReal(comp, key)
          var tmp = &"""fmi2GetDerivatives: "{key}": = {derivatives[i].float}"""
          filteredLog(comp, fmi2OK, fmiCall, tmp.fmi2String )

    return fmi2OK


proc fmi2GetEventIndicators*( comp: FmuRef; #ModelInstanceRef; 
                              eventIndicators: ptr fmi2Real;
                              ni: csize_t): fmi2Status =
    if invalidState(comp, "fmi2GetEventIndicators", MASK_fmi2GetEventIndicators):
        return fmi2Error

    if invalidNumber(comp, "fmi2GetEventIndicators", "ni", ni, comp.nEventIndicators): #NUMBER_OF_EVENT_INDICATORS):
        return fmi2Error

    when declared(getEventIndicator):
      if comp.nEventIndicators > 0:
        for i in 0 ..< ni:
          eventIndicators[i] = getEventIndicator(comp, i) # to be implemented by the includer of this file
          filteredLog(comp, fmi2OK, fmiCall, 
                       "fmi2GetEventIndicators: z{i} = {eventIndicators[i]}")

    return fmi2OK


proc fmi2GetContinuousStates*(comp: FmuRef; 
                              states: ptr fmi2Real; 
                              nx: csize_t): fmi2Status =
    ##[
    Return the new (continuous) state vector x.
    
    After calling function fmi2NewDiscreteStates and it returns with
    eventInfo>valuesOfContinuousStatesChanged = fmi2True all states with reinit=true
    must be updated. It can be done with this fuction to update all states, or by
    fmi2GetReal on the individual states that have reinit = true.
    ]##

    if invalidState(comp, "fmi2GetContinuousStates", MASK_fmi2GetContinuousStates):
        return fmi2Error
    if invalidNumber(comp, "fmi2GetContinuousStates", "nx", nx, comp.states.len):      
        return fmi2Error
    if nullPointer(comp, "fmi2GetContinuousStates", "states[]", states):
        return fmi2Error

    if comp.nStates > 0: # when?
        for i in 0 ..< nx:
            var n = comp.states[i]  

            #echo "i: ", i
            states[i] = getReal(comp, comp.reals[n]) # to be implemented by the includer of this file
            filteredLog(comp, fmi2OK, fmiCall, (&"fmi2GetContinuousStates: #r{n}# = {states[i]}").fmi2String )

    return fmi2OK


proc fmi2GetNominalsOfContinuousStates*(comp: FmuRef; # ¿Susituir por ModelInstance?
                                        x_nominal: ptr fmi2Real; # Esto en teoría es un array
                                        nx: csize_t): fmi2Status =
  #var comp: FmuRef = cast[ModelInstance](c)  # c es un pointer
  if invalidState(comp, "fmi2GetNominalsOfContinuousStates",
                 MASK_fmi2GetNominalsOfContinuousStates):
    return fmi2Error
  if invalidNumber(comp, "fmi2GetNominalContinuousStates", "nx", nx, comp.states.len):
    return fmi2Error
  if nx > 0 and
      nullPointer(comp, "fmi2GetNominalContinuousStates", "x_nominal[]", x_nominal):
    return fmi2Error

  #FILTERED_LOG(comp, fmi2OK, fmiCall, "fmi2GetNominalContinuousStates: x_nominal[0..%d] = 1.0", nx-1)
  filteredLog(comp, fmi2OK, fmiCall, fmt"fmi2GetNominalContinuousStates: x_nominal[0..{nx-1}] = 1.0".fmi2String)
  for i in 0 ..< nx: #(i = 0; i < nx; i++)
    x_nominal[i] = 1
  return fmi2OK

{.pop.}
