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

  if ParseNextToken = '(' then
    begin
      LsToken := ParseNextToken;
      if Assigned(OnExecute) then
        OnExecute(LsToken);

      if ParseNextToken = ')' then
        begin
          Result := LsToken;
          Exit;
        end
      else
        oOutput.LogError('Incorrect syntax: lack ")"');

    end
  else
    begin
      oOutput.LogError('Incorrect syntax: lack "("');
    end;
end;


end.
