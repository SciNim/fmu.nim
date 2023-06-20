import ../defs/[definitions, modelinstance]




# return fmi2True if logging category is on. Else return fmi2False.

proc isCategoryLogged*(comp: ModelInstanceRef; categoryIndex: cint): fmi2Boolean =
  if (categoryIndex < NUMBER_OF_CATEGORIES) and
      (comp.logCategories[categoryIndex].bool or comp.logCategories[LOG_ALL].bool):
    return fmi2True
  return fmi2False


#static fmi2String logCategoriesNames[] = {"logAll", "logError", "logFmiCall", "logEvent"};
let # :seq[fmi2String]
  logCategoriesNames* = @["logAll", "logError", "logFmiCall", "logEvent"]

template filteredLog*(  instance: ModelInstanceRef, 
                        status: fmi2Status, 
                        categoryIndex: int, 
                        message: fmi2String, 
                        args: varargs[fmi2String]) =
  var newArgs:seq[fmi2String]
  #for i in args:
  #  newArgs &= i.fmi2String
  echo "Entering: filteredLog"
  if status == fmi2Error or status == fmi2Fatal or isCategoryLogged(instance, categoryIndex).bool:
    instance.functions.logger(instance.functions.componentEnvironment, # fmi2ComponentEnvironment
                              instance.instanceName, # fmi2String
                              status, # fmi2Status
                              logCategoriesNames[categoryIndex].fmi2String, # fmi2String
                              message.fmi2String, # fmi2String
                              args ) # FIXME  # varargs[fmi2String]
