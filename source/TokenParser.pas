unit TokenParser;

interface

uses  ProjectItem, system.Classes, Project, Variables, output, SysUtils, TagType,
      NovusStringUtils,  TokenProcessor, CodeGeneratorItem;

type
   TEventParseTokenParameter = procedure(var aToken:string) of object;

   tTokenParser = class(Tobject)
   protected
     foCodeGeneratorItem: TCodeGeneratorItem;
     foOutput: TOutput;
     foProjectItem: tProjectItem;
     foVariables: TVariables;
   private
     function GetTokenIndex: Integer;
     procedure SetTokenIndex(Value: Integer);
   public
     constructor Create(aCodeGeneratorItem: TCodeGeneratorItem; aOutput: tOutput) ; overload;



     class function ParseToken(aObject: TObject; aToken: String;aProjectItem: tProjectItem; aVariables: TVariables; aOutput: Toutput; ATokens: tTokenProcessor; Var aTokenIndex: Integer; aProject: TProject): String;
     class function ParseSimpleToken(aToken: string; aOutput: tOutput): tTokenProcessor;
     class function ParseExpressionToken(aObject: TObject;aToken: String; aProjectItem: tProjectItem; aProject: TProject; aVariables: TVariables;aOutput: Toutput): tTokenProcessor; overload;
     class function ParseExpressionToken(aToken: string; aOutput: tOutput): tTokenProcessor; overload;

     function GetNextToken: String;

     property oCodeGeneratorItem: tCodeGeneratorItem
       read foCodeGeneratorItem;

     property oOutput: tOutput
       read foOutput;

     property oProjectItem: tProjectItem
       read foProjectItem;

     property oVariables:  tVariables
       read foVariables;

     property TokenIndex: Integer
      read GetTokenIndex
      write SetTokenIndex;
   end;

implementation

uses CodeGenerator, Runtime, Interpreter, Config, ExpressionParser, TagTypeParser;

class function tTokenParser.ParseSimpleToken(aToken: string; aOutput: tOutput): tTokenProcessor;
var
  liPos: Integer;
  lsToken: string;
  lsLastToken: String;
Const
  OpEqual = '=';
  OpQuote = '"';

begin
  Try
    Result := tTokenProcessor.Create;

    liPos := 1;

    While(liPos < Length(aToken)) Do
      begin
        lsToken :=  TNovusStringUtils.GetStrToken(aToken, [OpEqual, OpQuote], liPos, lsLastToken);
        Inc(liPos);

        Result.Add(lsToken);

        if lsLastToken = OpEqual then Result.Add(lsLastToken);
      end;
   Except
     aOutput.InternalError;
   End;
end;



class function tTokenParser.ParseExpressionToken(aObject: TObject;aToken: String; aProjectItem: tProjectItem; aProject: TProject; aVariables: TVariables;aOutput: Toutput): tTokenProcessor;
Var
  lEParser: tExpressionParser;
  I: Integer;
  lsNewToken: string;
  FiIndex: Integer;
begin
  Result := NIL;

  if not Assigned(aProject) or Not Assigned(aProjectItem) then Exit;

  Try
    Result := tTokenProcessor.Create;

    lEParser:= tExpressionParser.Create;

    lEParser.Expr := aToken;

    lEParser.ListTokens(Result);

    for I := 0 to Result.Count -1 do
      begin
        FiIndex := 0;
        Result.Strings[i] := ParseToken(aObject,  Result.Strings[i], aProjectItem, aVariables, aOutput, NIL, FiIndex, aProject);
      end;
  Except
    aOutput.InternalError;
  End;
end;

class function tTokenParser.ParseExpressionToken(aToken: string; aOutput: tOutput): tTokenProcessor;
Var
  lEParser: tExpressionParser;
  I: Integer;
  lsNewToken: string;
  FiIndex: Integer;
begin
  Result := NIL;

  if Trim(aToken) = '' then Exit;


  Try
    Result := tTokenProcessor.Create;

    lEParser:= tExpressionParser.Create;

    lEParser.Expr := aToken;

    lEParser.ListTokens(Result);

  Except
    aOutput.InternalError;
  End;
end;


constructor tTokenParser.Create(aCodeGeneratorItem: TCodeGeneratorItem; aOutput: tOutput);
begin
  foCodeGeneratorItem := aCodeGeneratorItem;
  foOutput:= aOutput;

  foCodeGeneratorItem.TokenIndex := 0;
