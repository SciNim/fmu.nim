#include "fmuTemplate.h"
/* ---------------------------------------------------------------------------*
 * fmuTemplate.c
 * Implementation of the FMI interface based on functions and macros to
 * be defined by the includer of this file.
 * The "FMI for Co-Simulation 2.0", implementation assumes that exactly the
 * following capability flags are set to fmi2True:
 *    canHandleVariableCommunicationStepSize, i.e. fmi2DoStep step size can vary
 * and all other capability flags are set to default, i.e. to fmi2False or 0.
 *
 * Revision history
 *  07.03.2014 initial version released in FMU SDK 2.0.0
 *  02.04.2014 allow modules to request termination of simulation, better time
 *             event handling, initialize() moved from fmi2EnterInitialization to
 *             fmi2ExitInitialization, correct logging message format in fmi2DoStep.
 *  10.04.2014 use FMI 2.0 headers that prefix function and types names with 'fmi2'.
 *  13.06.2014 when fmi2setDebugLogging is called with 0 categories, set all
 *             categories to loggingOn value.
 *  09.07.2014 track all states of Model-exchange and Co-simulation and check
 *             the allowed calling sequences, explicit isTimeEvent parameter for
 *             eventUpdate function of the model, lazy computation of computed values.
 *  07.05.2021 https://github.com/qtronic/fmusdk issue #6: allow NULL vector argument
 *             for FMI functions when there are zero states
 *
 * Author: Adrian Tirea
 * Copyright QTronic GmbH. All rights reserved.
 * ---------------------------------------------------------------------------*/

