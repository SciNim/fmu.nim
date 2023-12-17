import std/[strformat]
# template useGetReal():untyped =
#     mixin getReal

#     if comp.states.len > 0:  # NUMBER_OF_STATES > 0:
#         for i in 0 ..< comp.states.len: #NUMBER_OF_STATES:
#             prevState[i] = comp.realAddr[comp.states[i]][]

#         for i in 0 ..< comp.states.len: #NUMBER_OF_STATES:
#             var vr:fmi2ValueReference = comp.states[i].fmi2ValueReference #vrStates[i]
#             echo i, "-->"
#             comp.realAddr[comp.states[i]][] += h * getReal(comp, vr + 1)  # forward Euler step
#             echo "ok"

# template useGetEventIndicator():untyped =
#     mixin getEventIndicator

#     if comp.nEventIndicators > 0:
#         # initialize previous event indicators with current values
#         for i in 0 ..< comp.nEventIndicators: #NUMBER_OF_EVENT_INDICATORS:
#            prevEventIndicators[i] = getEventIndicator(comp, i)  # <-- // to be implemented by the includer of this file

# template useGetEventIndicator2():untyped =
#     mixin getEventIndicator

#     if comp.nEventIndicators > 0:
#         # check for state event
#         for i in 0 ..< comp.nEventIndicators: #NUMBER_OF_EVENT_INDICATORS:
#             var ei:double = getEventIndicator(comp, i)
#             var ei:float = 0.0  # <---- borrame
#             if ei * prevEventIndicators[i] < 0 :
#                 var tmp:string
#                 if ei < 0:
#                     tmp = "\\"
#                 else:
#                     tmp = "/"
#                 filteredLog(comp, fmi2OK, LOG_EVENT,
#                     fmt"fmi2DoStep: state event at {comp.time}, z{i} crosses zero -{tmp}-".fmi2String)
#                 inc stateEvent # stateEvent++

#             prevEventIndicators[i] = ei

{.push exportc,cdecl,dynlib.}

proc fmi2SetRealInputDerivatives*(comp: FmuRef; vr: ptr fmi2ValueReference;
                                 nvr: csize_t; order: ptr fmi2Integer;
                                 value: ptr fmi2Real): fmi2Status =
    ##var comp: ptr ModelInstanceRef = cast[ptr ModelInstanceRef](c)
    if invalidState(comp, "fmi2SetRealInputDerivatives", MASK_fmi2SetRealInputDerivatives):
        return fmi2Error

    filteredLog(comp, fmi2OK, fmiCall, fmt"fmi2SetRealInputDerivatives: nvr= {nvr}".fmi2String)
    filteredLog(comp, fmi2Error, error, fmt"fmi2SetRealInputDerivatives: ignoring function call.\nThis model cannot interpolate inputs: canInterpolateInputs='{fmi2False}'".fmi2String)
    return fmi2Error

proc fmi2GetRealOutputDerivatives*(comp: FmuRef; vr: ptr fmi2ValueReference;
                                  nvr: csize_t; order: ptr fmi2Integer;
                                  value: ptr fmi2Real): fmi2Status =
    ##var comp: ptr ModelInstanceRef = cast[ptr ModelInstanceRef](c)
    if invalidState(comp, "fmi2GetRealOutputDerivatives", MASK_fmi2GetRealOutputDerivatives):
        return fmi2Error
    filteredLog(comp, fmi2OK, fmiCall, fmt"fmi2GetRealOutputDerivatives: nvr= {nvr}".fmi2String)
    filteredLog(comp, fmi2Error, error, fmt"fmi2GetRealOutputDerivatives: ignoring function call.\nThis model cannot compute derivatives of outputs: MaxOutputDerivativeOrder='0'".fmi2String)
    for i in 0 ..< nvr:
        value[i] = 0
    return fmi2Error



