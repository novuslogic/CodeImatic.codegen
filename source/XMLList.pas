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

    function GetNode(aNodeName: string): TJvSimpleXmlElem;

    function IsLoaded: Boolean;
    function IsNodeNameExists(ANodeName: String): Boolean;
    function GetFirstNodeName(ANodeName: String;
      aParentNodeName: String = ''): String; overload;

    function GetFirstNodeNameEx(ANodeName: String;
      aParentNodeName: String = ''): TJvSimpleXmlElem;

    function GetNextNodeName(ANodeName: String;
      aParentNodeName: String = ''): String;
    function GetValueByIndex(aIndex: Integer): String;
    function GetNameByIndex(aIndex: Integer): String;
    function GetCount: Integer;

    property Position: Integer read fiPosition write fiPosition;

  end;

implementation

constructor tXMLlist.Create;
begin
  inherited Create;

  fiPosition := 0;
end;

function tXMLlist.GetNextNodeName(ANodeName: String;
  aParentNodeName: String = ''): String;
var
  aNodeList: TJvSimpleXmlElem;
  liIndex: Integer;
begin
  if aParentNodeName <> '' then
    aNodeList := FindNode(oXMLDocument.Root, aParentNodeName, fiPosition)
  else
    aNodeList := oXMLDocument.Root;

  if aNodeList = nil then
    aNodeList := oXMLDocument.Root;

  Result := GetFieldAsString(aNodeList, ANodeName);
end;


function tXMLlist.GetNode(aNodeName: string): TJvSimpleXmlElem;
begin
  Result := FindNode(oXMLDocument.Root, aNodeName,
      fiPosition );
end;

function tXMLlist.GetFirstNodeName(ANodeName: String;
  aParentNodeName: String = ''): String;
var
  aNodeList: TJvSimpleXmlElem;
  liIndex: Integer;
begin
  aNodeList := GetFirstNodeNameEx(ANodeName, aParentNodeName);


  Result := GetFieldAsString(aNodeList, ANodeName);
end;


function tXMLlist.GetFirstNodeNameEx(ANodeName: String;
  aParentNodeName: String = ''): TJvSimpleXmlElem;
var
  aNodeList: TJvSimpleXmlElem;
  liIndex: Integer;
begin
  fiPosition := 0;

  if aParentNodeName <> '' then
    aNodeList := FindNode(oXMLDocument.Root, aParentNodeName, fiPosition)
  else
    aNodeList := oXMLDocument.Root;

  if aNodeList = nil then
    aNodeList := oXMLDocument.Root;

  Result := aNodeList;
end;

function tXMLlist.IsNodeNameExists(ANodeName: String): Boolean;
Var
  I: Integer;
  lsNodeName: String;
begin
  Result := False;

  for I := 0 to NodeNames.Count - 1 do
  begin
    If Uppercase(NodeNames.Strings[I]) = Uppercase(ANodeName) then
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

  If aIndex > (NodeNames.Count - 1) then
    Exit;

  lsNodeName := NodeNames.Strings[aIndex];
  Result := GetFirstNodeName(lsNodeName);
end;

function tXMLlist.GetNameByIndex(aIndex: Integer): String;
begin
  Result := '';

  If aIndex > (NodeNames.Count - 1) then
    Exit;

  Result := NodeNames.Strings[aIndex];
end;

function tXMLlist.IsLoaded: Boolean;
begin
  Result := (NodeNames.Count > 0);
end;

end.
