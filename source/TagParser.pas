unit TagParser;

interface

Uses TagType, SysUtils, output, Classes, TokenProcessor, NovusStringUtils;

Type
  TTagParser = class(Tobject)
  protected
  private
    foProjectItem : tObject;
    foCodeGenerator : tObject;
    fsToken : String;
    foOutput: tOutput;
    FoTokenProcessor: tTokenProcessor;

    function InternalParseTag(aProjectItem: tObject;
      aCodeGenerator: tObject; aToken: string; aTokens: tTokenProcessor;
      aOutput: toutput; aTokenIndex: Integer; aIsTokens: Boolean): TTagType;
  public
    constructor Create(aProjectItem: tObject; aCodeGenerator: tObject;
      aToken: String; aOutput: toutput); overload;

    destructor Destroy; override;

    function Execute: boolean;

    property oTokenProcessor: tTokenProcessor
       read foTokenProcessor
       write foTokenProcessor;

    class function ParseTag(aProjectItem: tObject; aCodeGenerator: tObject;
      aTag: String; aOutput: toutput): TTagParser;


    class function ParseTagType(aProjectItem: tObject; aCodeGenerator: tObject;
      aTag: String; aOutput: toutput; aIsTokens: Boolean): TTagType; overload;

    class function ParseTagType(aProjectItem: tObject; aCodeGenerator: tObject;
      aTokens: tTokenProcessor; aOutput: toutput; aTokenIndex: Integer): TTagType; overload;

  end;

implementation

Uses Runtime, ProjectItem, CodeGenerator, TokenParser, Variables;


constructor TTagParser.Create(aProjectItem: tObject; aCodeGenerator: tObject;
      aToken: String; aOutput: toutput);
begin
  foProjectItem := aProjectItem;
  foCodeGenerator := aCodeGenerator;
  fsToken := aToken;

  foOutput:= aOutput;

  FoTokenProcessor := NIL;

end;

destructor TTagParser.Destroy;
Var
I: integer;
begin
  if Assigned(FoTokenProcessor) then
    begin
      TNovusStringUtils.ClearStringlist(FoTokenProcessor);



      FoTokenProcessor.Free;
    end;


  inherited;
end;



function TTagParser.Execute: boolean;
var
  lsToken: String;
  lTagType: TTagType;
  liTokenIndex: Integer;
  loTokenProcessorItem: tTokenProcessorItem;
begin
  result := False;

  Try
    FoTokenProcessor := tTokenParser.ParseExpressionToken(fsToken, foOutput);
    liTokenIndex := FoTokenProcessor.TokenIndex;
    lsToken := FoTokenProcessor.GetFirstToken;
    While(not FoTokenProcessor.EOF) do
      begin
        lTagType :=  InternalParseTag(foProjectItem,
          foCodeGenerator, lsToken, NIL, foOutput, liTokenIndex, false);

        loTokenProcessorItem:= tTokenProcessorItem.Create;

        loTokenProcessorItem.Token := lsToken;
        loTokenProcessorItem.TagType := lTagType;

        FoTokenProcessor.Objects[liTokenIndex] := loTokenProcessorItem;


        liTokenIndex := FoTokenProcessor.TokenIndex;
        lsToken := FoTokenProcessor.GetNextToken;
      end;


  Finally

  End;
end;


class function TTagParser.ParseTagType(aProjectItem: tObject; aCodeGenerator: tObject;
      aTag: String; aOutput: toutput; aIsTokens: Boolean): TTagType;
var
  lTagParser: TTagParser;
begin
  Result := TTagType.ttUnknown;

  Try
    Try
      lTagParser := TTagParser.ParseTag(aProjectItem, aCodeGenerator, '', aOutput);

      Result := lTagParser.InternalParseTag(aProjectItem,
       aCodeGenerator,aTag, NIL, aOutput, 0, aIsTokens);
    Finally
      lTagParser.Free;
    End;
  except
    aOutput.InternalError;
  End;
end;


class function TTagParser.ParseTagType(aProjectItem: tObject; aCodeGenerator: tObject;
      aTokens: tTokenProcessor; aOutput: toutput; aTokenIndex: Integer): TTagType;
var
  lTagParser: TTagParser;
begin
  Result := TTagType.ttUnknown;

  Try
    Try
      lTagParser := TTagParser.ParseTag(aProjectItem, aCodeGenerator, '', aOutput);

      Result := lTagParser.InternalParseTag(aProjectItem,
         aCodeGenerator,'',aTokens, aOutput, aTokenIndex, false);
    Finally
      lTagParser.Free;
    End;
  except
    aOutput.InternalError;
  End;

end;




function TTagParser.InternalParseTag(aProjectItem: tObject;
  aCodeGenerator: tObject; aToken: string; aTokens: tTokenProcessor;
  aOutput: toutput; aTokenIndex: Integer; aIsTokens: Boolean): TTagType;
var
  FTokenProcessor: tTokenProcessor;
  lsToken, lsToken1, lsToken2: string;
  foOutput: toutput;
begin
  if Assigned(aTokens) then
    begin
      if aTokens.Count = 0 then
      begin
        result := ttunknown;

        exit;
      end;

      lsToken1 := TVariables.CleanVariableName(Uppercase(aTokens.Strings[aTokenIndex]));

      if (aTokens.Count > 1) and (aTokenIndex <= aTokens.Count -1) then
        lsToken2 := TVariables.CleanVariableName(Uppercase(aTokens.Strings[aTokenIndex + 1]));
    end
  else
    begin
      if aToken = '' then
      begin
        result := ttunknown;

        exit;
      end;

      lsToken1 := Uppercase(aToken);
    end;


  Try
    FTokenProcessor := tTokenParser.ParseExpressionToken(lsToken1, aOutput);

    lsToken := Uppercase(FTokenProcessor.GetNextToken);

    if lsToken = '' then
      result := ttunknown
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
    else if ((lsToken ='<') and (aTokenIndex = 0)) then
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


class function TTagParser.ParseTag(aProjectItem: tObject; aCodeGenerator: tObject;
      aTag: String; aOutput: toutput): TTagParser;
begin
  Result := TTagParser.Create(aProjectItem,aCodeGenerator, aTag, aOutput);
end;

end.