proc fmi2CancelStep*(comp: FmuRef):fmi2Status =
    ##var comp: ptr ModelInstanceRef = cast[ptr ModelInstanceRef](c)
    if invalidState(comp, "fmi2CancelStep", MASK_fmi2CancelStep):
        # always fmi2CancelStep is invalid, because model is never in modelStepInProgress state.
        return fmi2Error

    filteredLog(comp, fmi2OK, fmiCall, "fmi2CancelStep".fmi2String)
    filteredLog(comp, fmi2Error, error,fmt"fmi2CancelStep: Can be called when fmi2DoStep returned fmi2Pending.\n This is not the case.".fmi2String)
    return fmi2Error


proc fmi2DoStep*( comp: FmuRef; 
                  currentCommunicationPoint: fmi2Real;
                  communicationStepSize: fmi2Real;
                  noSetFMUStatePriorToCurrentPoint: fmi2Boolean): fmi2Status =
    ##[

    ]##   
    var h:float  = communicationStepSize.float / 10.0

    var n = 10 # how many Euler steps to perform for one do step
    var prevState = newSeq[float](comp.nStates)
    var prevEventIndicators = newSeq[float](comp.nEventIndicators)

    var stateEvent = false
    var timeEvent  = false

    if invalidState(comp, "fmi2DoStep", MASK_fmi2DoStep):
        return fmi2Error

    var tmp:string
    if noSetFMUStatePriorToCurrentPoint.bool:
      tmp = "true"
    else:
      tmp = "false"
    var msg = "fmi2DoStep: "
    msg &= &"currentCommunicationPoint = {currentCommunicationPoint.float} "
    msg &= &"communicationStepSize = {communicationStepSize} "
    msg &= &"noSetFMUStatePriorToCurrentPoint = {tmp} "
    filteredLog(comp, fmi2OK, fmiCall, 
                msg.fmi2String)

    if (communicationStepSize.float <= 0.0):
        filteredLog(comp, fmi2Error, error,
            (&"fmi2DoStep: communication step size must be > 0. Fount {communicationStepSize.float}.").fmi2String )
        comp.state = modelError
        return fmi2Error
    
    when declared(getEventIndicator):
      if comp.nEventIndicators > 0:
        # initialize previous event indicators with current values
        for i in 0 ..< comp.nEventIndicators:
          prevEventIndicators[i] = comp.getEventIndicator(i)  # <-- implemented by the user

    # break the step into n steps and do forward Euler.
    comp.time = currentCommunicationPoint
    for k in 0 ..< n:
      comp.time += h

      when declared(getReal):
        if comp.nStates > 0:
          for i in 0 ..< comp.nStates:      
            prevState[i] = comp[comp.reals[comp.states[i]]].valueR         

          for i in 0 ..< comp.nStates:
            var key = comp.reals[comp.states[i]]
            var keyDer = comp.derivatives[i]
            comp[key].valueR += h * comp.getReal(keyDer) # forward Euler step

      when declared(getEventIndicator):
        if comp.nEventIndicators > 0:
            # check for state event
            for i in 0 ..< comp.nEventIndicators:
                var ei = comp.getEventIndicator(i)
                if ei * prevEventIndicators[i] < 0.0:
                    var tmp:string
                    if ei < 0:
                        tmp = "\\"
                    else:
                        tmp = "/"
                    filteredLog(comp, fmi2OK, event,
                        (&"fmi2DoStep: state event at {comp.time.float:0.2f}, z{i} crosses zero -{tmp}-").fmi2String)
                    #inc stateEvent # stateEvent++
                    stateEvent = true
                prevEventIndicators[i] = ei

      # check for time event
      if (comp.eventInfo.nextEventTimeDefined.bool and 
        (comp.time - comp.eventInfo.nextEventTime > -DT_EVENT_DETECT)):
        filteredLog(comp, fmi2OK, event, (&"fmi2DoStep: time event detected at {comp.time.float:0.2f}").fmi2String )
        timeEvent = true


      when declared(eventUpdate):
        if (stateEvent or timeEvent):
          #filteredLog(comp, fmi2OK, event, (&"fmi2DoStep: evntUpdate").fmi2String )
          comp.isNewEventIteration = true
          comp.eventUpdate(timeEvent)
          timeEvent  = false
          stateEvent = false

      # terminate simulation, if requested by the model in the previous step
      if comp.eventInfo.terminateSimulation.bool:
        filteredLog(comp, fmi2Discard, all, (&"fmi2DoStep: model requested termination at t={comp.time.float}").fmi2String)
        comp.state = modelStepFailed
        return fmi2Discard # enforce termination of the simulation loop

    return fmi2OK


