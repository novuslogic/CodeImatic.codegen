unit CodeGeneratorDetails;

interface

uses Project, ExpressionParser, NovusTemplate, Classes, SysUtils, tagType;

type


  TCodeGeneratorDetails = class(TObject)
  protected
    foCodeGenerator: TObject;
    foProject: tProject;
    fsDefaultTagName: String;
    FTagType: tTagType;
    ExpressionParser: tExpressionParser;
    FTemplateTag: TTemplateTag;
    FTokens: tStringlist;
    LiLoopID: Integer;
    foProjectItem: TObject;
    function GetToken1: string;
    function GetToken2: string;
  private
  public
    constructor Create(aProjectItem: TObject; aCodeGenerator: Tobject); virtual;
    destructor Destroy; override;

    procedure Execute;

    property oProject: tProject
      read foProject
      write foProject;

    property oTemplateTag: TTemplateTag
      read FTemplateTag
      write FTemplateTag;

    property Tokens: tStringlist
      read FTokens
      write FTokens;

    property TagType: tTagType
       read FTagType
       write FTagType;

    property DefaultTagName: String
      read fsDefaultTagName
      write fsDefaultTagName;

    property LoopID: Integer
      read liLoopId
      write liLoopId;

    property Token2: string
      read GetToken2;

    property Token1: string
      read GetToken1;
  end;

implementation

Uses TagTypeParser;

procedure TCodeGeneratorDetails.Execute;
var
  lsToken1, lsToken2: string;
begin
  fsDefaultTagName := oTemplateTag.TagName;

  ExpressionParser.Expr := oTemplateTag.TagName;

  ExpressionParser.ListTokens(FTokens);

  lsToken1 := Uppercase(FTokens.Strings[0]);
  if fTokens.Count > 1 then
    lsToken2 := Uppercase(FTokens.Strings[1]);

  FTagType := TTagTypeParser.ParseTagType(foProjectItem, foCodeGenerator, lsToken1,lsToken2   );
end;

function TCodeGeneratorDetails.GetToken1: string;
begin
  Result := Tokens[0];
end;

function TCodeGeneratorDetails.GetToken2: string;
begin
  Result := '';
  if Tokens.Count > 1 then
    Result := Tokens[1];
end;

constructor TCodeGeneratorDetails.Create;
begin
  inherited Create;

  foCodeGenerator := aCodeGenerator;

  foProjectItem := aProjectItem;

  ExpressionParser := TExpressionParser.Create;

  FTokens := tStringlist.Create;
end;

destructor TCodeGeneratorDetails.Destroy;
begin
  ExpressionParser.Free;

  FTokens.Free;

  inherited;
end;


end.
