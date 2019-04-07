unit TokenParser;

interface

uses ProjectItem, system.Classes, Project, Variables, output, SysUtils, TagType,
  NovusStringUtils, TokenProcessor, CodeGeneratorItem;

type
  TEventParseTokenParameter = procedure(var aToken: string) of object;

  tTokenParser = class(Tobject)
  protected
    fsTagName: String;
    foTokens: tTokenProcessor;
    foOutput: TOutput;
    foProjectItem: tProjectItem;
    foVariables: TVariables;
  private
    function GetTokenIndex: Integer;
    procedure SetTokenIndex(Value: Integer);
    function GetEOF: Boolean;
  public
    constructor Create(aProjectItem: tProjectItem;aTokens: tTokenProcessor;
      aOutput: TOutput; aTagName: String =''); overload;

    class function ParseToken(aObject: Tobject; aToken: String;
      aProjectItem: tProjectItem; aOutput: TOutput;
      ATokens: tTokenProcessor; Var aTokenIndex: Integer;
      aProject: TProject;
      aUseInterpreter : boolean = false): String;

    class function ParseSimpleToken(aToken: string; aOutput: TOutput)
      : tTokenProcessor;
    class function ParseExpressionToken(aObject: Tobject; aToken: String;
      aProjectItem: tProjectItem; aProject: TProject; (*aVariables: TVariables; *)
      aOutput: TOutput): tTokenProcessor; overload;
    class function ParseExpressionToken(aToken: string; aOutput: TOutput)
      : tTokenProcessor; overload;

    function ParseNextToken(aIgnoreEOF: boolean = false): String;

    function NextToken: string;


    //property oCodeGeneratorItem: TCodeGeneratorItem read foCodeGeneratorItem;

    property oTokens: tTokenProcessor read foTokens write foTokens;

    property oOutput: TOutput read foOutput;

    property oProjectItem: tProjectItem read foProjectItem;

    property oVariables: TVariables read foVariables write foVariables ;

    property TokenIndex: Integer read GetTokenIndex write SetTokenIndex;

    property EOF: Boolean read GetEOF;
  end;

implementation

uses CodeGenerator, Runtime, Interpreter, Config, ExpressionParser,
  TagParser;

class function tTokenParser.ParseSimpleToken(aToken: string; aOutput: TOutput)
  : tTokenProcessor;
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

    While (liPos < Length(aToken)) Do
    begin
      lsToken := TNovusStringUtils.GetStrToken(aToken, [OpEqual, OpQuote],
        liPos, lsLastToken);
      Inc(liPos);

      Result.Add(lsToken);

      if lsLastToken = OpEqual then
        Result.Add(lsLastToken);
    end;
  Except
    aOutput.InternalError;
  End;
end;

class function tTokenParser.ParseExpressionToken(aObject: Tobject;
  aToken: String; aProjectItem: tProjectItem; aProject: TProject;
  (*aVariables: TVariables;*) aOutput: TOutput): tTokenProcessor;
Var
  LExpressionParser: tExpressionParser;
  I: Integer;
  lsNewToken: string;
  FiIndex: Integer;
begin
  Result := NIL;

  if not Assigned(aProject) or Not Assigned(aProjectItem) then
    Exit;

  Try
    Result := tTokenProcessor.Create;

    LExpressionParser := tExpressionParser.Create;

    LExpressionParser.Expr := aToken;

    LExpressionParser.ListTokens(Result);

    for I := 0 to Result.Count - 1 do
    begin
      FiIndex := 0;
      Result.Strings[I] := ParseToken(aObject, Result.Strings[I], aProjectItem,
        (*aVariables,*) aOutput, NIL, FiIndex, aProject);
    end;
  Except
    aOutput.InternalError;
  End;
end;

class function tTokenParser.ParseExpressionToken(aToken: string;
  aOutput: TOutput): tTokenProcessor;
Var
  LExpressionParser: tExpressionParser;
  I: Integer;
  lsNewToken: string;
  FiIndex: Integer;
begin
  Result := NIL;

  if Trim(aToken) = '' then
    Exit;



  Try
    Result := tTokenProcessor.Create;

    LExpressionParser := tExpressionParser.Create;

    LExpressionParser.Expr := aToken;

    LExpressionParser.ListTokens(Result);

  Except
    aOutput.InternalError;
  End;
