unit StatementParser;

interface

Uses TokenProcessor, ExpressionParser, SysUtils, NovusUtilities;

type
  tStatementParser = class(tTokenProcessor)
  protected
  private
    fsErrorStatementMessage: String;
  public
    function IsEqual: Boolean;

    property ErrorStatementMessage: String
       read fsErrorStatementMessage;
  end;

implementation


function tStatementParser.IsEqual: Boolean;
var
  fExpressionParser: TExpressionParser;
begin
  Result := false;
  fsErrorStatementMessage := '';

  if Trim(Self.Text) = '' then Exit;

  Try
  Try
    fExpressionParser:= TExpressionParser.Create;
    fExpressionParser.Expr := Trim(Self.Text);

    Result := fExpressionParser.Execute;

    if not Result then
      fsErrorStatementMessage := fExpressionParser.ErrorExpressionMessage;
  Finally
    fExpressionParser.Free;
  End;
  Except
    fsErrorStatementMessage := TNovusUtilities.GetExceptMess
  End;
end;

end.
