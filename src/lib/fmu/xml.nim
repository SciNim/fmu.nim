import std/[xmltree, strformat, strtabs, tables, sequtils]
import options
import ../defs/[definitions, modelinstance, parameters]
import ./model

proc createXml*( myModel: Fmu; typ:fmi2Type = fmi2ModelExchange): string =
  var files:seq[XmlNode] = @[]
  for fname in myModel.sourceFiles:
    var file = newElement("File")
    `attrs=`(file, {"name" : fname}.toXmlAttributes)
    files &= file

  # Model
  var model:XmlNode

  let sourceFiles = newXmlTree("SourceFiles", files) # [file])

  let meAtt = { "modelIdentifier" : fmt"{myModel.id}" }.toXmlAttributes

  case typ
  of fmi2ModelExchange:
    model = newXmlTree("ModelExchange", [sourceFiles], meAtt)
  of fmi2CoSimulation:
    meAtt["canHandleVariableCommunicationStepSize"] = "true"
    model = newXmlTree("CoSimulation", [sourceFiles], meAtt)

  var categories = @["logAll", "logError", "logFmiCall", "logEvent"]  # FIXME
  var catChildren:seq[XmlNode] = @[]
  for category in categories:
    var cat = newElement("Category")
    `attrs=`(cat, {"name" : fmt"{category}"}.toXmlAttributes)
    #cat.attrs  = {"name" : fmt"{category}"}.toXmlAttributes    
    catChildren.add(cat)
  let logCategories = newXmlTree("LogCategories", catChildren)  

  var modelVariables = newElement("ModelVariables")

  var index = 1
  var modelStructureOutputs:seq[int]         = @[] # Ordered list of all outputs
  var modelStructureInitialUnknowns:seq[int] = @[] # Ordered list of all outputs
  var modelStructureDerivatives:seq[int] = @[] # Ordered list of all outputs

  for key, param in myModel.parameters.pairs:
    var scalarVariableAttrs = { "name" : key }.toXmlAttributes

    scalarVariableAttrs["causality"] = case param.causality
      of cParameter:           "parameter"
      of cCalculatedParameter: "calculatedParameter"
      of cInput:               "input"
      of cOutput:              "output"
      of cLocal:               "local"
      of cIndependent:         "independent"
    
    scalarVariableAttrs["variability"] = case param.variability
      of vConstant:   "constant"
      of vFixed:      "fixed"
      of vTunable:    "tunable"
      of vDiscrete:   "discrete"
      of vContinuous: "continuous"

    if param.initial != iUnset:
      scalarVariableAttrs["initial"] = case param.initial
        of iExact:      "exact"
        of iApprox:     "approx"
        of iCalculated: "calculated"
        else: ""

    scalarVariableAttrs["valueReference"] = $param.idx    
    scalarVariableAttrs["description"] = param.description

    if param.causality == cOutput:
      modelStructureOutputs &= index
      if param.initial in {iCalculated, iApprox}: #== iCalculated or param.initial == iApprox:
        modelStructureInitialUnknowns &= index
    
    elif param.causality == cCalculatedParameter:
      modelStructureInitialUnknowns &= index

    var scalarVariable:XmlNode
    if param.kind == tInteger:
      if param.startI.isSome:
        let initial = newElement("Integer")
        `attrs=`(initial, {"start" : $param.startI.get}.toXmlAttributes)
        #initial.attrs = { "start" : $param.startI.get}.toXmlAttributes
        scalarVariable = newXmlTree("ScalarVariable", [initial], scalarVariableAttrs)  
      else:
        #let initial = newElement("Integer")
        #initial.attrs = { "start" : $param.startI.get}.toXmlAttributes
        scalarVariable = newXmlTree("ScalarVariable", [], scalarVariableAttrs)          

    elif param.kind == tReal:
      let initial = newElement("Real")
      var flag = false
      var tmp = initTable[string, string]()
      if param.startR.isSome:
        tmp["start"] = $param.startR.get
        #`attrs=`(initial, {"start" : $param.startR.get}.toXmlAttributes)
        #initial.attrs = { "start" : $param.startR.get}.toXmlAttributes
        flag = true
      
      if param.reinit:
        tmp["reinit"] = "true"
        flag = true

      if param.min.isSome:
        tmp["min"] = $param.min.get
        flag = true

      if param.max.isSome:
        tmp["max"] = $param.max.get
        flag = true

      if param.derivative.isSome:
        tmp["derivative"] = $(param.derivative.get + 1)
        #`attrs=`(initial, {"derivative" : $(param.derivative.get + 1)}.toXmlAttributes)
        #initial.attrs = { "derivative" : $param.derivative.get}.toXmlAttributes
        flag = true
        modelStructureDerivatives &= index
        modelStructureInitialUnknowns &= index  
      
      if flag:
        `attrs=`(initial, tmp.pairs.toSeq.toXmlAttributes)
        scalarVariable = newXmlTree("ScalarVariable", [initial], scalarVariableAttrs) 
      else:
        scalarVariable = newXmlTree("ScalarVariable", [], scalarVariableAttrs)

    elif param.kind == tBoolean:
      if param.startB.isSome:
        let initial = newElement("Boolean")
        `attrs=`(initial, {"start" : $param.startB.get}.toXmlAttributes)
        #initial.attrs = { "start" : $param.startB.get}.toXmlAttributes
        scalarVariable = newXmlTree("ScalarVariable", [initial], scalarVariableAttrs)  
      else:
        #let initial = newElement("Boolean")
        #initial.attrs = { "start" : $param.startI.get}.toXmlAttributes
        scalarVariable = newXmlTree("ScalarVariable", [], scalarVariableAttrs)   

    elif param.kind == tString:
      if param.startS.isSome:
        let initial = newElement("String")
        `attrs=`(initial, {"start" : $param.startS.get}.toXmlAttributes)
        #initial.attrs = { "start" : $param.startS.get}.toXmlAttributes
        scalarVariable = newXmlTree("ScalarVariable", [initial], scalarVariableAttrs)  
      else:
        #let initial = newElement("String")
        #initial.attrs = { "start" : $param.startI.get}.toXmlAttributes
        scalarVariable = newXmlTree("ScalarVariable", [], scalarVariableAttrs) 

    modelVariables.add scalarVariable
    index += 1

  # Model Structure
  var modelStructure = newElement("ModelStructure")
  if modelStructureOutputs.len > 0:
    var outputs = newElement("Outputs")
    for i in modelStructureOutputs:
      var unknown = newElement("Unknown")
      `attrs=`(unknown, {"index" : $i}.toXmlAttributes)
      #unknown.attrs = {"index" : $i }.toXmlAttributes
      outputs.add unknown

    modelStructure.add outputs

  if modelStructureDerivatives.len > 0:
    var derivatives = newElement("Derivatives")  
    for i in modelStructureDerivatives:
      var unknown = newElement("Unknown")
      `attrs=`(unknown, {"index" : $i}.toXmlAttributes)
      #unknown.attrs = {"index" : $i }.toXmlAttributes
      derivatives.add unknown      

    modelStructure.add derivatives      

  if modelStructureInitialUnknowns.len > 0:
    var initialUnknowns = newElement("InitialUnknowns")
    for i in modelStructureInitialUnknowns:
      var unknown = newElement("Unknown")
      `attrs=`(unknown, {"index" : $i}.toXmlAttributes)
      #unknown.attrs = {"index" : $i }.toXmlAttributes
      initialUnknowns.add unknown      

    modelStructure.add initialUnknowns

  let att = { "fmiVersion": "2.0", 
              "modelName": fmt"{myModel.id}",
              "guid": fmt"{myModel.guid}",
              "numberOfEventIndicators" : fmt"{myModel.nEventIndicators}"}.toXmlAttributes
  let k = newXmlTree("fmiModelDescription", [model, logCategories, modelVariables, modelStructure], att)
  #let k = newXmlTree("fmiModelDescription", [modelExchange, logCategories, modelVariables, modelStructure], att)
  #echo repr modelVariables
  return xmlHeader & $k
