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

// fmi2Boolean isCategoryLogged(ModelInstance *comp, int categoryIndex);

// static fmi2Boolean invalidNumber(ModelInstance *comp, const char *f, const char *arg, int n, int nExpected) {
//     if (n != nExpected) {
//         comp->state = modelError;
//         FILTERED_LOG(comp, fmi2Error, LOG_ERROR, "%s: Invalid argument %s = %d. Expected %d.", f, arg, n, nExpected)
//         return fmi2True;
//     }
//     return fmi2False;
// }

// static fmi2Boolean invalidState(ModelInstance *comp, const char *f, int statesExpected) {
//     if (!comp)
//         return fmi2True;
//     if (!(comp->state & statesExpected)) {
//         comp->state = modelError;
//         FILTERED_LOG(comp, fmi2Error, LOG_ERROR, "%s: Illegal call sequence.", f)
//         return fmi2True;
//     }
//     return fmi2False;
// }

// static fmi2Boolean nullPointer(ModelInstance* comp, const char *f, const char *arg, const void *p) {
//     if (!p) {
//         comp->state = modelError;
//         FILTERED_LOG(comp, fmi2Error, LOG_ERROR, "%s: Invalid argument %s = NULL.", f, arg)
//         return fmi2True;
//     }
//     return fmi2False;
// }

// static fmi2Boolean vrOutOfRange(ModelInstance *comp, const char *f, fmi2ValueReference vr, int end) {
//     if (vr >= end) {
//         FILTERED_LOG(comp, fmi2Error, LOG_ERROR, "%s: Illegal value reference %u.", f, vr)
//         comp->state = modelError;
//         return fmi2True;
//     }
//     return fmi2False;
// }

// static fmi2Status unsupportedFunction(fmi2Component c, const char *fName, int statesExpected) {
//     ModelInstance *comp = (ModelInstance *)c;
//     fmi2CallbackLogger log = comp->functions->logger;
//     if (invalidState(comp, fName, statesExpected))
//         return fmi2Error;
//     FILTERED_LOG(comp, fmi2OK, LOG_FMI_CALL, fName);
//     FILTERED_LOG(comp, fmi2Error, LOG_ERROR, "%s: Function not implemented.", fName)
//     return fmi2Error;
// }



// ---------------------------------------------------------------------------
// Private helpers logger
// ---------------------------------------------------------------------------

// return fmi2True if logging category is on. Else return fmi2False.
// fmi2Boolean isCategoryLogged(ModelInstance *comp, int categoryIndex) {
//     if (categoryIndex < NUMBER_OF_CATEGORIES
//         && (comp->logCategories[categoryIndex] || comp->logCategories[LOG_ALL])) {
//         return fmi2True;
//     }
//     return fmi2False;
// }




#ifdef __cplusplus
} // closing brace for extern "C"
#endif
