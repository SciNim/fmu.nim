#[
Increases a counter every second.
]#
import fmu
import options
import std/tables

#[  
{.experimental: "dotOperators".}  
Este truco puede servir para trabajar fácilmente con los objectos


echo a.hola 
]#

# Define the variables to be used
# type
#   Inc = object of FmuRef
#     counter*:int = 1

#template `.`*(obj: FmuRef; field: untyped):int =
#  var tmp = obj.parameters[astToStr(field)].startI.get



var inc = FmuRef( id:   "inc",
                  guid: "{8c4e810f-3df3-4a00-8276-176fa3c9f008}" )

inc.sourceFiles = @["data/inc.c"]
inc.docFiles    = @["data/index.html"]
inc.icon        = "data/model.png"

inc.addInteger("counter")
inc.setOutput("counter")     
inc.setDiscrete("counter")
inc.setExact("counter")  
inc.setDescription("counter", "counts the seconds")  
inc.parameters["counter"].startI = some(1)


# IMHO, the following should be named: createTimeEvent.
# When t = 0s, it creates a time event at t = 1s.
# When t= 1s, the state is again=modelInitializationMode, so another time event is set: t = 2s
# and so on.


model(inc):
  proc calculateValues*(comp: FmuRef) = 
    ## calculate the inc of the FMU (Functional Mock-up Unit) variables 
    ## at a specific time step during simulation.
    if comp.state == modelInitializationMode:
        # set first time event
        comp.eventInfo.nextEventTimeDefined = fmi2True
        comp.eventInfo.nextEventTime        = 1 + comp.time

  # The following function is called whenever there is a time event
  # I think this the reason why the call this lazy evaluation
  # The evaluation only takes places during the time events.
  # TODO: to undestand better `eventInfo`
  proc eventUpdate*(comp: FmuRef;
                    eventInfo:ptr fmi2EventInfo;
                    timeEvent:bool;
                    isNewEventIteration:fmi2Boolean) =
    if timeEvent: 
        #comp.counter += 1
        #echo repr comp["counter"]
        comp["counter"] = comp["counter"] + 1
        #if comp.counter == 13: # in this case we finish (even if the simulation time is bigger)
        if comp["counter"] == 13: # in this case we finish (even if the simulation time is bigger)
            eventInfo.terminateSimulation  = fmi2True
            eventInfo.nextEventTimeDefined = fmi2False
        else:
            eventInfo.nextEventTimeDefined = fmi2True
            eventInfo.nextEventTime        = 1 + comp.time

when defined(fmu):
  inc.exportFmu("inc.fmu")