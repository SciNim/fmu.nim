import zip/zipfiles
import os, strutils, sugar


proc compressFolder(filename, origin:string) =
  var tmp:string
  #if origin.endsWith("fmu/"):
  #  tmp = origin.dup: removeSuffix("fmu/")
  #echo tmp


  var z: ZipArchive
  # add new file
  discard z.open(filename, fmWrite)
  #z.addFile("foo.bar")#, newStringStream("content"))

  for path in walkDirRec(origin):# relative = true): #,
    #if path.startsWith("fmu/"):
      var dest = path.dup: removePrefix( origin )
      #echo path
      #echo dest
      z.addFile(dest, path)

  # read file to string stream
  #z.open(filename, fmRead)
  #let outStream = newStringStream("")
  #z.extractFile("foo.bar", outStream)
  z.close()

when isMainModule:
  let filename = "prueba.fmu"
  let path = "fmusdk-master/fmu20/src/models/inc/fmu/"
  compressFolder(filename, path)
