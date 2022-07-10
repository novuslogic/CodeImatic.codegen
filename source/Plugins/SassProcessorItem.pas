unit SassProcessorItem;

interface

Uses Winapi.Windows, System.SysUtils, System.Classes, NovusFileUtils,
  Plugin, NovusPlugin,  Project, NovusTemplate,
  Output, System.Generics.Defaults, runtime, Config, NovusStringUtils,
  APIBase, ProjectItem, TagType, JvSimpleXml, DelphiLibSass, Loader, template;

type
  tSassProcessorItem = class(TProcessorItem)
  private
    fSassprocessor: TDelphiLibSass;
  protected
    function GetProcessorName: String; override;
  public
    function PreProcessor(aProjectItem: tObject; var aFilename: String;
      var aTemplate: tTemplate; aNodeLoader: tNodeLoader; aCodeGenerator: tObject): TPluginReturn; override;
    function PostProcessor(aProjectItem: tObject; var aTemplate: tTemplate;
      aTemplateFile: String; var aOutputFilename: string)
      : TPluginReturn; override;

    function Convert(aProjectItem: tObject; aInputFilename: string;
      var aOutputFilename: string): TPluginReturn; override;
  end;

implementation

function tSassProcessorItem.GetProcessorName: String;
begin
  Result := 'SASS';
end;

function tSassProcessorItem.PreProcessor(aProjectItem: tObject;
  var aFilename: String; var aTemplate: tTemplate; aNodeLoader: tNodeLoader; aCodeGenerator: tObject): TPluginReturn;
begin
  Result := PRIgnore;
end;

function tSassProcessorItem.PostProcessor(aProjectItem: tObject;
  var aTemplate: tTemplate; aTemplateFile: String; var aOutputFilename: string)
  : TPluginReturn;
Var
  fScssResult: TScssResult;
  FDelphiLibSass: TDelphiLibSass;
begin
  Try
    Try
      Try
        fScssResult := NIL;
        fSassprocessor := TDelphiLibSass.LoadInstance;

        if Assigned(fSassprocessor) then
        begin
          fScssResult := fSassprocessor.ConvertToCss(aTemplate.OutputDoc.text);
          if Assigned(fScssResult) then
          begin
            aTemplate.OutputDoc.text := fScssResult.CSS;
            Result := TPluginReturn.PRPassed;
          end;

        end;
      Except
        Result := TPluginReturn.PRFailed;

        oOutput.InternalError;
      End;
    Finally
      if Assigned(fSassprocessor) then
        fSassprocessor.Free;

      if Assigned(fScssResult) then
        fScssResult.Free;
    End;

    if Result = TPluginReturn.PRPassed then
    begin
      aOutputFilename := ChangeFileExt(aOutputFilename, '.' + outputextension);

      oOutput.Log('New output:' + aOutputFilename);
    end;

  Except
    Result := TPluginReturn.PRFailed;

    oOutput.InternalError;
  End;
end;

function tSassProcessorItem.Convert(aProjectItem: tObject;
  aInputFilename: string; var aOutputFilename: string): TPluginReturn;
begin
  Result := PRIgnore;
end;

end.
