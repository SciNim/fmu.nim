import ../defs/[definitions, modelinstance]
## ---------------------------------------------------------------------------
## Private helpers logger
## ---------------------------------------------------------------------------

proc isCategoryLogged*[I:SomeInteger]( comp:ModelInstanceRef, 
                                       categoryIndex:I): bool  =
    ## return fmi2True if logging category is on. Else return fmi2False.
    if categoryIndex < nCategories and ((comp.logCategories[categoryIndex.int] > 0) or (comp.logCategories[LOG_ALL] > 0)):
        return true
    return false

proc logCategoriesNames*[I:SomeInteger](idx: I):fmi2String =
  let categoriesNames: seq[string] = @["logAll", "logError", "logFmiCall", "logEvent"]
  return categoriesNames[idx.int32].fmi2String


proc fmi2SetDebugLogging*( comp:ModelInstanceRef;
                           loggingOn: fmi2Boolean;
                           nCategories: csize_t;
                           categories: cstringArray):fmi2Status =  #categories: ptr fmi2String
    ##[
    The function controls debug logging that is output via the logger function callback.

    If loggingOn = fmi2True, debug logging is enabled, otherwise it is switched off.

    If loggingOn = fmi2True and nCategories = 0, then all debug messages shall be
    output.

    If loggingOn=fmi2True and nCategories > 0, then only debug messages according to
    the categories argument shall be output. Vector categories has
    nCategories elements. The allowed values of categories are defined by the modeling
    environment that generated the FMU. Depending on the generating modeling environment,
    none, some or all allowed values for categories for this FMU are defined in the
    modelDescription.xml file via element “fmiModelDescription.LogCategories”, see
    section 2.2.4.
    ]##

    if comp.invalidState("fmi2SetDebugLogging", MASK_fmi2SetDebugLogging):
        return fmi2Error

    # set the "loggingOn" status
    comp.loggingOn = loggingOn
    filteredLog(comp, fmi2OK, fmiCall, "fmi2SetDebugLogging".fmi2String)

    # reset all categories
    comp.logCategories = {} # remove all categories

    if nCategories == 0:
        # no category specified, set all categories to have loggingOn value
        for i in LoggingCategories:
            comp.logCategories.incl( i )

    else:
        # set specific categories on
        var flagFound = false
        for i in 0 ..< nCategories:
            for j in LoggingCategories:
                if categories[i] == $j:
                    comp.logCategories.incl(j)
                    flagFound = true
            if not flagFound:
                comp.functions.logger( 
                    comp.componentEnvironment, 
                    comp.instanceName, 
                    fmi2Warning,
                    ($error).fmi2String, 
                    fmt"logging category '{categories[i]}' is not supported by model".fmi2String )
            
            flagFound = false

    return fmi2OK