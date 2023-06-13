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

proc createXml(modelName, guid: string, numberOfEventIndicators:int) =
  #var fmiModelDescription = newElement("fmiModelDescription")
  #fmiModelDescription.add newText("some text")
  #fmiModelDescription.add newComment("this is comment")

  #var h = newElement("secondTag")
  #h.add newEntity("some entity")



  var file = newElement("File")
  file.attrs  = {"name" : "inc.c"}.toXmlAttributes
  #let fileFinal = newXmlTree( file, @[], fileAtt)
  let sourceFiles = newXmlTree("SourceFiles", [file])

  let meAtt = { "modelIdentifier" : fmt"{modelName}" }.toXmlAttributes
  var modelExchange = newXmlTree("ModelExchange", [sourceFiles], meAtt)

  var categories = @["logAll", "logError", "logFmiCall", "logEvent"]
  var catChildren:seq[XmlNode] = @[]
  for category in categories:
    var cat = newElement("Category")
    cat.attrs  = {"name" : fmt"{category}"}.toXmlAttributes    
    catChildren.add(cat)
  let logCategories = newXmlTree("LogCategories", catChildren)  



  #var scalarVariable = newElement("ScalarVariable")
  let scalarVariableAttrs = { "name" : "counter",
                           "valueReference" : "0",
                           "description" : "counts the seconds",
                           "causality" : "output",
                           "variability" : "discrete",
                           "initial" : "exact" }.toXmlAttributes
  let initial = newElement("Integer")
  initial.attrs = { "start" : "1"}.toXmlAttributes
  let scalarVariable = newXmlTree("ScalarVariable", [initial], scalarVariableAttrs)  

  var modelVariables = newElement("ModelVariables")
  modelVariables.add scalarVariable

  var modelStructure = newElement("ModelStructure")
  var outputs = newElement("Outputs")
  var unknown = newElement("Unknown")
  unknown.attrs = {"index" : "1" }.toXmlAttributes
  outputs.add unknown
  modelStructure.add outputs

  let att = { "fmiVersion": "2.0", 
              "modelName": fmt"{modelName}",
              "guid": fmt"{guid}",
              "numberOfEventIndicators" : fmt"{numberOfEventIndicators}"}.toXmlAttributes
  let k = newXmlTree("fmiModelDescription", [modelExchange, logCategories, modelVariables, modelStructure], att)
  echo xmlHeader & $k

when isMainModule:
  createXml("inc", "{8c4e810f-3df3-4a00-8276-176fa3c9f008}", 0)