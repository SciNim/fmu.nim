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
