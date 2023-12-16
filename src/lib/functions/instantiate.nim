import std/[strformat, tables, options]

# https://forum.nim-lang.org/t/7182#45378
# https://forum.nim-lang.org/t/6980#43777mf


##  Creation and destruction of FMU instances and setting debug status

# https://forum.nim-lang.org/t/7496
#template genInstantiate*(inc:Fmu): untyped =

# template useSetStartValues() =
#   mixin setStartValues

#   when compiles(setStartValues):
#     setStartValues(comp)   # <------ to be implemented by the includer of this file

template genFmi2Instantiate(fmu:FmuRef) {.dirty.} =

  proc fmi2Instantiate*( instanceName:        fmi2String;
                         fmuType:             fmi2Type;
                         fmuGUID:             fmi2String;
                         fmuResourceLocation: fmi2String;
                         functions: fmi2CallBackFunctions,
                         visible:             fmi2Boolean;
                         loggingOn:           fmi2Boolean): FmuRef {.exportc:"$1",dynlib,cdecl.} = 
    ## instantiates a ModelInstance. This is a black box for the simulation
    ## tool; just a pointer will be shared.

    # Under the following conditions, it cannot be instantiated. Log details when possible.
    
    # - If no logger function, return inmediately
    if functions.logger.isNil:
        return nil

    # - If no "allocateMemory" or "freeMemory" functions, return and log.
    if functions.allocateMemory.isNil:
      functions.logger( functions.componentEnvironment, instanceName, fmi2Error, "error".fmi2String,
                "fmi2Instantiate: Missing 'allocateMemory' callback function.".fmi2String)
      return nil

    if functions.freeMemory.isNil:
      functions.logger( functions.componentEnvironment, instanceName, fmi2Error, "error".fmi2String,
                "fmi2Instantiate: Missing 'freeMemory' callback function.".fmi2String)
      return nil

    # - If instanceName not good, return and log 
    if instanceName.cstring.isNil or instanceName.cstring.len == 0:  # 
        # functions.componentEnvironment
        functions.logger( functions.componentEnvironment, "?".fmi2String, fmi2Error, "error".fmi2String,
                "fmi2Instantiate: Missing instance name.".fmi2String)
        return nil

    # - If fmuGUID not good, return and log 
    if fmuGUID.cstring.isNil or fmuGUID.cstring.len == 0:
        # functions.componentEnvironment
        functions.logger( functions.componentEnvironment, instanceName, fmi2Error, "error".fmi2String,
                  "fmi2Instantiate: Missing GUID.".fmi2String)
        return nil
     
    # Start creating the instance    
    var comp = FmuRef() #new typeof(`fmu`) 
    comp.time = 0
    comp.instanceName = ($instanceName).fmi2String
    comp.`type` = fmuType
    comp.guid = $fmuGUID
    comp.parameters = `fmu`.parameters
    #comp.states = `fmu`.states

    # Set initial values
  
    comp.reals    = `fmu`.reals
    comp.integers = `fmu`.integers
    comp.booleans = `fmu`.booleans  
    comp.strings  = `fmu`.strings  

    comp.isPositive = `fmu`.isPositive
    comp.nEventIndicators = comp.isPositive.len    

    # for p in `fmu`.parameters.values:
    #   if p.state:
    #     `fmu`.states &= p.idx

    # `fmu`.nStates = `fmu`.states.len

    for key,p in comp.parameters.pairs:
      case p.kind
      of tInteger:
        if p.startI.isSome:
          p.valueI = p.startI.get


      of tReal:
        if p.startR.isSome:
          p.valueR = p.startR.get
        if p.state:
          comp.states &= p.idx
        if p.derivative.isSome:
          comp.derivatives &= key

      of tBoolean:
        if p.startB.isSome:
          p.valueB = p.startB.get
        #comp.booleans &= key

      of tString:
        if p.startS.isSome:
          p.valueS = p.startS.get
      

    comp.nStates = comp.states.len

    # Set number of parameters
    comp.nIntegers = comp.integers.len
    comp.nFloats   = comp.reals.len    
    comp.nBooleans = comp.booleans.len     
    comp.nStrings  = comp.strings.len
    # If loggingOn=fmi2True: set all logging categories to ON.                     
    if not comp.isNil:
        # we log all considered categories
        # fmi2SetDebugLogging should be called to choose specific categories.
        if loggingOn == fmi2True:
          for i in LoggingCategories:
              comp.logCategories.incl( i ) 

    comp.functions = functions

    if functions.componentEnvironment == nil:
      echo "WARNING: instantiate.nim > fmi2Instantiate: functions.componentEnvironment == nil"  


    comp.loggingOn = loggingOn

    comp.state = modelInstantiated   # State changed
 
    when defined(setStartValues):
      setStartValues(comp)   # <------ to be implemented by the includer of this file

    #useSetStartValues() # This template just makes sure that `setStartValues` is defined. 
    comp.isDirtyValues = fmi2True # because we just called setStartValues
    comp.isNewEventIteration = fmi2False

    comp.eventInfo.newDiscreteStatesNeeded = fmi2False
    comp.eventInfo.terminateSimulation = fmi2False
    comp.eventInfo.nominalsOfContinuousStatesChanged = fmi2False
    comp.eventInfo.valuesOfContinuousStatesChanged = fmi2False
    comp.eventInfo.nextEventTimeDefined = fmi2False
    comp.eventInfo.nextEventTime = 0


    filteredLog( comp, fmi2OK, fmiCall, 
                  ("fmi2Instantiate: GUID=" & $fmuGUID).fmi2String)#, fmuGUID)

    return comp  



#[
In addition to GC_ref and GC_unref you can avoid the garbage collector 
by manually allocating memory with procs like:
  alloc, alloc0, allocShared, allocShared0 or allocCStringArray. 
  
The garbage collector won't try to free them, you need to call their 
respective dealloc pairs (dealloc, deallocShared, deallocCStringArray, etc) 
when you are done with them or they will leak.
]#



