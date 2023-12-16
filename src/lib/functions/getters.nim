## ---------------------------------------------------------------------------
## FMI functions: logging control, setters and getters for Real, Integer,
## Boolean, String
## ---------------------------------------------------------------------------
import strformat
import ../defs/[definitions, modelinstance, masks]
import helpers
import ../meta/filteredlog


{.push exportc: "$1",dynlib,cdecl.}

proc fmi2GetReal*(comp: FmuRef; 
                  vr: ptr fmi2ValueReference; 
                  nvr: csize_t;
                  value: ptr fmi2Real): fmi2Status =
    if invalidState(comp, "fmi2GetReal", MASK_fmi2GetReal):
        return fmi2Error
    
    if nvr > 0 and nullPointer(comp, "fmi2GetReal", "vr[]", vr):
        return fmi2Error
    
    if nvr > 0 and nullPointer(comp, "fmi2GetReal", "value[]", value):
        return fmi2Error

    if nvr > 0 and comp.isDirtyValues == fmi2True:
        when declared(calculateValues):
          calculateValues(comp)   # <---------------
        comp.isDirtyValues = fmi2False

    when declared(getReal):
      if comp.nFloats > 0:  # when: no puede evaluar en tiempo de compilación
        for i in 0 ..< nvr:
            if vrOutOfRange(comp, "fmi2GetReal", vr[i], comp.nFloats):
                return fmi2Error

            var key = comp.reals[vr[i]]
            value[i] = getReal(comp, key).fmi2Real # <--------to be implemented by the includer of this file
            var tmp = "fmi2GetReal: " & key & "= " & $(value[i].float)
            filteredLog(comp, fmi2OK, fmiCall, tmp.fmi2String )    
   
    return fmi2OK



proc fmi2GetInteger*( comp: FmuRef; 
                      vr: ptr fmi2ValueReference; 
                      nvr: csize_t;
                      value: ptr fmi2Integer): fmi2Status  =
    ## returns an integer value

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
        when declared(calculateValues):
          calculateValues(comp) # user declared
        comp.isDirtyValues = fmi2False


    # iterate over all the values required by `vr`

    for i in 0 ..< nvr: 
        if vrOutOfRange(comp, "fmi2GetInteger", vr[i], comp.nIntegers):#NUMBER_OF_INTEGERS):
            return fmi2Error

        # read the value from memory address (vr[i] is the position; `[]`: memory content)
        
        value[i] = comp.parameters[comp.integers[vr[i]]].valueI.fmi2Integer

        filteredLog(comp, fmi2OK, fmiCall, fmt"fmi2GetInteger: #i{vr[i]}# = {value[i]}".fmi2String )
    
    return fmi2OK

proc fmi2GetBoolean*(comp: FmuRef; vr: ptr fmi2ValueReference; nvr: csize_t;
                    value: ptr fmi2Boolean): fmi2Status  =
    #var comp: ptr ModelInstance = cast[ptr ModelInstance](c)
    if invalidState(comp, "fmi2GetBoolean", MASK_fmi2GetBoolean):
        return fmi2Error
    if nvr > 0 and nullPointer(comp, "fmi2GetBoolean", "vr[]", vr):
            return fmi2Error
    if nvr > 0 and nullPointer(comp, "fmi2GetBoolean", "value[]", value):
            return fmi2Error
    if nvr > 0 and comp.isDirtyValues == fmi2True:
        when declared(calculateValues):
          calculateValues(comp)
        comp.isDirtyValues = fmi2False
    
    for i in 0 ..< nvr:
        if vrOutOfRange(comp, "fmi2GetBoolean", vr[i], comp.nBooleans):#NUMBER_OF_BOOLEANS):
            return fmi2Error
        value[i] = comp[comp.booleans[vr[i]]].valueB.fmi2Boolean
        #value[i] = comp.getBoolean(vr[i]).fmi2Boolean
        var tmp:string
        if value[i] > 0:
           tmp = "true"
        else:
           tmp = "false"

        filteredLog(comp, fmi2OK, fmiCall, fmt"fmi2GetBoolean: #b{vr[i]}# = {tmp}".fmi2String)
    
    return fmi2OK

proc fmi2GetString*( comp: FmuRef; 
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
        when declared(calculateValues):
          calculateValues(comp)
        comp.isDirtyValues = fmi2False

    # var v = cast[ptr UncheckedArray[fmi2ValueReference]](vr)
    # var s = cast[ptr UncheckedArray[fmi2String]](comp.s)
    #var val = cast[ptr UncheckedArray[ptr fmi2String]](value)

    for i in 0 ..< nvr:
        if vrOutOfRange(comp, "fmi2GetString", vr[i], comp.nStrings):
            return fmi2Error

        
        value[i] = comp.parameters[comp.strings[vr[i]]].valueS.fmi2String
        var tmp = "fmi2GetString: " & $vr[i] & " = '" & $value[i] & "'"
        filteredLog(comp, fmi2OK, fmiCall, tmp.fmi2string)

    return fmi2OK

{.pop.}