# Co-simulation functions
proc getStatus( fname:string; 
                comp:FmuRef;
                s:fmi2StatusKind): fmi2Status =
    ## inquire slave status
    let statusKind = @["fmi2DoStepStatus", "fmi2PendingStatus", "fmi2LastSuccessfulTime"]
    if invalidState(comp, fname, MASK_fmi2GetStatus): # all get status have the same MASK_fmi2GetStatus
      return fmi2Error
    filteredLog(comp, fmi2OK, fmiCall, (&"{fname}: fmi2StatusKind = {statusKind[s.int]}").fmi2String )

    case s
    of fmi2DoStepStatus: 
      filteredLog(comp, fmi2Error, error,
            (&"{fname}: Can be called with fmi2DoStepStatus when fmi2DoStep returned fmi2Pending.").fmi2String,
            " This is not the case.".fmi2String)

    of fmi2PendingStatus: 
      filteredLog(comp, fmi2Error, error,
            (&"{fname}: Can be called with fmi2PendingStatus when fmi2DoStep returned fmi2Pending.").fmi2String,
            " This is not the case.".fmi2String)

    of fmi2LastSuccessfulTime: 
      filteredLog(comp, fmi2Error, error,
            (&"{fname}: Can be called with fmi2LastSuccessfulTime when fmi2DoStep returned fmi2Discard.").fmi2String,
            " This is not the case.".fmi2String)
    of fmi2Terminated: 
      filteredLog(comp, fmi2Error, error,
            (&"{fname}: Can be called with fmi2Terminated when fmi2DoStep returned fmi2Discard.").fmi2String,
            " This is not the case.".fmi2String)

    return fmi2Discard

proc fmi2GetStatus*( comp: FmuRef;
                     s: fmi2StatusKind;
                     value: ptr fmi2Status):fmi2Status =
    return getStatus("fmi2GetStatus", comp, s)


proc fmi2GetRealStatus*( comp: FmuRef; 
                         s: fmi2StatusKind;
                         value: ptr fmi2Real):fmi2Status =
    if s == fmi2LastSuccessfulTime:
      if invalidState(comp, "fmi2GetRealStatus", MASK_fmi2GetRealStatus):
          return fmi2Error
      value[] = comp.time
      return fmi2OK
  
    return getStatus("fmi2GetRealStatus", comp, s)


proc fmi2GetIntegerStatus(comp:FmuRef;
                          s:fmi2StatusKind;
                          value: ptr fmi2Integer):fmi2Status =
    return getStatus("fmi2GetIntegerStatus", comp, s)


proc fmi2GetBooleanStatus(comp:FmuRef;
                          s:fmi2StatusKind;
                          value:ptr fmi2Boolean):fmi2Status =
    if (s == fmi2Terminated):
        if invalidState(comp, "fmi2GetBooleanStatus", MASK_fmi2GetBooleanStatus):
            return fmi2Error
        value[] = comp.eventInfo.terminateSimulation
        return fmi2OK
    
    return getStatus("fmi2GetBooleanStatus", comp, s)


proc fmi2GetStringStatus(comp:FmuRef; 
                         s:fmi2StatusKind;
                         value: ptr fmi2String): fmi2Status =
    return getStatus("fmi2GetStringStatus", comp, s)


{.pop.}

#[




        // terminate simulation, if requested by the model in the previous step
        if (comp->eventInfo.terminateSimulation) {
            FILTERED_LOG(comp, fmi2Discard, LOG_ALL, "fmi2DoStep: model requested termination at t=%g", comp->time)
            comp->state = modelStepFailed;
            return fmi2Discard; // enforce termination of the simulation loop
        }
    }
    return fmi2OK;
}
]#