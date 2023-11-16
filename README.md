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


# Interesting projects
- [Awesome FMI](https://github.com/traversaro/awesome-fmi)
 
- Exporting FMUs:

  - [cppfmu](https://github.com/viproma/cppfmu)
  - [FMIpp](https://github.com/fmipp/fmipp)
  - [fmusdk](https://github.com/qtronic/fmusdk): inspirational for this project.

- Importing FMUs:
  
  - [FMI4cpp](https://github.com/NTNU-IHB/FMI4cpp): in order to simulate with FMI.