end;

class function tTokenParser.ParseToken;
var
  fsToken: String;
  lEParser: tExpressionParser;
  lTokens: tTokenProcessor;
  lTagType: tTagType;
  lsValue : String;
  loVarable: tVariable;
  lsToken1, lsToken2: string;
  lVariable: TVariable;
  loCodeGeneratorItem: tCodeGeneratorItem;
begin
  Result := aToken;

  loCodeGeneratorItem := NIL;

  If Copy(aToken, 1, 2) = '$$' then
    begin
      fsToken := TVariables.CleanVariableName(aToken);

      if aObject is tInterpreter then
        begin
          lsToken1 := fsToken;

          lTagType := TTagTypeParser.ParseTagType(aProjectItem, NIL, lsToken1, aOutput );
        end
      else
      if aObject is TCodeGenerator then
        begin
          Try
            lTokens := tTokenProcessor.Create;

            lEParser:= tExpressionParser.Create;

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
          End;

          lTagType := TTagTypeParser.ParseTagType(aProjectItem, (aObject as TCodeGenerator), lTokens, aOutput, 0 );
        end
        else
          lTagType := TTagTypeParser.ParseTagType(aProjectItem, NIL, aTokens , aOutput, aTokenIndex );

        case lTagType of
          ttProperty: Result := aProjectItem.oProperties.GetProperty(fsToken);
          ttPropertyEx: begin
             if aObject is tInterpreter then
               begin
                 lsToken2 :=  tInterpreter(aObject).GetNextToken(aTokenIndex, ATokens);

               end;

             if lsToken2 <> '' then
               begin
                 Result := aProjectItem.oProperties.GetProperty(lsToken2);
               end;
          end;
          ttprojectitem: begin
                  Result := aProjectItem.GetProperty(lsToken2, aProject);

              end;
          ttplugintag: begin
              if aObject is tInterpreter then
               begin
                 lsToken2 :=  tInterpreter(aObject).GetNextToken(aTokenIndex, ATokens);
                 if Assigned(tInterpreter(aObject).oCodeGeneratorItem) then 
                    loCodeGeneratorItem := tCodeGeneratorItem(tInterpreter(aObject).oCodeGeneratorItem) ;
               end;

              if oRuntime.oPlugins.IsTagExists(lsToken1, lsToken2) then
                begin
                  Result := oRuntime.oPlugins.GetTag(lsToken1, lsToken2, loCodeGeneratorItem);
                end;
          end;
          ttVariableCmdLine: begin
            lVariable := oConfig.oVariablesCmdLine.GetVariableByName(lsToken2);

            if Assigned(lVariable) then
              Result := lVariable.Value;

          end;

          ttConfigProperties: begin
            result := aProject.oProjectConfig.Getproperties(aTokens.GetNextToken);
          end;

          ttUnknown: begin
             aOutput.LogError('Syntax Error: Tag '+ lsToken1 + ' cannot be found.');

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
              aOutput.LogError('Syntax Error: variable '+ lsValue + ' cannot be found.');
            end
          else Result := loVarable.Value;
        end
      else
        begin
          aOutput.LogError('Syntax Error: variable '+ lsValue + ' cannot be found.');
        end;
    end;
end;

function tTokenParser.GetNextToken: String;
Var
  lsToken: string;
  liTokenIndex: Integer;
begin
  lsToken := foCodeGeneratorItem.GetNextToken(True);
  liTokenIndex := foCodeGeneratorItem.TokenIndex;

  Result :=  tTokenParser.ParseToken(foCodeGeneratorItem, lsToken,
      (foCodeGeneratorItem.oProjectItem as TProjectItem), (foCodeGeneratorItem.oVariables as TVariables), oOutput, foCodeGeneratorItem.oTokens, liTokenIndex,
      foCodeGeneratorItem.oProject);

  Inc(liTokenIndex);

  foCodeGeneratorItem.TokenIndex := liTokenIndex;
end;

function tTokenParser.GetTokenIndex: Integer;
begin
  Result := foCodeGeneratorItem.TokenIndex;
end;

procedure tTokenParser.SetTokenIndex(Value: Integer);
begin
  foCodeGeneratorItem.TokenIndex := Value;
end;


end.
