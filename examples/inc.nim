#[
Increases a counter every second.
]#
import fmu
import macros

var id = "inc"
var guid = "{8c4e810f-3df3-4a00-8276-176fa3c9f008}"
var outFile = "inc.fmu"

#expandMacros:
model(id, guid, outFile):
  var counter*:int = 1
  init(counter)

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
