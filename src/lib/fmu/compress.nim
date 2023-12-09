#import zip/zipfiles
import zippy/ziparchives
import os, strutils, sugar


proc compressInto*(folder, filename:string) =
  var cwd = getCurrentDir()
  #echo cwd
  setCurrentDir(folder)
  #echo getCurrentDir()
  #echo folder
  let z = ZipArchive()
  #var z: ZipArchive
  # add new file
  #discard z.open(filename, fmWrite)
  #z.addFile("foo.bar")#, newStringStream("content"))

  #for path in walkDirRec(folder):# relative = true): #,
    #if path.startsWith("fmu/"):
  #    var dest = path.dup: removePrefix( folder )
  #    dest = dest[1 ..< dest.len]

  #    z.addFile(path)

  z.addDir("./")
  setCurrentDir(cwd)
  z.writeZipArchive(filename)


when isMainModule:
  let filename = "prueba.fmu"
  let path = "fmusdk-master/fmu20/src/models/inc/fmu/"
  compressInto(path, filename)