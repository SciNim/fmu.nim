# Creates the folder structure
import std/os
#import strutils

proc createStructure*(folder:string = "fmu"; checkDir = false) =
  removeDir(folder, checkDir = checkDir)

  var folderPath = joinPath(folder, "binaries/linux64")
  createDir(folderPath)
  
  folderPath = joinPath(folder, "documentation")
  createDir(folderPath)
 
  folderPath = joinPath(folder, "sources")
  createDir(folderPath)


when isMainModule:
  createStructure()