end;

constructor tTokenParser.Create(aProjectItem: tProjectItem;aTokens: tTokenProcessor;
  aOutput: TOutput; aTagName: String ='');
begin
  fsTagName := aTagName;
  foProjectItem:= aProjectItem;

  foTokens := aTokens;
  foOutput := aOutput;

  //foCodeGeneratorItem.TokenIndex := 0;
end;

class function tTokenParser.ParseToken;
var
  fsToken: String;
  LExpressionParser: tExpressionParser;
  lTokens: tTokenProcessor;
  lTagType: tTagType;
  lsValue: String;
  loVarable: tVariable;
  lsToken1, lsToken2: string;
  lVariable: tVariable;
  loTokens: TTokenProcessor;
begin
  Result := aToken;

  loTokens := NIL;

  If Copy(aToken, 1, 2) = '$$' then
  begin
    fsToken := TVariables.CleanVariableName(aToken);

    if aObject is tInterpreter then
    begin
      lsToken1 := fsToken;

      lTagType := TTagParser.ParseTagType(aProjectItem, NIL,
        lsToken1, aOutput, false);
    end
    else if aObject is TCodeGenerator then
    begin
      Try
        lTokens := tTokenProcessor.Create;

        LExpressionParser := tExpressionParser.Create;

        LExpressionParser.Expr := fsToken;

        LExpressionParser.ListTokens(lTokens);

        if lTokens.Count > 0 then
        begin
          lsToken1 := Uppercase(lTokens.Strings[0]);
          if lTokens.Count > 1 then
            lsToken2 := Uppercase(lTokens.Strings[1]);
        end;

      lTagType := TTagParser.ParseTagType(aProjectItem,
        (aObject as TCodeGenerator), lTokens, aOutput, 0);
      Finally
        LExpressionParser.Free;
        lTokens.Free;
      End;


    end



    else
      lTagType := TTagParser.ParseTagType(aProjectItem, NIL, ATokens,
        aOutput, aTokenIndex);

    case lTagType of
      ttProperty:
        Result := aProjectItem.oProperties.GetProperty(fsToken);
      ttPropertyEx:
        begin
          //if aObject is tInterpreter then
          //begin
           // lsToken2 := tInterpreter(aObject).GetNextTokenA(aTokenIndex,
           //   ATokens);

          //end
          ATokens.TokenIndex := aTokenIndex + 1;

          lsToken2 := ATokens.GetNextToken(false);

          aTokenIndex := ATokens.TokenIndex;

          if lsToken2 <> '' then
          begin
            Result := aProjectItem.oProperties.GetProperty(lsToken2);
          end;
        end;
      ttprojectitem:
        begin
          Result := aProjectItem.GetProperty(lsToken2, aProject);

        end;
      ttplugintag:
        begin
          if aObject is tInterpreter then
          begin
            lsToken2 := tInterpreter(aObject).GetNextTokenA(aTokenIndex,
              ATokens);
            if Assigned(tInterpreter(aObject).oTokens) then
              loTokens :=
                TTokenProcessor(tInterpreter(aObject).oTokens);
          end
          else
          if aObject is tTokenProcessor then loTokens := (aObject as tTokenProcessor);

          if oRuntime.oPlugins.IsTagExists(lsToken1, lsToken2) then
          begin
            Result := oRuntime.oPlugins.GetTag(lsToken1, lsToken2,
              loTokens, (*aTokenIndex,*) aProjectItem);
          end;
        end;
      ttVariableCmdLine:
        begin
          lsToken2 := ATokens.GetNextToken(True);

          aTokenIndex := ATokens.TokenIndex;

          lVariable := oConfig.oVariablesCmdLine.GetVariableByName(lsToken2);

          if Assigned(lVariable) then
            Result := lVariable.Value;

        end;


      ttConfigProperties:
        begin
          lsToken2 := ATokens.GetNextToken(ATokens.TokenIndex + 2);

          aTokenIndex := ATokens.TokenIndex;

          if Assigned(aProject) then
            Result := aProject.oProjectConfig.Getproperties(lsToken2);
        end;

      ttUnknown:
        begin
          aOutput.LogError('Syntax Error: Tag ' + lsToken1 +
            ' cannot be found.');

        end;
    end;
  end
  else If Copy(aToken, 1, 1) = '$' then
  begin
    lsValue := TVariables.CleanVariableName(aToken);
    if Assigned(aProjectItem.oVariables) then
    begin
      loVarable := aProjectItem.oVariables.GetVariableByName(lsValue);
      if Not Assigned(loVarable) then
      begin
        aOutput.LogError('Syntax Error: variable ' + lsValue +
          ' cannot be found.');
      end
      else
        Result := loVarable.Value;
    end
    else
    begin
      aOutput.LogError('Syntax Error: variable ' + lsValue +
        ' cannot be found.');
    end;
  end;
  if aUseInterpreter then
    begin
      lTagType := TTagParser.ParseTagType(aProjectItem, NIL, ATokens,
        aOutput, aTokenIndex);

      case lTagType of
        ttProperty:
          Result := aProjectItem.oProperties.GetProperty(fsToken);
        ttPropertyEx:
          begin
            if aObject is tInterpreter then
            begin
              lsToken2 := tInterpreter(aObject).GetNextTokenA(aTokenIndex,
                ATokens);

            end;

            if lsToken2 <> '' then
            begin
              Result := aProjectItem.oProperties.GetProperty(lsToken2);
            end;
          end;
        ttprojectitem:
          begin
            Result := aProjectItem.GetProperty(lsToken2, aProject);

          end;
        ttplugintag:
          begin
            if aObject Is TTokenProcessor then
              begin
                lsToken1 := aToken;
                ATokens.TokenIndex := aTokenIndex + 1;
                lsToken2 := ATokens.GetNextToken;
                aTokenIndex := ATokens.TokenIndex;
                loTokens := TTokenProcessor(aObject);

              end
            else
            if aObject is tInterpreter then
            begin
              lsToken2 := tInterpreter(aObject).GetNextTokenA(aTokenIndex,
                ATokens);
              if Assigned(tInterpreter(aObject).oTokens) then
                loTokens :=
                  TTokenProcessor(tInterpreter(aObject).oTokens);
            end;

            if oRuntime.oPlugins.IsTagExists(lsToken1, lsToken2) then
            begin
              Result := oRuntime.oPlugins.GetTag(lsToken1, lsToken2,
                loTokens, (*aTokenIndex,*) aProjectItem);

              //aTokenIndex := aTokenIndex - 1;
              aTokenIndex :=  ATokens.TokenIndex;
            end;
          end;
        ttVariableCmdLine:
          begin
            lsToken2 := ATokens.GetNextToken(True);

            aTokenIndex := ATokens.TokenIndex;

            lVariable := oConfig.oVariablesCmdLine.GetVariableByName(lsToken2);

            if Assigned(lVariable) then
              Result := lVariable.Value;

          end;

        ttConfigProperties:
          begin
            (*
            lsToken2 := ATokens.GetNextToken(ATokens.TokenIndex + 1);

            aTokenIndex := ATokens.TokenIndex;

            if Assigned(aProject) then
              Result := aProject.oProjectConfig.Getproperties(lsToken2);
              *)
          end;


      end;

    end;

end;

function tTokenParser.ParseNextToken(aIgnoreEOF: boolean = false): String;
Var
  lsToken: string;
  liTokenIndex: Integer;
begin
  lsToken := foTokens.GetNextToken(True);
  liTokenIndex := foTokens.TokenIndex;

  Result := tTokenParser.ParseToken(foTokens, lsToken,
    (foProjectItem as tProjectItem),
     oOutput,
    foTokens, liTokenIndex, (foProjectItem as tProjectItem).oProject,
    true);

  Inc(liTokenIndex);

  foTokens.TokenIndex := liTokenIndex;

  if aIgnoreEOF = false then
    begin
     if foTokens.EOF then
       foTokens.TokenIndex := foTokens.Count -1;
    end;
end;

function tTokenParser.NextToken: String;
begin
  Result := foTokens.GetNextToken;

  if foTokens.EOF then
     foTokens.TokenIndex := foTokens.Count -1;

end;


function tTokenParser.GetTokenIndex: Integer;
begin
  Result := foTokens.TokenIndex;
end;

procedure tTokenParser.SetTokenIndex(Value: Integer);
begin
  foTokens.TokenIndex := Value;
end;

function tTokenParser.GetEOF: Boolean;
begin
  Result := foTokens.EOF;
end;

end.
