## ---------------------------------------------------------------------------
## FMI functions: logging control, setters and getters for Real, Integer,
## Boolean, String
## ---------------------------------------------------------------------------
#import fmi2TypesPlatform, status, modelinstancetype, helpers, masks, logger
#import model
import strformat
import ../defs/[definitions,modelinstance, masks]
import helpers
import ../meta/filteredlog


# FORWARD DECLARATION---
proc calculateValues*(comp:ModelInstanceRef)

var NUMBER_OF_REALS {.global.} = 0
var NUMBER_OF_INTEGERS {.global.} = 0
var NUMBER_OF_BOOLEANS {.global.} = 0
#------------------------

{.push exportc: "$1",dynlib,cdecl.}

proc fmi2GetReal*(comp: ModelInstanceRef; vr: ptr fmi2ValueReference; nvr: csize_t;
                 value: ptr fmi2Real): fmi2Status =
    #var comp: ptr ModelInstance = cast[ptr ModelInstance](c)
    
    if invalidState(comp, "fmi2GetReal", MASK_fmi2GetReal):
        return fmi2Error
    if nvr > 0 and nullPointer(comp, "fmi2GetReal", "vr[]", vr):
        return fmi2Error
    if nvr > 0 and nullPointer(comp, "fmi2GetReal", "value[]", value):
        return fmi2Error
    if nvr > 0 and comp.isDirtyValues > 0:
        calculateValues(comp)
        comp.isDirtyValues = fmi2False

    #---- Only compiled if NUMBER_OF_REALS is >0
    # FIXME
    # if NUMBER_OF_REALS > 0:  # when
    #     for i in 0 ..< nvr:
    #         if vrOutOfRange(comp, "fmi2GetReal", vr[i], NUMBER_OF_REALS):
    #             return fmi2Error
    #         value[i] = getReal(comp, val) # <--------to be implemented by the includer of this file
    #         #value[i] = comp.r[vr[i]]            
    #         #value[i] = r[val] #getReal(comp, val)
    #         filteredLog(comp, fmi2OK, LOG_FMI_CALL, fmt"fmi2GetReal: #r{vr[i]}# = {value[i]}" )
    return fmi2OK



proc fmi2GetInteger*(comp: ModelInstanceRef; vr: ptr fmi2ValueReference; nvr: csize_t;
                    value: ptr fmi2Integer): fmi2Status  =
    #var comp: ptr ModelInstance = cast[ptr ModelInstance](c)
    if invalidState(comp, "fmi2GetInteger", MASK_fmi2GetInteger):
        return fmi2Error
    if nvr > 0 and nullPointer(comp, "fmi2GetInteger", "vr[]", vr):
            return fmi2Error
    if nvr > 0 and nullPointer(comp, "fmi2GetInteger", "value[]", value):
            return fmi2Error
    if nvr > 0 and comp.isDirtyValues > 0:
        calculateValues(comp)
        comp.isDirtyValues = fmi2False
    
    for i in 0 ..< nvr:
        if vrOutOfRange(comp, "fmi2GetInteger", vr[i], NUMBER_OF_INTEGERS):
            return fmi2Error

        value[i] = comp.i[vr[i]]
        filteredLog(comp, fmi2OK, LOG_FMI_CALL, fmt"fmi2GetInteger: #i{vr[i]}# = {value[i]}" )
    
    return fmi2OK

proc fmi2GetBoolean*(comp: ModelInstanceRef; vr: ptr fmi2ValueReference; nvr: csize_t;
                    value: ptr fmi2Boolean): fmi2Status  =
    #var comp: ptr ModelInstance = cast[ptr ModelInstance](c)
    if invalidState(comp, "fmi2GetBoolean", MASK_fmi2GetBoolean):
        return fmi2Error
    if nvr > 0 and nullPointer(comp, "fmi2GetBoolean", "vr[]", vr):
            return fmi2Error
    if nvr > 0 and nullPointer(comp, "fmi2GetBoolean", "value[]", value):
            return fmi2Error
    if nvr > 0 and comp.isDirtyValues > 0:
        calculateValues(comp)
        comp.isDirtyValues = fmi2False
    
    for i in 0 ..< nvr:
        if vrOutOfRange(comp, "fmi2GetBoolean", vr[i], NUMBER_OF_BOOLEANS):
            return fmi2Error
        value[i] = comp.b[vr[i]]
        var tmp:string
        if value[i] > 0:
           tmp = "true"
        else:
           tmp = "false"

        filteredLog(comp, fmi2OK, LOG_FMI_CALL, fmt"fmi2GetBoolean: #b{vr[i]}# = {tmp}")
    
    return fmi2OK

proc fmi2GetString*(comp: ModelInstanceRef; vr: ptr fmi2ValueReference; nvr: csize_t;
                   value: ptr fmi2String): fmi2Status =
    #var comp: ptr ModelInstance = cast[ptr ModelInstance](c)
    if invalidState(comp, "fmi2GetString", MASK_fmi2GetString):
        return fmi2Error
    if nvr > 0 and nullPointer(comp, "fmi2GetString", "vr[]", vr):
            return fmi2Error
    if nvr > 0 and nullPointer(comp, "fmi2GetString", "value[]", value):
            return fmi2Error
    if nvr > 0 and comp.isDirtyValues > 0:
        calculateValues(comp)
        comp.isDirtyValues = fmi2False
    #FIXME---------------------
    # var v = cast[ptr UncheckedArray[fmi2ValueReference]](vr)
    # var s = cast[ptr UncheckedArray[fmi2String]](comp.s)
    # var val = cast[ptr UncheckedArray[ptr fmi2String]](value)
    # for i in 0 ..< nvr:
    #     if vrOutOfRange(comp, "fmi2GetString", vr[i], NUMBER_OF_STRINGS):
    #         return fmi2Error

    #     # WARNING: to be tested the following
    #     val[i] = unsafeAddr( s[v[i]] )
    #     filteredLog(comp, fmi2OK, LOG_FMI_CALL, fmt"fmi2GetString: #s{vr[i]}# = '{value[i]}'")
    #-------------------
    return fmi2OK

{.pop.}