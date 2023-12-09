import system
import std/[os, osproc, strformat] #, paths]
import model, folder, compress, xml
import ../defs/modelinstance
#import ../fmu
import logging

template exportFmu*( fmu:Fmu;
                     outFile:string;
                     clean:bool = false) =
  consoleLogger.log(lvlInfo, "fmuBuilder > exportFmu: exporting FMU")


  # 1. Create folder structure
  #var dir = mkdtemp()
  var tmpFolder = "tmpFmu"  # FIXME: create a temporal folder
  createStructure(tmpFolder)

  # 2. Populate folder content
  # 2.1 Create the library: inc.so
  var libFolder:string
  if defined(linux) and defined(amd64):
    libFolder = joinPath(tmpFolder, "binaries/linux64", fmu.id & ".so") 
  elif defined(windows) and defined(amd64):  # x86
    libFolder = joinPath(tmpFolder, "binaries/windows", fmu.id & ".dll")     
 
  var cmdline = "nim c --app:lib -o:" & libFolder & " --mm:orc -f -d:release " & fmu.nimFile
  # nim c --cpu:arm --os:linux --cc:clang --os:linux  --clang.exe="zigcc" --clang.linkerexe="zigcc" --passC:"-target arm-linux-musleabi -mcpu=arm1176jzf_s -fno-sanitize=undefined" --passL:"-target arm-linux-musleabi -mcpu=arm1176jzf_s" alarma.nim
  consoleLogger.log(lvlInfo, "fmuBuilder > exportFmu: exporting library using command line:\n" & "   " & cmdline)  

  doAssert execCmdEx( cmdline ).exitCode == QuitSuccess


  # 2.2 Documentation into: documentation/ 
  for docFile in fmu.docFiles:
    copyFileToDir( docFile, 
                  joinPath(tmpFolder, "documentation") )
    
  copyFileToDir( fmu.icon, 
                 joinPath(tmpFolder, "documentation") )


  # 2.3 Sources into: sources/  FIXME
  # Use --nimcache:folder and select all files.
  for sourceFile in fmu.sourceFiles:  
    copyFileToDir( sourceFile, 
                   joinPath(tmpFolder, "sources") )

  # 2.4 XML
  var xmlData = createXml(fmu)#, inc.nEventIndicators)
  writeFile(joinPath(tmpFolder, "modelDescription.xml"), xmlData)

  # 3. Compress
  tmpFolder.compressInto( outFile )

  # 4. Clean
  if clean:
    removeDir(tmpFolder, checkDir = false )