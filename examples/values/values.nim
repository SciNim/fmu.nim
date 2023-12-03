# Example showing the use of all FMU variable types
# Inspired by: https://github.com/qtronic/fmusdk/blob/master/fmu20/src/models/values/values.c

import fmu
import std/[tables, options]
import std/paths

var values = FmuRef( id: "values",
               guid: "{8c4e810f-3df3-4a00-8276-176fa3c9f004}")
values.sourceFiles = @["data/inc.c"]
values.docFiles    = @["data/index.html"]
values.icon        = "data/model.png"

model(values):
  # Define the variables (initialization)
  var
    months = @["jan","feb","march","april","may","june","july",
                "august","sept","october","november","december"]

  values.addFloat("myFloat")
  values.setLocal("myFloat")
  values.setContinuous("myFloat")  
  values.setExact("myFloat")   
  values.setDescription("myFloat", "used as continuous state" )

  values.states &= values.parameters["myFloat"].idx
  #values.parameters["myFloat"].isState = true
  values.parameters["myFloat"].startR = some(1.0) 

  values.addFloat("myFloatDerivative")
  values.setLocal("myFloatDerivative")
  values.setContinuous("myFloatDerivative")  
  values.setCalculated("myFloatDerivative")  
  values.setDescription("myFloatDerivative", "time derivative of x" )    
  # indicates this is the derivative for the first param ]#
  values.parameters["myFloatDerivative"].derivative = 1.uint.some

  values.addInteger("myInputInteger")
  values.setInput("myInputInteger") 
  values.setDiscrete("myInputInteger")  
  values.setDescription("myInputInteger", "integer input")       
  values.parameters["myInputInteger"].startI = 2.some

  values.addInteger("myOutputInteger")
  values.setOutput("myOutputInteger")     
  values.setDiscrete("myOutputInteger")
  values.setExact("myOutputInteger")  
  values.setDescription("myOutputInteger", "index in string array 'month'")  
  values.parameters["myOutputInteger"].startI = 0.some

  values.addBoolean("myInputBool")  
  values.setInput("myInputBool")    
  values.setDiscrete("myInputBool")  
  values.setDescription("myInputBool", "boolean input")    
  values.parameters["myInputBool"].startB = true.some

  values.addBoolean("myOutputBool")
  values.setOutput("myOutputBool")    
  values.setDiscrete("myOutputBool")   
  values.setExact("myOutputBool")  
  values.setDescription("myOutputBool", "boolean output")    
  values.parameters["myOutputBool"].startB = true.some


  values.addString("myInputString")
  values.setInput("myInputString")  
  values.setDiscrete("myInputString") 
  values.setDescription("myInputString", "string input")    
  values.parameters["myInputString"].startS = "QTronic".some

  values.addString("myOutputString")
  values.setOutput("myOutputString")   
  values.setDiscrete("myOutputString")   
  values.setExact("myOutputString")   
  values.setDescription("myOutputString", "the string month[int_out]" )    
  values.parameters["myOutputString"].startS = months[0].some # "jan"



  # create time events every second
  proc calculateValues*(comp: FmuRef) =
    ## calculate the values of the FMU (Functional Mock-up Unit) variables 
    ## at a specific time step during simulation.
    if comp.state == modelInitializationMode:
      # set first time event
      comp.eventInfo.nextEventTimeDefined = fmi2True
      comp.eventInfo.nextEventTime        = 1 + comp.time


  proc getReal*(comp: FmuRef;
                vr:fmi2ValueReference):fmi2Real =
    if vr == 0:  # el primer índice
      return comp.parameters["myfloat"].valueR.fmi2Real
    elif vr == 1:
      return -comp.parameters["myfloat"].valueR.fmi2Real
    else:
      return (0.0).fmi2Real

  proc eventUpdate*(comp:FmuRef; 
                    eventInfo:ptr fmi2EventInfo;
                    isTimeEvent:bool;
                    isNewEventIteration:fmi2Boolean) =
    if isTimeEvent:
      # Define next time event in 1s
      eventInfo.nextEventTimeDefined = fmi2True
      eventInfo.nextEventTime        = 1 + comp.time 

      comp.parameters["myOutputInteger"].valueI =  comp.parameters["myOutputInteger"].valueI + 1
      comp.parameters["myOutputBool"].valueB = not comp.parameters["myOutputBool"].valueB
      #myOutputBool = not myOutputBool

      # Assign each month to the output string
      if comp.parameters["myOutputInteger"].valueI < 12:
        comp.parameters["myOutputString"].valueS = months[comp.parameters["myOutputInteger"].valueI]

      # once done, terminate the simulation
      else:
        eventInfo.terminateSimulation  = fmi2True
        eventInfo.nextEventTimeDefined = fmi2False

when defined(fmu):
  values.exportFmu("values.fmu")
