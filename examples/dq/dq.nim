#[
Sample implementation of an FMU - the Dahlquist test equation.

 der(x) = - k * x and x(0) = 1.
 Analytical solution: x(t) = exp(-k*t).
 Copyright QTronic GmbH. All rights reserved.


The compilation of this file generates the creator of the fmu. So the following
line will create completely a `inc.fmu` in this case:

    $ nim c -r dq 

To test `inc.fmu`, the following will test it for 10sec using 0.1sec steps:

    $ fmusdk-master/fmu20/bin/fmusim_me inc.fmu 10 0.1


Número de estados:

    causality="local" variability="continuous" initial="exact"
]#
import fmusdk

fmu( "dq", "{8c4e810f-3df3-4a00-8276-176fa3c9f000}"):
  var x:float = 1.0
  register( x, cLocal, vContinuous, iExact, "the only state" )
  
  var k:float = 1.0
  register(k, cParameter, vFixed, iExact, "" )  
  
  var x_dot:float
  der(x_dot, x): -k * x


