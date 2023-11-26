## ---------------------------------------------------------------------------
## FMI functions: logging control, setters and getters for Real, Integer,
## Boolean, String
## ---------------------------------------------------------------------------
import strformat
import ../defs/[definitions, modelinstance, masks]
import helpers
import ../meta/filteredlog

template useGetReal():untyped =
    mixin getReal
    if comp.realAddr.len > 0:  # when: no puede evaluar en tiempo de compilación
     for i in 0 ..< nvr:
         if vrOutOfRange(comp, "fmi2GetReal", vr[i], comp.realAddr.len): #NUMBER_OF_REALS):
             return fmi2Error
         #echo "useGetReal - 1"
         value[i] = getReal(comp, i.fmi2ValueReference) # <--------to be implemented by the includer of this file
         #echo "useGetReal - 2"
         filteredLog(comp, fmi2OK, fmiCall, ("fmi2GetReal: #r" & $vr[i] & "# = " & $value[i]).fmi2String )    

{.push exportc: "$1",dynlib,cdecl.}


# forward declaration (this needs to be override by the user)
#proc getReal(comp: ModelInstanceRef; vr:ptr fmi2ValueReference):fmi2Real 

# https://forum.nim-lang.org/t/10272#68206
#var getReal*: proc(comp: ModelInstanceRef; vr:ptr fmi2ValueReference):fmi2Real 

proc fmi2GetReal*(comp: ModelInstanceRef; 
                  vr: ptr fmi2ValueReference; 
                  nvr: csize_t;
                  value: ptr fmi2Real): fmi2Status =
    #var comp: ptr ModelInstance = cast[ptr ModelInstance](c)
    #echo "fmi2GetReal: enter-------"
    if invalidState(comp, "fmi2GetReal", MASK_fmi2GetReal):
        return fmi2Error
    
    if nvr > 0 and nullPointer(comp, "fmi2GetReal", "vr[]", vr):
        return fmi2Error
    
    if nvr > 0 and nullPointer(comp, "fmi2GetReal", "value[]", value):
        return fmi2Error

    if nvr > 0 and comp.isDirtyValues == fmi2True:
        calculateValues(comp)   # <---------------
        comp.isDirtyValues = fmi2False

    #---- Only compiled if NUMBER_OF_REALS is >0
    # inspired by: 
    # https://forum.nim-lang.org/t/10272
    # https://forum.nim-lang.org/t/9070
    #echo "\n\n\n===========> NVR: ", nvr
    when compiles(useGetReal): # Checks if the template compiles
        useGetReal()

    # mixin getReal
    # if comp.realAddr.len > 0:  # when: no puede evaluar en tiempo de compilación
    #  for i in 0 ..< nvr:
    #      if vrOutOfRange(comp, "fmi2GetReal", vr[i], comp.realAddr.len): #NUMBER_OF_REALS):
    #          return fmi2Error
    #      value[i] = getReal(comp, i.fmi2ValueReference) # <--------to be implemented by the includer of this file
    #      #value[i] = comp.r[vr[i]]            
    #      #value[i] = r[val] #getReal(comp, val)
    #      filteredLog(comp, fmi2OK, fmiCall, fmt"fmi2GetReal: #r{vr[i]}# = {value[i]}".fmi2String )
    #echo "fmi2GetReal: exit-------"    
    return fmi2OK



