rm inc.so
rm inc.fmu
# --nimcache:cache --deadcodeElim:off 
nim c --app:lib -o:inc.so --mm:orc -f -d:release inc.nim
cp inc.so fmusdk-master/fmu20/src/models/inc/fmu/binaries/linux64/inc.so
cd fmusdk-master/fmu20/src/models/inc/fmu/
zip -r ../../../../../../inc.fmu ./
cd ../../../../../../
./fmuCheck.linux64 inc.fmu