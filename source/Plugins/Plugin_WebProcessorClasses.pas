unit Plugin_WebProcessorClasses;

interface

uses Winapi.Windows, System.SysUtils, System.Classes,NovusFileUtils,
  Plugin, NovusPlugin, Project, NovusTemplate,
  CodeImatic.Output, System.Generics.Defaults, runtime, Config, NovusStringUtils,
  APIBase, ProjectItem, TagType, SassProcessorItem,JvSimpleXml,
  MarkdownProcessorItem(*, LessCssProcessorItem*);

type
  tPlugin_WebProcessorBase = class(TProcessorPlugin)
  private
  protected
  public
    constructor Create(aOutput: tcimOutput; aPluginName: String;
      aProject: TProject; aConfigPlugin: tConfigPlugin); override;
  end;

  TPlugin_WebProcessor = class(TExternalPlugin)
  private
  protected
    foOutput: TcimOutput;
    foProject: TProject;
    FPlugin_WebProcessor: tPlugin_WebProcessorBase;
  public
    function GetPluginName: string; override; safecall;

    procedure Initialize; override; safecall;
    procedure Finalize; override; safecall;

    function CreatePlugin(aOutput: tcimOutput; aProject: TProject;
      aConfigPlugin: tConfigPlugin): TPlugin; override; safecall;
  end;

function GetPluginObject: TNovusPlugin; stdcall;

implementation


var
  _Plugin_WebProcessor: TPlugin_WebProcessor = nil;

constructor tPlugin_WebProcessorBase.Create(aOutput: tcimOutput; aPluginName: String;
  aProject: TProject; aConfigPlugin: tConfigPlugin);
begin
  Inherited Create(aOutput, aPluginName, aProject, aConfigPlugin);

  Try
    AddProcessorItem(tSassProcessorItem.Create(aConfigPlugin, aOutput, aProject));
    AddProcessorItem(tMarkdownProcessorItem.Create(aConfigPlugin, aOutput, aProject));
//    AddProcessorItem(tLessCssProcessorItem.Create(aConfigPlugin, aOutput, aProject));
  Except
    aOutput.oLog.AddLogException();
    aOutput.Failed := True;
  End;
end;

// Plugin_WebProcessor
function TPlugin_WebProcessor.GetPluginName: string;
begin
  Result := 'WebProcessor';
end;

procedure TPlugin_WebProcessor.Initialize;
begin
end;

function TPlugin_WebProcessor.CreatePlugin(aOutput: tcimOutput; aProject: TProject;
  aConfigPlugin: tConfigPlugin): TPlugin; safecall;
begin
  foProject := aProject;
  foOutput := aOutput;

  FPlugin_WebProcessor := tPlugin_WebProcessorBase.Create(aOutput, GetPluginName, foProject,
    aConfigPlugin);

  Result := FPlugin_WebProcessor;
end;

procedure TPlugin_WebProcessor.Finalize;
begin
  if Assigned(FPlugin_WebProcessor) then FPlugin_WebProcessor.Free;
end;


function GetPluginObject: TNovusPlugin;
begin
  if (_Plugin_WebProcessor = nil) then
    _Plugin_WebProcessor := TPlugin_WebProcessor.Create;
  Result := _Plugin_WebProcessor;
end;

exports GetPluginObject name func_GetPluginObject;

initialization

begin
  _Plugin_WebProcessor := nil;
end;

finalization

FreeAndNIL(_Plugin_WebProcessor);

end.
