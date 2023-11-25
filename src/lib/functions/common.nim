import strformat

{.push exportc:"$1",cdecl,dynlib.}

proc fmi2SetupExperiment*( comp: ModelInstanceRef; 
                           toleranceDefined: fmi2Boolean;
                           tolerance: fmi2Real; 
                           startTime: fmi2Real;
                           stopTimeDefined: fmi2Boolean; 
                           stopTime: fmi2Real): fmi2Status =
    # ignore arguments: stopTimeDefined, stopTime
    # echo "IN: fmi2SetupExperiment"
    # echo "comp.state: ", $comp.state
    # echo "mark: ", MASK_fmi2SetupExperiment
    if invalidState(comp, "fmi2SetupExperiment", MASK_fmi2SetupExperiment):
    #if invalidState(cast[ptr ModelInstanceRef](c), "fmi2SetupExperiment", MASK_fmi2SetupExperiment):
        echo "INVALID STATE!!!"
        return fmi2Error
    filteredLog( comp, fmi2OK, fmiCall,
                 fmt"fmi2SetupExperiment: toleranceDefined={toleranceDefined} tolerance={tolerance}".fmi2String)

    comp.time = startTime
    return fmi2OK


proc fmi2EnterInitializationMode*(comp: ModelInstanceRef): fmi2Status =
    ##var comp: ptr ModelInstanceRef = cast[ptr ModelInstanceRef](c)
    if invalidState(comp, "fmi2EnterInitializationMode", MASK_fmi2EnterInitializationMode):
        return fmi2Error
    filteredLog(comp, fmi2OK, fmiCall, "fmi2EnterInitializationMode".fmi2String)

    comp.state = modelInitializationMode
    return fmi2OK

proc fmi2ExitInitializationMode*(comp: ModelInstanceRef): fmi2Status =
    #var comp: ptr ModelInstanceRef = cast[ptr ModelInstanceRef](c)
    if invalidState(comp, "fmi2ExitInitializationMode", MASK_fmi2ExitInitializationMode):
        return fmi2Error
    filteredLog(comp, fmi2OK, fmiCall, "fmi2ExitInitializationMode".fmi2String)

    # if values were set and no fmi2GetXXX triggered update before,
    # ensure calculated values are updated now
    if comp.isDirtyValues > 0:
        calculateValues(comp)
        comp.isDirtyValues = fmi2False

    if comp.`type` == fmi2ModelExchange:
        comp.state = modelEventMode
        comp.isNewEventIteration = fmi2True

    else:
        comp.state = modelStepComplete
    return fmi2OK


proc fmi2Terminate*(comp: ModelInstanceRef): fmi2Status =
    #var comp: ptr ModelInstanceRef = cast[ptr ModelInstanceRef](c)
    if invalidState(comp, "fmi2Terminate", MASK_fmi2Terminate):
        return fmi2Error
    filteredLog(comp, fmi2OK, fmiCall, "fmi2Terminate".fmi2String)

    comp.state = modelTerminated
    return fmi2OK

# comp: ModelInstanceRef
proc fmi2Reset*(comp: ModelInstanceRef):fmi2Status =
    ##var comp: ptr ModelInstanceRef = cast[ptr ModelInstanceRef](c)
    #echo comp.GUID
    #var c = addr(comp)
    #echo type c
    if invalidState(comp, "fmi2Reset", MASK_fmi2Reset):
        return fmi2Error
    filteredLog(comp, fmi2OK, fmiCall, "fmi2Reset".fmi2String)

    comp.state = modelInstantiated
    echo "INSTANTIATED IN RESET"
    #setStartValues(c) # to be implemented by the includer of this file
    comp.isDirtyValues = fmi2True # because we just called setStartValues
    return fmi2OK





proc fmi2GetFMUstate*(comp:ModelInstanceRef; FMUstate: ptr fmi2FMUstate): fmi2Status =
    ##var comp: ptr ModelInstanceRef = cast[ptr ModelInstanceRef](c)
    return unsupportedFunction(comp, "fmi2GetFMUstate", MASK_fmi2GetFMUstate)

proc fmi2SetFMUstate*(comp: ModelInstanceRef; FMUstate: ptr fmi2FMUstate): fmi2Status =
    return unsupportedFunction(comp, "fmi2SetFMUstate", MASK_fmi2SetFMUstate)

proc fmi2FreeFMUstate*(comp: ModelInstanceRef; FMUstate: ptr fmi2FMUstate): fmi2Status =
    return unsupportedFunction(comp, "fmi2FreeFMUstate", MASK_fmi2FreeFMUstate)


proc fmi2SerializedFMUstateSize*(comp: ModelInstanceRef, FMUstate: ptr fmi2FMUstate,size: ptr csize_t): fmi2Status =
    return unsupportedFunction(comp, "fmi2SerializedFMUstateSize", MASK_fmi2SerializedFMUstateSize)

proc fmi2SerializeFMUstate*(comp:ModelInstanceRef; FMUstate: fmi2FMUstate;
                           serializedState: ptr fmi2Byte; size: csize_t): fmi2Status =
    return unsupportedFunction(comp, "fmi2SerializeFMUstate", MASK_fmi2SerializeFMUstate)

proc fmi2DeSerializeFMUstate*(comp:ModelInstanceRef; serializedState: ptr fmi2Byte;
                             size: csize_t; FMUstate: ptr fmi2FMUstate): fmi2Status =
    return unsupportedFunction(comp, "fmi2DeSerializeFMUstate", MASK_fmi2DeSerializeFMUstate)


proc fmi2GetDirectionalDerivative*(comp:ModelInstanceRef;
                                  vUnknown_ref: ptr fmi2ValueReference;
                                  nUnknown: csize_t;
                                  vKnown_ref: ptr fmi2ValueReference;
                                  nKnown: csize_t; dvKnown: ptr fmi2Real;
                                  dvUnknown: ptr fmi2Real): fmi2Status =
    return unsupportedFunction(comp, "fmi2GetDirectionalDerivative", MASK_fmi2GetDirectionalDerivative)

{.pop.}
