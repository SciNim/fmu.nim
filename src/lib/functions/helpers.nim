
## ---------------------------------------------------------------------------
## Private helpers used below to validate function arguments
## ---------------------------------------------------------------------------
#import modelinstancetype, modelstate, logger, status, fmi2TypesPlatform, fmi2callbackfunctions
import strformat
import ../defs/[definitions, modelinstance]
import ../meta/filteredlog

proc invalidNumber*( comp:ModelInstanceRef; 
                     f, arg:string;
                     n:csize_t; nExpected:int):bool  =
    if n.int != nExpected:
        comp.state = modelError
        filteredLog(comp, fmi2Error, LOG_ERROR, 
                    fmt"{f}: Invalid argument {arg} = {n}. Expected {nExpected}.".fmi2String)
        return true
    return false

proc invalidState*( comp:ModelInstanceRef, f:string,
                    statesExpected:ModelState):bool  =
    # FIXME
    #if comp.isNil:
    #    return true
    
    #echo "invalidState: ", repr comp
    if not (comp.state.int > 0 and  statesExpected.int > 0):
        comp.state = modelError
        #echo $f
        filteredLog(comp, fmi2Error, LOG_ERROR, fmt"{$f}: Illegal call sequence.".fmi2String )
        return true

    return false

proc nullPointer*(comp:ModelInstanceRef, f:string, arg:string, p:pointer):bool =
    if p.isNil:
        comp.state = modelError
        filteredLog(comp, fmi2Error, LOG_ERROR, fmt"{f}: Invalid argument {arg} = NULL.".fmi2String)
        return true

    return false

proc vrOutOfRange*(comp:ModelInstanceRef, f:string,  vr:fmi2ValueReference, `end`:int):bool =
    if vr.int >= `end`:
        filteredLog(comp, fmi2Error, LOG_ERROR, fmt"{f}: Illegal value reference {vr}.".fmi2String)
        comp.state = modelError
        return true

    return false

proc unsupportedFunction*(comp:ModelInstanceRef; fName: string; statesExpected: ModelState): fmi2Status =
    #var comp: ptr ModelInstanceRef = cast[ptr ModelInstanceRef](c)
    #var log:fmi2CallbackLogger = comp.functions.logger
    if invalidState(comp, fName, statesExpected):
        return fmi2Error
    filteredLog(comp, fmi2OK, LOG_FMI_CALL, fName.fmi2String)
    filteredLog(comp, fmi2Error, LOG_ERROR, fmt"{fName}: Function not implemented.".fmi2String)
    return fmi2Error


# -----------------------------------------------------------------


proc `[]=`*[N:SomeInteger](this:ptr fmi2Real, n:N, val:fmi2Real) =
    var this = cast[ptr UncheckedArray[fmi2Real]](this)
    this[n.int] = val

proc `[]`*[T:SomeInteger](vr:ptr fmi2ValueReference, n:T):fmi2ValueReference =
    var v = cast[ptr UncheckedArray[fmi2ValueReference]](vr) #fmi2ValueReference]
    v[n.uint64] #= cast[typeof(vr_tmp)](realloc(vr, nvr.int * sizeof(fmi2ValueReference)))

proc `[]`*(vr:ptr fmi2Real, n:uint64):fmi2Real =
    var v = cast[ptr UncheckedArray[fmi2Real]](vr) #fmi2ValueReference]
    v[n] #= cast[typeof(vr_tmp)](realloc(vr, nvr.int * sizeof(fmi2ValueReference)))

# proc `[]=`*[I:SomeInteger](vr:ptr fmi2Real, n:I, val:fmi2Real) =
#     var vr = cast[ptr UncheckedArray[fmi2Real]](vr)
#     vr[n] = val

proc `[]`*(vr:ptr fmi2Integer, n:uint64):fmi2Integer =
    var v = cast[ptr UncheckedArray[fmi2Integer]](vr) #fmi2ValueReference]
    v[n] #= cast[typeof(vr_tmp)](realloc(vr, nvr.int * sizeof(fmi2ValueReference)))

proc `[]=`*(vr:ptr fmi2Integer, n:uint64, val:fmi2Integer) =
    var vr = cast[ptr UncheckedArray[fmi2Integer]](vr)
    vr[n] = val

proc `[]=`*(vr:ptr fmi2String, n:uint64, val:fmi2String) =
    var vr = cast[ptr UncheckedArray[fmi2String]](vr)
    vr[n] = val


proc `[]`*(vr:ptr fmi2String, n:uint64):fmi2String =
    var v = cast[ptr UncheckedArray[fmi2String]](vr) #fmi2ValueReference]
    v[n] #= cast[typeof(vr_tmp)](realloc(vr, nvr.int * sizeof(fmi2ValueReference)))