unit List;

interface

Uses NovusXMLBO, Classes, SysUtils;

Type
  tReservelist = class(TNovusXMLBO)
  protected
  private
  public
    function IsWordExists(AReserveWord: String): Boolean;
    function GetWord(AReserveWord: String): String;
  end;

implementation


function tReservelist.GetWord(AReserveWord: String): String;
begin
  Result := GetFieldAsString(oXMLDocument.Root, AReserveWord);
end;

function tReservelist.IsWordExists(AReserveWord: String): Boolean;
Var
  I: integer;
begin
  Result := False;

  for i := 0 to NodeNames.Count - 1 do
    begin
      If Uppercase(NodeNames.Strings[i]) = Uppercase(AReserveWord) then
        begin
          Result := True;

          Exit;
        end;
    end;
end;

end.
