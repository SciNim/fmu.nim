import ../defs/[definitions, modelinstance]
import folder

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



proc genFMU*( m: FMU; fname:string ) =
  var tmpFolder = "tmpFmu"  # FIXME: create a temporal folder
  
  # 1. Create folder structure
  createStructure(tmpFolder)

  echo fname