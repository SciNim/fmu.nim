{.push exportc,cdecl,dynlib.}

proc fmi2SetRealInputDerivatives*(comp: var ModelInstance; vr: ptr fmi2ValueReference;
                                 nvr: csize_t; order: ptr fmi2Integer;
                                 value: ptr fmi2Real): fmi2Status =
    ##var comp: ptr ModelInstance = cast[ptr ModelInstance](c)
    if invalidState(comp, "fmi2SetRealInputDerivatives", MASK_fmi2SetRealInputDerivatives):
        return fmi2Error

    filteredLog(comp, fmi2OK, LOG_FMI_CALL, fmt"fmi2SetRealInputDerivatives: nvr= {nvr}")
    filteredLog(comp, fmi2Error, LOG_ERROR, fmt"fmi2SetRealInputDerivatives: ignoring function call.\nThis model cannot interpolate inputs: canInterpolateInputs='{fmi2False}'")
    return fmi2Error

proc fmi2GetRealOutputDerivatives*(comp: var ModelInstance; vr: ptr fmi2ValueReference;
                                  nvr: csize_t; order: ptr fmi2Integer;
                                  value: ptr fmi2Real): fmi2Status =
    ##var comp: ptr ModelInstance = cast[ptr ModelInstance](c)
    if invalidState(comp, "fmi2GetRealOutputDerivatives", MASK_fmi2GetRealOutputDerivatives):
        return fmi2Error
    filteredLog(comp, fmi2OK, LOG_FMI_CALL, fmt"fmi2GetRealOutputDerivatives: nvr= {nvr}")
    filteredLog(comp, fmi2Error, LOG_ERROR, fmt"fmi2GetRealOutputDerivatives: ignoring function call.\nThis model cannot compute derivatives of outputs: MaxOutputDerivativeOrder='0'")
    for i in 0 ..< nvr:
        value[i] = 0
    return fmi2Error


proc fmi2CancelStep*(comp: var ModelInstance):fmi2Status =
    ##var comp: ptr ModelInstance = cast[ptr ModelInstance](c)
    if invalidState(comp, "fmi2CancelStep", MASK_fmi2CancelStep):
        # always fmi2CancelStep is invalid, because model is never in modelStepInProgress state.
        return fmi2Error

    filteredLog(comp, fmi2OK, LOG_FMI_CALL, "fmi2CancelStep")
    filteredLog(comp, fmi2Error, LOG_ERROR,fmt"fmi2CancelStep: Can be called when fmi2DoStep returned fmi2Pending.\n This is not the case.")
    # comp.state = modelStepCanceled;
    return fmi2Error


proc fmi2DoStep*(comp: var ModelInstance; currentCommunicationPoint: fmi2Real;
                communicationStepSize: fmi2Real;
                noSetFMUStatePriorToCurrentPoint: fmi2Boolean): fmi2Status =
    ##[

    ]##
    var h:cdouble  = communicationStepSize / 10

    var n = 10 # how many Euler steps to perform for one do step
    var prevState: array[max(NUMBER_OF_STATES, 1), cdouble]
    var prevEventIndicators: array[max(NUMBER_OF_EVENT_INDICATORS, 1), cdouble]
    var stateEvent:int = 0
    var timeEvent:int = 0

    if invalidState(comp, "fmi2DoStep", MASK_fmi2DoStep):
        return fmi2Error

    var tmp:string
    if noSetFMUStatePriorToCurrentPoint > 1:
        tmp = "True"
    else:
        tmp = "False"
    filteredLog(comp, fmi2OK, LOG_FMI_CALL, fmt"fmi2DoStep: \ncurrentCommunicationPoint = {currentCommunicationPoint}, communicationStepSize = {communicationStepSize}, noSetFMUStatePriorToCurrentPoint = fmi2{tmp}" )

    if (communicationStepSize <= 0):
        filteredLog(comp, fmi2Error, LOG_ERROR,
            fmt"fmi2DoStep: communication step size must be > 0. Fount {communicationStepSize}." )
        comp.state = modelError
        return fmi2Error


    when NUMBER_OF_EVENT_INDICATORS > 0:
        # initialize previous event indicators with current values
        for i in 0 ..< NUMBER_OF_EVENT_INDICATORS:
           prevEventIndicators[i] = getEventIndicator(comp, i)  # <-- // to be implemented by the includer of this file

    # break the step into n steps and do forward Euler.
    comp.time = currentCommunicationPoint
    for k in 0 ..< n:
        comp.time += h

    when NUMBER_OF_STATES > 0:
        for i in 0 ..< NUMBER_OF_STATES:
            prevState[i] = comp.r[vrStates[i]][]

        for i in 0 ..< NUMBER_OF_STATES:
            var vr:fmi2ValueReference = vrStates[i]
            comp.r[vr][] += h * getReal(comp, vr + 1)  # forward Euler step

    when NUMBER_OF_EVENT_INDICATORS > 0:
        # check for state event
        for i in 0 ..< NUMBER_OF_EVENT_INDICATORS:
            var ei:double = getEventIndicator(comp, i)
            var ei:float = 0.0  # <---- borrame
            if ei * prevEventIndicators[i] < 0 :
                var tmp:string
                if ei < 0:
                    tmp = "\\"
                else:
                    tmp = "/"
                filteredLog(comp, fmi2OK, LOG_EVENT,
                    fmt"fmi2DoStep: state event at {comp.time}, z{i} crosses zero -{tmp}-")
                inc stateEvent # stateEvent++

            prevEventIndicators[i] = ei


        # check for time event
        if (comp.eventInfo.nextEventTimeDefined > 0 and (comp.time - comp.eventInfo.nextEventTime > -DT_EVENT_DETECT)):
            filteredLog(comp, fmi2OK, LOG_EVENT, fmt"fmi2DoStep: time event detected at {comp.time}" )
            timeEvent = 1


        if (stateEvent > 0 or timeEvent > 0):
            eventUpdate(comp, addr( comp.eventInfo ), timeEvent, fmi2True)
            timeEvent = 0
            stateEvent = 0


        # terminate simulation, if requested by the model in the previous step
        if (comp.eventInfo.terminateSimulation) > 0:
            filteredLog(comp, fmi2Discard, LOG_ALL, fmt"fmi2DoStep: model requested termination at t={comp.time}")
            comp.state = modelStepFailed
            return fmi2Discard # enforce termination of the simulation loop

    return fmi2OK

{.pop.}
