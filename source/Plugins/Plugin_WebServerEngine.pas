unit Plugin_WebServerEngine;

interface

Uses Output, APIBase, IdBaseComponent, IdComponent, IdTCPServer, IdHTTPServer, StdCtrls,
    ExtCtrls, HTTPApp, Windows, NovusConsoleUtils, SysUtils, IdCustomHTTPServer, IdContext,
    Classes, NovusFileUtils, IdServerIOHandler, IdSSL, IdSSLOpenSSL, NovusStringUtils,
    NovusIndyUtils, Config, Project, NovusWebUtils, IdGlobalProtocols, IdGlobal;

Type
  TPlugin_WebServerEngine = class(Tobject)
  protected
  private
    fbIsOpenBrowser: Boolean;
    fServerIOHandlerSSLOpenSSL: TIdServerIOHandlerSSLOpenSSL;
    fHTTPServer: TIdHTTPServer;
    foOutput: TOutput;
    foProject: tProject;
    foConfigPlugins : TConfigPlugins;

    function GetMIMEType(aURL: String): String;
    procedure ServerIOHandlerSSLOpenSSLGetPassword(var Password: string);
    procedure HTTPServerCommandGet(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);

    function GetOutputPath: String;
    function GetDefaultDocument: string;
    function GetUseSSL: boolean;
    function GetSSLPassword: string;
    function GetPort: integer;
    function GetSSLPath: String;
    function GetAddress: String;
    function GetServer: String;
    function GetSSLKeyFile: string;
    function GetSSLCertFile: String;
    function GetSSLRootCertFile: String;
  public
    constructor Create(aOutput: tOutput; aProject: tProject; aConfigPlugins: tConfigPlugins; aIsOpenBrowser: Boolean);
    destructor Destroy; override;

    function Execute: Boolean;

    property DefaultDocument: String
      read GetDefaultDocument;

    property OutputPath: String
      read GetOutputPath;

    property UseSSL: boolean
       read GetUseSSL;

    property SSLPassword: string
      read GetSSLPassword;

    property Port: Integer
      read GetPort;

    property SSLPath: string
      read GetSSLPath;

    property Address: String
      read GetAddress;

    property Server: String
      read GetServer;

    property SSLKeyFile: String
       read GetSSLKeyFile;

    property SSLCertFile: string
       read GetSSLCertFile;

    property SSLRootCertFile: string
       read GetSSLRootCertFile;
 end;

implementation

var
  FCtrlflag: integer;

constructor tPlugin_WebServerEngine.Create(aOutput: tOutput; aProject: tProject; aConfigPlugins: tConfigPlugins; aIsOpenBrowser: Boolean);
begin
  foOutput := aOutput;
  foConfigPlugins := aConfigPlugins;
  foProject := aProject;

  fbIsOpenBrowser := aIsOpenBrowser;

  FHTTPServer := TIdHTTPServer.Create(nil);

  FHTTPServer.OnCommandGet := HTTPServerCommandGet;

  fServerIOHandlerSSLOpenSSL:= TIdServerIOHandlerSSLOpenSSL.Create(nil);

  fServerIOHandlerSSLOpenSSL.OnGetPassword := ServerIOHandlerSSLOpenSSLGetPassword;
end;

destructor  tPlugin_WebServerEngine.Destroy;
begin
  fServerIOHandlerSSLOpenSSL.Free;
  FHTTPServer.Free;
end;

function ConProc(CtrlType : DWord) : Bool; stdcall; far;
var
S : String;
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

function tPlugin_WebServerEngine.GetOutputPath: string;
begin
  Result :=foProject.oProjectConfig.Outputpath;
  if Result = '' then
    Result := foProject.BasePath;
end;

function tPlugin_WebServerEngine.GetDefaultDocument: string;
begin
  Result := 'index.html';
  if foConfigPlugins.oConfigProperties.IsPropertyExists('DefaultDocument') then
    Result := foConfigPlugins.oConfigProperties.GetProperty('DefaultDocument');

