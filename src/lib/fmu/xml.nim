#https://rosettacode.org/wiki/XML/Output#Nim
#[
<?xml version="1.0" encoding="ISO-8859-1"?>
<fmiModelDescription
  fmiVersion="2.0"
  modelName="inc"
  guid="{8c4e810f-3df3-4a00-8276-176fa3c9f008}"
  numberOfEventIndicators="0">

<ModelExchange
  modelIdentifier="inc">
  <SourceFiles>
    <File name="inc.c"/>
  </SourceFiles>
</ModelExchange>

<LogCategories>
  <Category name="logAll"/>
  <Category name="logError"/>
  <Category name="logFmiCall"/>
  <Category name="logEvent"/>
</LogCategories>

<ModelVariables>
  <ScalarVariable name="counter" valueReference="0" description="counts the seconds"
                  causality="output" variability="discrete" initial="exact">
     <Integer start="1"/>
  </ScalarVariable>
</ModelVariables>

<ModelStructure>
  <Outputs>
    <Unknown index="1" />
  </Outputs>
</ModelStructure>

</fmiModelDescription>


]#

import xmltree
import strformat
import std/strtabs
import options
import ../defs/[modelinstance, parameters]

proc createXml*(myModel: ModelInstanceRef; numberOfEventIndicators:int):string =
  var file = newElement("File")
  file.attrs  = {"name" : "inc.c"}.toXmlAttributes
  #let fileFinal = newXmlTree( file, @[], fileAtt)
  let sourceFiles = newXmlTree("SourceFiles", [file])

  let meAtt = { "modelIdentifier" : fmt"{myModel.id}" }.toXmlAttributes
  var modelExchange = newXmlTree("ModelExchange", [sourceFiles], meAtt)

  var categories = @["logAll", "logError", "logFmiCall", "logEvent"]  # FIXME
  var catChildren:seq[XmlNode] = @[]
  for category in categories:
    var cat = newElement("Category")
    cat.attrs  = {"name" : fmt"{category}"}.toXmlAttributes    
    catChildren.add(cat)
  let logCategories = newXmlTree("LogCategories", catChildren)  

  var modelVariables = newElement("ModelVariables")
  for param in myModel.params:
    var scalarVariableAttrs = { "name" : "counter" }.toXmlAttributes

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

    scalarVariableAttrs["initial"] = case param.initial
      of iExact:      "exact"
      of iApprox:     "approx"
      of iCalculated: "calculated"
      else: ""

    scalarVariableAttrs["valueReference"] = $param.idx    
    scalarVariableAttrs["description"] = param.description
    var scalarVariable:XmlNode
    if param.kind == tInteger:
      if param.startI.isSome:
        let initial = newElement("Integer")
        initial.attrs = { "start" : $param.startI.get}.toXmlAttributes
        scalarVariable = newXmlTree("ScalarVariable", [initial], scalarVariableAttrs)  
      else:
        let initial = newElement("Integer")
        #initial.attrs = { "start" : $param.startI.get}.toXmlAttributes
        scalarVariable = newXmlTree("ScalarVariable", [], scalarVariableAttrs)          

    modelVariables = newElement("ModelVariables")

    modelVariables.add scalarVariable

  var modelStructure = newElement("ModelStructure")
  var outputs = newElement("Outputs")
  var unknown = newElement("Unknown")
  unknown.attrs = {"index" : "1" }.toXmlAttributes
  outputs.add unknown
  modelStructure.add outputs

  let att = { "fmiVersion": "2.0", 
              "modelName": fmt"{myModel.id}",
              "guid": fmt"{myModel.guid}",
              "numberOfEventIndicators" : fmt"{numberOfEventIndicators}"}.toXmlAttributes
  let k = newXmlTree("fmiModelDescription", [modelExchange, logCategories, modelVariables, modelStructure], att)
  return xmlHeader & $k


#[
<?xml version="1.0" encoding="UTF-8" ?>
<fmiModelDescription guid="{8c4e810f-3df3-4a00-8276-176fa3c9f008}" numberOfEventIndicators="0" modelName="inc" fmiVersion="2.0">
  <ModelExchange modelIdentifier="inc">
    <SourceFiles>
      <File name="inc.c" />
    </SourceFiles>
  </ModelExchange>
  <LogCategories>
    <Category name="logAll" />
    <Category name="logError" />
    <Category name="logFmiCall" />
    <Category name="logEvent" />
  </LogCategories>
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