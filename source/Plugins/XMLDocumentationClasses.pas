unit XMLDocumentationClasses;

interface

Uses Output, NovusTemplate, SysUtils, System.RegularExpressions, Novuslist,
  Template;

type
  TXMLTagItems = class(TnovusList)
  end;

  TXMLTagItem = class
  protected
  private
    fsTag: string;
    fiIndex: Integer;
    fsValue: String;
    fiLength: Integer;
  public
    property Tag: string read fsTag write fsTag;
    Property Index: Integer read fiIndex write fiIndex;
    property Value: String read fsValue write fsValue;
    property Length: Integer read fiLength write fiLength;
  end;

  TXMLDocumentation = class
  protected
  private
    foOutput: TOutput;
    foTemplate: tNovusTemplate;
    foXTLTagItems: TXMLTagItems;
    function InternalParserTag(aTemplate: tTemplate; aTag: string): boolean;
  public
    constructor Create(aOutput: TOutput);
    destructor Destroy; override;

    function GetRegExTag(aTag: String): String;

    function Parser(aTemplate: tTemplate): boolean;

    property oXTLTagItems: TXMLTagItems read foXTLTagItems write foXTLTagItems;
  end;

implementation

constructor TXMLDocumentation.Create(aOutput: TOutput);
begin
  foOutput := aOutput;

  foXTLTagItems := TXMLTagItems.Create(TXMLTagItem);
end;

destructor TXMLDocumentation.Destroy;
begin
  foXTLTagItems.Free;
end;

function TXMLDocumentation.InternalParserTag(aTemplate: tTemplate;
  aTag: string): boolean;
Var
  fRegularExpression: TRegEx;
  fMatchCollection: TMatchCollection;
  I: Integer;
  loXMLTagItem: TXMLTagItem;
begin
  Try
    Result := true;

    fRegularExpression := TRegEx.Create(GetRegExTag(aTag),
      [roIgnoreCase, roMultiLine]);

    fMatchCollection := fRegularExpression.Matches(aTemplate.TemplateDoc.Text);

    for I := 0 to fMatchCollection.Count - 1 do
    begin
      loXMLTagItem := TXMLTagItem.Create;
      loXMLTagItem.Tag := aTag;
      loXMLTagItem.Index := fMatchCollection.Item[I].Index;
      loXMLTagItem.Value := fMatchCollection.Item[I].Value;
      loXMLTagItem.Length := fMatchCollection.Item[I].Length;

      foXTLTagItems.Add(loXMLTagItem)
    end;
  Except
    foOutput.InternalError;

    Result := False;
  End;

end;

function TXMLDocumentation.Parser(aTemplate: tTemplate): boolean;
begin
  Result := true;

  if Not InternalParserTag(aTemplate, 'summary') then;

end;

function TXMLDocumentation.GetRegExTag(aTag: String): String;
begin
  Result := format('\/\/\/ <%s[^>]*>([\s\S]+?)<\/%s>', [aTag, aTag]);
end;

end.
