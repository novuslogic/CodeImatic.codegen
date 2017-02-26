unit Plugin_WebServerClasses;

interface

uses Classes,Plugin, NovusPlugin, NovusVersionUtils,Project,
    Output, SysUtils, System.Generics.Defaults,  runtime, config,
    APIBase, IdBaseComponent, IdComponent, IdTCPServer, IdHTTPServer, StdCtrls,
    ExtCtrls, HTTPApp, Windows, NovusConsoleUtils, Plugin_WebServerEngine;


type
  tPlugin_WebServerBase = class(TCommandLinePlugin)
  private
  protected
  public
    constructor Create(aOutput: tOutput; aPluginName: String; aProject: TProject; aConfigPlugins: TConfigPlugins); override;
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

    function CreatePlugin(aOutput: tOutput; aProject: TProject; aConfigPlugins: TConfigPlugins): TPlugin; safecall;

  end;

function GetPluginObject: INovusPlugin; stdcall;

implementation

var
  _Plugin_WebServer: TPlugin_WebServer = nil;

constructor tPlugin_WebServerBase.Create(aOutput: tOutput; aPluginName: String; aProject: TProject; aConfigPlugins: TConfigPlugins);
begin
  Inherited Create(aOutput,aPluginName, aProject, aConfigPlugins);
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

function tPlugin_WebServer.CreatePlugin(aOutput: tOutput; aProject: TProject; aConfigPlugins: TConfigPlugins): TPlugin; safecall;
begin
  FPlugin_WebServer := tPlugin_WebServerBase.Create(aOutput, GetPluginName, aProject, aConfigPlugins);

  Result := FPlugin_WebServer;
end;


procedure tPlugin_WebServer.Finalize;
begin
  //if Assigned(FPlugin_WebServer) then FPlugin_WebServer.Free;
end;

// tPlugin_WebServerBase
function tPlugin_WebServerBase.BeforeCodeGen: boolean;
begin
  Result := true;

end;

function tPlugin_WebServerBase.AfterCodeGen: boolean;
var
  loPlugin_WebServerEngine: TPlugin_WebServerEngine;
begin
  Result := false;

  if oProject.OutputConsole = false then
    oOutput.Log('Cannot run WebServer with Project option of OutputConsole = false')
  else
    begin
      Result := true;

      Try
        loPlugin_WebServerEngine:= TPlugin_WebServerEngine.Create(oOutput, oProject, oConfigPlugins);

        loPlugin_WebServerEngine.Execute;
      Finally
        loPlugin_WebServerEngine.Free;
      End;
    end;
end;

function tPlugin_WebServerBase.IsCommandLine(aCommandLine: string): boolean;
begin
  Result := Uppercase(aCommandLine) = '-WEBSERVER';
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


