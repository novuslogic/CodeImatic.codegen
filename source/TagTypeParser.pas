unit TagTypeParser;

interface

Uses TagType;

Type
   TTagTypeParser = class
   protected
   private
   public
     class function ParseTagType(aProjectItem: tObject;aToken1: string; aToken2: string): TTagType;
   end;

implementation

Uses Runtime, ProjectItem;

class function TTagTypeParser.ParseTagType(aProjectItem: tObject;aToken1: string; aToken2: string): TTagType;
begin
  if aToken1 = '' then
    begin
      result := ttunknown;

      exit;
    end;

  if aToken1= '' then
    result := ttunknown
  else
  if aToken1 = 'LANGUAGE' then
    Result := ttlanguage
  else
  if aToken1 = 'CONNECTION' then
    Result := ttConnection
  else
  if aToken1 = 'INCLUDE' then
    result := ttInclude
  else
  if aToken1 = 'PROJECTITEM' then
    result := ttprojectitem
  else
  if aToken1 = 'PROPERTIES' then
   begin
     Result := ttPropertyEx;
   end
  else
  if aToken1 = 'CONFIGPROPERTIES' then
   begin
     Result := ttConfigProperties;
   end
  else
  if aToken1 = 'VARIABLECMDLINE' then
   begin
     Result := ttVariableCmdLine;
   end
  else
  if (Assigned(aProjectItem) and Assigned((aProjectItem as tProjectItem).oProperties)) and ((aProjectItem as tProjectItem).oProperties.IsPropertyExists(aToken1)) then
    Result := ttProperty
  else
  if (oRuntime.oPlugins.IsTagExists(aToken1,aToken2 ) or oRuntime.oPlugins.IsPluginNameExists(aToken1)) then
    Result := ttplugintag
  else
    Result := ttInterpreter;
end;


end.
