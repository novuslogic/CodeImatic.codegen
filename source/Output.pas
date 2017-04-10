unit Output;

interface

Uses NovusLog, SysUtils, NovusUtilities;

type
  Toutput = class(TNovusLogFile)
  private
  protected
    fbErrors: Boolean;
    fbFailed: Boolean;
    fbconsoleoutputonly: Boolean;
  public
    procedure InitLog(AFilename: String;aOutputConsole: Boolean; aConsoleoutputonly: boolean);

    procedure Log(const aMsg: string);
    procedure LogFormat(const aFormat: string; const Args: array of const);
    procedure LogError(const aMsg: String);

    procedure InternalError;

    property Errors: Boolean
      read fbErrors
      write fbErrors;

    property Failed: Boolean
      read fbFailed
      write fbFailed;

  end;

implementation

procedure Toutput.InitLog(AFilename: String;aOutputConsole: Boolean; aConsoleoutputonly: Boolean);
begin
  OutputConsole := aOutputConsole;

  fbConsoleoutputonly := aConsoleoutputonly;

  Filename := AFilename;

  fbErrors := False;
end;


procedure TOutput.Log(const aMsg: string);
begin
  if fbConsoleoutputonly then
    Writeln(aMsg)
  else
    WriteLog(aMsg);
end;


procedure TOutput.LogError(const aMsg: String);
begin
  Log(aMsg);

  Failed := true;
end;

procedure TOutput.LogFormat(const aFormat: string; const Args: array of const);
begin
  Log(SysUtils.format(aFormat, Args));
end;

procedure TOutput.InternalError;
begin
  if fbConsoleoutputonly then
    WriteLn(TNovusUtilities.GetExceptMess)
  else
    WriteExceptLog;

  Failed := true;
end;

end.



