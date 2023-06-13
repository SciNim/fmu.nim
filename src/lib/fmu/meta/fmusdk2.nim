import macros
#modelinstancetype, modelstate
#import fmi2TypesPlatform, fmi2type, fmi2callbackfunctions, modelstate, fmi2eventinfo

template id(name:string):untyped =
  nnkPostfix.newTree(
     newIdentNode("*"),
     nnkAccQuoted.newTree( newIdentNode(name) )
  )
#a, b: untyped
macro fmu*(id, guid: static[string], body: untyped): untyped =
  ## This templates creates the appropriate structure for the FMU

  let modelIdentifier = id("MODEL_IDENTIFIER")
  let modelGuid= id("MODEL_GUID")
  let nReals = id("NUMBER_OF_REALS")
  let nInts = id("NUMBER_OF_INTEGERS")
  let nBools = id("NUMBER_OF_BOOLEANS")
  let nStrings = id("NUMBER_OF_STRINGS")
  let nStates = id("NUMBER_OF_STATES")
  let nEventIndicators = id("NUMBER_OF_EVENT_INDICATORS")
  let counter = id("counter")
  #echo modelIdentifier.repr
  result = quote do:
              import typedefinition
              import definitions, enquire

              const
                  `modelIdentifier` = `id`
                  `modelGuid`       = `guid`

                  `nReals` = 0
                  `nInts`  = 1
                  `nBools` = 0
                  `nStrings` = 0
                  `nStates`  = 0
                  `nEventIndicators` = 0


                  `counter` = 0

              genModelInstance(0,1,0,0,0,0, NUMBER_OF_CATEGORIES)

              `body`

              when NUMBER_OF_STATES > 0:
                 # array of value references of states
                 var vrStates*: array[NUMBER_OF_STATES, fmi2ValueReference] = STATES

              #include getters
              include logger, masks, helpers, getters, setters
              include modelinstance
              include common

              #proc getEventIndicator*(comp:ptr ModelInstance, i:int)

              include cosimulation
              include cosimulation2
              include modelexchange
  echo result.repr
