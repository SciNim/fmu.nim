# Example showing the use of all FMU variable types
# Inspired by: https://github.com/qtronic/fmusdk/blob/master/fmu20/src/models/values/values.c

import fmu

var 
  id      = "values"
  guid    = "{8c4e810f-3df3-4a00-8276-176fa3c9f004}"
  outFile = "values.fmu"

model(id, guid, outFile):
  # Define the variables (initialization)
    var
      months = @["jan","feb","march","april","may","june","july",
                 "august","sept","october","november","december"]
    #const
    #  NUMBER_OF_STATES = 1 # FIXME
    var
      myFloat:float         = 1.0
      myFloatDerivative:float
      myInputInteger:int    = 2
      myOutputInteger:int   = 0
      myInputBool:bool      = true
      myOutputBool:bool     = false
      myInputString:string  = "QTronic" 
      myOutputString:string = "jan" # months[0] # <--- NOT WORKING

    param( myFloat,     # include counter as a variable in the model.
           cLocal,      # causality: local variable
           vContinuous, # variability: continuous
           iExact,      # initialized at start
           "used as continuous state",
           isState = true) # description

    param( myFloatDerivative,     # include counter as a variable in the model.
           cLocal,      # causality: local variable
           vContinuous, # variability: continuous
           iCalculated,      # initialized at start
           "time derivative of x", # description
           derivative = 1 ) # indicates this is the derivative for the first param

    #myFloatDerivative.setDer

    param( myInputInteger,     # include counter as a variable in the model.
           cInput,      # causality: local variable
           vDiscrete,   # variability: discrete
           iUnset,      # initialized at start
           "integer input") # description

    param( myOutputInteger,     # include counter as a variable in the model.
           cOutput,      # causality: local variable
           vDiscrete,   # variability: discrete
           iExact,      # initialized at start
           "index in string array 'month'") # description

    param( myInputBool,     # include counter as a variable in the model.
           cInput,      # causality: local variable
           vDiscrete,   # variability: discrete
           iUnset,      # initialized at start
           "boolean input") # description

    param( myOutputBool,     # include counter as a variable in the model.
           cOutput,      # causality: local variable
           vDiscrete,   # variability: discrete
           iExact,      # initialized at start
           "boolean output") # description

    param( myInputString,     # include counter as a variable in the model.
           cInput,      # causality: local variable
           vDiscrete,   # variability: discrete
           iUnset,      # initialized at start
           "string input") # description

    param( myOutputString,     # include counter as a variable in the model.
           cOutput,      # causality: local variable
           vDiscrete,   # variability: discrete
           iExact,      # initialized at start
           "the string month[int_out]") # description
    init(myFloat, myFloatDerivative,
      myInputInteger, myOutputInteger, 
      myInputBool, myOutputBool, 
      myInputString, myOutputString)

    #setState( myFloat )

    #myModel.addState(myFloat)
#[
<ModelStructure>
  <Outputs>
    <Unknown index="4" />
    <Unknown index="6" />
    <Unknown index="8" />
  </Outputs>
  <Derivatives>
    <Unknown index="2" />
  </Derivatives>
  <InitialUnknowns>
    <Unknown index="2"/>
  </InitialUnknowns>
</ModelStructure>
]#

    # create time events every second
    proc calculateValues*(comp: ModelInstanceRef) =
      ## calculate the values of the FMU (Functional Mock-up Unit) variables 
      ## at a specific time step during simulation.
      if comp.state == modelInitializationMode:
        # set first time event
        comp.eventInfo.nextEventTimeDefined = fmi2True
        comp.eventInfo.nextEventTime        = 1 + comp.time


    proc getReal*(comp: ModelInstanceRef;
                  vr:fmi2ValueReference):fmi2Real =
      if vr == 0:  # el primer índice
        return myfloat.fmi2Real
      elif vr == 1:
        return -myfloat.fmi2Real
      else:
        return (0.0).fmi2Real

    proc eventUpdate*(comp:ModelInstanceRef; 
                      eventInfo:ptr fmi2EventInfo;
                      isTimeEvent:bool;
                      isNewEventIteration:fmi2Boolean) =
      if isTimeEvent:
        # Define next time event in 1s
        eventInfo.nextEventTimeDefined = fmi2True
        eventInfo.nextEventTime        = 1 + comp.time 

        myOutputInteger += 1
        myOutputBool = not myOutputBool

        # Assign each month to the output string
        if myOutputInteger < 12:
          myOutputString = months[myOutputInteger]

        # once done, terminate the simulation
        else:
          eventInfo.terminateSimulation  = fmi2True
          eventInfo.nextEventTimeDefined = fmi2False

 