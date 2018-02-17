unit CodeGeneratorItem;

interface

uses Project, ExpressionParser, NovusTemplate, Classes, SysUtils, tagType, output,
     NovusList, TokenProcessor;

type
  TCodeGeneratorItem = class(TObject)
  protected
    foOutput: tOutput;
    foCodeGenerator: TObject;
    foProject: tProject;
    fsDefaultTagName: String;
    FTagType: tTagType;
    ExpressionParser: tExpressionParser;
    FTemplateTag: TTemplateTag;
    FoTokens: tTokenProcessor;
    LiLoopID: Integer;
    foProjectItem: TObject;
    foVariables: Tobject;
  private
    function GetTokenIndex: Integer;
    procedure SetTokenIndex(Value: Integer);
  public
    constructor Create(aProjectItem: TObject; aCodeGenerator: Tobject; aVariables: tObject; aProject: Tobject); virtual;
    destructor Destroy; override;

    function GetNextToken(aIgnoreNextToken: Boolean = false): String;

    procedure Execute;

    property oProject: tProject
      read foProject
      write foProject;

    property oTemplateTag: TTemplateTag
      read FTemplateTag
      write FTemplateTag;

    property oTokens: tTokenProcessor
      read FoTokens
      write FoTokens;

    property TagType: tTagType
       read FTagType
       write FTagType;

    property DefaultTagName: String
      read fsDefaultTagName
      write fsDefaultTagName;

    property LoopID: Integer
      read liLoopId
      write liLoopId;

    property TokenIndex: Integer
      read GetTokenIndex
      write SetTokenIndex;

    property oProjectItem: TObject
      read foProjectItem;

    property oVariables: Tobject
      read foVariables;
  end;

implementation

Uses TagParser;

procedure TCodeGeneratorItem.Execute;
var
  lsToken1, lsToken2: string;
begin
  TokenIndex := 0;

  fsDefaultTagName := oTemplateTag.TagName;
  if (Pos('CODE=', uppercase(fsDefaultTagName)) > 0) then
    begin
      FTagType := ttcode;


    end
  else
    begin
      ExpressionParser.Expr := fsDefaultTagName;

      ExpressionParser.ListTokens(foTokens);

      FTagType := TTagParser.ParseTagType(foProjectItem, foCodeGenerator, foTokens , foOutput, 0  );
    end;
end;


constructor TCodeGeneratorItem.Create;
begin
  inherited Create;

  foCodeGenerator := aCodeGenerator;

  foProjectItem := aProjectItem;

  foVariables := aVariables;

  foProject := TProject(aProject);

  ExpressionParser := TExpressionParser.Create;

  FoTokens := tTokenProcessor.Create;
end;

destructor TCodeGeneratorItem.Destroy;
begin
  ExpressionParser.Free;

  FoTokens.Free;

  inherited;
end;

function TCodeGeneratorItem.GetNextToken(aIgnoreNextToken: Boolean): String;
begin
  Result := foTokens.GetNextToken(aIgnoreNextToken);
end;

function TCodeGeneratorItem.GetTokenIndex: Integer;
begin
  Result := foTokens.TokenIndex;
end;

procedure TCodeGeneratorItem.SetTokenIndex(Value: Integer);
begin
  foTokens.TokenIndex := Value;
end;



end.
