unit Snippits;

interface

Uses NovusXMLBO, Classes, SysUtils, XMLlist;

Type
  tSnippits = class(tXMLlist)
  protected
  private
  public
    function IsSnippitNameExists(ASnippitName: String): Boolean;
  end;

implementation

function tSnippits.IsSnippitNameExists(ASnippitName: String): Boolean;
Var
  I: integer;
begin
  Result := False;

  for i := 0 to NodeNames.Count - 1 do
    begin
      If Uppercase(NodeNames.Strings[i]) = Uppercase(ASnippitName) then
        begin
          Result := True;

          Exit;
        end;
    end;
end;


end.
