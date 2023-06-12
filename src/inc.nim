# nim c --deadcodeElim:off --nimcache:.cache --app:lib -o:inc.so inc.nim
# nim c --deadcodeElim:off --app:lib -o:inc.so inc.nim
{.passC: "-DDISABLE_PREFIX".}  # -DFMI2_FUNCTION_PREFIX=MyModel_ 
#{.passC: "-DFMI2_Export".}
#{.passC: "".}
#import fmuTemplate
import strformat
#---------------------------
import lib/defs/[definitions, modelinstance, masks]
export definitions, modelinstance, masks
#---------------------------

# Porting inc.c (a particular model)
{.push exportc, dynlib.}
const
   MODEL_IDENTIFIER* ="inc"
   MODEL_GUID* ="{8c4e810f-3df3-4a00-8276-176fa3c9f008}"
   
   #define model size
   NUMBER_OF_REALS* = 0
   NUMBER_OF_INTEGERS* = 1
   NUMBER_OF_BOOLEANS* = 0
   NUMBER_OF_STRINGS* = 0
   NUMBER_OF_STATES* = 0
   NUMBER_OF_EVENT_INDICATORS* = 0



const
   counter = 0


proc setStartValues*(comp: ModelInstanceRef) =  # Con ref object, no es necesario usar "var"
    comp.i &= 1.fmi2Integer

# El código generado es: (*comp).i[((NI) 0)] = ((NI32) 1);

proc calculateValues*(comp:ModelInstanceRef) =
    if comp.state == modelInitializationMode:
        # set first time event
        comp.eventInfo.nextEventTimeDefined = fmi2True
        comp.eventInfo.nextEventTime        = 1 + comp.time

proc eventUpdate*(comp:ModelInstanceRef, 
                 eventInfo:ptr fmi2EventInfo, 
                 timeEvent:bool,  # cint
                 isNewEventIteration:fmi2Boolean) =  #cint
    if timeEvent:
        comp.i[counter] += 1;
        if comp.i[counter] == 13:
            eventInfo.terminateSimulation  = fmi2True
            eventInfo.nextEventTimeDefined = fmi2False
        else:
            eventInfo.nextEventTimeDefined = fmi2True
            eventInfo.nextEventTime        = 1 + comp.time
{.pop.}
#------------------------
{.passC: "-I./".}
{.passC: "-Ifmusdk-master/fmu20/src/shared/include -w -fmax-errors=5".}

{.passC: "-DMODEL_IDENTIFIER=\\\"" & MODEL_IDENTIFIER & "\\\"".}
{.passC: "-DMODEL_GUID=\\\"" & MODEL_GUID & "\\\"".}
{.passC: "-DNUMBER_OF_REALS=" & $NUMBER_OF_REALS .}
{.passC: "-DNUMBER_OF_INTEGERS=" & $NUMBER_OF_INTEGERS .}
{.passC: "-DNUMBER_OF_BOOLEANS=" & $NUMBER_OF_BOOLEANS .}
{.passC: "-DNUMBER_OF_STRINGS=" & $NUMBER_OF_STRINGS .}
{.passC: "-DNUMBER_OF_STATES=" & $NUMBER_OF_STATES .}
{.passC: "-DNUMBER_OF_EVENT_INDICATORS=" & $NUMBER_OF_EVENT_INDICATORS .}
{.passC: "-DDISABLE_PREFIX".}
{.compile: "fmuTemplate.c".}

#import lib/functions/modelexchange

import lib/defs/[definitions, masks, modelinstance, parameters]
import lib/functions/[helpers, logger]

include lib/functions/modelexchange
include lib/functions/cosimulation
include lib/functions/common
include lib/functions/setters
include lib/functions/others
include lib/functions/getters
