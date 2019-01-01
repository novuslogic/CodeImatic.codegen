unit StatementParser;

interface

Uses TokenProcessor;

type
  tStatementParser = class(tTokenProcessor)
  protected
  private
  public

    function IsEqueal: Boolean;

  end;

implementation


function tStatementParser.IsEqueal: Boolean;
begin
  Result := True;
end;

end.