#ifdef __cplusplus
extern "C" {
#endif

// macro to be used to log messages. The macro check if current
// log category is valid and, if true, call the logger provided by simulator.
#define FILTERED_LOG(instance, status, categoryIndex, message, ...) if (status == fmi2Error || status == fmi2Fatal || isCategoryLogged(instance, categoryIndex)) \
        instance->functions->logger(instance->functions->componentEnvironment, instance->instanceName, status, \
        logCategoriesNames[categoryIndex], message, ##__VA_ARGS__);

static fmi2String logCategoriesNames[] = {"logAll", "logError", "logFmiCall", "logEvent"};

// array of value references of states
#if NUMBER_OF_STATES>0
fmi2ValueReference vrStates[NUMBER_OF_STATES] = STATES;
#endif

#ifndef max
#define max(a,b) ((a)>(b) ? (a) : (b))
#endif

#ifndef DT_EVENT_DETECT
#define DT_EVENT_DETECT 1e-10
#endif

// ---------------------------------------------------------------------------
// Private helpers used below to validate function arguments
// ---------------------------------------------------------------------------

fmi2Boolean isCategoryLogged(ModelInstance *comp, int categoryIndex);

static fmi2Boolean invalidNumber(ModelInstance *comp, const char *f, const char *arg, int n, int nExpected) {
    if (n != nExpected) {
        comp->state = modelError;
        FILTERED_LOG(comp, fmi2Error, LOG_ERROR, "%s: Invalid argument %s = %d. Expected %d.", f, arg, n, nExpected)
        return fmi2True;
    }
    return fmi2False;
}

static fmi2Boolean invalidState(ModelInstance *comp, const char *f, int statesExpected) {
    if (!comp)
        return fmi2True;
    if (!(comp->state & statesExpected)) {
        comp->state = modelError;
        FILTERED_LOG(comp, fmi2Error, LOG_ERROR, "%s: Illegal call sequence.", f)
        return fmi2True;
    }
    return fmi2False;
}

static fmi2Boolean nullPointer(ModelInstance* comp, const char *f, const char *arg, const void *p) {
    if (!p) {
        comp->state = modelError;
        FILTERED_LOG(comp, fmi2Error, LOG_ERROR, "%s: Invalid argument %s = NULL.", f, arg)
        return fmi2True;
    }
    return fmi2False;
}

static fmi2Boolean vrOutOfRange(ModelInstance *comp, const char *f, fmi2ValueReference vr, int end) {
    if (vr >= end) {
        FILTERED_LOG(comp, fmi2Error, LOG_ERROR, "%s: Illegal value reference %u.", f, vr)
        comp->state = modelError;
        return fmi2True;
    }
    return fmi2False;
}

static fmi2Status unsupportedFunction(fmi2Component c, const char *fName, int statesExpected) {
    ModelInstance *comp = (ModelInstance *)c;
    fmi2CallbackLogger log = comp->functions->logger;
    if (invalidState(comp, fName, statesExpected))
        return fmi2Error;
    FILTERED_LOG(comp, fmi2OK, LOG_FMI_CALL, fName);
    FILTERED_LOG(comp, fmi2Error, LOG_ERROR, "%s: Function not implemented.", fName)
    return fmi2Error;
}



// ---------------------------------------------------------------------------
// Private helpers logger
// ---------------------------------------------------------------------------

// return fmi2True if logging category is on. Else return fmi2False.
fmi2Boolean isCategoryLogged(ModelInstance *comp, int categoryIndex) {
    if (categoryIndex < NUMBER_OF_CATEGORIES
        && (comp->logCategories[categoryIndex] || comp->logCategories[LOG_ALL])) {
        return fmi2True;
    }
    return fmi2False;
}


// ---------------------------------------------------------------------------
// FMI functions: class methods not depending of a specific model instance
// ---------------------------------------------------------------------------

const char* fmi2GetVersion() {
    return fmi2Version;
}

const char* fmi2GetTypesPlatform() {
    return fmi2TypesPlatform;
}

// ---------------------------------------------------------------------------
// FMI functions: logging control, setters and getters for Real, Integer,
// Boolean, String
// ---------------------------------------------------------------------------



fmi2Status fmi2GetReal (fmi2Component c, const fmi2ValueReference vr[], size_t nvr, fmi2Real value[]) {
    int i;
    ModelInstance *comp = (ModelInstance *)c;
    if (invalidState(comp, "fmi2GetReal", MASK_fmi2GetReal))
        return fmi2Error;
    if (nvr > 0 && nullPointer(comp, "fmi2GetReal", "vr[]", vr))
        return fmi2Error;
    if (nvr > 0 && nullPointer(comp, "fmi2GetReal", "value[]", value))
        return fmi2Error;
    if (nvr > 0 && comp->isDirtyValues) {
        calculateValues(comp);
        comp->isDirtyValues = fmi2False;
    }
#if NUMBER_OF_REALS > 0
    for (i = 0; i < nvr; i++) {
        if (vrOutOfRange(comp, "fmi2GetReal", vr[i], NUMBER_OF_REALS))
            return fmi2Error;
        value[i] = getReal(comp, vr[i]); // to be implemented by the includer of this file

        FILTERED_LOG(comp, fmi2OK, LOG_FMI_CALL, "fmi2GetReal: #r%u# = %.16g", vr[i], value[i])
    }
#endif
    return fmi2OK;
}

fmi2Status fmi2GetInteger(fmi2Component c, const fmi2ValueReference vr[], size_t nvr, fmi2Integer value[]) {
    int i;
    ModelInstance *comp = (ModelInstance *)c;
    if (invalidState(comp, "fmi2GetInteger", MASK_fmi2GetInteger))
        return fmi2Error;
    if (nvr > 0 && nullPointer(comp, "fmi2GetInteger", "vr[]", vr))
            return fmi2Error;
    if (nvr > 0 && nullPointer(comp, "fmi2GetInteger", "value[]", value))
            return fmi2Error;
    if (nvr > 0 && comp->isDirtyValues) {
        calculateValues(comp);
        comp->isDirtyValues = fmi2False;
    }
    for (i = 0; i < nvr; i++) {
        if (vrOutOfRange(comp, "fmi2GetInteger", vr[i], NUMBER_OF_INTEGERS))
            return fmi2Error;
        value[i] = comp->i[vr[i]];
        FILTERED_LOG(comp, fmi2OK, LOG_FMI_CALL, "fmi2GetInteger: #i%u# = %d", vr[i], value[i])
    }
    return fmi2OK;
}

fmi2Status fmi2GetBoolean(fmi2Component c, const fmi2ValueReference vr[], size_t nvr, fmi2Boolean value[]) {
    int i;
    ModelInstance *comp = (ModelInstance *)c;
    if (invalidState(comp, "fmi2GetBoolean", MASK_fmi2GetBoolean))
        return fmi2Error;
    if (nvr > 0 && nullPointer(comp, "fmi2GetBoolean", "vr[]", vr))
            return fmi2Error;
    if (nvr > 0 && nullPointer(comp, "fmi2GetBoolean", "value[]", value))
            return fmi2Error;
    if (nvr > 0 && comp->isDirtyValues) {
        calculateValues(comp);
        comp->isDirtyValues = fmi2False;
    }
    for (i = 0; i < nvr; i++) {
        if (vrOutOfRange(comp, "fmi2GetBoolean", vr[i], NUMBER_OF_BOOLEANS))
            return fmi2Error;
        value[i] = comp->b[vr[i]];
        FILTERED_LOG(comp, fmi2OK, LOG_FMI_CALL, "fmi2GetBoolean: #b%u# = %s", vr[i], value[i]? "true" : "false")
    }
    return fmi2OK;
}

fmi2Status fmi2GetString (fmi2Component c, const fmi2ValueReference vr[], size_t nvr, fmi2String value[]) {
    int i;
    ModelInstance *comp = (ModelInstance *)c;
    if (invalidState(comp, "fmi2GetString", MASK_fmi2GetString))
        return fmi2Error;
    if (nvr>0 && nullPointer(comp, "fmi2GetString", "vr[]", vr))
            return fmi2Error;
    if (nvr>0 && nullPointer(comp, "fmi2GetString", "value[]", value))
            return fmi2Error;
    if (nvr > 0 && comp->isDirtyValues) {
        calculateValues(comp);
        comp->isDirtyValues = fmi2False;
    }
    for (i=0; i<nvr; i++) {
        if (vrOutOfRange(comp, "fmi2GetString", vr[i], NUMBER_OF_STRINGS))
            return fmi2Error;
        value[i] = comp->s[vr[i]];
        FILTERED_LOG(comp, fmi2OK, LOG_FMI_CALL, "fmi2GetString: #s%u# = '%s'", vr[i], value[i])
    }
    return fmi2OK;
}


// fmi2Status fmi2GetFMUstate (fmi2Component c, fmi2FMUstate* FMUstate) {
//     return unsupportedFunction(c, "fmi2GetFMUstate", MASK_fmi2GetFMUstate);
// }
// fmi2Status fmi2SetFMUstate (fmi2Component c, fmi2FMUstate FMUstate) {
//     return unsupportedFunction(c, "fmi2SetFMUstate", MASK_fmi2SetFMUstate);
// }
// fmi2Status fmi2FreeFMUstate(fmi2Component c, fmi2FMUstate* FMUstate) {
//     return unsupportedFunction(c, "fmi2FreeFMUstate", MASK_fmi2FreeFMUstate);
// }
// fmi2Status fmi2SerializedFMUstateSize(fmi2Component c, fmi2FMUstate FMUstate, size_t *size) {
//     return unsupportedFunction(c, "fmi2SerializedFMUstateSize", MASK_fmi2SerializedFMUstateSize);
// }
// fmi2Status fmi2SerializeFMUstate (fmi2Component c, fmi2FMUstate FMUstate, fmi2Byte serializedState[], size_t size) {
//     return unsupportedFunction(c, "fmi2SerializeFMUstate", MASK_fmi2SerializeFMUstate);
// }
// fmi2Status fmi2DeSerializeFMUstate (fmi2Component c, const fmi2Byte serializedState[], size_t size,
//                                     fmi2FMUstate* FMUstate) {
//     return unsupportedFunction(c, "fmi2DeSerializeFMUstate", MASK_fmi2DeSerializeFMUstate);
// }

// fmi2Status fmi2GetDirectionalDerivative(fmi2Component c, const fmi2ValueReference vUnknown_ref[], size_t nUnknown,
//                                         const fmi2ValueReference vKnown_ref[] , size_t nKnown,
//                                         const fmi2Real dvKnown[], fmi2Real dvUnknown[]) {
//     return unsupportedFunction(c, "fmi2GetDirectionalDerivative", MASK_fmi2GetDirectionalDerivative);
// }


//===========================
// FIXME
//===========================
// fmi2Component fmi2Instantiate(fmi2String instanceName, fmi2Type fmuType, fmi2String fmuGUID,
//                             fmi2String fmuResourceLocation, const fmi2CallbackFunctions *functions,
//                             fmi2Boolean visible, fmi2Boolean loggingOn) {
//     // ignoring arguments: fmuResourceLocation, visible
//     ModelInstance *comp;
//     printf("%p\n",(void*)functions->logger);
//     if (!functions->logger) {
//         return NULL;
//     }

//     if (!functions->allocateMemory || !functions->freeMemory) {
//         functions->logger(functions->componentEnvironment, instanceName, fmi2Error, "error",
//                 "fmi2Instantiate: Missing callback function.");
//         return NULL;
//     }
//     if (!instanceName || strlen(instanceName) == 0) {
//         functions->logger(functions->componentEnvironment, "?", fmi2Error, "error",
//                 "fmi2Instantiate: Missing instance name.");
//         return NULL;
//     }
//     if (!fmuGUID || strlen(fmuGUID) == 0) {
//         functions->logger(functions->componentEnvironment, instanceName, fmi2Error, "error",
//                 "fmi2Instantiate: Missing GUID.");
//         return NULL;
//     }
//     if (strcmp(fmuGUID, MODEL_GUID)) {
//         functions->logger(functions->componentEnvironment, instanceName, fmi2Error, "error",
//                 "fmi2Instantiate: Wrong GUID %s. Expected %s.", fmuGUID, MODEL_GUID);
//         return NULL;
//     }
//     comp = (ModelInstance *)functions->allocateMemory(1, sizeof(ModelInstance));
//     if (comp) {
//         int i;
//         comp->r = (fmi2Real *)   functions->allocateMemory(NUMBER_OF_REALS,    sizeof(fmi2Real));
//         comp->i = (fmi2Integer *)functions->allocateMemory(NUMBER_OF_INTEGERS, sizeof(fmi2Integer));
//         comp->b = (fmi2Boolean *)functions->allocateMemory(NUMBER_OF_BOOLEANS, sizeof(fmi2Boolean));
//         comp->s = (fmi2String *) functions->allocateMemory(NUMBER_OF_STRINGS,  sizeof(fmi2String));
//         comp->isPositive = (fmi2Boolean *)functions->allocateMemory(NUMBER_OF_EVENT_INDICATORS,
//             sizeof(fmi2Boolean));
//         comp->instanceName = (char *)functions->allocateMemory(1 + strlen(instanceName), sizeof(char));
//         comp->GUID = (char *)functions->allocateMemory(1 + strlen(fmuGUID), sizeof(char));

//         // set all categories to on or off. fmi2SetDebugLogging should be called to choose specific categories.
//         for (i = 0; i < NUMBER_OF_CATEGORIES; i++) {
//             comp->logCategories[i] = loggingOn;
//         }
//     }
//     if (!comp || !comp->r || !comp->i || !comp->b || !comp->s || !comp->isPositive
//         || !comp->instanceName || !comp->GUID) {

//         functions->logger(functions->componentEnvironment, instanceName, fmi2Error, "error",
//             "fmi2Instantiate: Out of memory.");
//         return NULL;
//     }
//     comp->time = 0; // overwrite in fmi2SetupExperiment, fmi2SetTime
//     strcpy((char *)comp->instanceName, (char *)instanceName);
//     comp->type = fmuType;
//     strcpy((char *)comp->GUID, (char *)fmuGUID);
//     comp->functions = functions;
//     comp->componentEnvironment = functions->componentEnvironment;
//     comp->loggingOn = loggingOn;
//     comp->state = modelInstantiated;
//     setStartValues(comp); // to be implemented by the includer of this file
//     comp->isDirtyValues = fmi2True; // because we just called setStartValues
//     comp->isNewEventIteration = fmi2False;

//     comp->eventInfo.newDiscreteStatesNeeded = fmi2False;
//     comp->eventInfo.terminateSimulation = fmi2False;
//     comp->eventInfo.nominalsOfContinuousStatesChanged = fmi2False;
//     comp->eventInfo.valuesOfContinuousStatesChanged = fmi2False;
//     comp->eventInfo.nextEventTimeDefined = fmi2False;
//     comp->eventInfo.nextEventTime = 0;

//     FILTERED_LOG(comp, fmi2OK, LOG_FMI_CALL, "fmi2Instantiate: GUID=%s", fmuGUID)

//     return comp;
// }




#ifdef __cplusplus
} // closing brace for extern "C"
#endif
