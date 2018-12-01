unit TagType;

interface

Type
  TTagType = (ttProperty, ttConnection, ttInterpreter, ttLanguage, ttInclude,
    ttUnknown, ttplugintag, ttprojectitem, ttPropertyEx, ttConfigProperties,
    ttVariableCmdLine, ttlayout, ttRenderBodyTag, ttCodebehine,
    ttOpenToken, ttCloseToken, ttrepeat, ttendrepeat, ttcode, ttif, ttendif);

  function IsInterpreterTagType(aTagType: tTagType): Boolean;

implementation


function IsInterpreterTagType(aTagType: tTagType): Boolean;
begin
  Result := False;
  if ATagType in [ttInterpreter, ttRepeat, ttEndRepeat, ttEndif, ttIf] then
      Result := True;
end;


end.
