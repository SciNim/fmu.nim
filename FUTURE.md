# Cambios a realizar
1. Tendría que ser sencilla la ejecución del modelo en Nim:
- definir la función
- que sea sencillo generar el FMU a partir de la función

Algo así:

```nim
proc calculateValues*(comp: ModelInstanceRef) =
  ## calculate the values of the FMU (Functional Mock-up Unit) variables 
  ## at a specific time step during simulation.
  if comp.state == modelInitializationMode:
      # set first time event
      comp.eventInfo.nextEventTimeDefined = fmi2True
      comp.eventInfo.nextEventTime        = 1 + comp.time

```

