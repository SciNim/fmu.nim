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
  # 2.1 Create the library: .so or .dll
  if not defined(zig):
    var libFolder:string
    if defined(linux) and defined(amd64):
      libFolder = joinPath(tmpFolder, "binaries/linux64", fmu.id & ".so") 
    elif defined(windows) and defined(amd64):  # x86
      libFolder = joinPath(tmpFolder, "binaries/windows", fmu.id & ".dll")     

    var cmdline = "nim c --app:lib "
    cmdline &= "-o:" & libFolder & " --mm:orc -f -d:release " & fmu.nimFile

    consoleLogger.log(lvlInfo, "fmuBuilder > exportFmu: exporting library using command line:\n" & "   " & cmdline)  

    doAssert execCmdEx( cmdline ).exitCode == QuitSuccess

  else:  # -d:zig
    if defined(linux):
      var libFolder = joinPath(tmpFolder, "binaries/linux64", fmu.id & ".so") 

      var cmdline = "nim c --app:lib "
      var zig = """ --os:linux --cc:clang --cpu:amd64 --os:linux --clang.exe="zigcc" --clang.linkerexe="zigcc" """
      zig &= """ --passC:"-target x86_64-linux-gnu -fno-sanitize=undefined" """
      zig &= """ --passL:"-target x86_64-linux-gnu -fno-sanitize=undefined" """
      cmdline &= zig
      cmdline &= "-o:" & libFolder & " --mm:orc -f -d:release " & fmu.nimFile

      consoleLogger.log(lvlInfo, "fmuBuilder > exportFmu: exporting library using command line:\n" & "   " & cmdline)  

      doAssert execCmdEx( cmdline ).exitCode == QuitSuccess


      libFolder = joinPath(tmpFolder, "binaries/win64", fmu.id & ".dll")
      cmdline = "nim c --app:lib "   
      zig = """ --os:windows --cc:clang --cpu:amd64 --os:windows --clang.exe="zigcc" --clang.linkerexe="zigcc" """
      zig &= """ --passC:"-target x86_64-windows -fno-sanitize=undefined" """
      zig &= """ --passL:"-target x86_64-windows -fno-sanitize=undefined" """
      cmdline &= zig
      cmdline &= "-o:" & libFolder & " --mm:orc -f -d:release " & fmu.nimFile

      consoleLogger.log(lvlInfo, "fmuBuilder > exportFmu: exporting library using command line:\n" & "   " & cmdline)  
      doAssert execCmdEx( cmdline ).exitCode == QuitSuccess
    
    
    elif defined(windows):
      var libFolder = joinPath(tmpFolder, "binaries/linux64", fmu.id & ".so") 

      var cmdline = "nim c --app:lib "
      var zig = """ --cc:clang --clang.exe="zigcc.cmd" --clang.linkerexe="zigcc.cmd" """
      zig &= """ --passC:"-target x86_64-linux-gnu" """
      zig &= """ --passL:"-target x86_64-linux-gnu" """
      cmdline &= zig
      cmdline &= "--os:linux -o:" & libFolder & " --mm:orc -f -d:release " & fmu.nimFile

      consoleLogger.log(lvlInfo, "fmuBuilder > exportFmu: exporting library using command line:\n" & "   " & cmdline)  

      doAssert execCmdEx( cmdline ).exitCode == QuitSuccess


      libFolder = joinPath(tmpFolder, "binaries/win64", fmu.id & ".dll")
      cmdline = "nim c --app:lib "   
      zig = """ --cc:clang --clang.exe="zigcc.cmd" --clang.linkerexe="zigcc.cmd" """
      zig &= """ --passC:"-target x86_64-windows" """
      zig &= """ --passL:"-target x86_64-windows" """
      cmdline &= zig
      cmdline &= "--os:windows -o:" & libFolder & " --mm:orc -f -d:release " & fmu.nimFile

      consoleLogger.log(lvlInfo, "fmuBuilder > exportFmu: exporting library using command line:\n" & "   " & cmdline)  
      doAssert execCmdEx( cmdline ).exitCode == QuitSuccess


  #zig &= """ --passC:"-target x86_64-linux-musl -fno-sanitize=undefined" """
  #zig &= """ --passL:"-target x86_64-linux-musl -fno-sanitize=undefined" """

  # x86_64-windows
  # aarch64-linux
  # nim c --cpu:arm --os:linux --cc:clang --os:linux  --clang.exe="zigcc" --clang.linkerexe="zigcc" --passC:"-target arm-linux-musleabi -mcpu=arm1176jzf_s -fno-sanitize=undefined" --passL:"-target arm-linux-musleabi -mcpu=arm1176jzf_s" alarma.nim



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