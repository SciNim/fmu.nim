#nim c -r -d:fmu --nimcache:data/src values
nim c -r -d:fmu values
#../fmuCheck.linux64 -h 1 -s 11 -f values.fmu
../fmuCheck.linux64 -h 1 -s 11 -f -l 6 -e values.log values.fmu
