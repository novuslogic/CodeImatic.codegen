unit Plugin_WebServerEngine;

interface

Uses Output, APIBase, IdBaseComponent, IdComponent, IdTCPServer, IdHTTPServer, StdCtrls,
    ExtCtrls, HTTPApp, Windows, NovusConsoleUtils, SysUtils;

Type
  TPlugin_WebServerEngine = class(Tobject)
  protected
  private
    foOutput: TOutput;
    function CurrentConsoleMode( handle: THandle ): Cardinal;
  public
    constructor Create(aOutput: tOutput);
    destructor Destroy; override;

    function Execute: Boolean;
  end;

implementation

var
  FCtrlflag: integer;

constructor tPlugin_WebServerEngine.Create(aOutput: tOutput);
begin
  foOutput := aOutput;
end;

destructor  tPlugin_WebServerEngine.Destroy;
begin
end;

function tPlugin_WebServerEngine.CurrentConsoleMode( handle: THandle ): Cardinal;
Begin
  Win32Check( GetConsoleMode( handle, Result ));
End;

function ConProc(CtrlType : DWord) : Bool; stdcall; far;
var
S : String;
begin
  FCtrlflag := CtrlType;

  (*
  case CtrlType of
    CTRL_C_EVENT : S := 'CTRL_C_EVENT';
    CTRL_BREAK_EVENT : S := 'CTRL_BREAK_EVENT';
    CTRL_CLOSE_EVENT : S := 'CTRL_CLOSE_EVENT';
    CTRL_LOGOFF_EVENT : S := 'CTRL_LOGOFF_EVENT';
    CTRL_SHUTDOWN_EVENT : S := 'CTRL_SHUTDOWN_EVENT';
    else
    S := 'UNKNOWN_EVENT';
  end;
  *)

  Result := True;
end;


function tPlugin_WebServerEngine.Execute: Boolean;
var
  stdin: THandle;
  start: Cardinal;
  ch: char;
begin
  Try
    foOutput.Log('WebServer running ... press ctrl-c to stop.');

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
  Except

  End;
end;

end.
