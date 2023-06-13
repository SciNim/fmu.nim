# TODO: 
# 1. ScalarVariable: al registrar, poder añadir la derivada.
# 2. Structure: generar la estructura adecuadamente
# 3. 

#modelinstancetype, modelstate
#import fmi2TypesPlatform, fmi2type, fmi2callbackfunctions, modelstate, fmi2eventinfo
#[
import macros

macro der(x,y, body:untyped):untyped  =
  result = quote do:
     `x` =  `body`
]#

template der*(dependant,independant,body:untyped):untyped {.dirty.} =
  static: numStates += 1
  #echo numStates
  #numStates = 1
  register(dependant, cLocal,     vContinuous, iCalculated, "", independant )
  equations:
    #dependant = body  # Derivative calculation
    body


template defineModel*( ):untyped {.dirty.} =                       
  const
      nIntegers*  = nParamsI    
      nReals*     = nParamsR 
      nBooleans*  = nParamsB
      nStrings*   = nParamsS
      nStates*    = numStates  # (known by the number of derivates) [Note that the information about continuous states is defined with element fmiModelDescription.ModelStructure.Derivatives
      nEventIndicators*  = 0 #numEventIndicators
  echo "Number of states: ", nStates
  #genModelInstance(0,1,0,0 ,0,0, NUMBER_OF_CATEGORIES)
  type
    ModelInstance* = ref object
        r*:          array[nReals, ptr float]  
        i*:          array[nIntegers, ptr int] 
        b*:          array[nBooleans, fmi2Boolean]
        s*:          array[nStrings, fmi2String]
        isPositive*: array[nEventIndicators, fmi2Boolean]
        time*: fmi2Real
        instanceName*: fmi2String
        `type`*: fmi2Type
        GUID*: fmi2String
        functions*: fmi2CallbackFunctions  #ptr fmi2CallbackFunctions  # <-----
        loggingOn*: fmi2Boolean
        logCategories*: array[nCategories, fmi2Boolean]
        componentEnvironment*: fmi2ComponentEnvironment
        state*: ModelState
        eventInfo*: fmi2EventInfo
        isDirtyValues*: fmi2Boolean
        isNewEventIteration*: fmi2Boolean

template setDefinitions*():untyped {.dirty.} =
  when not declared(nIntegers):
    defineModel( )

