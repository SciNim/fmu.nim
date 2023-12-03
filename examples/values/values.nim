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

  values.parameters["myFloat"] = Param(kind: tReal,
                      idx: 0,
                      causality: cLocal, #causality: local variable
                      variability: vContinuous, #variability: continuous
                      initial: iExact, #initialized at start
                      description: "used as continuous state",# description
                      )
  values.states &= values.parameters["myFloat"].idx
  #values.parameters["myFloat"].isState = true
  values.parameters["myFloat"].startR = some(1.0) 

  values.parameters["myFloatDerivative"] = Param(kind: tReal,
                      idx: 1,
                      causality: cLocal, #causality: local variable
                      variability: vContinuous, #variability: continuous
                      initial: iCalculated, #initialized at start
                      description: "time derivative of x",# description
                      ) # indicates this is the derivative for the first param
  values.parameters["myFloatDerivative"].derivative = 1.uint.some

  values.parameters["myInputInteger"] = Param(kind: tInteger,
                      idx: 0,
                      causality: cInput, #causality: input
                      variability: vDiscrete, #variability: discrete
                      initial: iUnset, #initialized at start
                      description: "integer input" ) # description 
  values.parameters["myInputInteger"].startI = 2.some

  values.parameters["myOutputInteger"] = Param(kind: tInteger,
                      idx: 1,
                      causality: cOutput, #causality: output
                      variability: vDiscrete, #variability: discrete
                      initial: iExact, #initialized at start
                      description: "index in string array 'month'" ) # description 
  values.parameters["myOutputInteger"].startI = 0.some

  values.parameters["myInputBool"] = Param(kind: tBoolean,
                      idx: 0,
                      causality: cInput, #causality: input
                      variability: vDiscrete, #variability: discrete
                      initial: iUnset, # unset?
                      description: "boolean input" ) # description 
  values.parameters["myInputBool"].startB = true.some

  values.parameters["myOutputBool"] = Param(kind: tBoolean,
                      idx: 1,
                      causality: cOutput, #causality: output
                      variability: vDiscrete, #variability: discrete
                      initial: iExact, # unset?
                      description: "boolean output" ) # description 
  values.parameters["myInputBool"].startB = true.some


  values.parameters["myInputString"] = Param(kind: tString,
                      idx: 0,
                      causality: cInput, #causality: input
                      variability: vDiscrete, #variability: discrete
                      initial: iUnset, # unset?
                      description: "string input" ) # description 
  values.parameters["myOutputBool"].startB = false.some

  values.parameters["myInputString"].startS = "QTronic".some

  values.parameters["myOutputString"] = Param(kind: tString,
                      idx: 1,
                      causality: cOutput, #causality: input
                      variability: vDiscrete, #variability: discrete
                      initial: iExact, # unset?
                      description: "the string month[int_out]" ) # description 
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
