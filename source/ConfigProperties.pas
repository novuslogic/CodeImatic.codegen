unit ConfigProperties;

interface

uses JvSimpleXml, NovusSimpleXML, SysUtils;

type
  TConfigProperties = class(Tobject)
  private
     foProperties: TJvSimpleXmlElem;
  protected
  public
     function IsPropertyExists(APropertyName: String): Boolean;
     function GetProperty(APropertyName: String): String;

     property oProperties: TJvSimpleXmlElem
        read  foProperties
        write foProperties;
  end;

implementation

function TConfigProperties.IsPropertyExists(APropertyName: String): Boolean;
Var
  I: integer;
  foProperty: TJvSimpleXmlElem;
begin
  Result := False;

  for i := 0 to foProperties.Items.Count - 1 do
    begin
      foProperty := foProperties.Items[i];

      If Uppercase(foProperty.Name) = Uppercase(APropertyName) then
        begin
          Result := True;

          Exit;
        end;
    end;
end;

function TConfigProperties.GetProperty(APropertyName: String): String;
Var
  I: integer;
  foProperty: TJvSimpleXmlElem;
begin
  Result := '';

  for i := 0 to foProperties.Items.Count - 1 do
    begin
      foProperty := foProperties.Items[i];

      If Uppercase(foProperty.Name) = Uppercase(APropertyName) then
        begin
          Result := foProperty.Value;

          Exit;
        end;
    end;
end;


end.
