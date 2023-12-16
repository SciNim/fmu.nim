#[
Based on: https://github.com/qtronic/fmusdk/blob/master/fmu20/src/models/dq/dq.c

Sample implementation of an FMU - the Dahlquist test equation.

 der(x) = - k * x and x(0) = 1.
 Analytical solution: x(t) = exp(-k*t)

]#
import fmu
import std/[tables, options]

var dq = FmuRef( id:   "dq",
                 guid: "{8c4e810f-3df3-4a00-8276-176fa3c9f000}" )

dq.sourceFiles = @[] #"data/inc.c"]
dq.docFiles    = @[] #"data/index.html"]
#dq.icon        = "data/model.png"


dq.addFloat("x").setLocal.setContinuous.setExact
  .setDescription("the only state")  
  .setInitial(1.0)
  .setState()  # Set as state variable

dq.addFloat("der(x)").setLocal.setContinuous.setCalculated
  .setDescription("time derivative of x")
  .derives(dq["x"])  # Set as derivative of x

dq.addFloat("k").setParameter.setFixed.setExact
  .setDescription("")  
  .setInitial(1.0)



model(dq):
  proc getReal*(comp: FmuRef;
                key:string):float =
    case key
    of "x": comp["x"].valueR
    of "k": comp["k"].valueR
    of "der(x)": -(comp["k"].valueR * comp["x"].valueR)
    else: 0.0

when defined(fmu):
  dq.exportFmu("dq.fmu")