end;


function tPlugin_WebServerEngine.Execute: Boolean;
var
  stdin: THandle;
  start: Cardinal;
  ch: char;
begin
  Try
    foOutput.Log('Starting WebServer ...');

    if not TNovusIndyUtils.IsTCPPortUsed(Port, Server) then
      begin
        FHTTPServer.DefaultPort := Port;

        if UseSSL then
          begin
            FHTTPServer.IOHandler := fServerIOHandlerSSLOpenSSL;

            fServerIOHandlerSSLOpenSSL.SSLOptions.KeyFile:= SSLPath +  SSLKeyFile;
            fServerIOHandlerSSLOpenSSL.SSLOptions.CertFile:= SSLPath + SSLCertFile;
            fServerIOHandlerSSLOpenSSL.SSLOptions.RootCertFile:= SSLPath  + SSLRootCertFile;
          end;

        foOutput.Log('WebServer address: ' + address);

        FHTTPServer.Active := true;

        foOutput.Log('WebServer running ... press ctrl-c to stop.');


        if fbIsOpenBrowser then
          TNovusWebUtils.OpenDefaultWebBrowser(address);

        stdin := TNovusConsoleUtils.GetStdInputHandle;

        SetConsoleCtrlHandler(@ConProc, True);

        FCtrlflag := -1;
        start := GetTickCount;
        Repeat
          If TNovusConsoleUtils.IsAvailableKey( stdin ) Then
            begin
              if FCtrlflag = CTRL_C_EVENT then break;

            end
          Else
            Sleep( 20 );
        Until false;

        FHTTPServer.Active := false;

        foOutput.Log('Stopping WebServer.');
      end
    else
      foOutput.Log('tcp port not open ... '+ Server + ':' + IntToStr(Port) + ' cannot start WebServer.');
  Except
    foOutput.InternalError;

    foOutput.Log('Cannot start WebServer.');

    FHTTPServer.Active := false;
  End;
end;

