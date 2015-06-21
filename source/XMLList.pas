unit XMLList;

interface

Uses NovusXMLBO, Classes, SysUtils, JvSimpleXml;

Type
  tXMLlist = class(TNovusXMLBO)
  protected
  private
    fiPosition: Integer;
  public
    constructor Create; override;


    function IsLoaded: Boolean;
    function IsNodeNameExists(ANodeName: String): Boolean;
    function GetFirstNodeName(aNodeName: String; aParentNodeName: String = ''): String;
    function GetNextNodeName(aNodeName: String; aParentNodeName: String = ''): String;
    function GetValueByIndex(aIndex: Integer): String;
    function GetNameByIndex(aIndex: Integer): String;
    function GetCount: Integer;

    property Position: Integer
      read fiPosition
      write fiPosition;

  end;

implementation

constructor tXMLlist.Create;
begin
  inherited Create;

  fiPosition := 0;
end;

function tXMLlist.GetNextNodeName(aNodeName: String; aParentNodeName: String = ''): String;
var
  aNodeList: TJvSimpleXmlElem;
  liIndex: Integer;
begin
  if aParentNodeName <> '' then
    aNodeList := FindNode(oXMLDocument.Root, aParentNodeName,fiPosition)
  else
    aNodeList := oXMLDocument.Root;

  if aNodeList = nil then aNodeList := oXMLDocument.Root;

  Result := GetFieldAsString(aNodeList, ANodeName);
end;

function tXMLlist.GetFirstNodeName(aNodeName: String; aParentNodeName: String = ''): String;
var
  aNodeList: TJvSimpleXmlElem;
  liIndex: Integer;
begin
  fiPosition := 0;

  if aParentNodeName <> '' then
    aNodeList := FindNode(oXMLDocument.Root, aParentNodeName,fiPosition)
  else
    aNodeList := oXMLDocument.Root;

  if aNodeList = nil then aNodeList := oXMLDocument.Root;

  Result := GetFieldAsString(aNodeList, ANodeName);
end;

function tXMLlist.IsNodeNameExists(ANodeName: String): Boolean;
Var
  I: integer;
  lsNodeName: String;
begin
  Result := False;

  for i := 0 to NodeNames.Count - 1 do
    begin
      If Uppercase(NodeNames.Strings[i]) = Uppercase(ANodeName) then
        begin
          Result := True;

          Exit;
        end;
    end;
end;

function tXMLlist.GetCount: Integer;
begin
  Result := NodeNames.Count;
end;

function tXMLlist.GetValueByIndex(aIndex: Integer): String;
Var
  lsNodeName: String;
begin
  Result := '';

  If aIndex > (NodeNames.Count - 1) then Exit;


  lsNodeName := NodeNames.Strings[AIndex];
  Result := GetFirstNodeName(lsNodeName);
end;

function tXMLlist.GetNameByIndex(aIndex: Integer): String;
begin
  Result := '';

  If aIndex > (NodeNames.Count - 1) then Exit;

  Result := NodeNames.Strings[AIndex];
end;

function tXMLlist.IsLoaded: Boolean;
begin
  result := (NodeNames.Count > 0);
end;


end.
