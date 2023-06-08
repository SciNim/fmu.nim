{.passC: "-DDISABLE_PREFIX".}
{.passC: "-I./fmusdk-master/fmu20/src/shared/include".}

{.passC: "-I./fmusdk-master/fmu20/src/shared".}
# Importing /home/jose/src/nimlang/fmusdk-master/fmu20/src/models/fmuTemplate.h
# Generated at 2019-07-11T23:18:41+02:00
# Command line:
#   /home/jose/.nimble/pkgs/nimterop-0.1.0/nimterop/toast --pnim --preprocess --recurse --defines+=DISABLE_PREFIX --defines+=FMI2_Export --defines+=FMI2_FUNCTION_PREFIX=MyModel_ --includeDirs+=/home/jose/src/nimlang/fmusdk-master/fmu20/src/shared/include --includeDirs+=/home/jose/src/nimlang/fmusdk-master/fmu20/src/shared --nim:/usr/bin/nim /home/jose/src/nimlang/fmusdk-master/fmu20/src/models/fmuTemplate.h

{.hint[ConvFromXtoItselfNotNeeded]: off.}

import lib/defs/definitions

const
  headerfmuTemplate {.used.} = "./fmusdk-master/fmu20/src/models/fmuTemplate.h"



  #  categories of logging supported by model.
  #  Value is the index in logCategories of a ModelInstance.
  # LOG_ALL* = 0
  # LOG_ERROR* = 1
  # LOG_FMI_CALL* = 2
  # LOG_EVENT* = 3
  # NUMBER_OF_CATEGORIES* = 4


{.pragma: impfmuTemplate, importc, header: headerfmuTemplate.}
{.pragma: impfmuTemplateC, impfmuTemplate, cdecl.}

type
  #fmi2Component* {.impfmuTemplate.} = pointer

#  Pointer to FMU instance
  fmi2ComponentEnvironment* {.impfmuTemplate.} = pointer

#  Pointer to FMU environment
  #fmi2FMUstate* {.impfmuTemplate.} = pointer

#  Pointer to internal FMU state
  #fmi2ValueReference* {.impfmuTemplate.} = cuint
  #fmi2Real* {.impfmuTemplate.} = cdouble
  #fmi2Integer* {.impfmuTemplate.} = cint
  #fmi2Boolean* {.impfmuTemplate.} = cint
  #fmi2Char* {.impfmuTemplate.} = cchar
  #fmi2String* {.impfmuTemplate.} = cstring #ptr fmi2Char
  #fmi2Byte* {.impfmuTemplate.} = cchar
  fmi2CallbackLogger* {.impfmuTemplate.} = proc(a1: fmi2ComponentEnvironment, a2: fmi2String, a3: fmi2Status, a4: fmi2String, a5: fmi2String) {.cdecl.}
  fmi2CallbackAllocateMemory* {.impfmuTemplate.} = proc(a1: cuint, a2: cuint) {.cdecl.}
  fmi2CallbackFreeMemory* {.impfmuTemplate.} = proc(a1: pointer) {.cdecl.}
  fmi2StepFinished* {.impfmuTemplate.} = proc(a1: fmi2ComponentEnvironment, a2: fmi2Status) {.cdecl.}
  # fmi2CallbackFunctions* {.impfmuTemplate, bycopy.} = object
  #   logger*: fmi2CallbackLogger
  #   allocateMemory*: fmi2CallbackAllocateMemory
  #   freeMemory*: fmi2CallbackFreeMemory
  #   stepFinished*: fmi2StepFinished
  #   componentEnvironment*: fmi2ComponentEnvironment


#  reset alignment policy to the one set before reading this file
#  Define fmi2 function pointer types to simplify dynamic loading
# **************************************************
# Types for Common Functions
# ***************************************************
#  Inquire version numbers of header files and setting logging status
  fmi2GetTypesPlatformTYPE* {.impfmuTemplate.} = proc(): cstring {.cdecl.}
  fmi2GetVersionTYPE* {.impfmuTemplate.} = proc(): cstring {.cdecl.}

#  Creation and destruction of FMU instances and setting debug status
  fmi2InstantiateTYPE* {.impfmuTemplate.} = proc(a1: fmi2String, a2: fmi2Type, a3: fmi2String, a4: fmi2String, a5: ptr fmi2CallbackFunctions, a6: fmi2Boolean, a7: fmi2Boolean): fmi2Component {.cdecl.}
  fmi2FreeInstanceTYPE* {.impfmuTemplate.} = proc(a1: fmi2Component) {.cdecl.}

#  Enter and exit initialization mode, terminate and reset
  fmi2SetupExperimentTYPE* {.impfmuTemplate.} = proc(a1: fmi2Component, a2: fmi2Boolean, a3: fmi2Real, a4: fmi2Real, a5: fmi2Boolean, a6: fmi2Real): fmi2Status {.cdecl.}
  fmi2EnterInitializationModeTYPE* {.impfmuTemplate.} = proc(a1: fmi2Component): fmi2Status {.cdecl.}
  fmi2ExitInitializationModeTYPE* {.impfmuTemplate.} = proc(a1: fmi2Component): fmi2Status {.cdecl.}
  fmi2TerminateTYPE* {.impfmuTemplate.} = proc(a1: fmi2Component): fmi2Status {.cdecl.}
  fmi2ResetTYPE* {.impfmuTemplate.} = proc(a1: fmi2Component): fmi2Status {.cdecl.}

