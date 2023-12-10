# Example showing the use of all FMU variable types
# Inspired by: https://github.com/qtronic/fmusdk/blob/master/fmu20/src/models/values/values.c

import fmu
import std/[tables, options]
#import std/paths

var values = FmuRef( id:   "values",
                     guid: "{8c4e810f-3df3-4a00-8276-176fa3c9f004}")
values.sourceFiles = @["data/inc.c"]
values.docFiles    = @["data/index.html"]
values.icon        = "data/model.png"

model(values):
  # Define the variables (initialization)
  var
    months = @["jan","feb","march","april","may","june","july",
                "august","sept","october","november","december"]

  values.addFloat("myFloat").setLocal.setContinuous.setExact
        .setDescription("used as continuous state")

  values.states &= values.parameters["myFloat"].idx
  #values.parameters["myFloat"].isState = true
  values["myFloat"].startR = some(1.0) 

  values.addFloat("myFloatDerivative").setLocal.setContinuous.setCalculated
        .setDescription("time derivative of x")
    
  # indicates this is the derivative for the first param ]#
  values["myFloatDerivative"].derivative = 1.uint.some

  values.addInteger("myInputInteger").setInput.setDiscrete
        .setDescription("integer input")       
  values["myInputInteger"].startI = 2.some

  values.addInteger("myOutputInteger").setOutput.setDiscrete.setExact 
        .setDescription("index in string array 'month'")  
  values["myOutputInteger"].startI = 0.some

  values.addBoolean("myInputBool").setInput.setDiscrete 
        .setDescription("boolean input")    
  values["myInputBool"].startB = true.some

  values.addBoolean("myOutputBool").setOutput.setDiscrete.setExact 
        .setDescription("boolean output")    
  values["myOutputBool"].startB = true.some


  values.addString("myInputString").setInput.setDiscrete
        .setDescription("string input")    
  values["myInputString"].startS = "QTronic".some

  values.addString("myOutputString").setOutput.setDiscrete.setExact 
        .setDescription("the string month[int_out]" )    
  values["myOutputString"].startS = months[0].some # "jan"



  # create time events every second
  proc calculateValues*(comp: FmuRef) =
    ## calculate the values of the FMU (Functional Mock-up Unit) variables 
    ## at a specific time step during simulation.
    if comp.state == modelInitializationMode:
      # set first time event
      comp.eventInfo.nextEventTimeDefined = fmi2True
      comp.eventInfo.nextEventTime        = 1 + comp.time


  proc getReal*(comp: FmuRef;
                vr:fmi2ValueReference):float =
    # FIXME: it should depend on the name, not in vr
    if vr == 0:  # el primer índice
      return comp["myfloat"].valueR
    elif vr == 1:
      return -comp["myfloat"].valueR
    else:
      return 0.0

  proc eventUpdate*(comp:FmuRef; 
                    eventInfo:ptr fmi2EventInfo;
                    isTimeEvent:bool;
                    isNewEventIteration:fmi2Boolean) =
    if isTimeEvent:
      # Define next time event in 1s
      eventInfo.nextEventTimeDefined = fmi2True
      eventInfo.nextEventTime        = 1 + comp.time 

      comp["myOutputInteger"] +=  1
      comp["myOutputBool"] = not comp["myOutputBool"]

      # Assign each month to the output string
      if comp["myOutputInteger"] < 12:
        comp["myOutputString"] = months[comp["myOutputInteger"].valueI]

      # once done, terminate the simulation
      else:
        eventInfo.terminateSimulation  = fmi2True
        eventInfo.nextEventTimeDefined = fmi2False

when defined(fmu):
  values.exportFmu("values.fmu")
