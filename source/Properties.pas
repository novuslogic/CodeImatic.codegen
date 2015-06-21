unit Properties;

interface

Uses NovusXMLBO, Classes, SysUtils, XMLlist, Project, MessagesLog;

Type
  tProperties = class(TXMLlist)
  protected
  private
    foProject: tProject;
    FoMesaagesLog: tMessagesLog;
  public
    function IsPropertyExists(APropertyName: String): Boolean;
    function GetProperty(APropertyName: String): String;

    property oProject: tProject
      read foProject
      write foProject;

    property oMessagesLog: tMessagesLog
      read FoMesaagesLog
      write FoMesaagesLog;
  end;

implementation


function tProperties.GetProperty(APropertyName: String): String;
var
  lsGetProperty: String;
begin
  lsGetProperty := GetFieldAsString(oXMLDocument.Root, APropertyName);
  Try
    if foProject.oProjectConfig.IsLoaded then
      lsGetProperty := foProject.oProjectConfig.Parseproperties(lsGetProperty);
  Except
    FoMesaagesLog.Writelog(APropertyName + ' Projectconfig error.');
  End;

  Result := lsGetProperty;
end;

function tProperties.IsPropertyExists(APropertyName: String): Boolean;
Var
  I: integer;
begin
  Result := False;

  for i := 0 to NodeNames.Count - 1 do
    begin
      If Uppercase(NodeNames.Strings[i]) = Uppercase(APropertyName) then
        begin
          Result := True;

          Exit;
        end;
    end;
end;

end.
