import definitions


const
  # ---------------------------------------------------------------------------
  # Function calls allowed state masks for both Model-exchange and Co-simulation
  # ---------------------------------------------------------------------------
  MASK_fmi2GetTypesPlatform*:set[ModelState] = {
    modelStartAndEnd, modelInstantiated, modelInitializationMode,
    modelEventMode, modelContinuousTimeMode,
    modelStepComplete, modelStepInProgress, modelStepFailed, modelStepCanceled,
    modelTerminated, modelError}
  MASK_fmi2GetVersion* = MASK_fmi2GetTypesPlatform
  MASK_fmi2SetDebugLogging*:set[ModelState] = {
    modelInstantiated, modelInitializationMode,
    modelEventMode, modelContinuousTimeMode,
    modelStepComplete, modelStepInProgress, modelStepFailed, modelStepCanceled,
    modelTerminated, modelError}
  MASK_fmi2Instantiate*:set[ModelState] = {modelStartAndEnd}
  MASK_fmi2FreeInstance*:set[ModelState] = {
    modelInstantiated, modelInitializationMode,
    modelEventMode, modelContinuousTimeMode,
    modelStepComplete, modelStepFailed, modelStepCanceled,
    modelTerminated, modelError}

  MASK_fmi2Terminate*:set[ModelState] = {
    modelEventMode, modelContinuousTimeMode,
    modelStepComplete, modelStepFailed }
  MASK_fmi2Reset* = MASK_fmi2FreeInstance


  MASK_fmi2SetupExperiment*:set[ModelState] = {modelInstantiated}
  MASK_fmi2EnterInitializationMode*:set[ModelState] = {modelInstantiated}
  MASK_fmi2ExitInitializationMode*:set[ModelState]  = {modelInitializationMode}
  MASK_fmi2GetReal*:set[ModelState] =  { 
    modelInitializationMode, modelEventMode,
    modelContinuousTimeMode, modelStepComplete, 
    modelStepFailed, modelStepCanceled, 
    modelTerminated, modelError }
  MASK_fmi2GetInteger* = MASK_fmi2GetReal
  MASK_fmi2GetBoolean* = MASK_fmi2GetReal
  MASK_fmi2GetString*  = MASK_fmi2GetReal
  MASK_fmi2SetReal*:set[ModelState] = {
    modelInstantiated, modelInitializationMode,
    modelEventMode, modelContinuousTimeMode,
    modelStepComplete }
  MASK_fmi2SetInteger*:set[ModelState] = {
    modelInstantiated, modelInitializationMode,
    modelEventMode, modelStepComplete }
  MASK_fmi2SetBoolean* =              MASK_fmi2SetInteger
  MASK_fmi2SetString* =               MASK_fmi2SetInteger
  MASK_fmi2GetFMUstate* =             MASK_fmi2FreeInstance
  MASK_fmi2SetFMUstate* =             MASK_fmi2FreeInstance
  MASK_fmi2FreeFMUstate* =            MASK_fmi2FreeInstance
  MASK_fmi2SerializedFMUstateSize* =  MASK_fmi2FreeInstance
  MASK_fmi2SerializeFMUstate* =       MASK_fmi2FreeInstance
  MASK_fmi2DeSerializeFMUstate* =     MASK_fmi2FreeInstance
  MASK_fmi2GetDirectionalDerivative*:set[ModelState] = { 
    modelInitializationMode,
    modelEventMode, modelContinuousTimeMode,
    modelStepComplete, modelStepFailed, modelStepCanceled,
    modelTerminated, modelError }

  # ---------------------------------------------------------------------------
  # Function calls allowed state masks for Model-exchange
  # ---------------------------------------------------------------------------
  MASK_fmi2EnterEventMode*:set[ModelState] = { modelEventMode, modelContinuousTimeMode }
  MASK_fmi2NewDiscreteStates* = {modelEventMode}
  MASK_fmi2EnterContinuousTimeMode* = {modelEventMode}
  MASK_fmi2CompletedIntegratorStep* = {modelContinuousTimeMode}
  MASK_fmi2SetTime* =  {modelEventMode, modelContinuousTimeMode}
  MASK_fmi2SetContinuousStates* = {modelContinuousTimeMode}
  MASK_fmi2GetEventIndicators* = { modelInitializationMode,
                                        modelEventMode, modelContinuousTimeMode,
                                        modelTerminated, modelError }
  MASK_fmi2GetContinuousStates* =     MASK_fmi2GetEventIndicators
  MASK_fmi2GetDerivatives* =          { modelEventMode, modelContinuousTimeMode,
                                        modelTerminated, modelError }
  MASK_fmi2GetNominalsOfContinuousStates* = { modelInstantiated,
                                        modelEventMode, modelContinuousTimeMode,
                                        modelTerminated, modelError }

  # ---------------------------------------------------------------------------
  # Function calls allowed state masks for Co-simulation
  # ---------------------------------------------------------------------------
  MASK_fmi2SetRealInputDerivatives* = { modelInstantiated, modelInitializationMode,
                                        modelStepComplete}
  MASK_fmi2GetRealOutputDerivatives* = { modelStepComplete, modelStepFailed, modelStepCanceled,
                                         modelTerminated, modelError}
  MASK_fmi2DoStep* =                  {modelStepComplete}
  MASK_fmi2CancelStep* =              {modelStepInProgress}
  MASK_fmi2GetStatus* =               { modelStepComplete, modelStepInProgress, modelStepFailed,
                                        modelTerminated }
  MASK_fmi2GetRealStatus* =           MASK_fmi2GetStatus
  MASK_fmi2GetIntegerStatus* =        MASK_fmi2GetStatus
  MASK_fmi2GetBooleanStatus* =        MASK_fmi2GetStatus
  MASK_fmi2GetStringStatus* =         MASK_fmi2GetStatus
