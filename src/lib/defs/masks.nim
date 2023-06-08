import definitions
#import modelstate
#import bitops
#[
import bitops
import strformat

var a = (1 shl 0)
var b = (1 shl 1)

echo fmt"{(a and b):b}"
]#

#proc `|`(a,b:ModelState):bool =


const
  # ---------------------------------------------------------------------------
  # Function calls allowed state masks for both Model-exchange and Co-simulation
  # ---------------------------------------------------------------------------
  MASK_fmi2GetTypesPlatform* =        ( modelStartAndEnd or modelInstantiated or modelInitializationMode or
                                        modelEventMode or modelContinuousTimeMode or
                                        modelStepComplete or modelStepInProgress or modelStepFailed or modelStepCanceled or
                                        modelTerminated or modelError)
  MASK_fmi2GetVersion* =              MASK_fmi2GetTypesPlatform
  MASK_fmi2SetDebugLogging* =         (modelInstantiated or modelInitializationMode or
                                        modelEventMode or modelContinuousTimeMode or
                                        modelStepComplete or modelStepInProgress or modelStepFailed or modelStepCanceled or
                                        modelTerminated or modelError)
  MASK_fmi2Instantiate* =             (modelStartAndEnd)
  MASK_fmi2FreeInstance* =            (modelInstantiated or modelInitializationMode or
                                        modelEventMode or modelContinuousTimeMode or
                                        modelStepComplete or modelStepFailed or modelStepCanceled or
                                        modelTerminated or modelError)



  MASK_fmi2Terminate* =               (modelEventMode or modelContinuousTimeMode or
                                        modelStepComplete or modelStepFailed)
  MASK_fmi2Reset* =                   MASK_fmi2FreeInstance


  MASK_fmi2SetupExperiment* = modelInstantiated
  MASK_fmi2EnterInitializationMode* = modelInstantiated
  MASK_fmi2ExitInitializationMode*  = modelInitializationMode
  MASK_fmi2GetReal* =  ( modelInitializationMode or modelEventMode or
                         modelContinuousTimeMode or modelStepComplete or modelStepFailed or modelStepCanceled or modelTerminated or modelError)
  MASK_fmi2GetInteger* = MASK_fmi2GetReal
  MASK_fmi2GetBoolean* = MASK_fmi2GetReal
  MASK_fmi2GetString*  = MASK_fmi2GetReal
  MASK_fmi2SetReal*    = ( modelInstantiated or modelInitializationMode or
                           modelEventMode or modelContinuousTimeMode or
                           modelStepComplete)
  MASK_fmi2SetInteger* = ( modelInstantiated or modelInitializationMode or
                           modelEventMode or modelStepComplete )
  MASK_fmi2SetBoolean* =              MASK_fmi2SetInteger
  MASK_fmi2SetString* =               MASK_fmi2SetInteger
  MASK_fmi2GetFMUstate* =             MASK_fmi2FreeInstance
  MASK_fmi2SetFMUstate* =             MASK_fmi2FreeInstance
  MASK_fmi2FreeFMUstate* =            MASK_fmi2FreeInstance
  MASK_fmi2SerializedFMUstateSize* =  MASK_fmi2FreeInstance
  MASK_fmi2SerializeFMUstate* =       MASK_fmi2FreeInstance
  MASK_fmi2DeSerializeFMUstate* =     MASK_fmi2FreeInstance
  MASK_fmi2GetDirectionalDerivative* = ( modelInitializationMode or
                                         modelEventMode or modelContinuousTimeMode or
                                         modelStepComplete or modelStepFailed or modelStepCanceled or
                                         modelTerminated or modelError )

  # ---------------------------------------------------------------------------
  # Function calls allowed state masks for Model-exchange
  # ---------------------------------------------------------------------------
  MASK_fmi2EnterEventMode* =          (modelEventMode or modelContinuousTimeMode)
  MASK_fmi2NewDiscreteStates* =       modelEventMode
  MASK_fmi2EnterContinuousTimeMode* = modelEventMode
  MASK_fmi2CompletedIntegratorStep* = modelContinuousTimeMode
  MASK_fmi2SetTime* =                 (modelEventMode or modelContinuousTimeMode)
  MASK_fmi2SetContinuousStates* =     modelContinuousTimeMode
  MASK_fmi2GetEventIndicators* =      ( modelInitializationMode or
                                        modelEventMode or modelContinuousTimeMode or
                                        modelTerminated or modelError)
  MASK_fmi2GetContinuousStates* =     MASK_fmi2GetEventIndicators
  MASK_fmi2GetDerivatives* =          ( modelEventMode or modelContinuousTimeMode or
                                        modelTerminated or modelError)
  MASK_fmi2GetNominalsOfContinuousStates* = ( modelInstantiated or
                                        modelEventMode or modelContinuousTimeMode or
                                        modelTerminated or modelError)

  # ---------------------------------------------------------------------------
  # Function calls allowed state masks for Co-simulation
  # ---------------------------------------------------------------------------
  MASK_fmi2SetRealInputDerivatives* = ( modelInstantiated or modelInitializationMode or
                                        modelStepComplete)
  MASK_fmi2GetRealOutputDerivatives* = ( modelStepComplete or modelStepFailed or modelStepCanceled or
                                         modelTerminated or modelError)
  MASK_fmi2DoStep* =                  modelStepComplete
  MASK_fmi2CancelStep* =              modelStepInProgress
  MASK_fmi2GetStatus* =               ( modelStepComplete or modelStepInProgress or modelStepFailed or
                                        modelTerminated)
  MASK_fmi2GetRealStatus* =           MASK_fmi2GetStatus
  MASK_fmi2GetIntegerStatus* =        MASK_fmi2GetStatus
  MASK_fmi2GetBooleanStatus* =        MASK_fmi2GetStatus
  MASK_fmi2GetStringStatus* =         MASK_fmi2GetStatus
