import options


template register*( val: float;
                    caus:  Option[Causality]   = none(Causality); #cLocal;
                    varia: Option[Variability] = none(Variability); #vContinuous;
                    ini:   Option[Initial]     = none(Initial); #iUnset;
                    desc:  Option[string]      = none(string);
                    deriva:Option[uint]        = none( uint );
                    strt:  Option[float]       = none(float) ) {.dirty.} =           
  if val.type.name == "float":
    var p = Param(kind: tReal)
    p.name = val.astToStr
    p.idx = nParamsR
    p.addressR = addr(val)
    p.causality = caus
    p.variability = varia
    p.initial = ini
    p.description = desc
    
    p.derivative = deriva
    p.startR = strt

    static: nParamsR += 1
                
    params.add p

#[
template register*( val: int,
                    caus:Causality,
                    varia:Variability,
                    ini:Initial,
                    desc:string) =
  var tmp = ParamI( name: val.astToStr,
                    typ: tInt,
                    idx: paramsI.len,
                    causality:caus,
                    variability:varia,
                    initial:ini,
                    description:desc,
                    initVal: val,
                    address: addr(val) ) #fmt"{typ}"   )   
  paramsI.add(tmp)
  static: nParamsI += 1
]#


template register*( val: float;
                    ca:Causality;# = cLocal;
                    va:Variability;# = vContinuous;
                    i:Initial;# = iUnset;
                    de:string;# = "";
                    deri:float) {.dirty.} = 
  #echo repr derivative
  var derIdx = -1
  for p in params:
    if addr(deri) == p.addressR:
      derIdx = p.idx + 1
  register( val, caus = ca.some, 
            varia = va.some, ini = i.some, desc = de.some, 
            deriva = derIdx.uint.some)
  #[
  var tmp = ParamR( name: val.astToStr,
                    typ: tFloat,
                    idx: paramsR.len,
                    causality:caus,
                    variability:varia,
                    initial:ini,
                    description:desc,
                    start: val,
                    address: addr(val) ) #fmt"{typ}"   )   
  paramsR.add(tmp)                     
  static: nParamsR += 1
  ]#

template register*( val: float;
                    ca:Causality;# = cLocal;
                    va:Variability;# = vContinuous;
                    i:Initial;# = iUnset;
                    de:string) {.dirty.} = # = -1) =                

  register(val, caus = ca.some, varia = va.some, ini = i.some, desc = de.some, strt = val.some )
