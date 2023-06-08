#import fmi2TypesPlatform, status, modelinstance,
#       modelstate, fmi2type, modelinstancetype, helpers, masks, logger
#import model
import strformat

{.push exportc:"$1",cdecl,dynlib.}

#comp:ModelInstance
proc fmi2SetupExperiment*(comp: ModelInstance; toleranceDefined: fmi2Boolean;
                         tolerance: fmi2Real; startTime: fmi2Real;
                         stopTimeDefined: fmi2Boolean; stopTime: fmi2Real): fmi2Status =

    # ignore arguments: stopTimeDefined, stopTime
    echo "ENTERING: fmi2SetupExperiment"
    echo typeof(comp.functions)


    #echo repr c
    #var comp = cast[ref ModelInstance](c)
    #echo comp.GUID
    #echo comp.isNil
    if invalidState(comp, "fmi2SetupExperiment", MASK_fmi2SetupExperiment):
    #if invalidState(cast[ptr ModelInstance](c), "fmi2SetupExperiment", MASK_fmi2SetupExperiment):
        echo "INVALID STATE!!!"
        return fmi2Error
    filteredLog( comp, fmi2OK, LOG_FMI_CALL,
                 fmt"fmi2SetupExperiment: toleranceDefined={toleranceDefined} tolerance={tolerance}")

    comp.time = startTime
    return fmi2OK


proc fmi2EnterInitializationMode*(comp: var ModelInstance): fmi2Status =
    ##var comp: ptr ModelInstance = cast[ptr ModelInstance](c)
    if invalidState(comp, "fmi2EnterInitializationMode", MASK_fmi2EnterInitializationMode):
        return fmi2Error
    filteredLog(comp, fmi2OK, LOG_FMI_CALL, "fmi2EnterInitializationMode")

    comp.state = modelInitializationMode
    return fmi2OK

proc fmi2ExitInitializationMode*(comp: var ModelInstance): fmi2Status =
    #var comp: ptr ModelInstance = cast[ptr ModelInstance](c)
    if invalidState(comp, "fmi2ExitInitializationMode", MASK_fmi2ExitInitializationMode):
        return fmi2Error
    filteredLog(comp, fmi2OK, LOG_FMI_CALL, "fmi2ExitInitializationMode")

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


proc fmi2Terminate*(comp: var ModelInstance): fmi2Status =
    #var comp: ptr ModelInstance = cast[ptr ModelInstance](c)
    if invalidState(comp, "fmi2Terminate", MASK_fmi2Terminate):
        return fmi2Error
    filteredLog(comp, fmi2OK, LOG_FMI_CALL, "fmi2Terminate")

    comp.state = modelTerminated
    return fmi2OK

# comp: ModelInstance
proc fmi2Reset*(comp: var ModelInstance):fmi2Status =
    ##var comp: ptr ModelInstance = cast[ptr ModelInstance](c)
    #echo comp.GUID
    #var c = addr(comp)
    #echo type c
    if invalidState(comp, "fmi2Reset", MASK_fmi2Reset):
        return fmi2Error
    filteredLog(comp, fmi2OK, LOG_FMI_CALL, "fmi2Reset")

    comp.state = modelInstantiated
    echo "INSTANTIATED IN RESET"
    #setStartValues(c) # to be implemented by the includer of this file
    comp.isDirtyValues = fmi2True # because we just called setStartValues
    return fmi2OK





proc fmi2GetFMUstate*(comp:var ModelInstance; FMUstate: ptr fmi2FMUstate): fmi2Status =
    ##var comp: ptr ModelInstance = cast[ptr ModelInstance](c)
    return unsupportedFunction(comp, "fmi2GetFMUstate", MASK_fmi2GetFMUstate)

proc fmi2SetFMUstate*(comp: var ModelInstance; FMUstate: ptr fmi2FMUstate): fmi2Status =
    return unsupportedFunction(comp, "fmi2SetFMUstate", MASK_fmi2SetFMUstate)

proc fmi2FreeFMUstate*(comp: var ModelInstance; FMUstate: ptr fmi2FMUstate): fmi2Status =
    return unsupportedFunction(comp, "fmi2FreeFMUstate", MASK_fmi2FreeFMUstate)


proc fmi2SerializedFMUstateSize*(comp: var ModelInstance, FMUstate: ptr fmi2FMUstate,size: ptr csize_t): fmi2Status =
    return unsupportedFunction(comp, "fmi2SerializedFMUstateSize", MASK_fmi2SerializedFMUstateSize)

proc fmi2SerializeFMUstate*(comp:var ModelInstance; FMUstate: fmi2FMUstate;
                           serializedState: ptr fmi2Byte; size: csize_t): fmi2Status =
    return unsupportedFunction(comp, "fmi2SerializeFMUstate", MASK_fmi2SerializeFMUstate)

proc fmi2DeSerializeFMUstate*(comp:var ModelInstance; serializedState: ptr fmi2Byte;
                             size: csize_t; FMUstate: ptr fmi2FMUstate): fmi2Status =
    return unsupportedFunction(comp, "fmi2DeSerializeFMUstate", MASK_fmi2DeSerializeFMUstate)


proc fmi2GetDirectionalDerivative*(comp:var ModelInstance;
                                  vUnknown_ref: ptr fmi2ValueReference;
                                  nUnknown: csize_t;
                                  vKnown_ref: ptr fmi2ValueReference;
                                  nKnown: csize_t; dvKnown: ptr fmi2Real;
                                  dvUnknown: ptr fmi2Real): fmi2Status =
    return unsupportedFunction(comp, "fmi2GetDirectionalDerivative", MASK_fmi2GetDirectionalDerivative)

{.pop.}
