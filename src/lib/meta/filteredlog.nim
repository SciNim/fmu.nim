import ../defs/[definitions, modelinstance]






proc isCategoryLogged*(comp: FmuRef; categoryIndex: LoggingCategories): bool =
  # return fmi2True if logging category is on. Else return fmi2False.
  # if categoryIndex > LoggingCategories.high.int:
  #   return false
  if all in comp.logCategories:
    return true
  elif categoryIndex.LoggingCategories in comp.logCategories:
    return true
  return false


template filteredLog*(  instance: FmuRef, 
                        status: fmi2Status, 
                        categoryIndex: LoggingCategories, 
                        message: fmi2String, 
                        args: varargs[fmi2String]) =
  # not part of the standard

  # error and fatal is always logged
  # then it depends on the categories to be logged
  if status == fmi2Error or status == fmi2Fatal or isCategoryLogged(instance, categoryIndex).bool:
    instance.functions.logger(instance.functions.componentEnvironment, # fmi2ComponentEnvironment
                              instance.instanceName, # fmi2String
                              status, # fmi2Status
                              #logCategoriesNames[categoryIndex].fmi2String, # fmi2String
                              ($categoryIndex).fmi2String,
                              message,
                              args ) # FIXME  # varargs[fmi2String]
