# fmu.nim
The purpose of this library is enable the creation of FMU files that can be later used in many compatible simulation packages such as OpenModelica, Matlab, Dymola, ...

This library is heavily based on [fmusdk](https://github.com/qtronic/fmusdk).

## Status
This is in a very alpha stage, but right now is capable of creating `inc.so` in almost pure Nim. The it embeds that library within an FMU. The folder structure and XML file is taken from the C version.

### How to test it?
Just run:
```sh
$ cd src
$ ./build.sh
```

