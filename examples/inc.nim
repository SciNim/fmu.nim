#[
Increases a counter every second.
]#
import fmu
#import macros

var 
  id      = "inc"
  guid    = "{8c4e810f-3df3-4a00-8276-176fa3c9f008}"
  outFile = "inc.fmu"

#expandMacros:
model(id, guid, outFile):
  var counter*:int = 1
  
  param(counter, cOutput, vDiscrete, iExact, "counts the seconds")

  init(counter)  # This macro creates setStartValues() among other things

  proc calculateValues*(comp: ModelInstanceRef) =
    ## calculate the values of the FMU (Functional Mock-up Unit) variables 
    ## at a specific time step during simulation.
    if comp.state == modelInitializationMode:
        # set first time event
        comp.eventInfo.nextEventTimeDefined = fmi2True
        comp.eventInfo.nextEventTime        = 1 + comp.time

  proc eventUpdate*(comp:ModelInstanceRef, 
                    eventInfo:ptr fmi2EventInfo, 
                    timeEvent:bool,  # cint
                    isNewEventIteration:fmi2Boolean) =  #cint
    if timeEvent: 
        counter += 1
        if counter == 13: # in this case we finish (even if the simulation time is bigger)
            eventInfo.terminateSimulation  = fmi2True
            eventInfo.nextEventTimeDefined = fmi2False
        else:
            eventInfo.nextEventTimeDefined = fmi2True
            eventInfo.nextEventTime        = 1 + comp.time


#[
The calculateValues function is a member function 
of the FMU class in the FMUSDK library. It is used to advance the
simulation by one step and calculate the values of the FMU's output variables for the current simulation time.

// called by fmi2GetReal, fmi2GetInteger, fmi2GetBoolean, fmi2GetString, fmi2ExitInitialization
// if setStartValues or environment set new values through fmi2SetXXX.
// Lazy set values for all variable that are computed from other variables.
]#