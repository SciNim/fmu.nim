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

# modelName = "van der Pol oscillator"

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

vdp.addFloat("mu").setParameter.setFixed.setExact
   .setDescription("the only state")  
   .setInitial(1.0)


model(vdp):
  proc getReal*(comp: FmuRef;
                key:string):float =
    case key
    of "x0": comp["x0"].valueR
    of "der(x0)": comp["x1"].valueR
    of "x1": comp["x1"].valueR
    of "der(x1)": comp["mu"].valueR * ((1.0-comp["x0"].valueR*comp["x0"].valueR)*comp["x1"].valueR) - comp["x0"].valueR
    of "mu": comp["mu"].valueR
    else: 0.0


when defined(fmu):
  vdp.exportFmu("vanDerPol.fmu")

