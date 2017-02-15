unit Output;

interface

Uses NovusLog, SysUtils;

type
  Toutput = class(TNovusLogFile)
  private
  protected
    fbErrors: Boolean;
    fbFailed: Boolean;
  public
    constructor Create(AFilename: String;aOutputConsole: Boolean);  virtual;

    procedure Log(const aMsg: string; aConsoleOnly: boolean = false);
    procedure LogFormat(const aFormat: string; const Args: array of const);

    procedure InternalError;

    property Errors: Boolean
      read fbErrors
      write fbErrors;

    property Failed: Boolean
      read fbFailed
      write fbFailed;

  end;

implementation

constructor Toutput.Create(AFilename: String;aOutputConsole: Boolean);
begin
  OutputConsole := aOutputConsole;

  inherited Create(AFilename);

  fbErrors := False;
end;


procedure TOutput.Log(const aMsg: string; aConsoleOnly: boolean = false);
begin
  WriteLog(aMsg);
end;

procedure TOutput.LogFormat(const aFormat: string; const Args: array of const);
begin
  WriteLog(SysUtils.format(aFormat, Args));
end;

procedure TOutput.InternalError;
begin
   Log(WriteExceptLog);

   Failed := true;
end;

end.



