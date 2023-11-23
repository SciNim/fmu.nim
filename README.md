# fmu.nim
The purpose of this library is enabling the creation of FMU files that can be later used in many compatible simulation packages such as OpenModelica, Matlab, Dymola, ...

This library is heavily based on [fmusdk](https://github.com/qtronic/fmusdk).

## Status
This is in an alpha stage. 

It is capable of creating a working FMU. It does so by:

1. Creating `inc.so` in almost pure Nim. 
2. Embedding the `inc.so` within the `.fmu` file. 
3. Creates the folder structure 
4. The XML file is taken from the C version.

### How to test it?
Go to the `examples` folder.

The following command will generate `inc.so` and embed it into `inc.fmu`:
```
$ nim c -r inc
```

Then test it:
```
$ fmuCheck.linux64 ./inc.fmu
```
or:
```
$ ./fmusim_me inc.fmu 5 0.1
```
> this will simulate during 5seconds using 0.1 second steps. it will create the file `results.csv`.

# TODO
- [ ] To provide: index.html as an input
- [ ] To provide: model.png as an input
- [ ] To provide: mode.c as a an input
- [ ] To create: modelDescription.xml as an input
- [ ] To compile using zigcc providing both linux and windows libraries


# Details
## Intro
In general terms, we are making Nim to export C functions fulfilling the naming conventions of the FMU standard.

## Model
A new model requires the info such as:
```nim
  id      = "inc"
  guid    = "{8c4e810f-3df3-4a00-8276-176fa3c9f008}"
  outFile = "inc.fmu"
```

We will call the `model` template with these values. The `model` template is defined in `src/fmu.nim`. This calls `model2` template (another template within `src/fmu.nim`). They both are responsible for structuring the code: the custom defined functions plus the other functions required by the standard.

All this will create two modes of operations for the code:

1. When compiled as a library, it will create a library such as `inc.so`.
2. When compiled as an app it uses `src/lib/fmubuilder.nim`:
  
  - Creates the folder structure
  - Creates the XML
  - Compress everything into a `.fmu` file.


At the end of `model2` there are plenty of includes. They implement the interface required by FMU. They depend on the functions that will go within `body`.


# Simulation sequence for a Model Exchange
## Instantiation
The first step is to instantiate the FMU within the simulation environment. This involves loading the FMU file and initializing its internal data structures.

## Initialization
After instantiation, the FMU needs to be initialized before the simulation begins. The simulation environment calls the FMU's initialization function, passing the necessary inputs, such as start time, stop time, and initial values for the model variables. The FMU sets up its internal state and prepares for simulation.

- `fmi2Instantiate`: This function creates an instance of the FMU and returns a handle that can be used to access the FMU's functions and data.
- `fmi2SetupExperiment`: This function sets up the initial experiment conditions, such as the start time and stop time of the simulation.
- `fmi2EnterInitializationMode`: This function puts the FMU into initialization mode, allowing it to perform any necessary initialization tasks.
- `fmi2ExitInitializationMode``: This function takes the FMU out of initialization mode and puts it into continuous-time mode, allowing it to start the simulation.

## Simulation Loop
The simulation loop is the core part of the calling sequences. It typically involves the following steps:

a. Set Inputs: The simulation environment sets the input values for the FMU. These inputs can include control signals, parameters, or any other data required by the model.

b. Communication Step: The simulation environment calls the FMU's communication step function. This function typically performs any necessary pre-processing steps, such as updating internal states, performing calculations, or applying inputs.

c. Solve Step: The simulation environment calls the FMU's solve step function. This function performs the actual simulation step, where the model equations are solved and the outputs are computed based on the current inputs and internal states. The solve step function may use numerical integration techniques or other algorithms to advance the simulation time.

d. Get Outputs: After the solve step, the simulation environment retrieves the output values from the FMU. These outputs represent the computed results of the simulation step.

e. Time Advancement: The simulation environment updates the simulation time based on the desired time step and proceeds to the next iteration of the simulation loop.

- `fmi2DoStep`: This function performs a single step of the simulation. It takes the current simulation time and step size as input, and returns the next simulation time and a status flag indicating whether the simulation should continue or stop.

## Termination
The simulation loop continues until the stop time is reached or a termination condition is met. At this point, the simulation is complete, and the FMU can be terminated.

- `fmi2Terminate`: This function terminates the simulation and cleans up any resources used by the FMU.



# Interesting projects
- [Awesome FMI](https://github.com/traversaro/awesome-fmi)
 
- Exporting FMUs:

  - [cppfmu](https://github.com/viproma/cppfmu)
  - [FMIpp](https://github.com/fmipp/fmipp)
  - [fmusdk](https://github.com/qtronic/fmusdk): inspirational for this project.

- Importing FMUs:
  
  - [FMI4cpp](https://github.com/NTNU-IHB/FMI4cpp): in order to simulate with FMI.


# Future
I would like being able of reducing the boilerplate. Something like:
```nim
var counter:int = 1

proc update(counter: var int) = 
  ## counter: counts the seconds [exact, discrete, output]
  counter += 1

when isMainModule:
  var counter = 1
  update(counter)
  update.toFmu( id: "inc",
              guid: "{8c4e810f-3df3-4a00-8276-176fa3c9f008}"
              outFile: "inc.fmu")
```

## TODO
### `setStartValues`
Called by `fmi2Instantiate`.

This is a user defined function. It is responsible for setting the initial value when required during instantiation of the module. This reminds me `__init__` in python.

Do we need this? The answer is NO. If I comment the line `setStartValues( comp )` in `instantiate.nim`, the model keeps on working.

In `inc.nim` we are already doing:
```nim
var counter*:int = 1
```

`modelInstance` is referencing the memory address, this is why it is not needed.

> WARNING: settings used unless changed by `fmi2SetX` before `fmi2EnterInitializationMode`
> TODO: to check if `fmi2SetX` and `fmi2EnterInitializationMode` work with current approach.

```c
void setStartValues(ModelInstance *comp) {
    i(counter_) = 1;
}
```


### `calculateValues`
Calculate the values of the FMU (Functional Mock-up Unit) variables at a specific time step during simulation 

Called by fmi2GetReal, fmi2GetInteger, fmi2GetBoolean, fmi2GetString, fmi2ExitInitialization if setStartValues or environment set new values through fmi2SetXXX.

Lazy set values for all variable that are computed from other variables.

Permite avanzar en el tiempo y obtener los valores actualizados de las variables en cada paso de la simulación.

La función calculateValues es llamada en cada paso de la simulación y su propósito principal es realizar los cálculos necesarios para actualizar los valores de las variables del modelo. Esto implica aplicar ecuaciones matemáticas, resolver sistemas de ecuaciones, simular fenómenos físicos, entre otros.

This function is defined by the user and called from `getters.nim` (`fmi2GetReal`, `fmi2GetInteger`, `fmi2GetBoolean`, `fmi2GetString`) and `common.nim` (`fmi2ExitInitializationMode`).

In the case of `inc.nim`:
```nim
proc calculateValues*(comp: ModelInstanceRef) =
  if comp.state == modelInitializationMode:
      # set first time event
      comp.eventInfo.nextEventTimeDefined = fmi2True
      comp.eventInfo.nextEventTime        = 1 + comp.time
```

Parece que siempre se usa el mismo contenido en todos los casos (aunque no se use siempre). Por ejemplo, `inc.c` y `values.c` lo usan.


Yo diría que `calculateValues` es un generador de eventos temporales:

- En el caso de `inc.c` los genera cada segundo. `eventUpdate` reacciona a cada evento temporal aumentando en 1 el contador.
- En el caso de `values.c` también genera eventos temporales cada segundo. En este caso actualiza también otros valores cada segundo.





## MASKS
To make it more like Nim:
- `masks.nim`
- `helpers.nim`

https://nim-lang.org/docs/manual.html#set-type-bit-fields


Something like:
```nim
type
  ModelState* {.size: sizeof(cint).}  = enum
    modelStartAndEnd        ,  ##  ME state
    modelInstantiated       ,  ##  ME states
    modelInitializationMode ,  ##  ME states
    modelEventMode          ,  ##  CS states
    modelContinuousTimeMode ,  ##  CS states
    modelStepComplete       ,
    modelStepInProgress     ,
    modelStepFailed         ,
    modelStepCanceled       ,
    modelTerminated         ,
    modelError              ,
    modelFatal              


type
  Mask = set[ModelState]

const
  MASK_fmi2GetReal* = { modelInitializationMode, modelEventMode,
                        modelContinuousTimeMode, modelStepComplete, 
                        modelStepFailed, modelStepCanceled, 
                        modelTerminated, modelError}

  MASK_fmi2GetInteger*:Mask  = MASK_fmi2GetReal
  MASK_fmi2GetBoolean*:Mask  = MASK_fmi2GetReal
  MASK_fmi2GetString*:Mask   = MASK_fmi2GetReal
  tmp:Mask = {}
echo repr MASK_fmi2GetInteger

if modelEventMode in MASK_fmi2GetInteger:
  echo "ok"

if tmp == {}:
  echo "nok"
echo tmp
```
## TODO: triggers
Una idea (incorrecta):
```c
void calculateValues(ModelInstance *comp) {
    // Get the current simulation time
    double currentTime = comp->time;

    // Define the delay after which the output variable should change
    double delay = 5.0; // Change the delay value as per your requirement

    // Check if the current time is greater than the delay
    if (currentTime > delay) {
        // Change the value of the output variable
        comp->pout = 10.0; // Change the output variable value as per your requirement
    }
}
```

Supongo que es necesaria tener otra variable local que almacene el instante de activación. Después el trigger, podría ser un time event generado por `calculateValues`.

## Componentes
Quizá sería interesante pensar en componentes o algo así, algo tipo simulink.