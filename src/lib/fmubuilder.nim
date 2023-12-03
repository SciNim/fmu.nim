import system
import std/[os, osproc, strformat] #, paths]
import fmu/[model, folder, compress, xml]
import ../fmu


template exportFmu*( fmu:Fmu;
                     outFile:string;
                     clean:bool = false) =
  echo "----------------- Exporting FMU -----------------"
  #echo repr getCurrentDir()
  # if compiles(calculateValues):
  #   echo "definido"
  #   #var calculateValues = calculaValues
  # if declared(calculateValues):
  #   echo "declared"
  # echo repr instantiationInfo()
  # echo "holA"
  # echo repr fmu
  # echo typeof(fmu)
  #var cmdline = &"nim c --app:lib -o:./borrame.so --mm:orc -f -d:release inc"
  #echo cmdLine
  #doAssert execCmdEx( cmdline ).exitCode == QuitSuccess
  #export(fmu)

  # 1. Create folder structure
  #var dir = mkdtemp()
  var tmpFolder = "tmpFmu"  # FIXME: create a temporal folder
  createStructure(tmpFolder)

  # 2. Populate folder content
  # 2.1 Create the library: inc.so
  #var nimFile = instantiationInfo().filename#callingFile
  #echo "Compiling module into a library: ", nimFile
  var libFolder = joinPath(tmpFolder, "binaries/linux64", fmu.id & ".so") 
  #echo "Lib folder: ", libFolder
  #var cmd = 
  var cmdline = "nim c --app:lib -o:" & libFolder & " --mm:orc -f -d:release " & fmu.nimFile
  echo "Create library:"
  echo cmdline
  # echo fmu.nimFile

  doAssert execCmdEx( cmdline ).exitCode == QuitSuccess


  # 2.2 Documentation into: documentation/ 
  for docFile in fmu.docFiles:
    copyFileToDir( docFile, 
                  joinPath(tmpFolder, "documentation") )
    
  copyFileToDir( fmu.icon, 
                 joinPath(tmpFolder, "documentation") )


  # 2.3 Sources into: sources/  FIXME
  for sourceFile in fmu.sourceFiles:  
    copyFileToDir( sourceFile, 
                 joinPath(tmpFolder, "sources") )

  # 2.4 XML
  var xmlData = createXml(fmu)#, inc.nEventIndicators)
  writeFile(joinPath(tmpFolder, "modelDescription.xml"), xmlData)

  # 3. Compress
  tmpFolder.compressInto( outFile) #fname )

  # 4. Clean
  if clean:
    removeDir(tmpFolder, checkDir = false )