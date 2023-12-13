#import model
#import definitions
#import fmi2TypesPlatform, fmi2type, fmi2callbackfunctions, modelstate, fmi2eventinfo,
#import logger
import strformat


# https://forum.nim-lang.org/t/7182#45378
# https://forum.nim-lang.org/t/6980#43777mf


##  Destruction of FMU instances and setting debug status
{.push exportc:"$1",dynlib,cdecl.}
# https://nim-lang.org/docs/destructors.html
proc fmi2FreeInstance*(comp: FmuRef) =
    ##[
    Disposes the given instance, unloads the loaded model, and frees all the allocated memory
    and other resources that have been allocated by the functions of the FMU interface. If a null
    pointer is provided for “c”, the function call is ignored (does not have an effect).
    ]##
    #echo "ENTERING: fmi2FreeInstance"
    `=destroy`(comp[])
    GC_fullCollect()


{.pop.}
