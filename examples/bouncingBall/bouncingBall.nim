#[
Based on: https://github.com/qtronic/fmusdk/blob/master/fmu20/src/models/vanDerPol/vanDerPol.c

Bouncing ball: this demonstrates the use of state events and reinit of states.
Equations:
 
  der(h) = v;
  der(v) = -g;
when h<0 then v := -e * v;

where:
  h      height [m], used as state, start = 1
  v      velocity of ball [m/s], used as state
  der(h) velocity of ball [m/s]
  der(v) acceleration of ball [m/s2]
  g      acceleration of gravity [m/s2], a parameter, start = 9.81
  e      a dimensionless parameter, start = 0.7
]#
import fmu
import std/[tables, options]

var bb = FmuRef( id:   "bouncingBall",
                 guid: "{8c4e810f-3df3-4a00-8276-176fa3c9f003}" )

bb.sourceFiles = @[] #"data/inc.c"]
bb.docFiles    = @[] #"data/index.html"]
#vdp.icon        = "data/model.png"

bb.addFloat("h").setLocal.setContinuous.setExact
  .setDescription("height, used as state")  
  .setInitial(1.0)
  .setState()  # Set as state variable

bb.addFloat("der(h)").setLocal.setContinuous.setCalculated
  .setDescription("velocity of ball")
  .derives(bb["h"])


bb.addFloat("v").setLocal.setContinuous.setExact
  .setDescription("velocity of ball, used as state")  
  .setInitial(0.0)
  .setReinit
  .setState()


bb.addFloat("der(v)").setLocal.setContinuous.setCalculated
   .setDescription("acceleration of ball")  
   .derives(bb["v"])

bb.addFloat("g").setParameter.setFixed.setExact
   .setDescription("acceleration of gravity")  
   .setInitial(9.81)

bb.addFloat("e").setParameter.setTunable.setExact
   .setDescription("dimensionless parameter")  
   .setInitial( 0.7 )
   .setMin( 0.5 )
   .setMax( 1.0 )

bb.isPositive["z=0"] = true

model(bb):
  const
    # offset for event indicator, adds hysteresis 
    # and prevents z=0 at restart
    EPS_INDICATORS = 1e-14

  
  var
    prevV:float   # previous value of r(v_)


  proc calculateValues*(comp: FmuRef) = 
    ## calculate the inc of the FMU (Functional Mock-up Unit) variables 
    ## at a specific time step during simulation.
    if comp.state == modelInitializationMode:
        # set first time event
        comp["der(v)"] = comp["g"] * (-1.0)
        comp.isPositive["z=0"] = comp["h"] > 0 
          
  proc getReal*(comp: FmuRef;
                key:string):float =
    case key
    of "h":      comp["h"].valueR
    of "der(h)": comp["v"].valueR
    of "v":      comp["v"].valueR
    of "der(v)": comp["der(v)"].valueR
    of "g":      comp["g"].valueR
    of "e":      comp["e"].valueR
    else:        0.0

  proc eventUpdate*( comp: FmuRef;
                     timeEvent:bool ) =
    #echo "eventUpdate: Entering"
    comp.eventInfo.newDiscreteStatesNeeded           = fmi2False
    comp.eventInfo.terminateSimulation               = fmi2False
    comp.eventInfo.nominalsOfContinuousStatesChanged = fmi2False
    comp.eventInfo.valuesOfContinuousStatesChanged   = fmi2False
    comp.eventInfo.nextEventTimeDefined              = fmi2False

    if comp.isNewEventIteration.bool:
      prevV = comp["v"].valueR

    comp.isPositive["z=0"] = comp["h"] > 0  # positive while h>0
    if comp.isPositive["z=0"] == false:    # What to do when h <= 0
      var tempV:float = -comp["e"].valueR * prevV
      #echo "ok1"
      if comp["v"].valueR != tempV:
        #echo "ok2"
        comp["h"] = 0.0
        #echo "ok3"        
        comp["v"] = tempV
        #echo "ok4"        
        comp.eventInfo.valuesOfContinuousStatesChanged = fmi2True
        #echo "ok5"
      # avoid fall-through effect. The ball will not jump high 
      # enough, so v and der_v is set to 0 at this surface impact.
      if comp["v"].valueR < 1e-3:
        #echo "ok6"        
        comp["v"] = 0
        comp["der(v)"] = 0  # turn off gravity.
        #echo "ok7"        
    #echo "eventUpdate: Ending"


  proc getEventIndicator*(comp:FmuRef; z:int):float =
    if z == 0:
      var tmp = if comp.isPositive["z=0"]:
                  EPS_INDICATORS
                else:
                  -EPS_INDICATORS

      return comp["h"].valueR + tmp
    else:
      return 0.0


when defined(fmu):
  bb.exportFmu("bouncingBall.fmu")
