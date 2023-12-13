# values.nim

## results
```txt
[INFO][FMUCHK] FMI compliance checker Test [FMILibrary: Test] build date: Jun  4 2023
[INFO][FMUCHK] Called with following options:
[INFO][FMUCHK] ../fmu.nim/examples/fmuCheck.linux64 -h 1 -s 13 values.fmu
[INFO][FMUCHK] Will process FMU values.fmu
[INFO][FMILIB] XML specifies FMI standard version 2.0
[INFO][FMUCHK] Model name: values
[INFO][FMUCHK] Model GUID: {8c4e810f-3df3-4a00-8276-176fa3c9f004}
[INFO][FMUCHK] Model version: 
[INFO][FMUCHK] FMU kind: ModelExchange
[INFO][FMUCHK] The FMU contains:
0 constants
0 parameters
6 discrete variables
2 continuous variables
3 inputs
3 outputs
2 local variables
0 independent variables
0 calculated parameters
2 real variables
2 integer variables
0 enumeration variables
2 boolean variables
2 string variables

[INFO][FMUCHK] No input data provided. In case of simulation initial values from FMU will be used.
[INFO][FMUCHK] Printing output file header
"time","int_out","bool_out","string_out"
[INFO][FMUCHK] Model identifier for ModelExchange: values
[INFO][FMILIB] Loading 'linux64' binary with 'default' platform types
[INFO][FMUCHK] Version returned from ME FMU: '2.0'

[INFO][FMUCHK] Initialized FMU for simulation starting at time 0
0.0000000000000000E+00,0,0,"jan"
1.0000000000000000E+00,1,1,"feb"
2.0000000000000000E+00,2,0,"march"
3.0000000000000000E+00,3,1,"april"
4.0000000000000000E+00,4,0,"may"
5.0000000000000000E+00,5,1,"june"
6.0000000000000000E+00,6,0,"july"
7.0000000000000000E+00,7,1,"august"
8.0000000000000000E+00,8,0,"sept"
9.0000000000000000E+00,9,1,"october"
1.0000000000000000E+01,10,0,"november"
1.1000000000000000E+01,11,1,"december"
1.2000000000000000E+01,12,0,"december"
[INFO][FMUCHK] FMU requested simulation termination
[INFO][FMUCHK] Simulation finished successfully at time 12
FMU check summary:
FMU reported:
	0 warning(s) and error(s)
Checker reported:
	0 Warning(s)
	0 Error(s)
```

In the original:
```txt
0.0000000000000000E+00,0,0,"jan"
1.0000000000000000E+00,1,1,"feb"
2.0000000000000000E+00,2,0,"march"
3.0000000000000000E+00,3,1,"april"
4.0000000000000000E+00,4,0,"may"
5.0000000000000000E+00,5,1,"june"
6.0000000000000000E+00,6,0,"july"
7.0000000000000000E+00,7,1,"august"
8.0000000000000000E+00,8,0,"sept"
9.0000000000000000E+00,9,1,"october"
1.0000000000000000E+01,10,0,"november"
1.1000000000000000E+01,11,1,"december"
1.2000000000000000E+01,12,0,"december"
```