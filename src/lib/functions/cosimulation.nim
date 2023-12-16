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

template useGetEventIndicator2():untyped =
    mixin getEventIndicator

    if comp.nEventIndicators > 0:
        # check for state event
        for i in 0 ..< comp.nEventIndicators: #NUMBER_OF_EVENT_INDICATORS:
            var ei:double = getEventIndicator(comp, i)
            var ei:float = 0.0  # <---- borrame
            if ei * prevEventIndicators[i] < 0 :
                var tmp:string
                if ei < 0:
                    tmp = "\\"
                else:
                    tmp = "/"
                filteredLog(comp, fmi2OK, LOG_EVENT,
                    fmt"fmi2DoStep: state event at {comp.time}, z{i} crosses zero -{tmp}-".fmi2String)
                inc stateEvent # stateEvent++

            prevEventIndicators[i] = ei

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
    # comp.state = modelStepCanceled;
    return fmi2Error


proc fmi2DoStep*( comp: FmuRef; 
                  currentCommunicationPoint: fmi2Real;
                  communicationStepSize: fmi2Real;
                  noSetFMUStatePriorToCurrentPoint: fmi2Boolean): fmi2Status =
    ##[

    ]##   
    var h:float  = communicationStepSize / 10.0

    var n = 10 # how many Euler steps to perform for one do step
    var prevState: seq[float] 
    var prevEventIndicators: seq[float]
    var stateEvent = false
    var timeEvent  = false


    if invalidState(comp, "fmi2DoStep", MASK_fmi2DoStep):
        return fmi2Error



    var tmp:string
    if noSetFMUStatePriorToCurrentPoint > 1:
        tmp = "True"
    else:
        tmp = "False"
    filteredLog(comp, fmi2OK, fmiCall, (&"fmi2DoStep: \ncurrentCommunicationPoint = {currentCommunicationPoint}, communicationStepSize = {communicationStepSize}, noSetFMUStatePriorToCurrentPoint = fmi2{tmp}").fmi2String )
    #[
    FILTERED_LOG(comp, fmi2OK, LOG_FMI_CALL, "fmi2DoStep: "
        "currentCommunicationPoint = %g, "
        "communicationStepSize = %g, "
        "noSetFMUStatePriorToCurrentPoint = fmi2%s",
        currentCommunicationPoint, communicationStepSize, noSetFMUStatePriorToCurrentPoint ? "True" : "False")
    ]#


    if (communicationStepSize <= 0):
        filteredLog(comp, fmi2Error, error,
            fmt"fmi2DoStep: communication step size must be > 0. Fount {communicationStepSize}.".fmi2String )
        comp.state = modelError
        return fmi2Error
    #[
        FILTERED_LOG(comp, fmi2Error, LOG_ERROR,
            "fmi2DoStep: communication step size must be > 0. Fount %g.", communicationStepSize) 
    ]#

    when declared(getEventIndicator):
        if comp.nEventIndicators > 0:
            # initialize previous event indicators with current values
            for i in 0 ..< comp.nEventIndicators: #NUMBER_OF_EVENT_INDICATORS:
              prevEventIndicators[i] = getEventIndicator(comp, i)  # <-- // to be implemented by the includer of this file

    # break the step into n steps and do forward Euler.
    comp.time = currentCommunicationPoint
    for k in 0 ..< n:
        comp.time += h

    when declared(getReal):
      if comp.states.len > 0:
        for i in 0 ..< comp.states.len:
          prevState[i] = comp[comp.reals[comp.states[i]]].valueR

        for i in 0 ..< comp.states.len:
          var vr = comp.states[i]
          #echo "--->",comp.reals[vr + 1]
          comp[comp.reals[vr]].valueR += h * comp.getReal(comp.reals[vr + 1]) # FIXME: no debería usar la derivada
          #r(vr) += h * getReal(comp, vr + 1); // forward Euler step



    # if comp.states.len > 0:  # NUMBER_OF_STATES > 0:

    #     for i in 0 ..< comp.states.len: #NUMBER_OF_STATES:
    #         prevState[i] = comp.realAddr[comp.states[i]][]

    #     for i in 0 ..< comp.states.len: #NUMBER_OF_STATES:
    #         var vr:fmi2ValueReference = comp.states[i].fmi2ValueReference #vrStates[i]
    #         comp.realAddr[comp.states[i]][] += h * getReal(comp, vr + 1)  # forward Euler step

    # when NUMBER_OF_EVENT_INDICATORS > 0:
    #     # check for state event
    #     for i in 0 ..< NUMBER_OF_EVENT_INDICATORS:
    #         var ei:double = getEventIndicator(comp, i)
    #         var ei:float = 0.0  # <---- borrame
    #         if ei * prevEventIndicators[i] < 0 :
    #             var tmp:string
    #             if ei < 0:
    #                 tmp = "\\"
    #             else:
    #                 tmp = "/"
    #             filteredLog(comp, fmi2OK, LOG_EVENT,
    #                 fmt"fmi2DoStep: state event at {comp.time}, z{i} crosses zero -{tmp}-".fmi2String)
    #             inc stateEvent # stateEvent++

    #         prevEventIndicators[i] = ei 

        when declared(getEventIndicator):
            if comp.nEventIndicators > 0:
                # check for state event
                for i in 0 ..< comp.nEventIndicators:
                    var ei = getEventIndicator(comp, i)
                    if ei * prevEventIndicators[i] < 0 :
                        var tmp:string
                        if ei < 0:
                            tmp = "\\"
                        else:
                            tmp = "/"
                        filteredLog(comp, fmi2OK, LOG_EVENT,
                            fmt"fmi2DoStep: state event at {comp.time}, z{i} crosses zero -{tmp}-".fmi2String)
                        inc stateEvent # stateEvent++

                    prevEventIndicators[i] = ei

        # check for time event
        if (comp.eventInfo.nextEventTimeDefined > 0 and (comp.time - comp.eventInfo.nextEventTime > -DT_EVENT_DETECT)):
            filteredLog(comp, fmi2OK, event, fmt"fmi2DoStep: time event detected at {comp.time}".fmi2String )
            timeEvent = true

        when declared(eventUpdate):
          if (stateEvent or timeEvent):
              #eventUpdate(comp)
              #comp.isNewEventIteration = fmi2True
              eventUpdate(comp, timeEvent)
              
              timeEvent = false
              stateEvent = false


        # terminate simulation, if requested by the model in the previous step
        if (comp.eventInfo.terminateSimulation) > 0:
            filteredLog(comp, fmi2Discard, all, (&"fmi2DoStep: model requested termination at t={comp.time}").fmi2String)
            comp.state = modelStepFailed
            return fmi2Discard # enforce termination of the simulation loop

    return fmi2OK

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