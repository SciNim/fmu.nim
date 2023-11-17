#import model
#import definitions
#import fmi2TypesPlatform, fmi2type, fmi2callbackfunctions, modelstate, fmi2eventinfo,
#import logger
import strformat


# https://forum.nim-lang.org/t/7182#45378
# https://forum.nim-lang.org/t/6980#43777mf


##  Creation and destruction of FMU instances and setting debug status
{.push exportc:"$1",dynlib,cdecl.}


# https://forum.nim-lang.org/t/7496

proc fmi2Instantiate*( instanceName: fmi2String;
                       fmuType: fmi2Type;
                       fmuGUID: fmi2String;
                       fmuResourceLocation: fmi2String;
                       functions: fmi2CallbackFunctions;
                       visible: fmi2Boolean;
                       loggingOn: fmi2Boolean): ModelInstanceRef = 
  ## instantiates a ModelInstance. This is a black box for the simulation
  ## tool; just a pointer will be shared.
  
  # ignoring arguments: fmuResourceLocation, visible
  echo "Entering fmi2Instantiate"
  echo repr functions
  echo repr functions.componentEnvironment

  # Under the following conditions, it cannot be instantiated. Log details when possible.
  
  # - If no logger function, return inmediately
  if functions.logger.isNil:
      return nil

  # - If no "allocateMemory" or "freeMemory" functions, return and log.
  if functions.allocateMemory.isNil or 
     functions.freeMemory.isNil:
    functions.logger( functions.componentEnvironment, instanceName, fmi2Error, "error".fmi2String,
              "fmi2Instantiate: Missing callback function.".fmi2String)
    return nil

  # - If instanceName not good, return and log 
  if instanceName.cstring.isNil or instanceName.cstring.len == 0:  # 
      functions.logger( functions.componentEnvironment, "?".fmi2String, fmi2Error, "error".fmi2String,
              "fmi2Instantiate: Missing instance name.".fmi2String)
      return nil

  # - If fmuGUID not good, return and log 
  if fmuGUID.cstring.isNil or fmuGUID.cstring.len == 0:
      functions.logger( functions.componentEnvironment, instanceName, fmi2Error, "error".fmi2String,
                "fmi2Instantiate: Missing GUID.".fmi2String)
      return nil
    
  # Start creating the instance
  var comp = ModelInstanceRef( time: 0, 
                               instanceName: instanceName, 
                               `type`: fmuType, 
                               guid: $fmuGUID )

  # If loggingOn=fmi2True: set all logging categories to ON.                     
  if not comp.isNil:
      # we log all considered categories
      # fmi2SetDebugLogging should be called to choose specific categories.
      if loggingOn == fmi2True:
        for i in LoggingCategories:
            comp.logCategories.incl( i ) 


  # if comp.isNil or comp.r.isNil or comp.i.isNil or comp.b.isNil or comp.s.isNil or comp.isPositive.isNil or
  #    comp.instanceName.cstring.isNil or comp.GUID.cstring.isNil:
  #     #functions.logger(functions.componentEnvironment, instanceName, fmi2Error, "error".fmi2String,
  #     #    "fmi2Instantiate: Out of memory.".fmi2String)
  #     echo "WRONG"
  #     return nil
  

  comp.functions = functions

  comp.componentEnvironment = functions.componentEnvironment

  comp.loggingOn = loggingOn

  comp.state = modelInstantiated   # State changed

  setStartValues( comp )    # <------ to be implemented by the includer of this file
  
  comp.isDirtyValues = fmi2True # because we just called setStartValues
  comp.isNewEventIteration = fmi2False

  comp.eventInfo.newDiscreteStatesNeeded = fmi2False
  comp.eventInfo.terminateSimulation = fmi2False
  comp.eventInfo.nominalsOfContinuousStatesChanged = fmi2False
  comp.eventInfo.valuesOfContinuousStatesChanged = fmi2False
  comp.eventInfo.nextEventTimeDefined = fmi2False
  comp.eventInfo.nextEventTime = 0

  # FILTERED_LOG(comp, fmi2OK, fmiCall, "fmi2Instantiate: GUID=%s", fmuGUID)
  echo "ok-4"     # FIXME-----
  filteredLog( comp, fmi2OK, fmiCall, 
                fmt"fmi2Instantiate: GUID={$fmuGUID}".fmi2String)#, fmuGUID)
  echo "ok-5"     # -----------
  echo "leaving fmi2Instantiate"
  return comp  



#[
In addition to GC_ref and GC_unref you can avoid the garbage collector 
by manually allocating memory with procs like:
  alloc, alloc0, allocShared, allocShared0 or allocCStringArray. 
  
The garbage collector won't try to free them, you need to call their 
respective dealloc pairs (dealloc, deallocShared, deallocCStringArray, etc) 
when you are done with them or they will leak.
]#


#[
if (!comp || !comp->r || !comp->i || !comp->b || !comp->s || !comp->isPositive
    || !comp->instanceName || !comp->GUID) {
    functions->logger(functions->componentEnvironment, instanceName, fmi2Error, "error",
        "fmi2Instantiate: Out of memory.");
    return NULL;
}
]#


{.pop.}
