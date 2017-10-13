unit FunctionParser;

interface

Uses TokenParser;

Type
   TFunctionParser = class(tTokenParser)
   private
   protected
   public
   end;

implementation

(*
function TFunctionParser.Functions(ATokens: tStringList; Var AIndex: Integer; ACommandIndex: Integer): String;
Var
  LStr: String;
begin
  Result := '';

  if GetNextToken(AIndex, ATokens) = '(' then
    begin
      LStr := GetNextToken(AIndex, ATokens);

      if GetNextToken(AIndex, ATokens) = ')' then
        begin
          case ACommandIndex of
            0: Result := Lowercase(LStr);
            1: Result := Uppercase(LStr);
            2: Result := TNovusStringUtils.UpLowerA(LStr, True);
            3: Result := FieldTypeToDataType(LStr);
            4: Result := ClearDataType(LStr);
            5: Result := IntToStr(Pred(StrToInt(LStr)));
          end;
        end
      else
        begin
          FOutput.Log('Incorrect syntax: lack ")"');
        end;
    end
  else
    begin
      FOutput.Log('Incorrect syntax: lack "("');
    end;
end;
*)

end.
