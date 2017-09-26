unit ConfigProperties;

interface

uses JvSimpleXml, NovusSimpleXML, SysUtils;

type
  TConfigProperties = class(Tobject)
  private
     foRootProperties: TJvSimpleXmlElem;
  protected
  public
     constructor Create(aRootProperties: TJvSimpleXmlElem);

     function IsPropertyExistsEx(APropertyName: String; aProperties: TJvSimpleXmlElem = NIL): TJvSimpleXmlElem;
     function IsPropertyExists(APropertyName: String; aProperties: TJvSimpleXmlElem = NIL): Boolean;
     function GetProperty(APropertyName: String; aProperties: TJvSimpleXmlElem = NIL): String;

     property oRootProperties: TJvSimpleXmlElem
        read  foRootProperties;
  end;

implementation

constructor TConfigProperties.Create(aRootProperties: TJvSimpleXmlElem);
begin
  foRootProperties := aRootProperties;
end;


function TConfigProperties.IsPropertyExistsEx(APropertyName: String; aProperties: TJvSimpleXmlElem): TJvSimpleXmlElem;
Var
  I: integer;
  loProperty,
  loProperties: TJvSimpleXmlElem;
begin
  Result := NIL;

  if Not Assigned(aProperties) then
    loProperties := foRootProperties
  else
    loProperties := aProperties;

  for i := 0 to loProperties.Items.Count - 1 do
    begin
      loProperty := loProperties.Items[i];

      If Uppercase(loProperty.Name) = Uppercase(APropertyName) then
        begin
          Result := loProperty;

          Exit;
        end;
    end;
end;


function TConfigProperties.IsPropertyExists(APropertyName: String; aProperties: TJvSimpleXmlElem): Boolean;
begin
  Result := (IsPropertyExistsEx(APropertyName, aProperties) <> NIL);
end;

function TConfigProperties.GetProperty(APropertyName: String; aProperties: TJvSimpleXmlElem): String;
Var
  I: integer;
  loProperty,
  loProperties: TJvSimpleXmlElem;
begin
  Result := '';

  if Not Assigned(aProperties) then
    loProperties := foRootProperties
  else
    loProperties := aProperties;

  for i := 0 to loProperties.Items.Count - 1 do
    begin
      loProperty := loProperties.Items[i];

      If Uppercase(loProperty.Name) = Uppercase(APropertyName) then
        begin
          Result := loProperty.Value;

          Exit;
        end;
    end;
end;


end.
