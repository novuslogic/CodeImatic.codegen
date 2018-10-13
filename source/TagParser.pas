unit TagParser;

interface

Uses TagType, SysUtils, output, Classes, TokenProcessor, NovusStringUtils;

Type
  TTagParser = class(Tobject)
  protected
  private
    foProjectItem: Tobject;
    foCodeGenerator: Tobject;
    fsToken: String;
    foOutput: tOutput;
    FoTokenProcessor: tTokenProcessor;

    function InternalParseTag(aProjectItem: Tobject; aCodeGenerator: Tobject;
      aToken: string; aTokens: tTokenProcessor; aOutput: tOutput;
      aTokenIndex: Integer; aIsTokens: Boolean): TTagType;
  public
    constructor Create(aProjectItem: Tobject; aCodeGenerator: Tobject;
      aToken: String; aOutput: tOutput); overload;

    destructor Destroy; override;

    function IsAnyDeleteLine: Boolean;

    function Execute: Boolean;

    property oTokenProcessor: tTokenProcessor read FoTokenProcessor
      write FoTokenProcessor;

    class function ParseTag(aProjectItem: Tobject; aCodeGenerator: Tobject;
      aTag: String; aOutput: tOutput): TTagParser;

    class function ParseTagType(aProjectItem: Tobject; aCodeGenerator: Tobject;
      aTag: String; aOutput: tOutput; aIsTokens: Boolean): TTagType; overload;

    class function ParseTagType(aProjectItem: Tobject; aCodeGenerator: Tobject;
      aTokens: tTokenProcessor; aOutput: tOutput; aTokenIndex: Integer)
      : TTagType; overload;

  end;

implementation

Uses Runtime, ProjectItem, CodeGenerator, TokenParser, Variables;

constructor TTagParser.Create(aProjectItem: Tobject; aCodeGenerator: Tobject;
  aToken: String; aOutput: tOutput);
begin
  foProjectItem := aProjectItem;
  foCodeGenerator := aCodeGenerator;
  fsToken := aToken;

  foOutput := aOutput;

  FoTokenProcessor := NIL;

end;

destructor TTagParser.Destroy;
Var
  I: Integer;
begin
  if Assigned(FoTokenProcessor) then
  begin
    TNovusStringUtils.ClearStringlist(FoTokenProcessor);

    FoTokenProcessor.Free;
  end;

  inherited;
end;

function TtagParser.IsAnyDeleteLine: Boolean;
var
  loTokenProcessorItem: tTokenProcessorItem;
begin
  Result := False;

  (*
  if Not Assigned(FoTokenProcessor)  then Exit;

  loTokenProcessorItem := FoTokenProcessor.GetFirstTokenProcessorItem;
  While (not FoTokenProcessor.EOF) do
    begin
      loTokenProcessorItem  := FoTokenProcessor.GetNextTokenProcessorItem;
    end;
  *)
end;

function TTagParser.Execute: Boolean;
var
  lsToken: String;
  lTagType: TTagType;
  liTokenIndex: Integer;
  loTokenProcessorItem: tTokenProcessorItem;
begin
  result := False;

  Try
    if not Assigned(FoTokenProcessor) then
      FoTokenProcessor := tTokenParser.ParseExpressionToken(fsToken, foOutput)
    else
      FoTokenProcessor.TokenIndex := 0;

    FoTokenProcessor := tTokenParser.ParseExpressionToken(fsToken, foOutput);
    liTokenIndex := FoTokenProcessor.TokenIndex;
    lsToken := FoTokenProcessor.GetFirstToken;
    While (not FoTokenProcessor.EOF) do
    begin
      lTagType := InternalParseTag(foProjectItem, foCodeGenerator, lsToken, NIL,
        foOutput, liTokenIndex, False);

      loTokenProcessorItem := tTokenProcessorItem.Create;

      loTokenProcessorItem.Token := lsToken;
      loTokenProcessorItem.TagType := lTagType;

      FoTokenProcessor.Objects[liTokenIndex] := loTokenProcessorItem;

      liTokenIndex := FoTokenProcessor.TokenIndex;
      lsToken := FoTokenProcessor.GetNextToken;
    end;

  Finally
    result := (FoTokenProcessor.Count <> 0);
  End;
end;

class function TTagParser.ParseTagType(aProjectItem: Tobject;
  aCodeGenerator: Tobject; aTag: String; aOutput: tOutput; aIsTokens: Boolean)
  : TTagType;
var
  lTagParser: TTagParser;
