#[
La compilación y ejecución de este fichero genera el fichero:

    prueba.nim


]#
import model, options

var fmu = newFMU("dq", "{8c4e810f-3df3-4a00-8276-176fa3c9f000}")

var x = RealParameter( name:"x", 
                       causality:cLocal, 
                       variability:vContinuous,
                       initial:iExact,
                       description: "the only state",
                       ini: some(1.0f64) )
fmu.add(x)
                       

var k = RealParameter( name:"x", 
                       causality:cParameter, 
                       variability:vFixed,
                       initial:iExact,
                       ini: some(1.0f64) )
fmu.add(k)
#echo repr fmu.realParameters

#var x_dot:float
#der(x_dot, x): -k * x

proc derivada*(x, k:float):float =
  -k * x


# template der*(dependant,independant,body:untyped):untyped {.dirty.} =
#   static: numStates += 1
#   register(dependant, cLocal,     vContinuous, iCalculated, "", independant )
#   equations:
#     body

fmu.exportFMU2("salida.fmu")



