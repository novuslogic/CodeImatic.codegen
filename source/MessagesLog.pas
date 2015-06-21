unit MessagesLog;

interface

Uses NovusLog;

type
  TMessagesLog = class(TNovusLogFile)
  private
  protected
    fbErrors: Boolean;
    fbFailed: Boolean;
  public
    constructor Create(AFilename: String;aOutputConsole: Boolean);  virtual;

    property Errors: Boolean
      read fbErrors
      write fbErrors;

    property Failed: Boolean
      read fbFailed
      write fbFailed;

  end;

implementation

constructor TMessagesLog.Create(AFilename: String;aOutputConsole: Boolean);
begin
  OutputConsole := aOutputConsole;

  inherited Create(AFilename);

  fbErrors := False;
end;


end.



