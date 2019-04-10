unit TagType;

interface

Type
  TTagType = (ttProperty, ttConnection, ttInterpreter, ttLanguage, ttInclude,
    ttUnknown, ttplugintag, ttprojectitem, ttPropertyEx, ttConfigProperties,
    ttVariableCmdLine, ttlayout, ttRenderBodyTag, ttCodebehine,
    ttOpenToken, ttCloseToken, ttrepeat, ttendrepeat, ttcode, ttif, ttendif, ttlog, ttComment);

  function IsInterpreterTagType(aTagType: tTagType): Boolean;





implementation


function IsInterpreterTagType(aTagType: tTagType): Boolean;
begin
  Result := False;
  if ATagType in [ttInterpreter, ttRepeat, ttEndRepeat, ttEndif, ttIf,ttLog, ttplugintag, ttComment ] then
      Result := True;
end;


end.