proc fmi2GetInteger*( comp: ModelInstanceRef; 
                      vr: ptr fmi2ValueReference; 
                      nvr: csize_t;
                      value: ptr fmi2Integer): fmi2Status  =
    ## returns an integer value
    ## `vr` is a vector and `nvr` its size.
    ## `value` is another vector with the results (same `nvr` size)

    # Perform a number of checks
    # - check if the model is in an invalid state
    if invalidState(comp, "fmi2GetInteger", MASK_fmi2GetInteger):
        return fmi2Error
    
    # - checks that vector `vr` is not null when `nvr > 0`.
    if nvr > 0 and nullPointer(comp, "fmi2GetInteger", "vr[]", vr):
        return fmi2Error

    # - checks that vector `value` is not null when `nvr > 0`.    
    if nvr > 0 and nullPointer(comp, "fmi2GetInteger", "value[]", value):      
        return fmi2Error
    
    # - if isDirtyValues recalculate the values. It seems this is done in a lazy way (by updating
    #   the time; the values are only calculate after a time event -I think-)
    if nvr > 0 and comp.isDirtyValues == fmi2True:       
        calculateValues(comp)
        comp.isDirtyValues = fmi2False


    # iterate over all the values required by `vr`

    for i in 0 ..< nvr: 
        #echo "comp.integerAddr.len: ", comp.integerAddr.len
        if vrOutOfRange(comp, "fmi2GetInteger", vr[i], comp.integerAddr.len):#NUMBER_OF_INTEGERS):
            return fmi2Error

        # read the value from memory address (vr[i] is the position; `[]`: memory content)
        value[i] = comp.integerAddr[vr[i]][].fmi2Integer 
        filteredLog(comp, fmi2OK, fmiCall, fmt"fmi2GetInteger: #i{vr[i]}# = {value[i]}".fmi2String )
    
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
    if nvr > 0 and comp.isDirtyValues == fmi2True:
        calculateValues(comp)
        comp.isDirtyValues = fmi2False
    
    for i in 0 ..< nvr:
        if vrOutOfRange(comp, "fmi2GetBoolean", vr[i], comp.boolAddr.len):#NUMBER_OF_BOOLEANS):
            return fmi2Error
        value[i] = comp.boolAddr[vr[i]][].fmi2Boolean
        var tmp:string
        if value[i] > 0:
           tmp = "true"
        else:
           tmp = "false"

        filteredLog(comp, fmi2OK, fmiCall, fmt"fmi2GetBoolean: #b{vr[i]}# = {tmp}".fmi2String)
    
    return fmi2OK

proc fmi2GetString*( comp: ModelInstanceRef; 
                     vr: ptr fmi2ValueReference; 
                     nvr: csize_t;
                     value: ptr fmi2String): fmi2Status =
    #var comp: ptr ModelInstance = cast[ptr ModelInstance](c)
    #echo "fmi2GetString----"
    if invalidState(comp, "fmi2GetString", MASK_fmi2GetString):
        return fmi2Error
    if nvr > 0 and nullPointer(comp, "fmi2GetString", "vr[]", vr):
            return fmi2Error
    if nvr > 0 and nullPointer(comp, "fmi2GetString", "value[]", value):
            return fmi2Error
    if nvr > 0 and comp.isDirtyValues == fmi2True:
        calculateValues(comp)
        comp.isDirtyValues = fmi2False
    #FIXME---------------------
    # var v = cast[ptr UncheckedArray[fmi2ValueReference]](vr)
    # var s = cast[ptr UncheckedArray[fmi2String]](comp.s)
    #var val = cast[ptr UncheckedArray[ptr fmi2String]](value)
    #echo nvr
    for i in 0 ..< nvr:
        #echo vr[i], " ", nvr, " ", comp.stringAddr.len
        #echo comp.stringAddr[0][]
        #echo comp.stringAddr[1][]
        if vrOutOfRange(comp, "fmi2GetString", vr[i], comp.stringAddr.len):
            return fmi2Error
        #echo vr[i]
        # WARNING: to be tested the following
        value[i] = comp.stringAddr[vr[i]][].fmi2String   # unsafeAddr
        var tmp = "fmi2GetString: " & $vr[i] & " = '" & comp.stringAddr[vr[i]][] & "'"
        filteredLog(comp, fmi2OK, fmiCall, tmp.fmi2string)
    #-------------------
    #echo "fmi2GetString - exit"
    return fmi2OK


#[
fmi2Status fmi2GetString (fmi2Component c, const fmi2ValueReference vr[], size_t nvr, fmi2String value[]) {
    int i;
    ModelInstance *comp = (ModelInstance *)c;
    if (invalidState(comp, "fmi2GetString", MASK_fmi2GetString))
        return fmi2Error;
    if (nvr>0 && nullPointer(comp, "fmi2GetString", "vr[]", vr))
            return fmi2Error;
    if (nvr>0 && nullPointer(comp, "fmi2GetString", "value[]", value))
            return fmi2Error;
    if (nvr > 0 && comp->isDirtyValues) {
        calculateValues(comp);
        comp->isDirtyValues = fmi2False;
    }
    for (i=0; i<nvr; i++) {
        if (vrOutOfRange(comp, "fmi2GetString", vr[i], NUMBER_OF_STRINGS))
            return fmi2Error;
        value[i] = comp->s[vr[i]];
        FILTERED_LOG(comp, fmi2OK, LOG_FMI_CALL, "fmi2GetString: #s%u# = '%s'", vr[i], value[i])
    }
    return fmi2OK;
}
]#
{.pop.}