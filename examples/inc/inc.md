# inc.nim
## run.sh
```
$ nim c -r -d:fmu inc
$ ../fmuCheck.linux64 -h 0.2 inc.fmu
```

## Result
```sh
$ ../fmuCheck.linux64 -h 0.2 inc.fmu  
[INFO][FMUCHK] FMI compliance checker Test [FMILibrary: Test] build date: Jun  4 2023
[INFO][FMUCHK] Called with following options:
[INFO][FMUCHK] ../fmuCheck.linux64 -h 0.2 inc.fmu
[INFO][FMUCHK] Will process FMU inc.fmu
[INFO][FMILIB] XML specifies FMI standard version 2.0
[INFO][FMUCHK] Model name: inc
[INFO][FMUCHK] Model GUID: {8c4e810f-3df3-4a00-8276-176fa3c9f008}
[INFO][FMUCHK] Model version: 
[INFO][FMUCHK] FMU kind: ModelExchange
[INFO][FMUCHK] The FMU contains:
0 constants
0 parameters
1 discrete variables
0 continuous variables
0 inputs
1 outputs
0 local variables
0 independent variables
0 calculated parameters
0 real variables
1 integer variables
0 enumeration variables
0 boolean variables
0 string variables

[INFO][FMUCHK] Printing output file header
"time","counter"
[INFO][FMUCHK] Model identifier for ModelExchange: inc
[INFO][FMILIB] Loading 'linux64' binary with 'default' platform types
[INFO][FMUCHK] Version returned from ME FMU: '2.0'

[INFO][FMUCHK] Initialized FMU for simulation starting at time 0
0.0000000000000000E+00,1
2.0000000000000001E-01,1
4.0000000000000002E-01,1
6.0000000000000009E-01,1
8.0000000000000004E-01,1
1.0000000000000000E+00,2
[INFO][FMUCHK] Simulation finished successfully at time 1
ENTERING: fmi2FreeInstance
FMU check summary:
FMU reported:
	0 warning(s) and error(s)
Checker reported:
	0 Warning(s)
	0 Error(s)
```


