import system
import std/[os, osproc, strformat] #, paths]
import model, folder, compress, xml
import ../defs/[definitions, modelinstance]
#import ../fmu
import logging

template exportFmu*( fmu:Fmu;
                     outFile:string;
                     typ:fmi2Type = fmi2ModelExchange;
                     clean:bool = false) =
  consoleLogger.log(lvlInfo, "fmuBuilder > exportFmu: exporting FMU")


  # 1. Create folder structure
  #var dir = mkdtemp()
  var tmpFolder = "tmpFmu"  # FIXME: create a temporal folder
  createStructure(tmpFolder)

  # 2. Populate folder content
  # 2.1 Create the library: .so or .dll
  if not defined(zig):
    var libFolder:string
    if defined(linux) and defined(amd64):
      libFolder = joinPath(tmpFolder, "binaries/linux64", fmu.id & ".so") 
    elif defined(windows) and defined(amd64):  # x86
      libFolder = joinPath(tmpFolder, "binaries/win64", fmu.id & ".dll")     

    var cmdline = "nim c --app:lib "
    cmdline &= "-o:" & libFolder & " --mm:orc -f -d:release " & fmu.nimFile

    consoleLogger.log(lvlInfo, "fmuBuilder > exportFmu: exporting library using command line:\n" & "   " & cmdline)  

    doAssert execCmdEx( cmdline ).exitCode == QuitSuccess

  else:  # -d:zig

    var cmdline = "nim c --app:lib "
    
    var zigPath = "zigcc"
    if defined(windows):
      zigPath &= ".cmd"
    #var osvalue, relpath, ext, target: string
    for (osvalue, relpath, ext, target) in @[("linux",   "binaries/linux64", ".so",  "x86_64-linux-gnu"),  ("windows", "binaries/win64",   ".dll", "x86_64-windows")]:
      var execLine = cmdline
      execLine &= " --os:" & osvalue & " --cc:clang --cpu:amd64 --os:" & osvalue
      execLine &= " --clang.exe=\"" & zigPath & "\" --clang.linkerexe=\"" & zigPath & "\" "
      execLine &= " --passC:\"-target " & target & " -fno-sanitize=undefined\" "
      execLine &= " --passL:\"-target " & target & " -fno-sanitize=undefined\" "
      var libFolder = joinPath(tmpFolder, relpath, fmu.id & ext) 
      execLine &= "-o:" & libFolder & " --mm:orc -f -d:release " & fmu.nimFile

      consoleLogger.log(lvlInfo, "fmuBuilder > exportFmu: exporting library using command line:\n" & "   " & execLine)  

      doAssert execCmdEx( execLine ).exitCode == QuitSuccess


  #zig &= """ --passC:"-target x86_64-linux-musl -fno-sanitize=undefined" """
  #zig &= """ --passL:"-target x86_64-linux-musl -fno-sanitize=undefined" """

  # x86_64-windows
  # aarch64-linux
  # nim c --cpu:arm --os:linux --cc:clang --os:linux  --clang.exe="zigcc" --clang.linkerexe="zigcc" --passC:"-target arm-linux-musleabi -mcpu=arm1176jzf_s -fno-sanitize=undefined" --passL:"-target arm-linux-musleabi -mcpu=arm1176jzf_s" alarma.nim



  # 2.2 Documentation into: documentation/ 
  for docFile in fmu.docFiles:
    copyFileToDir( docFile, 
                  joinPath(tmpFolder, "documentation") )
  
  if fmu.icon != "":
    copyFileToDir( fmu.icon, 
                  joinPath(tmpFolder, "documentation") )


  # 2.3 Sources into: sources/  FIXME
  # Use --nimcache:folder and select all files.
  for sourceFile in fmu.sourceFiles:  
    copyFileToDir( sourceFile, 
                   joinPath(tmpFolder, "sources") )

  # 2.4 XML
  # 2.4.1 Make sure that the states are updated
  for p in fmu.parameters.values:
    if p.kind == tReal:
      if p.state:
        fmu.states &= p.idx
  
  # 2.4.2 Make sure that the events are considered
  #for p in fmu.isPositive.values:
  #  if p.state:
  #    fmu.states &= p.idx
  fmu.nEventIndicators = fmu.isPositive.len

  var xmlData = fmu.createXml(typ)
  writeFile(joinPath(tmpFolder, "modelDescription.xml"), xmlData)

  # 3. Compress
  tmpFolder.compressInto( outFile )

  # 4. Clean
  if clean:
    removeDir(tmpFolder, checkDir = false )


#[
  "aarch64_be-linux-gnu",
  "aarch64_be-linux-musl",
  "aarch64_be-windows-gnu",
  "aarch64-linux-gnu",
  "aarch64-linux-musl",
  "aarch64-windows-gnu",
  "armeb-linux-gnueabi",
  "armeb-linux-gnueabihf",
  "armeb-linux-musleabi",
  "armeb-linux-musleabihf",
  "armeb-windows-gnu",
  "arm-linux-gnueabi",
  "arm-linux-gnueabihf",
  "arm-linux-musleabi",
  "arm-linux-musleabihf",
  "arm-windows-gnu",
  "i386-linux-gnu",
  "i386-linux-musl",
  "i386-windows-gnu",
  "mips64el-linux-gnuabi64",
  "mips64el-linux-gnuabin32",
  "mips64el-linux-musl",
  "mips64-linux-gnuabi64",
  "mips64-linux-gnuabin32",
  "mips64-linux-musl",
  "mipsel-linux-gnu",
  "mipsel-linux-musl",
  "mips-linux-gnu",
  "mips-linux-musl",
  "powerpc64le-linux-gnu",
  "powerpc64le-linux-musl",
  "powerpc64-linux-gnu",
  "powerpc64-linux-musl",
  "powerpc-linux-gnu",
  "powerpc-linux-musl",
  "riscv64-linux-gnu",
  "riscv64-linux-musl",
  "s390x-linux-gnu",
  "s390x-linux-musl",
  "sparc-linux-gnu",
  "sparcv9-linux-gnu",
  "wasm32-freestanding-musl",
  "x86_64-linux-gnu",
  "x86_64-linux-gnux32",
  "x86_64-linux-musl",
  "x86_64-windows-gnu"
]#