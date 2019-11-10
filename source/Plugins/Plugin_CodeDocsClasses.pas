unit Plugin_CodeDocsClasses;

interface

uses Winapi.Windows, System.SysUtils, System.Classes,
  Plugin, NovusPlugin, NovusVersionUtils, Project, NovusTemplate,
  Output, System.Generics.Defaults, runtime, Config, NovusStringUtils,
  APIBase, ProjectItem, TagType, CodeDocsProcessorItem, JvHtmlParser;


  //https://wiki.delphi-jedi.org/wiki/JVCL_Help:TJvHTMLParser

type
  tPlugin_CodeDocsBase = class(TProcessorPlugin)
  private
  protected
  public
    constructor Create(aOutput: tOutput; aPluginName: String;
      aProject: TProject; aConfigPlugin: tConfigPlugin); override;
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
      aConfigPlugin: tConfigPlugin): TPlugin; safecall;

  end;

function GetPluginObject: INovusPlugin; stdcall;

implementation

var
  _Plugin_CodeDocs: TPlugin_CodeDocs = nil;

constructor tPlugin_CodeDocsBase.Create(aOutput: tOutput; aPluginName: String;
  aProject: TProject; aConfigPlugin: tConfigPlugin);
begin
   Inherited Create(aOutput, aPluginName, aProject, aConfigPlugin);

   SingleItem := true;

  Try
    AddProcessorItem(tCodeDocsProcessorItem.Create(aConfigPlugin, aOutput, aProject));
  Except
    aOutput.InternalError;
  End;
end;

// Plugin_CodeDocs
function TPlugin_CodeDocs.GetPluginName: string;
begin
  Result := 'CodeDocsProcessor';
end;

procedure TPlugin_CodeDocs.Initialize;
begin
end;

function TPlugin_CodeDocs.CreatePlugin(aOutput: tOutput; aProject: TProject;
  aConfigPlugin: tConfigPlugin): TPlugin; safecall;
begin
  foProject := aProject;
  foOutput := aOutput;

  FPlugin_CodeDocs := tPlugin_CodeDocsBase.Create(aOutput, GetPluginName, foProject,
    aConfigPlugin);

  Result := FPlugin_CodeDocs;
end;

procedure TPlugin_CodeDocs.Finalize;
begin
  // if Assigned(FPlugin_CodeDocs) then FPlugin_CodeDocs.Free;
end;

// tPlugin_CodeDocsBase

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
