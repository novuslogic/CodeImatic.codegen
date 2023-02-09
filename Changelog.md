09/02/2023

* All StaticWebSite Samples have been moved to StaticWebsite folder in samples
* Fixed folder creation when usinf projectitem folder in project file

23/01/2023

* Upgraded NovuscodeLibrary Delphi 11 v.1.0
* Updated Codeimatic.codegen for Delphi 11.2
* Rwname SysTags.dll plugin to CodeImatic.codegen.Tags.Sys.dll
* Rename CodeDocsTags.dll plugin to CodeImatic.codegen.Tags.CodeDocs.dll
* Rename DBTags.dll plugin to CodeImatic.codegen.Tags.DB.Dll
* Ranmed JSONTags.dll plugin to CodeImatic.codegen.Tags.JSON.dll 
* Rename XMLTags.dll plugin to CodeImatic.codegen.Tags.XML.dll
* Rename CodeDocsProcessor.dll plugin to CodeImatic.codegen.Processor.CodeDocs.dll
* Rename SQLDir.dll plugin to CodeImatic.codegen.DataProcessor.SQLDir.dll
* Rename WebProcessor.dll plugin to CodeImatic.codegen.Processor.Web.dll
* Rename WebServer.dll plugin to CodeImatic.codegen.WebServer.dll
* Rename SystemExt.dll plugin to CodeImatic.codegen.Pascal.SystemExt.dll

10/07/2022

* Upgraded to Pre multi Plantform NovuscodeLibrary Delphi 11 v.1.0

09/07/2022

* Refactored for upgraded Novusplugin unit in NovuscodeLibrary

20/02/2022

* Upgraded TokenProcessor with tNovusTokenProcessor

24/01/2022

* Updated Codeimatic.codegen for Delphi 11

29/12/2021

* Removed FastMM5 unit

08/06/2021

* Renamed TScriptEnginePlugin to TPascalScriptPlugin

19/05/2021

* Renamed tScriptEngine class to tPascalScriptEngine
  
28/03/2021

* Changed function TVariables.AddVariableObject(AVariableName: String; aObject: Tobject; aIsDestroy: boolean): String;
* Updated for NovusGUID class for NovuscodeLibrary

26/01/2021

* Updated for new changes in NovuscodeLibrary
* Refectored TNovusStringUtils.IsNumberStr to TNovusStringUtils.IsNumeric
* Log unload external plugins

10/01/2021

* Upgraded DelphiVerion.inc
* Upgraded FastMM5 
* WebServer plugin support for 404.html
* Changed Ctrl-C to Ctrl-S WebServer Plugin 
* Fix tMarkdownProcessorItem.DoBlockEvent crashing when aBlock.lines is NILL
* Cleaned up StaticWebSite to current CodeImatic.gencode

06/05/2020

* Upgraded FastMM4 to FastMM5

21/03/2020

* Upgrade to NovuscodeLibrary new NovusObject Package

16/03/2020

* New Project tag [%workingdirectory%] Current working directory

9/3/2020

  * reintroduced command line -outputlog 
  * fixed outputlogfile default 
  * fixed a memory leak in function tProjectParser.ParseProject

25/02/2020

* Start of the Changelog
* Upgrade to NovusCommandLine class
* -var command line changed to allow multiple access. 
   Example: -var FOO=XYZ or -var FOO="AAAA"