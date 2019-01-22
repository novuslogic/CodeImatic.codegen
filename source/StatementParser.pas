unit StatementParser;

interface

Uses TokenProcessor, ExpressionParser;

type
  tStatementParser = class(tTokenProcessor)
  protected
  private
  public
    function IsEqual: Boolean;
  end;

implementation


function tStatementParser.IsEqual: Boolean;
var
  fExpressionParser: TExpressionParser;
begin
  Result := false;
  Try
  Try
    fExpressionParser:= TExpressionParser.Create;
    fExpressionParser.Expr := Self.Text;

    Result := fExpressionParser.Execute;
  Finally
    fExpressionParser.Free;
  End;
  Except


  End;
end;

end.
