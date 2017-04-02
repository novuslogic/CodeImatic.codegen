unit VariablesCmdLine;

interface

uses Variables,Classes, NovusStringUtils, ExpressionParser, NovusTemplate, SysUtils;

type
   tVariablesCmdLine = class(tVariables)
   protected
      fsError: String;
      fbFailed: Boolean;
   public
     function AddVarCmdLine(aVarCmdLine: String): boolean;

     property Error: String
        read fsError;

     property Failed: Boolean
        read fbFailed;
   end;

implementation

function tVariablesCmdLine.AddVarCmdLine(aVarCmdLine: String): Boolean;
Var
  FVarCmdLineStrList: TStringList;
  FExpressionParser: TExpressionParser;
  I: integer;
  FTokens: tStringList;
  fsVariableName: String;
  fsValue: String;
  fsOperator: String;
begin
  Try
    Result := true;

    FVarCmdLineStrList := TStringList.Create;
    FExpressionParser:= TExpressionParser.Create;
    FTokens:= tStringList.Create;


    TNovusStringUtils.ParseStringList(';', aVarCmdLine, FVarCmdLineStrList);

    for I := 0 to FVarCmdLineStrList.Count - 1 do
      begin
        FTokens.Clear;
        FExpressionParser.Expr := FVarCmdLineStrList.Strings[i];
        FExpressionParser.ListTokens(FTokens);

        if FTokens.Count > 0 then
          begin
            fsVariableName := FTokens[0];
            if FTokens.Count > 2 then
              begin
                fsOperator := FTokens[1];
                fsValue := FTokens[2];

                if fsOperator = '=' then
                  begin
                    Self.AddVariable(fsVariableName, fsValue);
                  end
                else
                  begin
                    fsError := 'Command line variable syntax error: Operator not ''=''';
                    fbFailed := True;

                    Result := False;
                    Exit;
                  end;
              end
            else
              begin
                fsError := 'Command line variable syntax error.';
                Result := False;
                fbFailed := True;

                Exit;
              end;
          end
        else
           begin
             fsError := 'Command line variable synatx error.';
             fbFailed := True;
             Result := False;

             Exit;
           end;

      end;

  Finally
    FExpressionParser.Free;
    FTokens.Free;
    FVarCmdLineStrList.Free;
  End;

end;

end.
