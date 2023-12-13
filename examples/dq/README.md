# dq.nim

## Result
```txt
[INFO][FMUCHK] FMI compliance checker Test [FMILibrary: Test] build date: Jun  4 2023
[INFO][FMUCHK] Called with following options:
[INFO][FMUCHK] ../fmuCheck.linux64 -h 0.1 dq.fmu
[INFO][FMUCHK] Will process FMU dq.fmu
[INFO][FMILIB] XML specifies FMI standard version 2.0
[INFO][FMUCHK] Model name: dq
[INFO][FMUCHK] Model GUID: {8c4e810f-3df3-4a00-8276-176fa3c9f000}
[INFO][FMUCHK] Model version: 
[INFO][FMUCHK] FMU kind: ModelExchange
[INFO][FMUCHK] The FMU contains:
0 constants
1 parameters
0 discrete variables
2 continuous variables
0 inputs
0 outputs
2 local variables
0 independent variables
0 calculated parameters
3 real variables
0 integer variables
0 enumeration variables
0 boolean variables
0 string variables

[INFO][FMUCHK] Printing output file header
"time"
[INFO][FMUCHK] Model identifier for ModelExchange: dq
[INFO][FMILIB] Loading 'linux64' binary with 'default' platform types
[INFO][FMUCHK] Version returned from ME FMU: '2.0'

[INFO][FMUCHK] Initialized FMU for simulation starting at time 0
0.0000000000000000E+00
1.0000000000000001E-01
2.0000000000000001E-01
3.0000000000000004E-01
4.0000000000000002E-01
5.0000000000000000E-01
5.9999999999999998E-01
6.9999999999999996E-01
7.9999999999999993E-01
8.9999999999999991E-01
9.9999999999999989E-01
1.0000000000000000E+00
[INFO][FMUCHK] Simulation finished successfully at time 1
FMU check summary:
FMU reported:
	0 warning(s) and error(s)
Checker reported:
	0 Warning(s)
	0 Error(s)
```