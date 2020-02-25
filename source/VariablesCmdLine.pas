unit VariablesCmdLine;

interface

uses Variables,Classes, NovusStringUtils, ExpressionParser, NovusTemplate, SysUtils,
      NovusUtilities, NovusStringParser ;

type
   tVariablesCmdLine = class(tVariables)
   protected
      fsError: String;
      fbFailed: Boolean;
   public
     function AddVariableCmdLine(aVarCmdLine: String): boolean;

     property Error: String
        read fsError;

     property Failed: Boolean
        read fbFailed;
   end;

implementation

function tVariablesCmdLine.AddVariableCmdLine(aVarCmdLine: String): Boolean;
Var
  I: integer;
  fsVariableName: String;
  fsValue: String;
  fsOperator: String;
  fNovusStringParser: tNovusStringParser;
begin
  Try
    Try
        Result := true;
        fNovusStringParser:= tNovusStringParser.Create(aVarCmdLine, true);

            if fNovusStringParser.Items.Count > 0 then
              begin
                fsVariableName := fNovusStringParser.Items[0];

                if fNovusStringParser.Items.Count > 2 then
                  begin
                    fsOperator := fNovusStringParser.Items[1];
                    fsValue := fNovusStringParser.Items[2];

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

      Finally
        fNovusStringParser.Free;
      End;
  Except
    fsError := TNovusUtilities.GetExceptMess;

    Result := False;

    Exit;
  End;

end;

end.
