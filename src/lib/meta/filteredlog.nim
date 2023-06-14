import ../defs/[definitions, modelinstance]


# // return fmi2True if logging category is on. Else return fmi2False.
# fmi2Boolean isCategoryLogged(ModelInstanceRef *comp, int categoryIndex) {
#     if (categoryIndex < NUMBER_OF_CATEGORIES
#         && (comp->logCategories[categoryIndex] || comp->logCategories[LOG_ALL])) {
#         return fmi2True;
#     }
#     return fmi2False;
# }


# return fmi2True if logging category is on. Else return fmi2False.

#proc `and`*(bool,)

proc isCategoryLogged*(comp: ModelInstanceRef; categoryIndex: cint): fmi2Boolean =
  if (categoryIndex < NUMBER_OF_CATEGORIES) and
      (comp.logCategories[categoryIndex].bool or comp.logCategories[LOG_ALL].bool):
    return fmi2True
  return fmi2False


#static fmi2String logCategoriesNames[] = {"logAll", "logError", "logFmiCall", "logEvent"};
let # :seq[fmi2String]
  logCategoriesNames* = @["logAll", "logError", "logFmiCall", "logEvent"]

template filteredLog*( instance: ModelInstanceRef, 
                        status: fmi2Status, 
                        categoryIndex: int, 
                        message: fmi2String, 
                        args: varargs[fmi2String]) =
  var newArgs:seq[fmi2String]
  #for i in args:
  #  newArgs &= i.fmi2String
  if status == fmi2Error or status == fmi2Fatal or isCategoryLogged(instance, categoryIndex).bool:
    instance.functions.logger(instance.functions.componentEnvironment, # fmi2ComponentEnvironment
                              instance.instanceName, # fmi2String
                              status, # fmi2Status
                              logCategoriesNames[categoryIndex].fmi2String, # fmi2String
                              message.fmi2String, # fmi2String
                              args ) # FIXME  # varargs[fmi2String]

#[
#define FILTERED_LOG(instance, status, categoryIndex, message, ...) 
if (status == fmi2Error || status == fmi2Fatal || isCategoryLogged(instance, categoryIndex)) \
        instance->functions->logger(instance->functions->componentEnvironment, 
                                    instance->instanceName,
                                    status, \
                                    logCategoriesNames[categoryIndex], 
                                    message, 
                                    ##__VA_ARGS__);
]#