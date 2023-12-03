import lib/defs/[definitions, masks, modelinstance, parameters]
export definitions, masks, modelinstance, parameters

import lib/fmu/[model]
export model

template export*( m:Fmu#,
                  #body:untyped
                  ) {.dirty.} =
    ## organize the code, keeping the required includes at the end

    # {.push exportc, dynlib.}

    # body

    # {.pop.}

    include lib/functions/modelexchange
    include lib/functions/cosimulation
    include lib/functions/common
    include lib/functions/setters
    include lib/functions/instantiate    
    include lib/functions/freeinstance
    include lib/functions/debuglogging    
    include lib/functions/getters
    include lib/functions/enquire
