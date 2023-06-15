import system
import std/[os, osproc, strformat]
import fmu/[model, folder, compress, xml]
import ../fmu

# FMU BUILDER
proc genFmu2*(myModel: FMU; fname:string; callingFile: string) =
  # 1. Create folder structure
  var tmpFolder = "tmpFmu"  # FIXME: create a temporal folder
  createStructure(tmpFolder)

  # 2. Populate folder content
  # 2.1 Create the library: inc.so
  var nimFile = callingFile
  echo "Compiling module into a library: ", nimFile
  var libFolder = joinPath(tmpFolder, "binaries/linux64", myModel.id & ".so") 
  var cmdline = &"nim c --app:lib -o:{libFolder} --mm:orc -f -d:release {nimFile}"
  doAssert execCmdEx( cmdline ).exitCode == QuitSuccess
  echo "Executed: ", cmdline

  # 2.2 Documentation into: documentation/  FIXME
  copyFileToDir( "fmusdk-master/fmu20/src/models/inc/index.html", 
                 joinPath(tmpFolder, "documentation") )
  copyFileToDir( "fmusdk-master/fmu20/src/models/inc/model.png", 
                 joinPath(tmpFolder, "documentation") )


  # 2.3 Sources into: sources/  FIXME
  copyFileToDir( "fmusdk-master/fmu20/src/models/inc/inc.c", 
                 joinPath(tmpFolder, "sources") )

  # 2.4 XML
  var xmlData = createXml(myModel.id, myModel.guid, myModel.nEventIndicators)
  writeFile(joinPath(tmpFolder, "modelDescription.xml"), xmlData)

  # 3. Compress
  tmpFolder.compressInto( fname )

  # 4. Clean
  #removeDir(tmpFolder, checkDir = false )


template genFmu*(myModel: FMU; fname:string) =
  # needed in order to know the filename calling `genFmu`
  let pos = instantiationInfo()
  genFmu2(myModel, fname, pos.filename)