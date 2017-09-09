unit Plugin_SassClasses;

interface

uses Winapi.Windows, System.SysUtils, System.Classes,
  Plugin, NovusPlugin, NovusVersionUtils, Project, NovusTemplate,
  Output, System.Generics.Defaults, runtime, Config, NovusStringUtils,
  APIBase, ProjectItem, TagType, DelphiLibSass;

type
  tPlugin_SassBase = class(TProcessorPlugin)
  private
     fSassprocessor: TDelphiLibSass;
  protected
    function Getoutputextension: string; override;
    function Getsourceextension: string; override;
  public
    constructor Create(aOutput: tOutput; aPluginName: String;
      aProject: TProject; aConfigPlugins: tConfigPlugins); override;
    destructor Destroy; override;

    function PostProcessor(aProjectItem: tObject; aTemplate: tNovusTemplate;
      var aOutputFile: string): boolean; overload; override;
    function PreProcessor(aFilename: String; var aTemplateDoc: tStringlist)
      : boolean; override;

  end;

  TPlugin_Sass = class(TSingletonImplementation, INovusPlugin, IExternalPlugin)
  private
  protected
    foOutput: TOutput;
    foProject: TProject;
    FPlugin_Sass: tPlugin_SassBase;
  public
    function GetPluginName: string; safecall;

    procedure Initialize; safecall;
    procedure Finalize; safecall;

    property PluginName: string read GetPluginName;

    function CreatePlugin(aOutput: tOutput; aProject: TProject;
      aConfigPlugins: tConfigPlugins): TPlugin; safecall;

  end;

function GetPluginObject: INovusPlugin; stdcall;

implementation

var
  _Plugin_Sass: TPlugin_Sass = nil;

constructor tPlugin_SassBase.Create(aOutput: tOutput; aPluginName: String;
  aProject: TProject; aConfigPlugins: tConfigPlugins);
begin
  Inherited Create(aOutput, aPluginName, aProject, aConfigPlugins);

  Try
    fSassprocessor := TDelphiLibSass.LoadInstance;
  Except
    aOutput.InternalError;
  End;

end;

destructor tPlugin_SassBase.Destroy;
begin
  Inherited;

  Try
    if Assigned(fSassprocessor) then
      fSassprocessor.Free;
  Except
    foOutput.InternalError;
  End;
end;

// Plugin_Sass
function TPlugin_Sass.GetPluginName: string;
begin
  Result := 'Sass';
end;

procedure TPlugin_Sass.Initialize;
begin
end;

function TPlugin_Sass.CreatePlugin(aOutput: tOutput; aProject: TProject;
  aConfigPlugins: tConfigPlugins): TPlugin; safecall;
begin
  foProject := aProject;
  foOutput := aOutput;

  FPlugin_Sass := tPlugin_SassBase.Create(aOutput, GetPluginName, foProject,
    aConfigPlugins);

  Result := FPlugin_Sass;
end;

procedure TPlugin_Sass.Finalize;
begin
  // if Assigned(FPlugin_Sass) then FPlugin_Sass.Free;
end;

// tPlugin_SassBase

function tPlugin_SassBase.Getoutputextension: String;
begin
  Result := 'css';
  if foConfigPlugins.oConfigProperties.IsPropertyExists('outputextension') then
    Result := foConfigPlugins.oConfigProperties.GetProperty('outputextension');
end;

function tPlugin_SassBase.Getsourceextension: String;
begin
  Result := 'scss';
  if foConfigPlugins.oConfigProperties.IsPropertyExists('sourceextension') then
    Result := foConfigPlugins.oConfigProperties.GetProperty('sourceextension');
end;

function tPlugin_SassBase.PreProcessor(aFilename: string;
  var aTemplateDoc: tStringlist): boolean;
  (*
Var
  fScssResult: TScssResult;
  FDelphiLibSass : TDelphiLibSass;
  *)
begin
  Result := True;
  (*
  foOutput.Log('Processor:' + PluginName);

  Try
    Try
      fScssResult := NIL;

      if Assigned(fSassprocessor) then
      begin
        fScssResult := fSassprocessor.ConvertToCss(aTemplateDoc.Text);
        if Assigned(fScssResult) then
        begin
          aTemplateDoc.Text := fScssResult.CSS;
          Result := true;
        end;

      end;
    Except
      Result := False;

      foOutput.InternalError;
    End;
  Finally
    if Assigned(fScssResult) then
      fScssResult.Free;
  End;
  *)
end;

function tPlugin_SassBase.PostProcessor(aProjectItem: tObject;
  aTemplate: tNovusTemplate; var aOutputFile: string): boolean;
Var
  fScssResult: TScssResult;
  FDelphiLibSass : TDelphiLibSass;
begin
  Result := False;

  foOutput.Log('Postprocessor:' + PluginName);

   Try
      Try
      Try
        fScssResult := NIL;

        if Assigned(fSassprocessor) then
        begin
          fScssResult := fSassprocessor.ConvertToCss(aTemplate.OutputDoc.text);
          if Assigned(fScssResult) then
          begin
            aTemplate.OutputDoc.text := fScssResult.CSS;
            Result := true;
          end;

        end;
      Except
        Result := False;

        foOutput.InternalError;
      End;
    Finally
      if Assigned(fScssResult) then
        fScssResult.Free;
    End;

    if Result then
      begin
        aOutputFile := ChangeFileExt(aOutputFile, '.' + outputextension);

        foOutput.Log('New output:' + aOutputFile);
      end;

  Except
    Result := False;

    foOutput.InternalError;
  End;
end;

function GetPluginObject: INovusPlugin;
begin
  if (_Plugin_Sass = nil) then
    _Plugin_Sass := TPlugin_Sass.Create;
  Result := _Plugin_Sass;
end;

exports GetPluginObject name func_GetPluginObject;

initialization

begin
  _Plugin_Sass := nil;
end;

finalization

FreeAndNIL(_Plugin_Sass);

end.