procedure tPlugin_WebServerEngine.HTTPServerCommandGet(AContext: TIdContext;
  ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
var
  localurl: string;
  fContent:TStream;
begin
  localurl := TNovusStringUtils.ReplaceChar(ExpandFilename(OutputPath + aRequestInfo.Document),
       '/', '\');

  if ((localurl[Length(localurl)] = '\') and DirectoryExists(localurl)) then
    localurl := ExpandFileName(localurl + DefaultDocument);

  if FileExists(localurl) then
    begin
      if AnsiSameText(Copy(localurl, 1, Length(OutputPath)), ExtractFilePath(OutputPath)) then // File down in dir structure
      begin
         try
          aResponseInfo.ResponseNo := 200;
          aResponseInfo.ContentType := GetMIMEType(localurl);
          aResponseInfo.CharSet := 'UTF-8';

          if TNovusFileUtils.IsFileInUse(localurl) then foOutput.Log(localurl + ' ... locked or in use.')
          else
            begin
              fContent := TIdReadFileExclusiveStream.Create(localurl);

              aResponseInfo.ContentStream := fContent;
              aResponseInfo.ContentLength := fContent.Size;
            end;



        Except
          foOutput.InternalError;
        end;


        (*
        if AnsiSameText(aRequestInfo.Command, 'HEAD') then
        begin

          ResultFile := TFileStream.create(localurl, fmOpenRead	or fmShareDenyWrite);
          try
            aResponseInfo.ResponseNo := 200;
            aResponseInfo.ContentType := GetMIMEType(localurl);
            aResponseInfo.ContentLength := ResultFile.Size;
          finally
            ResultFile.Free;
          end;
        end
        else
        begin
          aResponseInfo.ResponseNo := 200;
          aResponseInfo.ContentType := GetMIMEType(localurl);
          aResponseInfo.ContentStream   := TFileStream.create(localurl, fmOpenRead	or fmShareDenyWrite);


          (*
          aResponseInfo.CharSet := 'utf-8';

          aResponseInfo.ContentStream := TMemoryStream.Create;
          try
            FFileContents.LoadFromFile(localurl, TEncoding.ASCII);

            AResponseInfo.ContentStream.Write(Pointer(strJSON)^, Length(strJSON));
            AResponseInfo.ContentStream.Position := 0;
            AResponseInfo.WriteContent;
          finally
            AResponseInfo.ContentStream := nil;
          end;


          //aResponseInfo.ContentStream   := TFileStream.create(localurl, fmOpenRead	or fmShareDenyWrite);
          //if aResponseInfo.ContentStream = NIL then ;
          // AResponseInfo.ContentText := strJSON;
           //AResponseInfo.ContentLength := IndyTextEncoding_UTF8.GetByteCount(strJSON);

        end;
        *)
      end;
    end
    else
    begin
      aResponseInfo.ResponseNo := 404;
      aResponseInfo.ContentText := '<html><head><title>Error</title></head><body><h1>' + aResponseInfo.ResponseText + '</h1></body></html>';
    end;
end;



procedure tPlugin_WebServerEngine.ServerIOHandlerSSLOpenSSLGetPassword(var Password: string);
begin
  password:=SSLPassword;
end;


function tPlugin_WebServerEngine.GetUseSSL: boolean;
begin
  Result := false;
  if foConfigPlugins.oConfigProperties.IsPropertyExists('UseSSL') then
    Result := TNovusStringUtils.StrToBoolean(foConfigPlugins.oConfigProperties.GetProperty('UseSSL'));
end;

function tPlugin_WebServerEngine.GetSSLPassword: String;
begin
  result := '';
  if foConfigPlugins.oConfigProperties.IsPropertyExists('SSLPassword') then
    Result := foConfigPlugins.oConfigProperties.GetProperty('SSLPassword');
end;

function tPlugin_WebServerEngine.GetPort: integer;
begin
  result := 8080;
  if foConfigPlugins.oConfigProperties.IsPropertyExists('Port') then
    Result := TNovusStringUtils.Str2Int(foConfigPlugins.oConfigProperties.GetProperty('Port'));
end;

function tPlugin_WebServerEngine.GetSSLPath: String;
begin
  result := TNovusFileUtils.TrailingBackSlash(TNovusStringUtils.RootDirectory) + 'SSL\'
end;

function tPlugin_WebServerEngine.GetAddress: String;
begin
  if UseSSL then result := 'https://'
  else
    result := 'http://';

  result := result + Server + ':' +  IntToStr(Port);
end;

function tPlugin_WebServerEngine.GetServer: string;
begin
  Result := '';
  if foConfigPlugins.oConfigProperties.IsPropertyExists('Server') then
    Result := foConfigPlugins.oConfigProperties.GetProperty('Server');
end;

function tPlugin_WebServerEngine.GetSSLKeyFile: string;
begin
  Result := '';
  if foConfigPlugins.oConfigProperties.IsPropertyExists('SSLKeyFile') then
    Result := foConfigPlugins.oConfigProperties.GetProperty('SSLKeyFile');
end;

function tPlugin_WebServerEngine.GetSSLCertFile: String;
begin
  result := '';
  if foConfigPlugins.oConfigProperties.IsPropertyExists('SSLCertFile') then
    Result := foConfigPlugins.oConfigProperties.GetProperty('SSLCertFile');
end;

function tPlugin_WebServerEngine.GetSSLRootCertFile: String;
begin
  result := '';
  if foConfigPlugins.oConfigProperties.IsPropertyExists('SSLRootCertFile') then
    Result := foConfigPlugins.oConfigProperties.GetProperty('SSLRootCertFile');
end;


function tPlugin_WebServerEngine.GetMIMEType(aURL: string): string;
begin
  Result := TNovusWebUtils.GetMIMEType(aURL);
end;

end.