#a, b: untyped
template fmu*(id, guid:string, body: untyped): untyped {.dirty.} =
  ## This templates creates the appropriate structure for the FMU
  const
    modelId*   = id 
    modelGuid* = guid

  #import typedefinition
  include definitions#, enquire
  include enquire

  body
  
  setDefinitions()  

  proc setStartValues*( comp: ModelInstance)  =
      #var c = cast[ModelInstance](comp)
      #echo repr c.GUID.string
      var nParamR = 0
      var nParamI = 0
      for param in params:
        case param.kind
        of tInteger: 
          comp.i[nParamI] = param.addressI
          nParamI += 1
        of tReal: 
          comp.r[nParamR] = param.addressR
          nParamR += 1
        else: discard  
        #comp.i[param.idx][] = param.initValI #.fmi2Integer
        #param.addrI[] = int(param.initVal)
        #echo param.name
      #when typ == tInt:
      #  comp.i[n] = val.fmi2Integer  # Asigna al primer valor entero el valor "1"
      #when typ == tFloat:
      #  tFloat: comp.r[n]  = val.fmi2Real
      #of tBool: comp.b[n]   = val.fmi2Boolean
      #of tString: comp.s[n] = val.cstring.fmi2String  

  when not declared(calculateValues):
    #setDefinitions( )    
    proc calculateValues*( comp: ModelInstance) = discard

  when not declared(eventUpdate):
    #setDefinitions( )    
    proc eventUpdate*( comp: ModelInstance, eventInfo:ptr fmi2EventInfo,
                      isTimeEvent:bool, isNewEventIteration:int) = discard


  #[ Lenguaje C
  // define state vector as vector of value references
  #define STATES { x_ }

  // array of value references of states
  #if NUMBER_OF_STATES>0
  fmi2ValueReference vrStates[NUMBER_OF_STATES] = STATES;
  #endif
  ]#
  when nStates > 0:
     # array of value references of states
     var vrStates*: array[nStates, fmi2ValueReference]
     vrStates = [0.fmi2ValueReference]

  #include getters
  #include lib/logger
  include logger, masks, helpers, getters, setters
  include modelinstance
  include common

  #proc getEventIndicator*(comp:ptr ModelInstance, i:int)

  include cosimulation
  include cosimulation2
  include modelexchange



  #------
  when not compileOption("app", "lib"):
    import system, osproc, os, strformat, strutils, genfmu, tempfile, schema/xml
    #echo "OK"
    # Create the folder structure
    var dir = mkdtemp()
    let libDestination = dir / "binaries/linux64"
    createDir( libDestination )
    createDir( dir / "documentation" )
    createDir( dir / "sources" )

    # Create the library
    let (_,name, ext) = getAppFilename().splitFile
    let nimFile = name & ".nim"

    # Compilation
    let libName = fmt"{modelId}.so"
    # --nimcache:.cache
    doAssert execCmdEx( fmt"nim c --deadcodeElim:off  --gc:arc --app:lib -o:{libDestination / libName} {nimFile}" ).exitCode == QuitSuccess

    # Move the library to the right folder
    #let path = "fmusdk-master/fmu20/src/models/inc/fmu/"
    #copyFile( libName, path / "binaries/linux64" / libName )

    # Create XML
    let data = createXml( modelId, modelGuid, 0,
                          params )
    #echo repr paramsI

    writeFile(  dir / "modelDescription.xml", data )

    let fmuName = fmt"{modelId}.fmu"
    compressFolder( fmuName, dir & "/")
    echo "FMU created: ", fmuName
    echo fmt"Try it: fmusdk-master/fmu20/bin/fmusim_me {fmuName} 10 0.1"
    quit(QuitSuccess)

#template calculate*(body: untyped): untyped {.dirty.} =
#    body



template initialization*(body: untyped): untyped {.dirty.} =
  #when not defined(modelId):
  setDefinitions( )

  proc calculateValues*( comp: ModelInstance) =  
    if comp.state == modelInitializationMode:
      body

template event*(body:untyped):untyped {.dirty.} =
  setDefinitions( )  
  proc eventUpdate*( comp: ModelInstance, eventInfo:ptr fmi2EventInfo,
                    isTimeEvent:bool, isNewEventIteration:int) =
    body

template equations*(body: untyped): untyped {.dirty.} =
  #[ TODO: no soporta el que haya varias derivadas

  ]#
  setDefinitions() 
  #echo "EQUATIONS"
  # called by fmi2GetReal, fmi2GetContinuousStates and fmi2GetDerivatives
  proc getReal*(comp:ModelInstance, vr:fmi2ValueReference):fmi2Real {.exportc:"$1", dynlib, cdecl.} =
      #if params[vr].initial.get == iCalculated:
      #  body
      #var x = comp.r[0][]
      #var k = comp.r[1][]
      case vr:
        of 0: 
          return comp.r[0][]
        of 1: 
          return comp.r[1][]
        of 2: 
          var x = comp.r[0][]
          var k = comp.r[1][]
          return body
        else: 
          return 0.0
      #[
      case vr:
      of 0..nReals-1:
        #echo vr
        echo repr comp.r
        #echo vr.int " -> ", repr comp.r[vr.int]
        comp.r[vr][]
      else:
        0
      ]#
      #case vr:
      #of 0..nReals-1: comp.r[vr][].fmi2Real
      #else: 0.fmi2Real
      #return comp.r[vr][]

      #case vr:
      #  of x     : return comp.r[x]
      #  of der_x : return - r[k] * r[x]
      #  of k     : return r[k]
      #  else     : return 0  