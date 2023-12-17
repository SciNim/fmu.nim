# inc.nim
## Compilation as FMI 2.0 Model Exchange
```sh
nim c -r -d:fmu2me inc.nim
```

## Testing
```sh
../fmuCheck.linux64 -h 1 -s 14 -f -l 6 -e inc.log inc.fmu
```
This creates the log file: [inc.log](https://github.com/mantielero/fmu.nim/blob/main/examples/inc/inc.log).

It also displays the following results:
```txt
"time","counter"
0.0000000000000000E+00,1
1.0000000000000000E+00,2
2.0000000000000000E+00,3
3.0000000000000000E+00,4
4.0000000000000000E+00,5
5.0000000000000000E+00,6
6.0000000000000000E+00,7
7.0000000000000000E+00,8
8.0000000000000000E+00,9
9.0000000000000000E+00,10
1.0000000000000000E+01,11
1.1000000000000000E+01,12
1.2000000000000000E+01,13
```