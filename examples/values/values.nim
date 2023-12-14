#[
# Based on: https://github.com/qtronic/fmusdk/blob/master/fmu20/src/models/values/values.c

This demonstrates the use of all FMU variable types.
]#
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
    months = @[ "jan","feb","march","april","may","june","july",
                "august","sept","october","november","december"]

  values.addFloat("myFloat").setLocal.setContinuous.setExact
        .setDescription("used as continuous state")
        .setInitial(1.0)
        .setState()

  values.addFloat("myFloatDerivative").setLocal.setContinuous.setCalculated
        .setDescription("time derivative of x")
        .derives(values["myFloat"])


  values.addInteger("myInputInteger").setInput.setDiscrete
        .setDescription("integer input")
        .setInitial(2)     

  values.addInteger("myOutputInteger").setOutput.setDiscrete.setExact 
        .setDescription("index in string array 'month'")  
        .setInitial(0)

  values.addBoolean("myInputBool").setInput.setDiscrete 
        .setDescription("boolean input")
        .setInitial(true)   

  values.addBoolean("myOutputBool").setOutput.setDiscrete.setExact 
        .setDescription("boolean output")    
        .setInitial(true)

  values.addString("myInputString").setInput.setDiscrete
        .setDescription("string input")  
        .setInitial("QTronic")  

  values.addString("myOutputString").setOutput.setDiscrete.setExact 
        .setDescription("the string month[int_out]" )  
        .setInitial(months[0])    # "jan"


  # create time events every second
  proc calculateValues*(comp: FmuRef) =
    ## calculate the values of the FMU (Functional Mock-up Unit) variables 
    ## at a specific time step during simulation.
    if comp.state == modelInitializationMode:
      # set first time event
      comp.eventInfo.nextEventTimeDefined = fmi2True
      comp.eventInfo.nextEventTime        = 1 + comp.time


  proc getReal*(comp: FmuRef;
                key: string): float =
    case key
    of "myFloat": comp["myfloat"].valueR
    of "myFloatDerivative": -comp["myfloat"].valueR
    else: 0.0

  proc eventUpdate*(comp:FmuRef; 
                    isTimeEvent:bool ) =
    if isTimeEvent:
      # Define next time event in 1s
      comp.eventInfo.nextEventTimeDefined = fmi2True
      comp.eventInfo.nextEventTime        = 1 + comp.time 

      comp["myOutputInteger"] +=  1
      comp["myOutputBool"] = not comp["myOutputBool"]

      # Assign each month to the output string
      if comp["myOutputInteger"] < 12:
        comp["myOutputString"] = months[comp["myOutputInteger"].valueI]

      # once done, terminate the simulation
      else:
        comp.eventInfo.terminateSimulation  = fmi2True
        comp.eventInfo.nextEventTimeDefined = fmi2False

when defined(fmu):
  values.exportFmu("values.fmu")