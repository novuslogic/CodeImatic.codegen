unit FunctionsParser;

interface

Uses TokenParser;

Type
   TFunctionsParser = class(tTokenParser)
   private
   protected
   public
     function Execute: String;
   end;

implementation


function TFunctionsParser.Execute: String;
Var
  LsToken: String;
begin
  Result := '';

  if GetNextToken = '(' then
    begin
      LsToken := GetNextToken;

      if GetNextToken = ')' then
        begin
      
        end
      else
        begin
          oOutput.LogError('Incorrect syntax: lack ")"');
        end;
    end
  else
    begin
      oOutput.LogError('Incorrect syntax: lack "("');
    end;

end;


end.
