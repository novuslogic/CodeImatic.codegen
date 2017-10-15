unit TagTypeParser;

interface

Uses TagType, SysUtils, output, Classes, TokenProcessor;

Type
  TTagTypeParser = class
  protected
  private
    class function InternalParseTagType(aProjectItem: tObject;
      aCodeGenerator: tObject; aToken: string; aTokens: tStringlist;
      aOutput: toutput; aTokenIndex: Integer = 0): TTagType;
  public
    class function ParseTagType(aProjectItem: tObject; aCodeGenerator: tObject;
      aToken: String; aOutput: toutput): TTagType; overload;

    class function ParseTagType(aProjectItem: tObject; aCodeGenerator: tObject;
      aTokens: tStringlist; aOutput: toutput; aTokenIndex: Integer): TTagType; overload;

  end;

implementation

Uses Runtime, ProjectItem, CodeGenerator, TokenParser, Variables;

class function TTagTypeParser.ParseTagType(aProjectItem: tObject; aCodeGenerator: tObject;
      aToken: String; aOutput: toutput): TTagType;
begin
   Result := TTagTypeParser.InternalParseTagType(aProjectItem,
       aCodeGenerator,aToken, NIL, aOutput);
end;

class function TTagTypeParser.ParseTagType(aProjectItem: tObject; aCodeGenerator: tObject;
      aTokens: tStringlist; aOutput: toutput; aTokenIndex: Integer): TTagType;
begin
  Result := TTagTypeParser.InternalParseTagType(aProjectItem,
       aCodeGenerator,'',aTokens, aOutput, aTokenIndex);
end;


class function TTagTypeParser.InternalParseTagType(aProjectItem: tObject;
  aCodeGenerator: tObject; aToken: string; aTokens: tStringlist;
  aOutput: toutput; aTokenIndex: Integer): TTagType;
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

    lsToken := FTokenProcessor.GetNextToken;

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

end.
