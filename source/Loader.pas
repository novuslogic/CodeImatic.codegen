unit Loader;

interface

Uses novusSimpleXML, JvSimpleXML, Classes, SysUtils, NovusEnvironment, NovusStringUtils;

type
  tNodeLoader = record
  private
    fiIndexPos: INteger;
    fNode: TJvSimpleXmlElem;
    function GetPropertyName: string;
    function GetPropertyValue: string;
    function GetPropertyValueA: string;
    function GetValue: string;
    procedure SetValue(Value: string);
  public
    constructor Create(aIndexPos: Integer);
    function IsExists: Boolean;

    property Node: TJvSimpleXmlElem read fNode write fNode;

    property PropertyName: String read GetPropertyName;

    property Value: String read GetValue write SetValue;

    property PropertyValue: String read GetPropertyValue;
    property PropertyValueA: String read GetPropertyValueA;

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

    procedure SetFieldAsBoolean(aNodeList: TJvSimpleXmlElem; FieldName: String;
        Value: Boolean);
    procedure SetFieldAsinteger(aNodeList: TJvSimpleXmlElem; FieldName: String;
        Value: Integer);
    procedure SetFieldAsString(aNodeList: TJvSimpleXmlElem; FieldName: String;
        Value: String);
    function GetFieldAsinteger(aNodeList: TJvSimpleXmlElem;
        FieldName: String): Integer;
    function GetFieldAsBoolean(aNodeList: TJvSimpleXmlElem;
        FieldName: String): Boolean;
    function GetFieldAsString(aNodeList: TJvSimpleXmlElem;
        FieldName: String): String;

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
  Result := tNovusEnvironment.ParseGetEnvironmentVar
    (aValue, ETTToken2);

  //Result :=  tNovusEnvironment.ParseGetEnvironmentVar(result, ETTToken1);
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

procedure tLoader.SetFieldAsString(aNodeList: TJvSimpleXmlElem;
  FieldName: String; Value: String);
Var
  Index: Integer;
  fJvSimpleXmlElem: TJvSimpleXmlElem;
begin
  Index := 0;
  fJvSimpleXmlElem := TNovusSimpleXML.FindNode(aNodeList, FieldName, Index);

  If Assigned(fJvSimpleXmlElem) then
    fJvSimpleXmlElem.Value := Value;
end;

procedure tLoader.SetFieldAsBoolean(aNodeList: TJvSimpleXmlElem;
  FieldName: String; Value: Boolean);
begin
  If Value = True then
    SetFieldAsString(aNodeList, FieldName, 'True')
  else
    SetFieldAsString(aNodeList, FieldName, 'False');
end;

procedure tLoader.SetFieldAsinteger(aNodeList: TJvSimpleXmlElem;
  FieldName: String; Value: Integer);
begin
  SetFieldAsString(aNodeList, FieldName, InttoStr(Value))
end;

function tLoader.GetFieldAsString(aNodeList: TJvSimpleXmlElem;
  FieldName: String): String;
Var
  Index: Integer;
  fJvSimpleXmlElem: TJvSimpleXmlElem;
begin
  Result := '';

  If Not Assigned(aNodeList) then
    Exit;

  Index := 0;
  fJvSimpleXmlElem := TNovusSimpleXML.FindNode(aNodeList, FieldName, Index);

  If Assigned(fJvSimpleXmlElem) then
    Result := fJvSimpleXmlElem.Value;
end;

function tLoader.GetFieldAsBoolean(aNodeList: TJvSimpleXmlElem;
  FieldName: String): Boolean;
begin
  Result := False;
  If uppercase(GetFieldAsString(aNodeList, FieldName)) = 'TRUE' then
    Result := True;
end;

function tLoader.GetFieldAsinteger(aNodeList: TJvSimpleXmlElem;
  FieldName: String): Integer;
begin
  Result := TNovusStringUtils.Str2Int(GetFieldAsString(aNodeList, FieldName));
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
  Result := uppercase(GetPropertyValueA);
end;

function tNodeLoader.GetPropertyValueA: string;
begin
  Result := '';
  if IsExists then
    if Node.Properties.Count > 0 then
      Result := Trim(Node.Properties[0].Value);
end;

function tNodeLoader.GetValue: string;
begin
  Result := '';
  if IsExists then
    Result := uppercase(Node.Value);
end;

procedure tNodeLoader.SetValue(Value: string);
begin
 if IsExists then
    Node.Value := Value;
end;




end.
