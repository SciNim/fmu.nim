import std/[os,osproc, strformat]
import ../defs/[definitions, modelinstance]


type
  FmuObj* = object
    id*: string
    guid*: string

    nIntegers*: int
    nBooleans*: int
    nStrings*: int
    nReals*: int
    nEventIndicators*: int
    nStates*: int

    counter*: int   # FIXME: needed? 

    setStartValues*:  proc( comp: ModelInstanceRef )
    calculateValues*: proc( comp: ModelInstanceRef )
    eventUpdate*:     proc( comp:ModelInstanceRef, 
                            eventInfo:ptr fmi2EventInfo, 
                            timeEvent:bool,  # cint
                            isNewEventIteration:fmi2Boolean )

  FMU* = ref FmuObj


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


