unit Plugin_CodeDocsClasses;

interface

uses Winapi.Windows, System.SysUtils, System.Classes,
  Plugin, NovusPlugin, NovusVersionUtils, Project, NovusTemplate,
  Output, System.Generics.Defaults, runtime, Config, NovusStringUtils,
  APIBase, ProjectItem, TagType;

type
  tPlugin_CodeDocsBase = class(TProcessorPlugin)
  private
  protected
  public
    constructor Create(aOutput: tOutput; aPluginName: String;
      aProject: TProject; aConfigPlugins: tConfigPlugins); override;
    destructor Destroy; override;

    function PostProcessor(aProjectItem: tObject; aTemplate: tNovusTemplate;
      var aOutputFile: string): boolean; overload; override;
    function PreProcessor(aFilename: String; var aTemplateDoc: tStringlist)
      : boolean; override;

  end;

  TPlugin_CodeDocs = class(TSingletonImplementation, INovusPlugin, IExternalPlugin)
  private
  protected
    foOutput: TOutput;
    foProject: TProject;
    FPlugin_CodeDocs: tPlugin_CodeDocsBase;
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
  _Plugin_CodeDocs: TPlugin_CodeDocs = nil;

constructor tPlugin_CodeDocsBase.Create(aOutput: tOutput; aPluginName: String;
  aProject: TProject; aConfigPlugins: tConfigPlugins);
begin
  Inherited Create(aOutput, aPluginName, aProject, aConfigPlugins);

  Try
   // fCodeDocsprocessor := TDelphiLibCodeDocs.LoadInstance;
  Except
    aOutput.InternalError;
  End;

end;

destructor tPlugin_CodeDocsBase.Destroy;
begin
  Inherited;

  Try
   // if Assigned(fCodeDocsprocessor) then
  //    fCodeDocsprocessor.Free;
  Except
    foOutput.InternalError;
  End;
end;

// Plugin_CodeDocs
function TPlugin_CodeDocs.GetPluginName: string;
begin
  Result := 'CodeDocs';
end;

procedure TPlugin_CodeDocs.Initialize;
begin
end;

function TPlugin_CodeDocs.CreatePlugin(aOutput: tOutput; aProject: TProject;
  aConfigPlugins: tConfigPlugins): TPlugin; safecall;
begin
  foProject := aProject;
  foOutput := aOutput;

  FPlugin_CodeDocs := tPlugin_CodeDocsBase.Create(aOutput, GetPluginName, foProject,
    aConfigPlugins);

  Result := FPlugin_CodeDocs;
end;

procedure TPlugin_CodeDocs.Finalize;
begin
  // if Assigned(FPlugin_CodeDocs) then FPlugin_CodeDocs.Free;
end;

// tPlugin_CodeDocsBase
function tPlugin_CodeDocsBase.PreProcessor(aFilename: string;
  var aTemplateDoc: tStringlist): boolean;
begin
  Result := False;

  foOutput.Log('Processor:' + PluginName);



  (*
  foOutput.Log('Processor:' + PluginName);

  Try
    Try
      fScssResult := NIL;

      if Assigned(fCodeDocsprocessor) then
      begin
        fScssResult := fCodeDocsprocessor.ConvertToCss(aTemplateDoc.Text);
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

function tPlugin_CodeDocsBase.PostProcessor(aProjectItem: tObject;
  aTemplate: tNovusTemplate; var aOutputFile: string): boolean;
begin
  Result := False;

  foOutput.Log('Postprocessor:' + PluginName);

  Try
    //aOutputFile := ChangeFileExt(aOutputFile, '.' + outputextension);

    //foOutput.Log('New output:' + aOutputFile);

    Result := true;
  Except
    Result := False;
    foOutput.InternalError;
  End;
end;

function GetPluginObject: INovusPlugin;
begin
  if (_Plugin_CodeDocs = nil) then
    _Plugin_CodeDocs := TPlugin_CodeDocs.Create;
  Result := _Plugin_CodeDocs;
end;

exports GetPluginObject name func_GetPluginObject;

initialization

begin
  _Plugin_CodeDocs := nil;
end;

finalization

FreeAndNIL(_Plugin_CodeDocs);

end.
