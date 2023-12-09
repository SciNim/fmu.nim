#nim c -r -d:fmu --nimcache:data/src values
nim c -r -d:fmu values
../fmuCheck.linux64 -h 1 -s 13 values.fmu