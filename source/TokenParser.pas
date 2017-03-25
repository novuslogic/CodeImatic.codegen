unit TokenParser;

interface

uses ExpressionParser, system.Classes, Project, Variables, output, SysUtils;

type
   tTokenParser = class
   protected
   private
   public
     class function ParseToken(aObject: TObject;aToken: String; aProjectItem: tProjectItem; aVariables: TVariables;aOutput: Toutput; ATokens: tStringList; Var aIndex: Integer): String;
   end;

implementation

uses CodeGenerator, Runtime, Interpreter;

class function tTokenParser.ParseToken(aObject: TObject; aToken: String;aProjectItem: tProjectItem; aVariables: TVariables; aOutput: Toutput; ATokens: tStringList; Var aIndex: Integer): String;
var
  fsToken: String;
  lEParser: tFEParser;
  lTokens: TStringlist;
  lTagType: tTagType;
  lsValue : String;
  loVarable: tVariable;
  lsToken1, lsToken2: string;
begin
  Result := aToken;

  If Copy(aToken, 1, 2) = '$$' then
    begin
      fsToken := Copy(aToken, 3, Length(aToken));

      if aObject is tInterpreter then
        begin
          lsToken1 := fsToken;

//          lsToken2

        end
      else
      if aObject is TCodeGenerator then
        begin
          Try
            lTokens := TStringList.Create;

            lEParser:= tFEParser.Create;

            lEParser.Expr := fsToken;

            lEParser.ListTokens(lTokens);

            if lTokens.Count > 0 then
              begin
                lsToken1 := Uppercase(lTokens.Strings[0]);
                if lTokens.Count > 1 then
                  lsToken2 := Uppercase(lTokens.Strings[1]);
               end;
           Finally
            lEParser.Free;
            lTokens.Free;
          End
        end;


        lTagType := TCodeGenerator.GetTagType(lsToken1,lsToken2 );

        case lTagType of
          ttProperty: Result := oRuntime.oProperties.GetProperty(fsToken);
          ttPropertyEx: begin
             if aObject is tInterpreter then
               begin
                 lsToken2 :=  tInterpreter(aObject).GetNextToken(AIndex, ATokens);

               end;

             if lsToken2 <> '' then
               begin
                 Result := oRuntime.oProperties.GetProperty(lsToken2);
               end;
          end;
          ttprojectitem: Result := aProjectItem.GetProperty(lTokens);
          ttplugintag: begin
              if aObject is tInterpreter then
               begin
                 lsToken2 :=  tInterpreter(aObject).GetNextToken(AIndex, ATokens);

               end;


              if oRuntime.oPlugins.IsTagExists(lsToken1, lsToken2) then
                begin
                  Result := oRuntime.oPlugins.GetTag(lsToken1, lsToken2);
                end;
          end;

          ttUnknown: begin
             aOutput.WriteLog('Syntax Error: Tag '+ lsToken1 + ' cannot be found.');
              aOutput.Failed := true;

          end;
        end;
      end
   else
   If Copy(aToken, 1, 1) = '$' then
    begin
      lsValue := TVariables.CleanVariableName(aToken);
      if Assigned(aVariables) then
        begin
          loVarable := aVariables.GetVariableByName(lsValue);
          if Not Assigned(loVarable) then
            begin
              aOutput.WriteLog('Syntax Error: variable '+ lsValue + ' cannot be found.');
              aOutput.Failed := true;
            end
          else Result := loVarable.Value;
        end
      else
        begin
          aOutput.WriteLog('Syntax Error: variable '+ lsValue + ' cannot be found.');
          aOutput.Failed := true;
        end;
    end;
end;




end.
