unit FunctionsParser;

interface

Uses TokenParser, TagParser, TagType;

Type
   TOnExecute = procedure(var aToken:string) of object;

   TFunctionsParser = class(tTokenParser)
   private
   protected
   public
     OnExecute: TOnExecute;
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
          if Assigned(OnExecute) then
            OnExecute(LsToken);

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
