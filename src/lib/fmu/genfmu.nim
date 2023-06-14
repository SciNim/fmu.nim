import model
import genlib
import folder, compress
import std/[os,osproc]


proc genFMU*( m: FMU; fname:string ) =
  var tmpFolder = "tmpFmu"  # FIXME: create a temporal folder
  
  # 1. Create folder structure
  createStructure(tmpFolder)


  # 2. Create the library
  echo genCode(m)


  # 3. Populate folder content
  # 3.1 Library into: binaries/linux64/
  copyFileToDir( "inc.so", joinPath(tmpFolder, "binaries/linux64") )

  # 3.2 Documentation into: documentation/
  copyFileToDir( "fmusdk-master/fmu20/src/models/inc/index.html", 
                 joinPath(tmpFolder, "documentation") )
  copyFileToDir( "fmusdk-master/fmu20/src/models/inc/model.png", 
                 joinPath(tmpFolder, "documentation") )

  # 3.3 Sources into: sources/
  copyFileToDir( "fmusdk-master/fmu20/src/models/inc/inc.c", 
                 joinPath(tmpFolder, "sources") )


  # 4. Compress
  tmpFolder.compressInto( fname )


  # 5. Clean
  removeDir(tmpFolder, checkDir = false )

