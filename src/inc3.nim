import fmu

# FIXME: I don't like the use of `counter` within `eventUpdate`
var 
  counter* = 0 # FIXME

proc setStartValues*(comp: ModelInstanceRef) =  # Con ref object, no es necesario usar "var"
  comp.i &= 1.fmi2Integer


proc calculateValues*(comp:ModelInstanceRef) =
    if comp.state == modelInitializationMode:
        # set first time event
        comp.eventInfo.nextEventTimeDefined = fmi2True
        comp.eventInfo.nextEventTime        = 1 + comp.time

proc eventUpdate*(comp:ModelInstanceRef, 
                 eventInfo:ptr fmi2EventInfo, 
                 timeEvent:bool,  # cint
                 isNewEventIteration:fmi2Boolean) =  #cint
    # FIXME: I don't like this function
    if timeEvent:
        comp.i[counter] += 1;
        if comp.i[counter] == 13:
            eventInfo.terminateSimulation  = fmi2True
            eventInfo.nextEventTimeDefined = fmi2False
        else:
            eventInfo.nextEventTimeDefined = fmi2True
            eventInfo.nextEventTime        = 1 + comp.time

proc main =
  var myModel = FMU( id: "inc", guid: "{8c4e810f-3df3-4a00-8276-176fa3c9f008}")
  myModel.nIntegers = 1
  myModel.nBooleans = 0
  myModel.nStrings = 0
  myModel.nReals = 0
  myModel.nEventIndicators = 0
  myModel.nStates = 0

  myModel.counter = 0

  myModel.setStartValues = setStartValues
  myModel.calculateValues = calculateValues
  myModel.eventUpdate = eventUpdate


  myModel.genFMU("inc2.fmu")


main()

