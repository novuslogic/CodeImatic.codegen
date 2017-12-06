unit Loader;

interface

Uses novusSimpleXML, JvSimpleXML, Classes, SysUtils;

type
  tNodeLoader = record
  private
    fiIndexPos: INteger;
    fNode: TJvSimpleXmlElem;
    function GetPropertyName: string;
    function GetPropertyValue: string;
    function GetValue: string;
  public
    constructor Create(aIndexPos: Integer);
    function IsExists: Boolean;

    property Node: TJvSimpleXmlElem read fNode write fNode;

    property PropertyName: String read GetPropertyName;

    property Value: String read GetValue;

    property PropertyValue: String read GetPropertyValue;

    property IndexPos: INteger read fiIndexPos write fiIndexPos;
  end;

  TLoader = class
  protected
  private
    fRootNodeLoader: tNodeLoader;
    fRootNode: TJvSimpleXmlElem;
  public
    function Load: Boolean; virtual;

    procedure Init(aNodeLoader: tNodeLoader);

    function GetNode(aNodeLoader: TNodeLoader; aNodeName: String; aIndexPos: integer = 0): TNodeLoader;
    function GetRootNode: TNodeLoader;

    function GetValue(aValue: String): String; virtual;

    property RootNode: TJvSimpleXmlElem read fRootNode write fRootNode;
    property RootNodeLoader: tNodeLoader read fRootNodeLoader write fRootNodeLoader;

  end;

implementation

function TLoader.Load: Boolean;
begin
  Result := false;
end;

procedure TLoader.Init(aNodeLoader: tNodeLoader);
begin
  if aNodeLoader.IsExists then
    begin
      RootNode := aNodeLoader.Node;
      RootNodeLoader := aNodeLoader;
    end;
end;

function TLoader.GetRootNode: TNodeLoader;
begin
  Result.Create(0);
  Result.Node := RootNode;
end;

function TLoader.GetValue(aValue: String): String;
begin
  Result := '';
end;

function TLoader.GetNode(aNodeLoader: TNodeLoader; aNodeName: String; aIndexPos: integer): TNodeLoader;
Var
  FNode: TJvSimpleXmlElem;
  fIndex: Integer;
begin
  Result.Create(aIndexPos);
  fIndex := aIndexPos;
  Result.Node := TnovusSimpleXML.FindNode(aNodeLoader.Node,aNodeName, fIndex);
  Result.IndexPos := fIndex;
end;

// NodeLoader

constructor tNodeLoader.Create(aIndexPos: Integer);
begin
  fiIndexPos := aIndexPos;
end;

function tNodeLoader.IsExists: Boolean;
begin
  Result := Assigned(Node);
end;

function tNodeLoader.GetPropertyName: string;
begin
  Result := '';
  if IsExists then
    if Node.Properties.Count > 0 then
      Result := uppercase(Node.Properties[0].Name);
end;

function tNodeLoader.GetPropertyValue: string;
begin
  Result := '';
  if IsExists then
    if Node.Properties.Count > 0 then
      Result := uppercase(Node.Properties[0].Value);
end;

function tNodeLoader.GetValue: string;
begin
  Result := '';
  if IsExists then
    Result := uppercase(Node.Value);
end;

end.
