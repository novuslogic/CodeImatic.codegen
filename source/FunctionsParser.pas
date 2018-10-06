unit FunctionsParser;

interface

Uses TokenParser, TagParser, TagType;

Type
   TOnExecuteFunction = procedure(var aToken:string) of object;

   TFunctionsParser = class(tTokenParser)
   private
   protected
   public
     OnExecuteFunction: TOnExecuteFunction;
     function Execute: String;
   end;

implementation


function TFunctionsParser.Execute: String;
Var
  LsToken: String;
  fTagType: TTagType;
begin
  Result := '';

  if GetNextToken = '(' then
    begin
      LsToken := GetNextToken(true);


      if GetNextToken = ')' then
        begin
          if Assigned(OnExecuteFunction) then
            OnExecuteFunction(LsToken);

          Result := LsToken;
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
