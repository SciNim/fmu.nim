import ../defs/[definitions, modelinstance]
## ---------------------------------------------------------------------------
## Private helpers logger
## ---------------------------------------------------------------------------

proc isCategoryLogged*[I:SomeInteger](comp:ModelInstance, categoryIndex:I):bool  =
    ## return fmi2True if logging category is on. Else return fmi2False.
    if categoryIndex < nCategories and ((comp.logCategories[categoryIndex.int] > 0) or (comp.logCategories[LOG_ALL] > 0)):
        return true
    return false

proc logCategoriesNames*[I:SomeInteger](idx: I):fmi2String =
  let categoriesNames: seq[string] = @["logAll", "logError", "logFmiCall", "logEvent"]
  return categoriesNames[idx.int32].fmi2String

proc filteredLog*( comp:ModelInstance, 
                   status:fmi2Status, 
                   categoryIndex:cint, 
                   message:cstring) =
   #var i = cast[ModelInstance](instance)
   if status == fmi2Error or
      status == fmi2Fatal or
      isCategoryLogged(comp, categoryIndex):
      #FIXME
      discard
      #let log = comp.functions.logger

      #log( comp.functions.componentEnvironment, comp.instanceName,
      #     status, logCategoriesNames(categoryIndex), message.fmi2String )
