unit Plugin_WebServerEngine;

interface

Uses CodeImatic.Output, APIBase, IdBaseComponent, IdComponent,
  IdTCPServer, IdHTTPServer,
  StdCtrls,
  ExtCtrls, HTTPApp, Windows, NovusConsole, SysUtils, IdCustomHTTPServer,
  IdContext, Plugins,
  Classes, NovusFileUtils, IdServerIOHandler, IdSSL, IdSSLOpenSSL,
  NovusStringUtils, IdSSLOpenSSLHeaders,
  NovusIndyUtils, Config, Project, NovusWebUtils, IdGlobalProtocols, IdGlobal,
  RuntimeProjectItems;

Type
  TPlugin_WebServerEngine = class(Tobject)
  protected
  private
    fbIsOpenBrowser: Boolean;
    fServerIOHandlerSSLOpenSSL: TIdServerIOHandlerSSLOpenSSL;
    fHTTPServer: TIdHTTPServer;
    foOutput: TcimOutput;
    foProject: tProject;
    foConfigPlugin: TConfigPlugin;

    function ServerIOHandlerSSLOpenSSL1VerifyPeer(Certificate: TIdX509;
      AOk: Boolean; ADepth, AError: Integer): Boolean;
    function GetMIMEType(aURL: String): String;
    procedure ServerIOHandlerSSLOpenSSLGetPassword(var Password: string);
    procedure HTTPServerCommandGet(AContext: TIdContext;
      ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
    procedure HTTPServerCommandError(AContext: TIdContext;
      ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo;
      AException: Exception);
    procedure HTTPServerException(AContext: TIdContext; AException: Exception);

    function GetOutputPath: String;
    function GetDefaultDocument: string;
    function GetUseSSL: Boolean;
    function GetSSLPassword: string;
    function GetPort: Integer;
    function GetSSLPath: String;
    function GetAddress: String;
    function GetServer: String;
    function GetSSLKeyFile: string;
    function GetSSLCertFile: String;
    function GetSSLRootCertFile: String;
    function Get404: string;

    function RunProjectItems: Boolean;
  public
    constructor Create(aOutput: TcimOutput; aProject: tProject;
      aConfigPlugin: TConfigPlugin; aIsOpenBrowser: Boolean);
    destructor Destroy; override;

    function Execute: Boolean;

    property DefaultDocument: String read GetDefaultDocument;

    property OutputPath: String read GetOutputPath;

    property UseSSL: Boolean read GetUseSSL;

    property SSLPassword: string read GetSSLPassword;

    property Port: Integer read GetPort;

    property SSLPath: string read GetSSLPath;

    property Address: String read GetAddress;

    property Server: String read GetServer;

    property SSLKeyFile: String read GetSSLKeyFile;

    property SSLCertFile: string read GetSSLCertFile;

    property SSLRootCertFile: string read GetSSLRootCertFile;
  end;

implementation

var
  FCtrlflag: Integer;

constructor TPlugin_WebServerEngine.Create(aOutput: TcimOutput; aProject: tProject;
  aConfigPlugin: TConfigPlugin; aIsOpenBrowser: Boolean);
begin
  foOutput := aOutput;
  foConfigPlugin := aConfigPlugin;
  foProject := aProject;

  fbIsOpenBrowser := aIsOpenBrowser;

  fHTTPServer := TIdHTTPServer.Create(nil);

  fHTTPServer.OnCommandGet := HTTPServerCommandGet;

  fServerIOHandlerSSLOpenSSL := TIdServerIOHandlerSSLOpenSSL.Create(nil);

  fServerIOHandlerSSLOpenSSL.OnGetPassword :=
    ServerIOHandlerSSLOpenSSLGetPassword;

  fServerIOHandlerSSLOpenSSL.OnVerifyPeer :=
    ServerIOHandlerSSLOpenSSL1VerifyPeer;

  fHTTPServer.OnException := HTTPServerException;
  fHTTPServer.OnCommandError := HTTPServerCommandError;

end;

destructor TPlugin_WebServerEngine.Destroy;
begin
  fServerIOHandlerSSLOpenSSL.Free;
  fHTTPServer.Free;
end;

function TPlugin_WebServerEngine.ServerIOHandlerSSLOpenSSL1VerifyPeer
  (Certificate: TIdX509; AOk: Boolean; ADepth, AError: Integer): Boolean;
begin
  if ADepth = 0 then
    Result := AOk
  else
    Result := True;
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
  Result := foProject.oProjectConfigLoader.OutputPath;
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
    foOutput.oLog.AddLogInformation('Starting WebServer ...');

    if Port = 0 then
    begin
      foOutput.oLog.AddLogError('Cannot start WebServer with port: 0');

      Exit;
    end;

    if not TNovusIndyUtils.IsTCPPortUsed(Port, Server) then
    begin
      try
        fHTTPServer.DefaultPort := Port;

        // IdOpenSSLSetLibPath('D:\Projects\CodeImatic.codegen\build');

        if UseSSL then
        begin
          fHTTPServer.IOHandler := fServerIOHandlerSSLOpenSSL;

          fServerIOHandlerSSLOpenSSL.SSLOptions.KeyFile := SSLPath + SSLKeyFile;
          fServerIOHandlerSSLOpenSSL.SSLOptions.CertFile := SSLPath +
            SSLCertFile;
          fServerIOHandlerSSLOpenSSL.SSLOptions.RootCertFile := SSLPath +
            SSLRootCertFile;
          // fServerIOHandlerSSLOpenSSL.SSLOptions.method := sslvSSLv3;

          // fServerIOHandlerSSLOpenSSL.SSLOptions.SSLVersions := [sslvTLSv1,sslvTLSv1_1,sslvTLSv1_2];

          fServerIOHandlerSSLOpenSSL.SSLOptions.Mode := sslmServer;
        end;

        foOutput.oLog.AddLogInformation('WebServer address: ' + Address);

        fHTTPServer.Active := True;

        foOutput.oLog.AddLogInformation
          ('WebServer running ... press ctrl-s to stop | ctrl-r to refresh project. | ctrl-b open in default browser');

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

              if ch = #19 then
                break;

              if ch = #02 then
              begin
                foOutput.oLog.AddLogInformation('Opening default browser ...');
                tNovusWebUtils.OpenDefaultWebBrowser(Address);
              end;

              if ch = #18 then
              begin
                RunProjectItems;

                foOutput.oLog.AddLogInformation
                  ('WebServer running ... press ctrl-s to stop | ctrl-r to refresh project. | ctrl-b open in defaultdn browser');
              end;
            end;
          end
          Else
            Sleep(20);

        Until false;

        fHTTPServer.Active := false;

        foOutput.oLog.AddLogInformation('Stopping WebServer.');
      finally

      end;
    end
    else
      foOutput.oLog.AddLogInformation('port not open ... ' + Server + ':' + IntToStr(Port) +
        ' cannot start WebServer.');
  Except
    foOutput.oLog.AddLogException();


    foOutput.oLog.AddLogError('Cannot start WebServer.');
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
          foOutput.oLog.AddLogError(localurl + ' ... locked or in use.')
        else
        begin
          fContent := TIdReadFileExclusiveStream.Create(localurl);

          AResponseInfo.ContentStream := fContent;
          AResponseInfo.ContentLength := fContent.Size;
        end;

      Except
        foOutput.oLog.AddLogException();
        foOutput.Failed := True;
      end;

    end;
  end
  else
  begin
    AResponseInfo.ResponseNo := 404;

    fContent := TIdReadFileExclusiveStream.Create(OutputPath + Get404);

    AResponseInfo.ContentStream := fContent;
    AResponseInfo.ContentLength := fContent.Size;
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

function TPlugin_WebServerEngine.GetPort: Integer;
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

function TPlugin_WebServerEngine.Get404: String;
begin
  Result := '';
  if foConfigPlugin.oConfigProperties.IsPropertyExists('404') then
    Result := foConfigPlugin.oConfigProperties.GetProperty('404');
end;

function TPlugin_WebServerEngine.GetMIMEType(aURL: string): string;
begin
  Result := tNovusWebUtils.GetMIMEType(aURL);
end;

procedure TPlugin_WebServerEngine.HTTPServerCommandError(AContext: TIdContext;
  ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo;
  AException: Exception);
begin
  foOutput.oLog.AddLogException(AException);
end;

procedure TPlugin_WebServerEngine.HTTPServerException(AContext: TIdContext;
  AException: Exception);
begin
  if AException.Message = 'Connection Closed Gracefully.' then
    Exit;

  foOutput.oLog.AddLogException(AException);
end;

function TPlugin_WebServerEngine.RunProjectItems: Boolean;
Var
  loRuntimeProjectItems: tRuntimeProjectItems;
begin
  Try
    loRuntimeProjectItems := tRuntimeProjectItems.Create(foOutput, foProject,
      (foProject.oPlugins as TPlugins));

    Result := loRuntimeProjectItems.RunProjectItems
  Finally
    loRuntimeProjectItems.Free;
  End;
end;

end.
