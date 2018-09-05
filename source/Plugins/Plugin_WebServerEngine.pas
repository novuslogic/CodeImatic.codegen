unit Plugin_WebServerEngine;

interface

Uses Output, APIBase, IdBaseComponent, IdComponent, IdTCPServer, IdHTTPServer,
  StdCtrls,
  ExtCtrls, HTTPApp, Windows, NovusConsole, SysUtils, IdCustomHTTPServer,
  IdContext, Plugins,
  Classes, NovusFileUtils, IdServerIOHandler, IdSSL, IdSSLOpenSSL,
  NovusStringUtils,
  NovusIndyUtils, Config, Project, NovusWebUtils, IdGlobalProtocols, IdGlobal,
  RuntimeProjectItems;

Type
  TPlugin_WebServerEngine = class(Tobject)
  protected
  private
    fbIsOpenBrowser: Boolean;
    fServerIOHandlerSSLOpenSSL: TIdServerIOHandlerSSLOpenSSL;
    fHTTPServer: TIdHTTPServer;
    foOutput: TOutput;
    foProject: tProject;
    foConfigPlugin: TConfigPlugin;

    function GetMIMEType(aURL: String): String;
    procedure ServerIOHandlerSSLOpenSSLGetPassword(var Password: string);
    procedure HTTPServerCommandGet(AContext: TIdContext;  ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
    procedure HTTPServerCommandError(AContext: TIdContext;
  ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo;
  AException: Exception);
    procedure HTTPServerException(AContext: TIdContext;
      AException: Exception);

    function GetOutputPath: String;
    function GetDefaultDocument: string;
    function GetUseSSL: Boolean;
    function GetSSLPassword: string;
    function GetPort: integer;
    function GetSSLPath: String;
    function GetAddress: String;
    function GetServer: String;
    function GetSSLKeyFile: string;
    function GetSSLCertFile: String;
    function GetSSLRootCertFile: String;
    function RunProjectItems: boolean;
  public
    constructor Create(aOutput: TOutput; aProject: tProject;
      aConfigPlugin: TConfigPlugin; aIsOpenBrowser: Boolean);
    destructor Destroy; override;

    function Execute: Boolean;

    property DefaultDocument: String read GetDefaultDocument;

    property OutputPath: String read GetOutputPath;

    property UseSSL: Boolean read GetUseSSL;

    property SSLPassword: string read GetSSLPassword;

    property Port: integer read GetPort;

    property SSLPath: string read GetSSLPath;

    property Address: String read GetAddress;

    property Server: String read GetServer;

    property SSLKeyFile: String read GetSSLKeyFile;

    property SSLCertFile: string read GetSSLCertFile;

    property SSLRootCertFile: string read GetSSLRootCertFile;
  end;

implementation

var
  FCtrlflag: integer;

constructor TPlugin_WebServerEngine.Create(aOutput: TOutput; aProject: tProject;
  aConfigPlugin: TConfigPlugin; aIsOpenBrowser: Boolean);
begin
  foOutput := aOutput;
  foConfigPlugin := aConfigPlugin;
  foProject := aProject;

  fbIsOpenBrowser := aIsOpenBrowser;

  FHTTPServer := TIdHTTPServer.Create(nil);

  FHTTPServer.OnCommandGet := HTTPServerCommandGet;

  fServerIOHandlerSSLOpenSSL:= TIdServerIOHandlerSSLOpenSSL.Create(nil);

  fServerIOHandlerSSLOpenSSL.OnGetPassword := ServerIOHandlerSSLOpenSSLGetPassword;
  FHTTPServer.OnException := HTTPServerException;
  FHTTPServer.OnCommandError := HTTPServerCommandError;


//
end;

destructor TPlugin_WebServerEngine.Destroy;
begin
  fServerIOHandlerSSLOpenSSL.Free;
  FHTTPServer.Free;
end;

function ConProc(CtrlType: DWord): Bool; stdcall; far;
var
  S: String;
begin
  FCtrlflag := CtrlType;

  (*
    case CtrlType of
    CTRL_C_EVENT : S :;
    CTRL_BREAK_EVENT : ;
    CTRL_CLOSE_EVENT : ;
    CTRL_LOGOFF_EVENT : ;
    CTRL_SHUTDOWN_EVENT : ;

    end;
  *)


  Result := True;
end;

function TPlugin_WebServerEngine.GetOutputPath: string;
begin
  Result := foProject.oProjectConfig.OutputPath;
  if Result = '' then
    Result := foProject.BasePath;
end;

function TPlugin_WebServerEngine.GetDefaultDocument: string;
begin
  Result := 'index.html';
  if foConfigPlugin.oConfigProperties.IsPropertyExists('DefaultDocument') then
    Result := foConfigPlugin.oConfigProperties.GetProperty('DefaultDocument');

end;

function TPlugin_WebServerEngine.Execute: Boolean;
var
  stdin: THandle;
  start: Cardinal;
  ch: char;
  loKeyEvent: TKeyEvent;
begin
  Try
    foOutput.Log('Starting WebServer ...');

    if Port = 0 then
    begin
      foOutput.Log('Cannot start WebServer with port:0');

      Exit;
    end;

  if not TNovusIndyUtils.IsTCPPortUsed(Port, Server) then
    begin
      try
        FHTTPServer.DefaultPort := Port;

        if UseSSL then
        begin
          FHTTPServer.IOHandler := fServerIOHandlerSSLOpenSSL;

          fServerIOHandlerSSLOpenSSL.SSLOptions.KeyFile:= SSLPath +  SSLKeyFile;
          fServerIOHandlerSSLOpenSSL.SSLOptions.CertFile:= SSLPath + SSLCertFile;
          fServerIOHandlerSSLOpenSSL.SSLOptions.RootCertFile:= SSLPath  + SSLRootCertFile;
        end;

        foOutput.Log('WebServer address: ' + Address);

        FHTTPServer.Active := true;

        foOutput.Log('WebServer running ... press ctrl-c to stop | ctrl-r to refresh project.');

        Sleep(2000);

        if fbIsOpenBrowser then
          TNovusWebUtils.OpenDefaultWebBrowser(Address);

        stdin := TNovusConsole.GetStdInputHandle;

        SetConsoleCtrlHandler(@ConProc, True);

        FCtrlflag := -1;
        start := GetTickCount;
        Repeat
          loKeyEvent := TNovusConsole.IsAvailableKeyEx(stdin);

          if (loKeyEvent.KeyCode <> 0) or (loKeyEvent.ScanCode <> 0) then
          begin
            if FCtrlflag = CTRL_C_EVENT then
              begin
                break;
              end
            else
              begin
                ch := TNovusConsole.GetAvailableChar(stdin);

                if ch = #18 then
                  begin
                    RunProjectItems;

                    foOutput.Log('Press ctrl-c to stop | ctrl-r to refresh project.');
                  end;
              end;
          end
          Else
            Sleep(20);
        Until false;

        FHTTPServer.Active := false;

        foOutput.Log('Stopping WebServer.');
      finally
 
      end;
    end
    else
      foOutput.Log('port not open ... ' + Server + ':' + IntToStr(Port) +
        ' cannot start WebServer.');
  Except
    foOutput.InternalError;

    foOutput.Log('Cannot start WebServer.');
  End;

end;

procedure TPlugin_WebServerEngine.HTTPServerCommandGet(AContext: TIdContext;
  ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
var
  localurl: string;
  fContent: TStream;
begin
  localurl := TNovusStringUtils.ReplaceChar
    (ExpandFilename(OutputPath + ARequestInfo.Document), '/', '\');

  if ((localurl[Length(localurl)] = '\') and DirectoryExists(localurl)) then
    localurl := ExpandFilename(localurl + DefaultDocument);

  if FileExists(localurl) then
  begin
    if AnsiSameText(Copy(localurl, 1, Length(OutputPath)),
      ExtractFilePath(OutputPath)) then // File down in dir structure
    begin
      try
        AResponseInfo.ResponseNo := 200;
        AResponseInfo.ContentType := GetMIMEType(localurl);
        AResponseInfo.CharSet := 'UTF-8';

        if TNovusFileUtils.IsFileInUse(localurl) then
          foOutput.Log(localurl + ' ... locked or in use.')
        else
        begin
          fContent := TIdReadFileExclusiveStream.Create(localurl);

          AResponseInfo.ContentStream := fContent;
          AResponseInfo.ContentLength := fContent.Size;
        end;

      Except
        foOutput.InternalError;
      end;

    end;
  end
  else
  begin
    AResponseInfo.ResponseNo := 404;
    AResponseInfo.ContentText :=
      '<html><head><title>Error 404</title></head><body><h1>' +
      AResponseInfo.ResponseText + '</h1></body></html>';
  end;
end;

procedure TPlugin_WebServerEngine.ServerIOHandlerSSLOpenSSLGetPassword
  (var Password: string);
begin
  Password := SSLPassword;
end;

function TPlugin_WebServerEngine.GetUseSSL: Boolean;
begin
  Result := false;
  if foConfigPlugin.oConfigProperties.IsPropertyExists('UseSSL') then
    Result := TNovusStringUtils.StrToBoolean
      (foConfigPlugin.oConfigProperties.GetProperty('UseSSL'));
end;

function TPlugin_WebServerEngine.GetSSLPassword: String;
begin
  Result := '';
  if foConfigPlugin.oConfigProperties.IsPropertyExists('SSLPassword') then
    Result := foConfigPlugin.oConfigProperties.GetProperty('SSLPassword');
end;

function TPlugin_WebServerEngine.GetPort: integer;
begin
  Result := 8080;
  if foConfigPlugin.oConfigProperties.IsPropertyExists('Port') then
    Result := TNovusStringUtils.Str2Int
      (foConfigPlugin.oConfigProperties.GetProperty('Port'));
end;

function TPlugin_WebServerEngine.GetSSLPath: String;
begin
  Result := TNovusFileUtils.TrailingBackSlash
    (TNovusStringUtils.RootDirectory) + 'SSL\'
end;

function TPlugin_WebServerEngine.GetAddress: String;
begin
  if UseSSL then
    Result := 'https://'
  else
    Result := 'http://';

  Result := Result + Server + ':' + IntToStr(Port);
end;

function TPlugin_WebServerEngine.GetServer: string;
begin
  Result := '';
  if foConfigPlugin.oConfigProperties.IsPropertyExists('Server') then
    Result := foConfigPlugin.oConfigProperties.GetProperty('Server');
end;

function TPlugin_WebServerEngine.GetSSLKeyFile: string;
begin
  Result := '';
  if foConfigPlugin.oConfigProperties.IsPropertyExists('SSLKeyFile') then
    Result := foConfigPlugin.oConfigProperties.GetProperty('SSLKeyFile');
end;

function TPlugin_WebServerEngine.GetSSLCertFile: String;
begin
  Result := '';
  if foConfigPlugin.oConfigProperties.IsPropertyExists('SSLCertFile') then
    Result := foConfigPlugin.oConfigProperties.GetProperty('SSLCertFile');
end;

function TPlugin_WebServerEngine.GetSSLRootCertFile: String;
begin
  Result := '';
  if foConfigPlugin.oConfigProperties.IsPropertyExists('SSLRootCertFile') then
    Result := foConfigPlugin.oConfigProperties.GetProperty('SSLRootCertFile');
end;

function TPlugin_WebServerEngine.GetMIMEType(aURL: string): string;
begin
  Result := TNovusWebUtils.GetMIMEType(aURL);
end;


procedure TPlugin_WebServerEngine.HTTPServerCommandError(AContext: TIdContext;
  ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo;
  AException: Exception);
begin
  foOutput.LogException(AException);
end;

procedure TPlugin_WebServerEngine.HTTPServerException(AContext: TIdContext;
  AException: Exception);
begin
  if AException.Message = 'Connection Closed Gracefully.' then Exit;

  foOutput.LogException(AException);
end;

function TPlugin_WebServerEngine.RunProjectItems: boolean;
Var
  loRuntimeProjectItems: tRuntimeProjectItems;
  I: Integer;
begin
  Try
    loRuntimeProjectItems:= tRuntimeProjectItems.Create(foOutput, foProject, (foProject.oPlugins as TPlugins));

    Result := loRuntimeProjectItems.RunProjectItems
  Finally
    loRuntimeProjectItems.Free;
  End;
end;

end.
