#[
Increases a counter every second.
]#
import fmu

var 
  id      = "inc"
  guid    = "{8c4e810f-3df3-4a00-8276-176fa3c9f008}"
  outFile = "inc.fmu"

model(id, guid, outFile):
  # Define the variable that we will use for output.
  var counter*:int = 1
  
  param( counter,   # include counter as a variable in the model.
         cOutput,   # set it as an output variable
         vDiscrete, # variability: discrete
         iExact,    # initialized at start
         "counts the seconds") # description

  # I think this macro is no longer needed (we performed the initialization above)
  init(counter)  # This macro creates setStartValues() among other things

  # IMHO, the following should be named: createTimeEvent.
  # When t = 0s, it creates a time event at t = 1s.
  # When t= 1s, the state is again=modelInitializationMode, so another time event is set: t = 2s
  # and so on.
  proc calculateValues*(comp: ModelInstanceRef) =
    ## calculate the values of the FMU (Functional Mock-up Unit) variables 
    ## at a specific time step during simulation.
    if comp.state == modelInitializationMode:
        # set first time event
        comp.eventInfo.nextEventTimeDefined = fmi2True
        comp.eventInfo.nextEventTime        = 1 + comp.time

  # The following function is called whenever there is a time event
  # I think this the reason why the call this lazy evaluation
  # The evaluation only takes places during the time events.
  # TODO: to undestand better `eventInfo`
  proc eventUpdate*(comp:ModelInstanceRef; 
                    eventInfo:ptr fmi2EventInfo;
                    timeEvent:bool;
                    isNewEventIteration:fmi2Boolean) =
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
of the FMU class in the FMUSDK library. 

It is used to advance the simulation by one step and calculate the values of the FMU's output variables for the current simulation time.

// called by fmi2GetReal, fmi2GetInteger, fmi2GetBoolean, fmi2GetString, fmi2ExitInitialization
// if setStartValues or environment set new values through fmi2SetXXX.
// Lazy set values for all variable that are computed from other variables.
]#