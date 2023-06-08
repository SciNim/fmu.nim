import ../defs/[definitions, modelinstance]


# // return fmi2True if logging category is on. Else return fmi2False.
# fmi2Boolean isCategoryLogged(ModelInstance *comp, int categoryIndex) {
#     if (categoryIndex < NUMBER_OF_CATEGORIES
#         && (comp->logCategories[categoryIndex] || comp->logCategories[LOG_ALL])) {
#         return fmi2True;
#     }
#     return fmi2False;
# }


# return fmi2True if logging category is on. Else return fmi2False.

#proc `and`*(bool,)

proc isCategoryLogged*(comp: ModelInstance; categoryIndex: cint): fmi2Boolean =
  if (categoryIndex < NUMBER_OF_CATEGORIES) and
      (comp.logCategories[categoryIndex].bool or comp.logCategories[LOG_ALL].bool):
    return fmi2True
  return fmi2False


#static fmi2String logCategoriesNames[] = {"logAll", "logError", "logFmiCall", "logEvent"};
let # :seq[fmi2String]
  logCategoriesNames* = @["logAll", "logError", "logFmiCall", "logEvent"]

template filteredLog*( instance: ModelInstance, 
                        status: fmi2Status, 
                        categoryIndex: int, 
                        message: string, 
                        args: varargs[string]): untyped =
  var newArgs:seq[fmi2String]
  for i in args:
    newArgs &= i.fmi2String
  if status == fmi2Error or status == fmi2Fatal or isCategoryLogged(instance, categoryIndex).bool:
    instance.functions.logger(instance.functions.componentEnvironment, 
                              instance.instanceName, 
                              status,
                              logCategoriesNames[categoryIndex].fmi2String, 
                              message.fmi2String)#, newArgs) # FIXME

