unit Plugin_MarkdownClasses;

interface

uses Classes,Plugin, NovusPlugin, NovusVersionUtils, Project, NovusTemplate,
    Output, SysUtils, System.Generics.Defaults,  runtime, Config,  NovusStringUtils,
    APIBase, MarkdownDaringFireball, MarkdownProcessor, ProjectItem, TagType ;


type
  tPlugin_MarkdownBase = class( TPostProcessorPlugin)
  private
  protected
    function Getoutputextension: string; override;
    function Getsourceextension: string; override;
  public
    constructor Create(aOutput: tOutput; aPluginName: String; aProject: TProject; aConfigPlugins: tConfigPlugins); override;
    destructor Destroy; override;

    function PostProcessor(aProjectItem: tProjectItem; aTemplate: tNovusTemplate;var aOutputFile: string): boolean; overload; override;
    function PostProcessor(aFilename: String; var aTemplateDoc: tStringlist): boolean; overload; override;


  end;

  TPlugin_Markdown = class( TSingletonImplementation, INovusPlugin, IExternalPlugin)
  private
  protected
    foProject: TProject;
    FPlugin_Markdown: tPlugin_MarkdownBase;

  public
    function GetPluginName: string; safecall;

    procedure Initialize; safecall;
    procedure Finalize; safecall;

    property PluginName: string read GetPluginName;

    function CreatePlugin(aOutput: tOutput; aProject: Tproject; aConfigPlugins: TConfigPlugins): TPlugin; safecall;


  end;

function GetPluginObject: INovusPlugin; stdcall;

implementation

var
  _Plugin_Markdown: TPlugin_Markdown = nil;

constructor tPlugin_MarkdownBase.Create(aOutput: tOutput; aPluginName: String; aProject: TProject; aConfigPlugins: tConfigPlugins);
begin
  Inherited Create(aOutput,aPluginName, aProject, aConfigPlugins);
end;


destructor  tPlugin_MarkdownBase.Destroy;
begin
  Inherited;
end;

// Plugin_Markdown
function tPlugin_Markdown.GetPluginName: string;
begin
  Result := 'Markdown';
end;

procedure tPlugin_Markdown.Initialize;
begin
end;

function tPlugin_Markdown.CreatePlugin(aOutput: tOutput; aProject: TProject; aConfigPlugins: TConfigPlugins): TPlugin; safecall;
begin
  foProject := aProject;

  FPlugin_Markdown := tPlugin_MarkdownBase.Create(aOutput, GetPluginName, foProject, aConfigPlugins);

  Result := FPlugin_Markdown;
end;


procedure tPlugin_Markdown.Finalize;
begin
  //if Assigned(FPlugin_Markdown) then FPlugin_Markdown.Free;
end;

// tPlugin_MarkdownBase

function tPlugin_MarkdownBase.Getoutputextension: String;
begin
  Result := 'html';
  if foConfigPlugins.oConfigProperties.IsPropertyExists('outputextension') then
    Result := foConfigPlugins.oConfigProperties.GetProperty('outputextension');
end;

function tPlugin_MarkdownBase.Getsourceextension: String;
begin
  Result := 'md';
  if foConfigPlugins.oConfigProperties.IsPropertyExists('sourceextension') then
    Result := foConfigPlugins.oConfigProperties.GetProperty('sourceextension');
end;

function  tPlugin_MarkdownBase.PostProcessor(aFilename: string; var aTemplateDoc: tStringlist): boolean;
Var
  fMarkdownprocessor: TMarkdownDaringFireball;
  fsProcessed: string;
begin
  Result := False;    result := false;

  foOutput.Log('Postprocessor:' + pluginname);

  Try
    Try
      fMarkdownprocessor:= TMarkdownDaringFireball.Create;

      fsProcessed := fMarkdownprocessor.process(aTemplateDoc.Text);

      aTemplateDoc.Text := fsProcessed;

      result := true;
    Except
      result := false;

      foOutput.InternalError;
    End;



  Finally
    fMarkdownprocessor.Free;
  End;



end;

function tPlugin_MarkdownBase.PostProcessor(aProjectItem: tProjectItem; aTemplate: tNovusTemplate; var aOutputFile: string): boolean;
Var
  fMarkdownprocessor: TMarkdownDaringFireball;
  fsProcessed: string;
begin
  result := false;

  foOutput.Log('Postprocessor:' + pluginname);

  Try
    Try
      fMarkdownprocessor:= TMarkdownDaringFireball.Create;

      fsProcessed := fMarkdownprocessor.process(aTemplate.OutputDoc.Text);


      aTemplate.OutputDoc.Text := fsProcessed;

      aOutputFile := ChangeFileExt(aOutputFile, '.' + outputextension);

      foOutput.Log('New output:' + aOutputFile);

      result := true;
    Except
      result := false;

      foOutput.InternalError;
    End;



  Finally
    fMarkdownprocessor.Free;
  End;

end;


function GetPluginObject: INovusPlugin;
begin
  if (_Plugin_Markdown = nil) then _Plugin_Markdown := TPlugin_Markdown.Create;
  result := _Plugin_Markdown;
end;

exports
  GetPluginObject name func_GetPluginObject;

initialization
  begin
    _Plugin_Markdown := nil;
  end;

finalization
  FreeAndNIL(_Plugin_Markdown);

end.


