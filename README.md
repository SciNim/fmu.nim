# fmu.nim
## Purpose
The purpose of this library is enabling the creation of FMU files that can be later used in many compatible simulation packages such as OpenModelica, Matlab, Dymola, ...

This library is heavily based on [fmusdk](https://github.com/qtronic/fmusdk).

## Installing
You need nim v2.0. You can use choosenim in order to install Nim. 

As usual, with nimble:
```sh
nimble install https://github.com/mantielero/fmu.nim
```

TODO: to explore `atlas`.

## Status
This is in an alpha stage. Nonetheless, in its current state is capable some remarkable features. For example, it can create and FMU that works both in windows and linux.

It is capable of creating a working FMU. It does so by:

1. Creating `inc.so` in pure Nim. 
2. Embedding the `inc.so` within the `.fmu` file. 
3. Creating the folder structure 
4. Creating the XML file.
5. Packaging everything in a zip file and changing the extension into .fmu.

### How to test it?
Go to the `examples` folder.

The following command will generate `inc.so` and embed it into `inc.fmu`:
```
$ nim c -r -d:fmu inc
```
The `-d:fmu` forces the creation of a FMU.

Then test it:
```
$ fmuCheck.linux64 ./inc.fmu
```
or:
```
$ ./fmusim_me inc.fmu 5 0.1
```
> this will simulate during 5seconds using 0.1 second steps. it will create the file `results.csv`.

### FMU compatible with windows and linux
If you compile like this:
```sh
nim c -r -d:fmu inc
```
you will get a FMU that is compatible only with the platform in which it was compile.

But if you compile using `zig`:
```sh
nim c -r -d:fmu -d:zig inc
```
you will get a FMU compatible with windows and linux (amd64 in both cases).

#### Getting zig
Install `zig` as you would do in windows or linux. (In windows, you need to have the binary reachable in the path; in Linux your package manager will take care of that).

Then you need to install with `nimble` (Nim package manager) the package: `zigcc`.
```sh
nimble install zigcc
```
(this is the same for both windows and linux; in windows you might need to install `git`)



# Details
## Intro
In general terms, we are making Nim to export C functions fulfilling the naming conventions of the FMU standard.

## Model
A new model requires the info such as:
```nim
  id      = "inc"
  guid    = "{8c4e810f-3df3-4a00-8276-176fa3c9f008}"
```

We will call the `model` template with these values. The `model` template is defined in `src/fmu.nim`. This calls `model2` template (another template within `src/fmu.nim`). They both are responsible for structuring the code: the custom defined functions plus the other functions required by the standard.

All this will create two modes of operations for the code:

1. When compiled as a library, it will create a library such as `inc.so`.
2. When compiled as an app it uses `src/lib/fmubuilder.nim`:
  
  - Creates the folder structure
  - Creates the XML
  - Compress everything into a `.fmu` file.


# Importing an FMU in OpenModelica
In Linux, open:
```sh
$ OMEdit
```
Then import the created FMU:

![](https://i.imgur.com/AvVh6mq.png)

![](https://i.imgur.com/pN7xbqJ.png)

![](https://i.imgur.com/bqhYm5T.png)

Create a new Model (we will use the imported FMU in it):

![](https://i.imgur.com/0JEJday.png)

![](https://i.imgur.com/nLPxsxE.png)

Then drag-n-drop the FMU into the model:

![](https://i.imgur.com/fm1W72l.png)

![](https://i.imgur.com/yMy25P5.png)

Add an output for the integer. For that, drag-n-drop `IntegerOutput` on the model:

![](https://i.imgur.com/L8DU8jV.png)

![](https://i.imgur.com/DAZibNo.png)

and connect the FMU instance to `IntegerOutput`:

![](https://i.imgur.com/ElqfXfA.png)

Configure the simulation:

![](https://i.imgur.com/vtb6EQn.png)

![](https://i.imgur.com/879tGGo.png)

At this point, OpenModelica ask you to store the model somewhere (`example.mo` file). Select whereever it suits you.

![](https://i.imgur.com/MY7r14a.png)

![](https://i.imgur.com/mtXbQsn.png)



## Manual
### `setStartValues`
Called by `fmi2Instantiate` with signature `setStartValues(comp:Fmu)`.

In `fmusdk`, it initialize everything. This is no needed here. Right now this would only be needed in case of requiring to setup something during the FMU instantiation phase.


### `calculateValues`
Calculate the values of the FMU (Functional Mock-up Unit) variables at a specific time step during simulation. 

This function is defined by the user and called from `getters.nim` (`fmi2GetReal`, `fmi2GetInteger`, `fmi2GetBoolean`, `fmi2GetString`) and `common.nim` (`fmi2ExitInitializationMode`).

Lazy set values (given it is only called when `isDirtyValues == true` in the model) for all variable that are computed from other variables.


// Lazy set values for all variable that are computed from other variables.
void calculateValues(ModelInstance *comp) {
    //if (comp->state == modelInitializationMode) {
    //  initialization code here
    //  set first time event, if any, using comp->eventInfo.nextEventTime
    //}

#### Example: `inc.nim`
Defines:
```nim
proc calculateValues*(comp: ModelInstanceRef) =
  if comp.state == modelInitializationMode:
      # set first time event
      comp.eventInfo.nextEventTimeDefined = fmi2True
      comp.eventInfo.nextEventTime        = 1 + comp.time
```

In this case, `calculateValues` creates new temporal events. In particular, creates in the `InitializationMode` state a new event 1s after the start.


### eventUpdate
Used to set the next time event, if any.
#### Example: `inc.nim`
Reacts to events. In the `inc.nim` example, the first event was created in `calculateValues`.

In the `inc.nim` case, `eventUpdate` reacts to the event by creating a new event.

- [ ] TODO: To talk about: 
  ```nim
  type
    fmi2EventInfo* {.bycopy.} = object
      newDiscreteStatesNeeded*: fmi2Boolean
      terminateSimulation*: fmi2Boolean
      nominalsOfContinuousStatesChanged*: fmi2Boolean
      valuesOfContinuousStatesChanged*: fmi2Boolean
      nextEventTimeDefined*: fmi2Boolean
      nextEventTime*: fmi2Real
  ```
  and about: `comp.isNewEventIteration`


### getReal
This is a user defined function with signature `proc getReal*(comp: FmuRef; vr:fmi2ValueReference):float`. It is called by `getters.nim` in `fmi2GetReal`.

It is responsible for calculating the float values.

### Example: `values.nim`
Defined as:
```nim
proc getReal*(comp: FmuRef;
              vr:fmi2ValueReference):float =
  if vr == 0:  # el primer índice
    return comp["myfloat"].valueR
  elif vr == 1:
    return -comp["myfloat"].valueR
  else:
    return 0.0
```

# TODO
- [ ] unit testing for the examples
- [ ] avoid using numbers for `getReal`
- [ ] replace `compiles` with `defined`
- [ ] To support co-simulation
- [ ] To simulate within Nim. This would prevent the need for `fmuChecker`.

# Interesting projects related to FMU
- [Awesome FMI](https://github.com/traversaro/awesome-fmi)
 
- Exporting FMUs:

  - [cppfmu](https://github.com/viproma/cppfmu)
  - [FMIpp](https://github.com/fmipp/fmipp)
  - [fmusdk](https://github.com/qtronic/fmusdk): inspirational for this project.

- Importing FMUs:
  
  - [FMI4cpp](https://github.com/NTNU-IHB/FMI4cpp): in order to simulate with FMI.

