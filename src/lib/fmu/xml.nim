import std/[xmltree, strformat, strtabs]
import options
import ../defs/[modelinstance, parameters]
import ./model

proc createXml*( myModel: Fmu): string =
  
  var file = newElement("File")
  `attrs=`(file, {"name" : "inc.c"}.toXmlAttributes)
  #file.attrs  = {"name" : "inc.c"}.toXmlAttributes  # FIXME: I don't know why this fails.
  #let fileFinal = newXmlTree( file, @[], fileAtt)
  let sourceFiles = newXmlTree("SourceFiles", [file])

  let meAtt = { "modelIdentifier" : fmt"{myModel.id}" }.toXmlAttributes
  var modelExchange = newXmlTree("ModelExchange", [sourceFiles], meAtt)

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

    #[
    ll continuous-time states and all state derivatives (defined with element
<Derivatives> from <ModelStructure>) with initial="approx" or
"calculated" [if a Co-Simulation FMU does not define the
<Derivatives> element, (3) cannot be present.
    ]#





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
      if param.startR.isSome:
        `attrs=`(initial, {"start" : $param.startR.get}.toXmlAttributes)
        #initial.attrs = { "start" : $param.startR.get}.toXmlAttributes
        flag = true
      
      if param.derivative.isSome:
        `attrs=`(initial, {"derivative" : $param.derivative.get}.toXmlAttributes)
        #initial.attrs = { "derivative" : $param.derivative.get}.toXmlAttributes
        flag = true
        modelStructureDerivatives &= index
        modelStructureInitialUnknowns &= index     

      if flag:
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
  let k = newXmlTree("fmiModelDescription", [modelExchange, logCategories, modelVariables, modelStructure], att)
  #let k = newXmlTree("fmiModelDescription", [modelExchange, logCategories, modelVariables, modelStructure], att)
  #echo repr modelVariables
  return xmlHeader & $k


#[
<?xml version="1.0" encoding="UTF-8" ?>
<fmiModelDescription guid="{8c4e810f-3df3-4a00-8276-176fa3c9f008}" numberOfEventIndicators="0" modelName="inc" fmiVersion="2.0">


  <ModelVariables>
    <ScalarVariable variability="discrete" valueReference="0" description="counts the seconds" causality="output" initial="exact" name="counter">
      <Integer start="1" />
    </ScalarVariable>
  </ModelVariables>
  <ModelStructure>
    <Outputs>
      <Unknown index="1" />
    </Outputs>
  </ModelStructure>
</fmiModelDescription>

]#