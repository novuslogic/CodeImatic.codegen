unit CodeGeneratorItem;

interface

uses Project, ExpressionParser, NovusTemplate, Classes, SysUtils, tagType;

type
  TCodeGeneratorItem = class(TObject)
  protected
    foOutput:
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

procedure TCodeGeneratorItem.Execute;
var
  lsToken1, lsToken2: string;
begin
  fsDefaultTagName := oTemplateTag.TagName;
  if (Pos('CODE=', uppercase(fsDefaultTagName)) > 0) then
    begin
      FTagType := ttcode;


    end
  else
    begin
      ExpressionParser.Expr := fsDefaultTagName;

      ExpressionParser.ListTokens(FTokens);

      lsToken1 := Uppercase(FTokens.Strings[0]);
      if fTokens.Count > 1 then
        lsToken2 := Uppercase(FTokens.Strings[1]);

      FTagType := TTagTypeParser.ParseTagType(foProjectItem, foCodeGenerator, lsToken1,lsToken2 , foOutput  );


    end;
end;

function TCodeGeneratorItem.GetToken1: string;
begin
  Result := Tokens[0];
end;

function TCodeGeneratorItem.GetToken2: string;
begin
  Result := '';
  if Tokens.Count > 1 then
    Result := Tokens[1];
end;

constructor TCodeGeneratorItem.Create;
begin
  inherited Create;

  foCodeGenerator := aCodeGenerator;

  foProjectItem := aProjectItem;

  ExpressionParser := TExpressionParser.Create;

  FTokens := tStringlist.Create;
end;

destructor TCodeGeneratorItem.Destroy;
begin
  ExpressionParser.Free;

  FTokens.Free;

  inherited;
end;


end.
