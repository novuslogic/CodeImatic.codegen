unit Reservelist;

interface

Uses NovusXMLBO, Classes, SysUtils, XMLlist;

Type
  tReservelist = class(TXMLlist)
  protected
  private
  public
    function IsReserveWordExists(AReserveWord: String): Boolean;
    function GetReserveWord(AReserveWord: String): String;
  end;

implementation


function tReservelist.GetReserveWord(AReserveWord: String): String;
begin
  Result := GetFieldAsString(oXMLDocument.Root, AReserveWord);
end;

function tReservelist.IsReserveWordExists(AReserveWord: String): Boolean;
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
