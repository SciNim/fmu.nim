import zip/zipfiles
import os, strutils, sugar


proc compressInto*(folder, filename:string) =
  var tmp:string
  #if origin.endsWith("fmu/"):
  #  tmp = origin.dup: removeSuffix("fmu/")
  #echo tmp


  var z: ZipArchive
  # add new file
  discard z.open(filename, fmWrite)
  #z.addFile("foo.bar")#, newStringStream("content"))

  for path in walkDirRec(folder):# relative = true): #,
    #if path.startsWith("fmu/"):
      var dest = path.dup: removePrefix( folder )
      #echo path
      #echo dest
      z.addFile(dest, path)

  z.close()

when isMainModule:
  let filename = "prueba.fmu"
  let path = "fmusdk-master/fmu20/src/models/inc/fmu/"
  compressInto(path, filename)