#  Getting and setting variable values
#  Getting and setting the internal FMU state
  fmi2GetFMUstateTYPE* {.impfmuTemplate.} = proc(a1: fmi2Component, a2: ptr fmi2FMUstate): fmi2Status {.cdecl.}
  fmi2SetFMUstateTYPE* {.impfmuTemplate.} = proc(a1: fmi2Component, a2: fmi2FMUstate): fmi2Status {.cdecl.}
  fmi2FreeFMUstateTYPE* {.impfmuTemplate.} = proc(a1: fmi2Component, a2: ptr fmi2FMUstate): fmi2Status {.cdecl.}
  fmi2SerializedFMUstateSizeTYPE* {.impfmuTemplate.} = proc(a1: fmi2Component, a2: fmi2FMUstate, a3: ptr cuint): fmi2Status {.cdecl.}

#  Getting partial derivatives
# **************************************************
# Types for Functions for FMI2 for Model Exchange
# ***************************************************
#  Enter and exit the different modes
  fmi2EnterEventModeTYPE* {.impfmuTemplate.} = proc(a1: fmi2Component): fmi2Status {.cdecl.}
  fmi2NewDiscreteStatesTYPE* {.impfmuTemplate.} = proc(a1: fmi2Component, a2: ptr fmi2EventInfo): fmi2Status {.cdecl.}
  fmi2EnterContinuousTimeModeTYPE* {.impfmuTemplate.} = proc(a1: fmi2Component): fmi2Status {.cdecl.}
  fmi2CompletedIntegratorStepTYPE* {.impfmuTemplate.} = proc(a1: fmi2Component, a2: fmi2Boolean, a3: ptr fmi2Boolean, a4: ptr fmi2Boolean): fmi2Status {.cdecl.}

#  Providing independent variables and re-initialization of caching
  fmi2SetTimeTYPE* {.impfmuTemplate.} = proc(a1: fmi2Component, a2: fmi2Real): fmi2Status {.cdecl.}

#  Evaluation of the model equations
# **************************************************
# Types for Functions for FMI2 for Co-Simulation
# ***************************************************
#  Simulating the slave
  fmi2DoStepTYPE* {.impfmuTemplate.} = proc(a1: fmi2Component, a2: fmi2Real, a3: fmi2Real, a4: fmi2Boolean): fmi2Status {.cdecl.}
  fmi2CancelStepTYPE* {.impfmuTemplate.} = proc(a1: fmi2Component): fmi2Status {.cdecl.}

#  Inquire slave status
  fmi2GetStatusTYPE* {.impfmuTemplate.} = proc(a1: fmi2Component, a2: fmi2StatusKind, a3: ptr fmi2Status): fmi2Status {.cdecl.}
  fmi2GetRealStatusTYPE* {.impfmuTemplate.} = proc(a1: fmi2Component, a2: fmi2StatusKind, a3: ptr fmi2Real): fmi2Status {.cdecl.}
  fmi2GetIntegerStatusTYPE* {.impfmuTemplate.} = proc(a1: fmi2Component, a2: fmi2StatusKind, a3: ptr fmi2Integer): fmi2Status {.cdecl.}
  fmi2GetBooleanStatusTYPE* {.impfmuTemplate.} = proc(a1: fmi2Component, a2: fmi2StatusKind, a3: ptr fmi2Boolean): fmi2Status {.cdecl.}
  fmi2GetStringStatusTYPE* {.impfmuTemplate.} = proc(a1: fmi2Component, a2: fmi2StatusKind, a3: ptr fmi2String): fmi2Status {.cdecl.}

#[
// ---------------------------------------------------------------------------
// Function calls allowed state masks for both Model-exchange and Co-simulation
// ---------------------------------------------------------------------------
]#


#  end of extern "C" {
#
#   Export FMI2 API functions on Windows and under GCC.
#   If custom linking is desired then the FMI2_Export must be
#   defined before including this file. For instance,
#   it may be set to __declspec(dllimport).
#
#  Macros to construct the real function name
#    (prepend function name by FMI2_FUNCTION_PREFIX)
# **************************************************
# Common Functions
# ***************************************************
# **************************************************
# Functions for FMI2 for Model Exchange
# ***************************************************
# **************************************************
# Functions for FMI2 for Co-Simulation
# ***************************************************
#  Version number
# **************************************************
# Common Functions
# ***************************************************
#  Inquire version numbers of header files
#  Creation and destruction of FMU instances
#  Enter and exit initialization mode, terminate and reset
#  Getting and setting variables values
#  Getting and setting the internal FMU state
#  Getting partial derivatives
# **************************************************
# Functions for FMI2 for Model Exchange
# ***************************************************
#  Enter and exit the different modes
#  Providing independent variables and re-initialization of caching
#  Evaluation of the model equations
# **************************************************
# Functions for FMI2 for Co-Simulation
# ***************************************************
#  Simulating the slave
#  Inquire slave status
#  end of extern "C" {
#  macros used to define variables
proc setString*(comp: fmi2Component, vr: fmi2ValueReference, 
value: fmi2String): fmi2Status {.impfmuTemplateC.}

