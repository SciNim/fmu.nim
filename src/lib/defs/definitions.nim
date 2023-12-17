
{.push exportc:"$1",dynlib, cdecl.}
# Logging categories
type
  LoggingCategories* = enum
    all     = "logAll",
    error   = "logError",
    fmiCall = "logFmiCall",
    event   = "logEvent"

const
  DT_EVENT_DETECT*:float = 1e-10  # It could be modified

type
  ModelState* {.size: sizeof(cint).} = enum
    modelStartAndEnd        , ##  ME state
    modelInstantiated       , ##  ME states
    modelInitializationMode , ##  ME states
    modelEventMode          , ##  CS states
    modelContinuousTimeMode , ##  CS states
    modelStepComplete       ,
    modelStepInProgress     ,
    modelStepFailed         ,
    modelStepCanceled       ,
    modelTerminated         ,
    modelError              ,
    modelFatal              


type
  fmi2Type* = enum
    fmi2ModelExchange = 0,
    fmi2CoSimulation  = 1

type
  fmi2StatusKind* = enum
    fmi2DoStepStatus       = 0,
    fmi2PendingStatus      = 1,
    fmi2LastSuccessfulTime = 2,
    fmi2Terminated         = 3

const
  fmi2True*  = 1
  fmi2False* = 0

type
  fmi2Component*  = pointer #  Pointer to FMU instance
    ##[
    This is a pointer to an FMU specific data structure that contains the information needed to
    process the model equations or to process the co-simulation of the respective slave. This data
    structure is implemented by the environment that provides the FMU; in other words, the calling
    environment does not know its content, and the code to process it must be provided by the FMU
    generation environment and must be shipped with the FMU.
    ]##

  # Pointer to FMU environment
  fmi2ComponentEnvironment*  = pointer 
  #fmi2ComponentEnvironment*  = pointer #  Pointer to FMU environment
  ##[
  This is a pointer to a data structure in the simulation environment that calls the FMU. Using this
  pointer, data from the modelDescription.xml file [(for example, mapping of valueReferences to
  variable names)] can be transferred between the simulation environment and the logger function
  (see section 2.1.5).
  ]##


  fmi2FMUstate* = pointer #  Pointer to internal FMU state


  fmi2ValueReference* = uint32 # unsigned int
  fmi2Real* = float64   # double
  fmi2Integer* = int32  # int
  fmi2Boolean* = int32 #{.dynlib.}
  fmi2Char* = char
  fmi2String* = distinct cstring #ptr fmi2Char
  fmi2Byte*  = char

proc `$`*(a:fmi2String): string {.borrow.}   # https://forum.nim-lang.org/t/7502



type
  fmi2EventInfo* {.bycopy.} = object
    newDiscreteStatesNeeded*: fmi2Boolean
    terminateSimulation*: fmi2Boolean
    nominalsOfContinuousStatesChanged*: fmi2Boolean
    valuesOfContinuousStatesChanged*: fmi2Boolean
    nextEventTimeDefined*: fmi2Boolean
    nextEventTime*: fmi2Real

#[
pag. 18

2.1.3 Status Returned by Functions
This section defines the “status” flag (an enumeration of type fmi2Status defined in file
“fmi2FunctionTypes.h”) that is returned by all functions to indicate the success of the function call:
]#

type
  fmi2Status* = enum
    ## Status returned by functions. The status has the following meaning
    fmi2OK      = 0,
      ## all well
    fmi2Warning = 1,
      ## things are not quite right, but the computation can continue. Function “logger” was
      ## called in the model (see below), and it is expected that this function has shown the prepared
      ## information message to the user.
    fmi2Discard = 2,
      ##[
      this return status is only possible if explicitly defined for the corresponding function3
      (ModelExchange: fmi2SetReal, fmi2SetInteger, fmi2SetBoolean, fmi2SetString,
      fmi2SetContinuousStates, fmi2GetReal, fmi2GetDerivatives,
      fmi2GetContinuousStates, fmi2GetEventIndicators;
      CoSimulation: fmi2SetReal, fmi2SetInteger, fmi2SetBoolean, fmi2SetString,
      fmi2DoStep, fmiGetXXXStatus):
      - For "model exchange": It is recommended to perform a smaller step size and evaluate the model
      equations again, for example because an iterative solver in the model did not converge or because
      a function is outside of its domain (for example sqrt(<negative number>)). If this is not possible, the
      simulation has to be terminated.
      - For "co-simulation": fmi2Discard is returned also if the slave is not able to return the required
      status information. The master has to decide if the simulation run can be continued.
      In both cases, function “logger” was called in the FMU (see below) and it is expected that this
      function has shown the prepared information message to the user if the FMU was called in debug
      mode (loggingOn = fmi2True). Otherwise, “logger” should not show a message.

      3 Functions fmi2SetXXX do not usually perform calculations but just store the values that are passed in internal buffers. The
      actual calculation is performed by fmi2GetXXX functions. Still fmi2SetXXX functions could check whether the input arguments
      are in their validity range. If not, these functions could return with fmi2Discard.
      ]##
    fmi2Error   = 3,
      ##[
      the FMU encountered an error. The simulation cannot be continued with this FMU
      instance. If one of the functions returns fmi2Error, it can be tried to restart the simulation from a
      formerly stored FMU state by calling fmi2SetFMUstate. This can be done if the capability flag
      canGetAndSetFMUstate is true and fmi2GetFMUstate was called before in non-erroneous state.
      If not, the simulation cannot be continued and fmi2FreeInstance or fmi2Reset must be called
      afterwards.4
      Further processing is possible after this call; especially other FMU instances are not affected.
      Function “logger” was called in the FMU (see below), and it is expected that this function has
      shown the prepared information message to the user.
      ]##
    fmi2Fatal   = 4,
      ##[
      the model computations are irreparably corrupted for all FMU instances. [For example,
      due to a run-time exception such as access violation or integer division by zero during the execution
      of an fmi function]. Function “logger” was called in the FMU (see below), and it is expected that this
      function has shown the prepared information message to the user. It is not possible to call any other
      function for any of the FMU instances.
      ]##
    fmi2Pending = 5
      ##[
      this status is returned only from the co-simulation interface, if the slave executes the
      function in an asynchronous way. That means the slave starts to compute but returns immediately.
      The master has to call fmi2GetStatus(..., fmi2DoStepStatus) to determine if the slave has
      finished the computation. Can be returned only by fmi2DoStep and by fmi2GetStatus (see
      section 4.2.3).
      ]##




