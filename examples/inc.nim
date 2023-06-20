#[
Increase a counter every second.
]#
import fmu
import macros

#var myModel = ModelInstanceRef(id: "inc", guid: "{8c4e810f-3df3-4a00-8276-176fa3c9f008}")

var id = "inc"
var guid = "{8c4e810f-3df3-4a00-8276-176fa3c9f008}"
var outFile = "inc.fmu"

#var myModel* = ModelInstanceRef(id: id, guid: guid) 
#expandMacros:
model(id, guid, outFile):
  #var ctr = Param( name:"counter", kind: tInteger )
  #var counter*:int = 1 # Inicializamos
  #add2(counter)
  var counter*:int = 1
  init(counter)
    

  #  comp.setInit("counter", 1)  # TODO: cargarme el comp
  #init2()

  const   
    NUMBER_OF_STATES = 0
    NUMBER_OF_EVENT_INDICATORS = 0


  #const
  #  counter = 0  # Representa el índice del array de valores enteros en el que almacena el valor.

  #proc setStartValues*(comp: ModelInstanceRef) =
  #    ## used to initialize the variables (integers are stored in the seq `comp.i`)
      #comp.i &= 1.fmi2Integer
  #    ctr = 1


  proc calculateValues*(comp: ModelInstanceRef) =
      ## calculate the values of the FMU (Functional Mock-up Unit) variables 
      ## at a specific time step during simulation.
      if comp.state == modelInitializationMode:
          # set first time event
          comp.eventInfo.nextEventTimeDefined = fmi2True
          comp.eventInfo.nextEventTime        = 1 + comp.time
          #echo "comp.time: ", comp.time

  proc eventUpdate*(comp:ModelInstanceRef, 
                    eventInfo:ptr fmi2EventInfo, 
                    timeEvent:bool,  # cint
                    isNewEventIteration:fmi2Boolean) =  #cint
      if timeEvent:
          #discard
          #comp.i[counter] += 1 
          counter += 1        
          #if comp.i[counter] == 13: 
          if counter == 13: # in this case we finish (even if the simulation time is bigger)
              eventInfo.terminateSimulation  = fmi2True
              eventInfo.nextEventTimeDefined = fmi2False
          else:
              eventInfo.nextEventTimeDefined = fmi2True
              eventInfo.nextEventTime        = 1 + comp.time








