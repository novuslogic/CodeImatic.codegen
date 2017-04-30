unit TagTypeParser;

interface

Uses TagType, SysUtils;

Type
  TTagTypeParser = class
  protected
  private
  public
    class function ParseTagType(aProjectItem: tObject; aCodeGenerator: tObject;
      aToken1: string; aToken2: string): TTagType;
  end;

implementation

Uses Runtime, ProjectItem, CodeGenerator, TokenParser;

class function TTagTypeParser.ParseTagType(aProjectItem: tObject;
  aCodeGenerator: tObject; aToken1: string; aToken2: string): TTagType;
var
  FTokenProcessor : tTokenProcessor;
  lsToken: string;
begin
  if aToken1 = '' then
  begin
    result := ttunknown;

    exit;
  end;


  Try
    FTokenProcessor := tTokenParser.ParseExpressionToken(aToken1);

    lsToken := FTokenProcessor.GetNextToken;

    if lsToken = '' then
      result := ttunknown
    else
    if lsToken = 'LANGUAGE' then
      result := ttlanguage
    else
    if  lsToken = 'CONNECTION' then
      result := ttConnection
    else
    if lsToken = 'LAYOUT' then
      result := ttLayout
    else
    if Uppercase(lsToken) = 'INCLUDE' then
       result := ttInclude
    else
    if Uppercase(lsToken) = 'PROJECTITEM' then
       result := ttprojectitem
    else
    if Uppercase(lsToken) = 'PROPERTIES' then
      result := ttPropertyEx
    else
    if Uppercase(lsToken) = 'CONFIGPROPERTIES' then
     result := ttConfigProperties
    else
    if Uppercase(aToken1) = 'VARIABLECMDLINE' then
      result := ttVariableCmdLine
    else
    if (Assigned(aProjectItem) and
        Assigned((aProjectItem as tProjectItem).oProperties)) and
        ((aProjectItem as tProjectItem).oProperties.IsPropertyExists(lsToken)) then
      result := ttProperty
    else
    if (oRuntime.oPlugins.IsTagExists(lsToken, aToken2 (* FTokenProcessor.GetNextToken*)) or
        oRuntime.oPlugins.IsPluginNameExists(lsToken)) then
    result := ttplugintag
  else
  if Assigned(aCodeGenerator) and
    (Uppercase(TCodeGenerator(aCodeGenerator).renderbodytag) = Uppercase(lsToken)) then
    result := ttRenderBodyTag
  else
    result := ttInterpreter;

  Finally
    FTokenProcessor.Free;
  End;


  (*
  if aToken1 = '' then
    result := ttunknown
  else if aToken1 = 'LANGUAGE' then
    result := ttlanguage
  else if aToken1 = 'CONNECTION' then
    result := ttConnection
  else if aToken1 = 'LAYOUT' then
    result := ttLayout
  else if Uppercase(aToken1) = 'INCLUDE' then
    result := ttInclude
  else if Uppercase(aToken1) = 'PROJECTITEM' then
    result := ttprojectitem
  else if Uppercase(aToken1) = 'PROPERTIES' then
  begin
    result := ttPropertyEx;
  end
  else if Uppercase(aToken1) = 'CONFIGPROPERTIES' then
  begin
    result := ttConfigProperties;
  end
  else if Uppercase(aToken1) = 'VARIABLECMDLINE' then
  begin
    result := ttVariableCmdLine;
  end
  else if (Assigned(aProjectItem) and Assigned((aProjectItem as tProjectItem)
    .oProperties)) and ((aProjectItem as tProjectItem)
    .oProperties.IsPropertyExists(aToken1)) then
    result := ttProperty
  else if (oRuntime.oPlugins.IsTagExists(aToken1, aToken2) or
    oRuntime.oPlugins.IsPluginNameExists(aToken1)) then
    result := ttplugintag
  else if Assigned(aCodeGenerator) and
    (Uppercase(TCodeGenerator(aCodeGenerator).renderbodytag)
    = Uppercase(aToken1)) then
    result := ttRenderBodyTag
  else
    result := ttInterpreter;
    *)
end;

end.
