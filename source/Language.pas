unit Language;

interface

Uses NovusXMLBO, Classes, SysUtils, JvSimpleXml;

Type
  tLanguage = class(TNovusXMLBO)
  protected
    fsLanguage: String;
  private
  public
    function ReadXML(ANode: String; AKey: String): String;

    property Language: String
      read fsLanguage
      write fsLanguage;

  end;

implementation

function tLanguage.ReadXML(ANode: String; AKey: String): String;
Var
  liIndex: Integer;
  FRoot: TJvSimpleXmlElem;
begin
  liIndex := 0;

  Result := AKey;

  if Uppercase(oXMLDocument.Root.Name) <> Uppercase(Language) then Exit;

  FRoot := FindNode(oXMLDocument.Root, ANode, liIndex);
  if FRoot <> NIL then
    Result := GetFieldAsString(FRoot, AKey);

  if Result = '' then Result := AKey;
end;

end.
