import std/[os,osproc, strformat]
import ../defs/[definitions, modelinstance, parameters]



# type
#   FmuObj* = object
#     id*: string
#     guid*: string
#     params*:seq[Param]

#     nEventIndicators*: int
#     nStates*: int


#   FMU* = ref FmuObj


# proc genCode*( m: FMU ) =
#   echo "TODO. GENERATE"
#   # Compilation
#   let libDestination = "."
#   let libName = fmt"{m.id}.so"
#   let nimFile = "genlib.nim"
  
#   import genlib
#   prueba(m.id) 
#   # --nimcache:.cache
#   #doAssert execCmdEx( fmt"nim c --mm:orc --app:lib -o:{libDestination / libName} {nimFile}" ).exitCode == QuitSuccess
#   #doAssert execCmdEx( fmt"nim c --mm:orc --app:lib -o:{libDestination / libName} {nimFile}" ).exitCode == QuitSuccess 
#   doAssert execCmdEx( fmt"nim c --mm:orc lib/fmu/genlib.nim" ).exitCode == QuitSuccess 



