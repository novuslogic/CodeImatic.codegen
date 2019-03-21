unit FunctionsParser;

interface

Uses TokenParser, TagParser, TagType, TokenProcessor, SysUtils;

Type
   TOnExecute = procedure(var aToken:string) of object;
   TOnExecuteA = procedure(var aToken: String; aTokenParser: tTokenParser; aTokens: tTokenProcessor) of object;

   TFunctionParser = class(tTokenParser)
   private
   protected
   public
     OnExecute: TOnExecute;
     function Execute: String;
   end;

   TFunctionAParser = class(tTokenParser)
   private
   protected
   public
     OnExecute: TOnExecuteA;
     function Execute: String;
   end;

   TFunctionBParser = class(tTokenParser)
   private
   protected
   public
     OnExecute: TOnExecute;
     function Execute: String;
   end;


implementation


function TFunctionParser.Execute: String;
Var
  LsToken: String;
  fTagType: TTagType;
  lsNextToken: String;
begin
  Result := '';

  if fsTagName = oTokens.Strings[TokenIndex] then
     oTokens.TokenIndex := oTokens.TokenIndex + 1;

  lsNextToken := ParseNextToken;
  if  lsNextToken = '(' then
    begin
      LsToken := ParseNextToken;
      if Assigned(OnExecute) then
        OnExecute(LsToken);

      lsNextToken := ParseNextToken;
      if  lsNextToken = ')' then
        begin
          Result := LsToken;
          Exit;
        end
      else
        oOutput.LogError('Syntax error: lack ")" not "'+ lsNextToken +'"');

    end
  else
    begin

      oOutput.LogError('Syntax error: lack "(" not "'+ lsNextToken +'"');
    end;
end;

function TFunctionAParser.Execute: String;
Var
  LsToken, LsToken2: String;
  fTagType: TTagType;
  lsNextToken: String;
begin
  Result := '';

  if fsTagName = oTokens.Strings[TokenIndex] then
     oTokens.TokenIndex := oTokens.TokenIndex + 1;

  lsNextToken := ParseNextToken;
  if lsNextToken = '(' then
    begin
      LsToken := ParseNextToken;
      if Assigned(OnExecute) then
        OnExecute(LsToken, self, oTokens);

      if Trim(LsToken) = '' then
        begin
          oTokens.TokenIndex := oTokens.TokenIndex + 1;
          if oTokens.EOF then
            oTokens.TokenIndex := oTokens.Count -1;
        end;

      lsNextToken := ParseNextToken;
      if lsNextToken = ')' then
        begin
          Result := LsToken;

          Exit;
        end
      else
        begin
          oOutput.LogError('Syntax error: lack ")" not "'+ lsNextToken +'"' );
        end;

    end
  else
    begin
      oOutput.LogError('Syntax error: lack "(s" not "'+ lsNextToken +'"');
    end;
end;


function TFunctionBParser.Execute: String;
Var
  LsToken: String;
  fTagType: TTagType;
begin
  Result := '';

  if fsTagName = oTokens.Strings[TokenIndex] then
     oTokens.TokenIndex := oTokens.TokenIndex + 1;

  if ParseNextToken = '(' then
    begin
      LsToken := NextToken;
      if Assigned(OnExecute) then
        OnExecute(LsToken);

      if NextToken = ')' then
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
