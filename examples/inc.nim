#[
Increase a counter every second.
]#
import fmu

const
  guid = "{8c4e810f-3df3-4a00-8276-176fa3c9f008}"


model(guid):
  const
    NUMBER_OF_INTEGERS* = 1
    NUMBER_OF_BOOLEANS* = 0
    NUMBER_OF_STRINGS* = 0
    
    NUMBER_OF_STATES = 0
    NUMBER_OF_EVENT_INDICATORS = 0
    NUMBER_OF_REALS = 0

  const
    counter = 0

  proc setStartValues*(comp: ModelInstanceRef) =
      comp.i &= 1.fmi2Integer

  proc calculateValues*(comp: ModelInstanceRef) =
      if comp.state == modelInitializationMode:
          # set first time event
          comp.eventInfo.nextEventTimeDefined = fmi2True
          comp.eventInfo.nextEventTime        = 1 + comp.time

  proc eventUpdate*(comp:ModelInstanceRef, 
                    eventInfo:ptr fmi2EventInfo, 
                    timeEvent:bool,  # cint
                    isNewEventIteration:fmi2Boolean) =  #cint
      if timeEvent:
          comp.i[counter] += 1;
          if comp.i[counter] == 13:
              eventInfo.terminateSimulation  = fmi2True
              eventInfo.nextEventTimeDefined = fmi2False
          else:
              eventInfo.nextEventTimeDefined = fmi2True
              eventInfo.nextEventTime        = 1 + comp.time


# ------- FMU BUILDER----------------------------------------


# The following is only compiled if called as main module
when isMainModule and not compileOption("app", "lib"):
  import lib/fmubuilder

  var myModel = FMU( id: "inc", guid: guid)
  myModel.genFmu("inc.fmu")


  


