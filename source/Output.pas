unit Output;

interface

Uses NovusLog, SysUtils, NovusUtilities, uPSRuntime, uPSUtils;

type
  TErrorTypes = (tETNone, tETOverflow_Error, tETUnderflow_Error, tETSyntax_Error, tETOutOfRangeBranch, tETLabelError, tETTagUnknown, tETFatalError);

  Toutput = class(TNovusLogFile)
  private
  protected
    fsLastExParam: tbtstring;
    fLastExError: TPSError;
    fbErrors: Boolean;
    fbFailed: Boolean;
    fbconsoleoutputonly: Boolean;
  public
    procedure InitLog(AFilename: String; aOutputConsole: Boolean;
      aConsoleoutputonly: Boolean);

    procedure Log(const aMsg: string);
    procedure LogFormat(const aFormat: string; const Args: array of const);
    procedure LogError(const aMsg: String); overload;
    procedure LogError(aLineNo: Integer; aErrorType: TErrorTypes = tETNone); overload;

    procedure InternalError;
    procedure LogException(AException: Exception);

    property Errors: Boolean read fbErrors write fbErrors;

    property Failed: Boolean read fbFailed write fbFailed;

    property LastExError: TPSError read fLastExError write fLastExError;

    property LastExParam: tbtstring read fsLastExParam write fsLastExParam;

    property Consoleoutputonly: boolean read fbConsoleoutputonly write fbConsoleoutputonly default true;
  end;

implementation

procedure Toutput.InitLog(AFilename: String; aOutputConsole: Boolean;
  aConsoleoutputonly: Boolean);
begin
  OutputConsole := aOutputConsole;

  fbconsoleoutputonly := aConsoleoutputonly;

  Filename := AFilename;

  fbErrors := False;
end;

procedure Toutput.Log(const aMsg: string);
begin
  if fbconsoleoutputonly then
    Writeln(aMsg)
  else
    WriteLog(aMsg);
end;

procedure Toutput.LogError(const aMsg: String);
begin
  Log(aMsg);

  Failed := true;
end;

procedure Toutput.LogFormat(const aFormat: string; const Args: array of const);
begin
  Log(SysUtils.format(aFormat, Args));
end;

procedure Toutput.InternalError;
begin
  if fbconsoleoutputonly then
    Writeln(TNovusUtilities.GetExceptMess)
  else
    WriteExceptLog;

  Failed := true;
end;

procedure Toutput.LogException(AException: Exception);
var
  lsMessage: String;
begin
  if Not Assigned(AException) then
    Exit;

  lsMessage := 'Error:' + AException.Message;

  Log(lsMessage);

  Failed := true;
end;

procedure Toutput.LogError(aLineNo: Integer; aErrorType: TErrorTypes = tETNone);
Var
  lsMsg: String;
begin
  case aErrorType of
    TErrorTypes.tETOverflow_error:
      lsMsg := SysUtils.format('[Overflow error] (%d)', [aLineNo]);
    TErrorTypes.tETUnderflow_error:
      lsMsg := SysUtils.format('[Underflow error] (%d)' , [aLineNo]);
    TErrorTypes.tETSyntax_Error:
      lsMsg := SysUtils.format('[Syntax error] (%d)', [aLineNo]);
    TErrorTypes.tETOutOfRangeBranch:
      lsMsg := SysUtils.format('[Out of Range Brach] (%d) ', [aLineNo]);
    TErrorTypes.tETLabelError:
      lsMsg := SysUtils.format('[Label Error] (%d)', [aLineNo]);
    TErrorTypes.tETtagUnknown:
      lsMsg := SysUtils.format('[Tag Unknown]', [aLineNo]);
    else
      lsMsg := SysUtils.format('[Error] (%d)', [aLineNo]);
  end;

  Log(lsMsg);
end;

end.