##[
The struct contains pointers to functions provided by the environment to be used by the
FMU. It is not allowed to change these functions between fmi2Instantiate(..) and
fmi2Terminate(..) calls. Additionally, a pointer to the environment is provided
(componentEnvironment) that needs to be passed to the “logger” function, in order that the
logger function can utilize data from the environment, such as mapping a valueReference
to a string. In the unlikely case that fmi2Component is also needed in the logger, it has to be
passed via argument componentEnvironment. Argument componentEnvironment may be
a null pointer.
The componentEnvironment pointer is also passed to the stepFinished(..) function in
order that the environment can provide an efficient way to identify the slave that called
stepFinished(..).
In the default fmi2FunctionTypes.h file, typedefs for the function definitions are present
to simplify the usage; this is non-normative. The functions have the following meaning:
Function logger:
Pointer to a function that is called in the FMU, usually if an fmi2XXX function, does not
behave as desired. If “logger” is called with “status = fmi2OK”, then the message is a
pure information message. “instanceName” is the instance name of the model that calls this
function. “category” is the category of the message. The meaning of “category” is defined
by the modeling environment that generated the FMU. Depending on this modeling
environment, none, some or all allowed values of “category” for this FMU are defined in the
modelDescription.xml file via element “<fmiModelDescription><LogCategories>”,
see section 2.2.4. Only messages are provided by function logger that have a category
according to a call to fmi2SetDebugLogging (see below). Argument “message” is provided
in the same way and with the same format control as in function “printf” from the C
standard library. [Typically, this function prints the message and stores it optionally in a log
file.]
All string-valued arguments passed by the FMU to the logger may be deallocated by the
FMU directly after function logger returns. The environment must therefore create copies of
these strings if it needs to access these strings later.
The logger function will append a line break to each message when writing messages
after each other to a terminal or a file (the messages may also be shown in other ways, for
example, as separate text-boxes in a GUI). The caller may include line-breaks (using "\n")
within the message, but should avoid trailing line breaks.
Variables are referenced in a message with “#<Type><ValueReference>#” where
<Type> is “r” for fmi2Real, “i” for fmi2Integer, “b” for fmi2Boolean and “s” for
fmi2String. If character “#”shall be included in the message, it has to be prefixed with “#”,
so “#” is an escape character. [Example:
A message of the form
“#r1365# must be larger than zero (used in IO channel ##4)”
might be changed by the logger function to
“body.m must be larger than zero (used in IO channel #4)”
if “body.m” is the name of the fmi2Real variable with fmi2ValueReference =
1365.]
Function allocateMemory:
Pointer to a function that is called in the FMU if memory needs to be allocated. If attribute
“canNotUseMemoryManagementFunctions = true” in


<fmiModelDescription><ModelExchange / CoSimulation>, then function
allocateMemory is not used in the FMU and a void pointer can be provided. If this attribute
has a value of “false” (which is the default), the FMU must not use malloc, calloc or
other memory allocation functions. One reason is that these functions might not be available
for embedded systems on the target machine. Another reason is that the environment may
have optimized or specialized memory allocation functions. allocateMemory returns a
pointer to space for a vector of nobj objects, each of size “size” or NULL, if the request
cannot be satisfied. The space is initialized to zero bytes [(a simple implementation is to use
calloc from the C standard library)].
Function freeMemory:
Pointer to a function that must be called in the FMU if memory is freed that has been
allocated with allocateMemory. If a null pointer is provided as input argument obj, the
function shall perform no action [(a simple implementation is to use free from the C
standard library; in ANSI C89 and C99, the null pointer handling is identical as defined
here)]. If attribute “canNotUseMemoryManagementFunctions = true” in
<fmiModelDescription><ModelExchange / CoSimulation>, then function
freeMemory is not used in the FMU and a null pointer can be provided.
Function stepFinished:

Optional call back function to signal if the computation of a communication step of a co-
simulation slave is finished. A null pointer can be provided. In this case the master must

use fmiGetStatus(..) to query the status of fmi2DoStep. If a pointer to a function
is provided, it must be called by the FMU after a completed communication step.
[Note: In FMI 3.0, memory callback functions were removed, because their intended
uses failed to materialize and the implementations often had issues.
New in FMI 2.0.2: It is discouraged to use the memory callback functions.]

]##


{.pop.}