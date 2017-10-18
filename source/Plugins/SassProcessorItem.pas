unit SassProcessorItem;

interface

Uses Winapi.Windows, System.SysUtils, System.Classes,NovusFileUtils,
  Plugin, NovusPlugin, NovusVersionUtils, Project, NovusTemplate,
  Output, System.Generics.Defaults, runtime, Config, NovusStringUtils,
  APIBase, ProjectItem, TagType, JvSimpleXml, DelphiLibSass;

type
  tSassProcessorItem = class(TProcessorItem)
  private
    fSassprocessor : TDelphiLibSass;
  protected
    function GetProcessorName: String; override;
  public
    function PreProcessor(aFilename: String; aTemplate: tNovusTemplate)
      : TPluginReturn; override;
    function PostProcessor(aProjectItem: tObject;
        aTemplate: tNovusTemplate; aTemplateFile: string;var aOutputFile: string): TPluginReturn; override;

    function Convert(aFilename: string; var aOutputFile: string):TPluginReturn; override;
  end;

implementation

function tSassProcessorItem.GetProcessorName: String;
begin
  Result := 'SASS';
end;

function tSassProcessorItem.PreProcessor(aFilename: String; aTemplate: tNovusTemplate): TPluginReturn;
begin
  Result := PRIgnore;
end;

function tSassProcessorItem.PostProcessor(aProjectItem: tObject; aTemplate: tNovusTemplate;
     aTemplateFile: string;var aOutputFile: string): TPluginReturn;
Var
  fScssResult: TScssResult;
  FDelphiLibSass : TDelphiLibSass;
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
        aOutputFile := ChangeFileExt(aOutputFile, '.' + outputextension);

        oOutput.Log('New output:' + aOutputFile);
      end;

  Except
    Result := TPluginReturn.PRFailed;

    oOutput.InternalError;
  End;
end;

function tSassProcessorItem.Convert(aFilename: string; var aOutputFile: string): TPluginReturn;
begin
  Result := PRIgnore;
end;



end.