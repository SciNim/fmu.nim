# https://github.com/qtronic/fmusdk/blob/master/fmu20/src/models/vanDerPol/vanDerPol.c
#[
/* ---------------------------------------------------------------------------*
 * Sample implementation of an FMU - the Van der Pol oscillator.
 * See http://en.wikipedia.org/wiki/Van_der_Pol_oscillator
 *  
 *   der(x0) = x1
 *   der(x1) = mu * ((1 - x0 ^ 2) * x1) - x0;
 *
 *   start values: x0=2, x1=0, mue=1
 * Copyright QTronic GmbH. All rights reserved.
 * ---------------------------------------------------------------------------*/
]#
import fmu#sdk
import std/[tables, options]

var vdp = FmuRef( id:   "vanDerPol",
                 guid: "{8c4e810f-3da3-4a00-8276-176fa3c9f000}" )

vdp.sourceFiles = @[] #"data/inc.c"]
vdp.docFiles    = @[] #"data/index.html"]
#vdp.icon        = "data/model.png"

vdp.addFloat("x0").setLocal.setContinuous.setExact
   .setDescription("the only state")  
   .setInitial(2.0)
   .setState()  # Set as state variable

vdp.addFloat("der(x0)").setLocal.setContinuous.setCalculated
   .setDescription("the only state")
   .derives(vdp["x0"])
   #.setInitial(1.0)

vdp.addFloat("x1").setLocal.setContinuous.setExact
   .setDescription("the only state")  
   .setInitial(0.0)
   .setState()  # Set as state variable

vdp.addFloat("der(x1)").setLocal.setContinuous.setCalculated
   .setDescription("the only state")  
   .derives(vdp["x1"])
   #.setInitial(1.0)

vdp.addFloat("mu").setLocal.setContinuous.setExact
   .setDescription("the only state")  
   .setInitial(1.0)


model(vdp):
  proc getReal*(comp: FmuRef;
                vr:fmi2ValueReference):float =
    # FIXME: it should depend on the name, not in vr
    if vr == 0:   # 0:"x0"
      return comp["x0"].valueR
    elif vr == 1: # 1: "der(x0)"
      return comp["x1"].valueR
    elif vr == 2: # 2: "x1"
      return comp["x1"].valueR
    elif vr == 3: # 3: "der(x1)"
      return comp["mu"].valueR * ((1.0-comp["x0"].valueR*comp["x0"].valueR)*comp["x1"].valueR) - comp["x0"].valueR
    elif vr == 4: # 4: "mu"
      return comp["mu"].valueR
    else:
      return 0.0

when defined(fmu):
  vdp.exportFmu("vanDerPol.fmu")