begin
  result := TTagType.ttUnknown;

  Try
    Try
      lTagParser := TTagParser.ParseTag(aProjectItem, aCodeGenerator,
        '', aOutput);

      result := lTagParser.InternalParseTag(aProjectItem, aCodeGenerator, aTag,
        NIL, aOutput, 0, aIsTokens);
    Finally
      lTagParser.Free;
    End;
  except
    aOutput.InternalError;
  End;
end;

class function TTagParser.ParseTagType(aProjectItem: Tobject;
  aCodeGenerator: Tobject; aTokens: tTokenProcessor; aOutput: tOutput;
  aTokenIndex: Integer): TTagType;
var
  lTagParser: TTagParser;
begin
  result := TTagType.ttUnknown;

  Try
    Try
      lTagParser := TTagParser.ParseTag(aProjectItem, aCodeGenerator,
        '', aOutput);

      result := lTagParser.InternalParseTag(aProjectItem, aCodeGenerator, '',
        aTokens, aOutput, aTokenIndex, False);
    Finally
      lTagParser.Free;
    End;
  except
    aOutput.InternalError;
  End;

end;

function TTagParser.InternalParseTag(aProjectItem: Tobject;
  aCodeGenerator: Tobject; aToken: string; aTokens: tTokenProcessor;
  aOutput: tOutput; aTokenIndex: Integer; aIsTokens: Boolean): TTagType;
var
  FTokenProcessor: tTokenProcessor;
  lsToken, lsToken1, lsToken2: string;
  foOutput: tOutput;
begin
  if Assigned(aTokens) then
  begin
    if aTokens.Count = 0 then
    begin
      result := ttUnknown;

      exit;
    end;

    lsToken1 := TVariables.CleanVariableName
      (Uppercase(aTokens.Strings[aTokenIndex]));

      (*

      This need to be fixed for second token need new system
    if (aTokens.Count > 1) and (aTokenIndex <= aTokens.Count - 1) then
      lsToken2 := TVariables.CleanVariableName
        (Uppercase(aTokens.Strings[aTokenIndex + 1]));*)
  end
  else
  begin
    if aToken = '' then
    begin
      result := ttUnknown;

      exit;
    end;

    lsToken1 := Uppercase(aToken);
  end;

  Try
    FTokenProcessor := tTokenParser.ParseExpressionToken(lsToken1, aOutput);

    lsToken := Uppercase(FTokenProcessor.GetNextToken);

    if lsToken = '' then
      result := ttUnknown
    else if lsToken = 'LANGUAGE' then
      result := ttlanguage
    else if lsToken = 'CONNECTION' then
      result := ttConnection
    else if lsToken = 'LAYOUT' then
      result := ttLayout
    else if Uppercase(lsToken) = 'INCLUDE' then
      result := ttInclude
    else if Uppercase(lsToken) = 'PROJECTITEM' then
      result := ttprojectitem
    else if Uppercase(lsToken) = 'PROPERTIES' then
      result := ttPropertyEx
    else if Uppercase(lsToken) = 'CONFIGPROPERTIES' then
      result := ttConfigProperties
    else if Uppercase(lsToken1) = 'VARIABLECMDLINE' then
      result := ttVariableCmdLine
    else if Uppercase(lsToken1) = 'CODEBEHINE' then
      result := ttCodebehine
    else if Uppercase(lsToken1) = 'CODE' then
      result := ttCode
    else if ((lsToken = '<') and (aTokenIndex = 0)) then
      result := ttOpenToken
    else if ((lsToken = '>') and (EOF = true)) then
      result := ttCloseToken
    else if (Assigned(aProjectItem) and Assigned((aProjectItem as tProjectItem)
      .oProperties)) and ((aProjectItem as tProjectItem)
      .oProperties.IsPropertyExists(lsToken)) then
      result := ttProperty
    else if Assigned(oRuntime.oPlugins) and
      (oRuntime.oPlugins.IsTagExists(lsToken,
      lsToken2 (* FTokenProcessor.GetNextToken *) ) or
      oRuntime.oPlugins.IsPluginNameExists(lsToken)) then
      result := ttplugintag
    else if Assigned(aCodeGenerator) and
      (Uppercase(TCodeGenerator(aCodeGenerator).renderbodytag)
      = Uppercase(lsToken)) then
      result := ttRenderBodyTag
    else
      result := ttInterpreter;

  Finally
    FTokenProcessor.Free;
  End;
end;

class function TTagParser.ParseTag(aProjectItem: Tobject;
  aCodeGenerator: Tobject; aTag: String; aOutput: tOutput): TTagParser;
begin
  result := TTagParser.Create(aProjectItem, aCodeGenerator, aTag, aOutput);
end;

end.
