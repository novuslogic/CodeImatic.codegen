unit Plugin_WebServerClasses;

interface

uses Classes,Plugin, NovusPlugin, Project, NovusCommandLine,
    Output, SysUtils, System.Generics.Defaults,  runtime, config, TagType,
    APIBase, IdBaseComponent, IdComponent, IdTCPServer, IdHTTPServer, StdCtrls,
    ExtCtrls, HTTPApp, Windows, {NovusConsoleUtils,} Plugin_WebServerEngine;


type
  tPlugin_WebServerBase = class(TPlugin)
  private
  protected
    fbIsOpenBrowser: boolean;
    fbIsWebServer: Boolean;
  public
    constructor Create(aOutput: tOutput; aPluginName: String; aProject: TProject; aConfigPlugin: TConfigPlugin); override;
    destructor Destroy; override;

    function IsCommandLine(aResultCommand: INovusCommandLineResultCommand): boolean; override;
    function BeforeCodeGen: boolean; override;
    function AfterCodeGen: boolean; override;

    property IsWebServer: boolean
      read fbIsWebServer
      write fbIsWebServer;

    property IsOpenBrowser: boolean
       read fbIsOpenBrowser
       write fbIsOpenBrowser;
  end;

  TPlugin_WebServer = class( TExternalPlugin)
  private
  protected
    FPlugin_WebServer: tPlugin_WebServerBase;
  public
    function GetPluginName: string; override; safecall;

    procedure Initialize; override; safecall;
    procedure Finalize; override; safecall;

    function CreatePlugin(aOutput: tOutput; aProject: TProject; aConfigPlugin: TConfigPlugin): TPlugin; override; safecall;
  end;

function GetPluginObject: TNovusPlugin; stdcall;

implementation

var
  _Plugin_WebServer: TPlugin_WebServer = nil;

constructor tPlugin_WebServerBase.Create(aOutput: tOutput; aPluginName: String; aProject: TProject; aConfigPlugin: TConfigPlugin);
begin
  Inherited Create(aOutput,aPluginName, aProject, aConfigPlugin);

  fbIsWebServer := false;
  fbIsOpenBrowser := false;
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

function tPlugin_WebServer.CreatePlugin(aOutput: tOutput; aProject: TProject; aConfigPlugin: TConfigPlugin): TPlugin;
begin
  FPlugin_WebServer := tPlugin_WebServerBase.Create(aOutput, GetPluginName, aProject, aConfigPlugin);

  Result := FPlugin_WebServer;
end;


procedure tPlugin_WebServer.Finalize;
begin
  if Assigned(FPlugin_WebServer) then FPlugin_WebServer.Free;
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
  Result := True;

  if IsWebServer then
    begin
      if oProject.OutputConsole = false then
        begin
          oOutput.Log('Cannot run webserver [runwerbserver] with Project option of OutputConsole = false');

          result := False;
        end
      else
        begin

          Try
            loPlugin_WebServerEngine:= TPlugin_WebServerEngine.Create(oOutput, oProject, oConfigPlugin, fbIsOpenBrowser);

            loPlugin_WebServerEngine.Execute;
          Finally
            loPlugin_WebServerEngine.Free;
          End;
        end;
    end;
end;

function tPlugin_WebServerBase.IsCommandLine(aResultCommand: INovusCommandLineResultCommand): boolean;
Var
  loResultOption: INovusCommandLineResultOption;
begin
  Result := true;

  if Not Assigned(aResultCommand) then Exit;


  loResultOption := aResultCommand.Options.FindOptionByName('command');
  if Assigned(loResultOption) then
    begin
      if lowercase(Trim(loResultOption.Value)) =  'runwebserver' then
        IsWebServer := true;


    end;


   (*
  if FindCmdLineSwitch('runwebserver', true) then
     IsWebServer := true;

  if FindCmdLineSwitch('openbrowser', true) then
     if (IsWebServer = true) then IsOpenBrowser := true
        else
          begin
            oOutput.Log('Cannot run -OpenBrowser without -WebServer option.');

            result := False;
          end;

   *)

end;



function GetPluginObject: TNovusPlugin;
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


