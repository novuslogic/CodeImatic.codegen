unit Plugin_WebServerClasses;

interface

uses Classes,Plugin, NovusPlugin, NovusVersionUtils,
    Output, SysUtils, System.Generics.Defaults,  runtime,
    APIBase ;


type
  tPlugin_WebServerBase = class(TCommandLinePlugin)
  private
  protected
  public
    constructor Create(aOutput: tOutput; aPluginName: String); override;
    destructor Destroy; override;

    function IsCommandLine(aCommandLine: String): boolean; override;
    function BeforeCodeGen: boolean; override;
    function AfterCodeGen: boolean; override;
  end;

  TPlugin_WebServer = class( TSingletonImplementation, INovusPlugin, IExternalPlugin)
  private
  protected
    FPlugin_WebServer: tPlugin_WebServerBase;
  public
    function GetPluginName: string; safecall;

    procedure Initialize; safecall;
    procedure Finalize; safecall;

    property PluginName: string read GetPluginName;

    function CreatePlugin(aOutput: tOutput): TPlugin; safecall;

  end;

function GetPluginObject: INovusPlugin; stdcall;

implementation

var
  _Plugin_WebServer: TPlugin_WebServer = nil;

constructor tPlugin_WebServerBase.Create(aOutput: tOutput; aPluginName: String);
begin
  Inherited Create(aOutput,aPluginName);
end;


destructor  tPlugin_WebServerBase.Destroy;
begin
  Inherited;
end;

// Plugin_WebServer
function tPlugin_WebServer.GetPluginName: string;
begin
  Result := 'WebServer';
end;

procedure tPlugin_WebServer.Initialize;
begin
end;

function tPlugin_WebServer.CreatePlugin(aOutput: tOutput): TPlugin; safecall;
begin
  FPlugin_WebServer := tPlugin_WebServerBase.Create(aOutput, GetPluginName);

  Result := FPlugin_WebServer;
end;


procedure tPlugin_WebServer.Finalize;
begin
  //if Assigned(FPlugin_WebServer) then FPlugin_WebServer.Free;
end;

// tPlugin_WebServerBase
function tPlugin_WebServerBase.BeforeCodeGen: boolean;
begin
  Result := False;
end;

function tPlugin_WebServerBase.AfterCodeGen: boolean;
begin
  Result := False;
end;

function tPlugin_WebServerBase.IsCommandLine(aCommandLine: string): boolean;
begin
  Result := Uppercase(aCommandLine) = 'WEBSERVER';
end;



function GetPluginObject: INovusPlugin;
begin
  if (_Plugin_WebServer = nil) then _Plugin_WebServer := TPlugin_WebServer.Create;
  result := _Plugin_WebServer;
end;

exports
  GetPluginObject name func_GetPluginObject;

initialization
  begin
    _Plugin_WebServer := nil;
  end;

finalization
  FreeAndNIL(_Plugin_WebServer);

end.


