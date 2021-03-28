unit Interpreter;

interface

Uses
  Classes, ExpressionParser, SysUtils, DB, NovusStringUtils, Output,
  NovusList, Variants, Variables, XMLList, NovusGUID, TokenProcessor, TagType,
  CodeGeneratorItem, TokenParser, ProjectItem, StatementParser, NovusUtilities;

Type
  TNavigateType = (ltrepeat, ltendrepeat, ltif, ltendif);

  TNavigatePosType = (lpStart, lpEnd);

  TNavigatePos = record
    SkipPos: Integer;
    ID: string;
    IsNested: Boolean;
  end;

  TNavigate = Class(TObject)
  protected
    fStatementParser: tStatementParser;
    FNavigateType: TNavigateType;
    FNavigatePosType: TNavigatePosType;
    FNavigatePos: TNavigatePos;
    fiLevel: Integer;
    FoCodeGeneratorItem: TObject;
    FiValue: Integer;
    FbNegitiveFlag: Boolean;
    fsID: String;
    fsLinkID: String;
    fiSkipPos: Integer;
    fbHasRun: Boolean;
  private
  public
    constructor Create; overload;
    destructor Destroy; override;

    property NavigatePosType: TNavigatePosType read FNavigatePosType write FNavigatePosType;

    property NavigateType: TNavigateType read FNavigateType write FNavigateType;

    property Level: Integer read fiLevel write fiLevel;

    property CodeGeneratorItem: TObject read FoCodeGeneratorItem
      write FoCodeGeneratorItem;

    property Value: Integer read FiValue write FiValue;

    property NegitiveFlag: Boolean read FbNegitiveFlag write FbNegitiveFlag;

    property StatementParser: tStatementParser read fStatementParser
      write fStatementParser;

    property ID: String read fsID write fsID;

    property LinkID: String read fsLinkID write fsLinkID;

    property SkipPos: Integer read fiSkipPos write fiSkipPos;

    property HasRun: Boolean read fbHasRun write fbHasRun;

    property NavigatePos: TNavigatePos read FNavigatePos write FNavigatePos;

  End;

  TInterpreter = Class(tTokenParser)
  protected
    FoCodeGenerator: TObject;
    fiLevelCounter: Integer;
    FNavigateList: tNovusList;
    FoCodeGeneratorItem: TCodeGeneratorItem;
  private
    function GetVariables: tVariables;

    function IsVariable(aToken: string): Boolean;


    function DoPluginTag(aTokens: tTokenProcessor; Var aIndex: Integer): string;

    function IsEndIf(aCodeGeneratorItem: TObject): Boolean;
    function IsRepeat(aCodeGeneratorItem: TObject): Boolean;
    function IsEndRepeat(aCodeGeneratorItem: TObject): Boolean;

    function IsIf(aCodeGeneratorItem: TObject): Boolean; overload;
    function IsIf(aToken: string): boolean; overload;

    function FindNavigatePos(aIndex: Integer;
      aStartTagName, aEndTagName: string): TNavigatePos;

    function FindEndNavigateIndexPos(aIndex: Integer;
      aStartTagName, aEndTagName: string): Integer;

    function FindNavigateLevel(aNavigateType: TNavigateType; aLevel: Integer)
      : TNavigate;

    function FindNavigate(aID: String) : TNavigate;

    function FindNavigateLinkID(aNavigateType: TNavigateType; aID: String)
      : TNavigate;

    function GetNextTag(aTokens: tTokenProcessor; Var aIndex: Integer;
      Var ASkipPOs: Integer; ASubCommand: Boolean = False;
      ASubVariable: Boolean = False): String;
    procedure AddVariable(AVariableName: String; AValue: Variant);

    function ParseVariable(aTokens: tTokenProcessor; Var aIndex: Integer;
      ASubCommand: Boolean = False): String;

    function GetCodeGeneratorItemBySourceLineNo(ASourceLineNo: Integer;
      Var APos: Integer): TCodeGeneratorItem;

    function DoRepeat(aTokens: tTokenProcessor; Var aIndex: Integer;
      aTagType: TTagType; Var ASkipPOs: Integer): string;

    function DoIF(aTokens: tTokenProcessor; Var aIndex: Integer;
      aTagType: TTagType; Var ASkipPOs: Integer): string;

    function DoLog(aTokens: tTokenProcessor; Var aIndex: Integer;
      aTagType: TTagType; Var ASkipPOs: Integer): string;

    function DoComment(aTokens: tTokenProcessor; Var aIndex: Integer;
      aTagType: TTagType; Var ASkipPOs: Integer): string;

  public
    constructor Create(aCodeGenerator: TObject; aOutput: TOutput;
      aProjectItem: TProjectItem); overload;

    destructor Destroy; override;

    function ParseToken(aToken: string; var aIndex: Integer;
      aTokens: tTokenProcessor; ASkipPOs: Integer): String;

    procedure ResetToEnd(aTokens: tTokenProcessor; var aIndex: Integer);

    function GetNextToken(Var aIndex: Integer; aTokens: tTokenProcessor;
      aIgnoreTokenParser: Boolean; ASkipPOs: Integer): String; overload;

    function GetNextToken(Var aIndex: Integer; aTokens: tTokenProcessor): String; overload;

    function Execute(aCodeGeneratorItem: TCodeGeneratorItem;
      Var ASkipPos: Integer): String;

    function LanguageFunctions(AFunction: string; ADataType: String): String;

    property oVariables: tVariables read GetVariables;
  End;

implementation

Uses
  NovusTemplate,
  CodeGenerator,
  Reservelist,
  DataProcessor,
  runtime,
  TagParser,
  FunctionsParser;

constructor TInterpreter.Create(aCodeGenerator: TObject; aOutput: TOutput;
  aProjectItem: TProjectItem);
begin
  inherited Create;

  foProjectItem := aProjectItem;

  FoCodeGenerator := aCodeGenerator;

  FNavigateList := tNovusList.Create(TNavigate);

  FoOutput := aOutput;

  fiLevelCounter := 0;
end;

destructor TInterpreter.Destroy;
begin
  FNavigateList.Free;

  inherited;
end;



function TInterpreter.DoPluginTag(aTokens: tTokenProcessor;
  Var aIndex: Integer): string;
var
  fTagParser: TTagParser;
  lsToken1, lsToken2: String;
begin
  Result := '';

  aTokens.TokenIndex := aIndex;

  lsToken1 := aTokens.GetNextToken;
  lsToken2 := aTokens.GetNextToken;

  if oRuntime.oPlugins.IsTagExists(lsToken1, lsToken2) then
  begin
    Result := oRuntime.oPlugins.GetTag(lsToken1, lsToken2, aTokens,
      TProjectItem(foProjectItem));
  end;

  aIndex := aTokens.TokenIndex;
end;

procedure TInterpreter.ResetToEnd(aTokens: tTokenProcessor;
  var aIndex: Integer);
begin
  if aIndex = aTokens.Count then
    aIndex := aTokens.Count - 1;
end;

function TInterpreter.ParseToken(aToken: string; var aIndex: Integer;
  aTokens: tTokenProcessor; ASkipPOs: Integer): String;
var
  fTagType: TTagType;
begin
  Try
    Result := aToken;

    if Pos('$$', aTokens[aIndex]) = 1 then
      Result := tTokenParser.ParseToken(Self, aTokens[aIndex],
        (foProjectItem as TProjectItem), FoOutput, aTokens, aIndex,
        TCodeGenerator(FoCodeGenerator).oProject)
    else if Pos('$', aTokens[aIndex]) = 1 then
      Result := ParseVariable(aTokens, aIndex);

    fTagType := TTagParser.ParseTagType(foProjectItem, FoCodeGenerator, aToken,
      FoOutput, true);

    case fTagType of
      ttplugintag:
        Result := DoPluginTag(aTokens, aIndex);
      ttrepeat:
        Result := DoRepeat(aTokens, aIndex, ttrepeat, ASkipPOs);
      ttendrepeat:
        Result := DoRepeat(aTokens, aIndex, ttendrepeat, ASkipPOs);
      ttif:
        Result := DoIF(aTokens, aIndex, ttif, ASkipPOs);
      ttendif:
        Result := DoIF(aTokens, aIndex, ttendif, ASkipPOs);
      ttLog:
        Result := DoLog(aTokens, aIndex, fTagType, ASkipPOs);
      ttComment:
        Result := DoComment(aTokens, aIndex, fTagType, ASkipPOs);
    end;

  Except
    FoOutput.InternalError;
  end;
end;


function TInterpreter.IsVariable(aToken: string): Boolean;
begin
  Result := (ttVariable = TTagParser.ParseTagType(foProjectItem, FoCodeGenerator,
      aToken, FoOutput, true));
end;

function TInterpreter.GetNextTag(aTokens: tTokenProcessor; Var aIndex: Integer;
  Var ASkipPOs: Integer; ASubCommand: Boolean = False;
  ASubVariable: Boolean = False): String;
Var
  lsNextToken: string;
  fTagType: TTagType;
  lVariable: Tvariable;
begin
  Result := '';
  if ASubCommand then
    Result := aTokens[aIndex];
  try
    lsNextToken := aTokens[aIndex];

    fTagType := TTagParser.ParseTagType(foProjectItem, FoCodeGenerator,
      lsNextToken, FoOutput, true);

    if fTagType = ttplugintag then
    begin
      Result := DoPluginTag(aTokens, aIndex);
    end
    else if fTagType = ttrepeat then
      Result := DoRepeat(aTokens, aIndex, ttrepeat, ASkipPOs)
    else if fTagType = ttendrepeat then
      Result := DoRepeat(aTokens, aIndex, ttendrepeat, ASkipPOs)
    else if fTagType = ttif then
      Result := DoIF(aTokens, aIndex, ttif, ASkipPOs)
    else if fTagType = ttendif then
      Result := DoIF(aTokens, aIndex, ttendif, ASkipPOs)
    else if fTagType = ttLog then
      Result := DoLog(aTokens, aIndex, fTagType, ASkipPOs)
    else if fTagType = ttComment then
      Result := DoComment(aTokens, aIndex, fTagType, ASkipPOs);

    if aTokens.EOF then
      Exit;


    if (Not ASubCommand) (*or (fTagType in [ttPropertyVariable, ttVariable]) *) then
     begin
      if Pos('$$', aTokens[aIndex]) = 1 then
        Result := tTokenParser.ParseToken(Self, aTokens[aIndex],
          (foProjectItem as TProjectItem), (* TCodeGenerator(FoCodeGenerator)
            .oVariables, *) FoOutput, aTokens, aIndex,
          TCodeGenerator(FoCodeGenerator).oProject)
      else if Pos('$', aTokens[aIndex]) = 1 then
        Result := ParseVariable(aTokens, aIndex)

    end
    else
      begin
        if (Pos('$$', aTokens[aIndex]) = 1) or (Pos('$', aTokens[aIndex]) = 1) then
          begin
            lVariable := oVariables.GetVariableByName(lsNextToken);

            if Assigned(lVariable) then Result := lVariable.AsString;

          end;
     end;
  Except
    FoOutput.InternalError;
  end;
end;

function TInterpreter.DoRepeat(aTokens: tTokenProcessor; Var aIndex: Integer;
  aTagType: TTagType; Var ASkipPOs: Integer): string;
Var
  LNavigatePos: TNavigatePos;
  lbNegitiveFlag: Boolean;
  liPos, liLineNoPos, liPosMax: Integer;
  liStartPos1, liEndPos1, liStartPos2, liEndPos2: Integer;
  LStartNavigate, FNavigate: TNavigate;
  liLastSourceNo, I, X, Y, Z, A: Integer;
  LCodeGeneratorItem3, LCodeGeneratorItem2, LCodeGeneratorItem1
    : TCodeGeneratorItem;
  LTemplateTag1, LTemplateTag2: TTemplateTag;
  LTemplate: TNovusTemplate;
  liSkipPos, liTagIndex: Integer;
  LCodeGenerator: TCodeGenerator;
  LsValue: String;
  LiValue: Integer;
  liLineCount: Integer;
  lsTagValue: String;
  liStartTagIndex, liEndTagIndex, liTagIndexCounter, liLastEndSourceLineNo,
  liLastNextSourceLineNo, liNextSourceLineNo1, liNextSourceLineNo2,
  liStartSourceLineNo, liSourceLineCount, liEndSourceLineNo: Integer;
  lbIsNested: Boolean;

  function GetCodeGeneratorItemBySourceLineNo(ASourceLineNo: Integer;
    Var APos: Integer): TCodeGeneratorItem;
  Var
    Z: Integer;
    LCodeGeneratorItem: TCodeGeneratorItem;
  begin
    Result := NIL;

    for Z := APos to TCodeGenerator(FoCodeGenerator)
      .oCodeGeneratorList.Count - 1 do
    begin
      LCodeGeneratorItem := TCodeGeneratorItem(TCodeGenerator(FoCodeGenerator)
        .oCodeGeneratorList.Items[Z]);

      if LCodeGeneratorItem.oTemplateTag.SourceLineNo = ASourceLineNo then
      begin
        Result := LCodeGeneratorItem;

        APos := Z + 1;

        Break;
      end;
    end;

    if Z > APos then
      APos := Z;

  end;

begin
  Result := '';

  case aTagType of
    ttrepeat:
      begin
        If GetNextToken(aIndex, aTokens) = '(' then
        begin
          LsValue := GetNextToken(aIndex, aTokens);

          if TNovusStringUtils.IsNumeric(LsValue) then
          begin
            if GetNextToken(aIndex, aTokens) = ')' then
            begin
              Inc(fiLevelCounter, 1);

              FNavigate := TNavigate.Create;

              FNavigate.NavigateType := ltrepeat;
              FNavigate.NavigatePosType := lpStart;
              FNavigate.Level := fiLevelCounter;

              FNavigate.CodeGeneratorItem := FoCodeGeneratorItem;

              FNavigate.NegitiveFlag := (StrToint(LsValue) < 0);

              FNavigate.Value := 0;
              If StrToint(LsValue) > 0 then
                FNavigate.Value := StrToint(LsValue);

              FNavigateList.Add(FNavigate);

              liStartPos1 := FoCodeGeneratorItem.oTemplateTag.TagIndex;

              FNavigate.ID := FoCodeGeneratorItem.ID;

              Inc(liStartPos1, 1);

              LNavigatePos := FindNavigatePos(liStartPos1, 'repeat',
                'endrepeat');

              if LNavigatePos.ID = '' then
              begin
                FoOutput.LogError
                  ('Syntax Error: Block Repeat without EndRepeat.');

              end;

              FoCodeGeneratorItem.oTemplateTag.TagValue := cDeleteLine;

              ASkipPos := LNavigatePos.SkipPos;

              FNavigate.SkipPos := ASkipPOs;
              FNavigate.LinkID := LNavigatePos.ID;

              FNavigate.NavigatePos := LNavigatePos;


            end
            else
              FoOutput.LogError('Syntax Error: lack ")"');

          end
          else
            FoOutput.LogError('Syntax Error: Index is not a number ');

        end
        else
          FoOutput.LogError('Syntax Error: lack "("');
      end;
    ttendrepeat:
      begin
        ASkipPOs := 0;

        LStartNavigate := FindNavigateLinkID(ltrepeat, FoCodeGeneratorItem.ID);


        if Assigned(LStartNavigate) then
        begin
          if LStartNavigate.LinkID = FoCodeGeneratorItem.ID then
          begin


            LiValue := LStartNavigate.Value;
            lbNegitiveFlag := LStartNavigate.NegitiveFlag;

            liStartPos1 :=
              (LStartNavigate.CodeGeneratorItem As TCodeGeneratorItem)
              .oTemplateTag.TagIndex;
            Inc(liStartPos1, 1);

            liStartSourceLineNo :=
              (LStartNavigate.CodeGeneratorItem As TCodeGeneratorItem)
              .oTemplateTag.SourceLineNo;

            liEndPos1 := (FoCodeGeneratorItem As TCodeGeneratorItem)
              .oTemplateTag.TagIndex;
            Dec(liEndPos1, 1);

            liEndSourceLineNo := (FoCodeGeneratorItem As TCodeGeneratorItem)
              .oTemplateTag.SourceLineNo;
            Dec(liEndSourceLineNo, 1);

            LCodeGenerator := (FoCodeGenerator As TCodeGenerator);

            LTemplate := LCodeGenerator.oTemplate;

            liLastNextSourceLineNo := liStartSourceLineNo;

            FNavigate := NIL;

            I := 0;

            liLastEndSourceLineNo := (liEndSourceLineNo - liStartSourceLineNo);

            Repeat
              liPos := 0;

              While (liPos < TCodeGenerator(FoCodeGenerator)
                .oCodeGeneratorList.Count) do
              begin
                LCodeGeneratorItem1 := GetCodeGeneratorItemBySourceLineNo
                  ((liLastNextSourceLineNo + I) + 1, liPos);

                if Assigned(LCodeGeneratorItem1) then
                begin
                  LTemplateTag1 := LCodeGeneratorItem1.oTemplateTag;

                  liTagIndex := LTemplateTag1.TagIndex;

                  LCodeGenerator.RunPropertyVariables(liTagIndex, liTagIndex);

                  LCodeGenerator.RunInterpreter(liTagIndex, liTagIndex);

                  if IsInterpreterTagType(LCodeGeneratorItem1.TagType) then
                  begin
                    If IsRepeat(LCodeGeneratorItem1) then
                    begin

                    end
                    else If IsEndRepeat(LCodeGeneratorItem1) then
                    begin

                      FNavigate := FindNavigateLinkID(ltrepeat,
                        LCodeGeneratorItem1.ID);

                      liLastEndSourceLineNo := liEndSourceLineNo + 1;
                      liSourceLineCount :=
                        (liEndSourceLineNo - liStartSourceLineNo);

                      // Break;
                    end;
                  end;
                end;
              end;

              Inc(I);
              if I > (liLastEndSourceLineNo - 1) then
                Break;
            until False;

            if LiValue = 0 then
            begin
              If lbNegitiveFlag then
              begin
                For A := 0 to liLastEndSourceLineNo do
                begin
                  LTemplate.OutputDoc.strings[liStartSourceLineNo + A] := '';
                end;
              end;

              Exit;
            end;

            if Not Assigned(FNavigate) then
            begin
              liLastEndSourceLineNo := liEndSourceLineNo;

              if ((FindEndNavigateIndexPos(liStartPos1, 'repeat', 'endrepeat') +
                liStartPos1) < (liEndSourceLineNo - liStartSourceLineNo)) then
                liSourceLineCount := (liEndSourceLineNo - liStartSourceLineNo) -
                  ((FindEndNavigateIndexPos(liStartPos1, 'repeat', 'endrepeat')
                  + liStartPos1) + 1)
              else
                liSourceLineCount :=
                  (liEndSourceLineNo - liStartSourceLineNo) - 1;
            end;

            liLineNoPos := 0;
            Y := 0;
            repeat
              liStartTagIndex := 0;
              liEndTagIndex := 0;

              for I := 0 to liSourceLineCount do
              begin
                liNextSourceLineNo1 := liLastEndSourceLineNo + liLineNoPos;

                LTemplate.InsertLineNo(liNextSourceLineNo1,
                  LTemplate.TemplateDoc.strings[liStartSourceLineNo + I]);


                liPos := 0;

                liPosMax := TCodeGenerator(FoCodeGenerator)
                  .oCodeGeneratorList.Count;

                While (liPos < liPosMax) do
                begin
                  LCodeGeneratorItem1 := GetCodeGeneratorItemBySourceLineNo
                    ((liStartSourceLineNo + I) + 1, liPos);

                  if Assigned(LCodeGeneratorItem1) then
                  begin
                    LTemplateTag1 := LCodeGeneratorItem1.oTemplateTag;

                    LTemplateTag2 := TTemplateTag.Create(NIL);

                    LTemplateTag2.SourceLineNo := liNextSourceLineNo1 + 1;

                    LTemplateTag2.SourcePos := LTemplateTag1.SourcePos;

                    LTemplateTag2.TagName := LTemplateTag1.TagName;
                    LTemplateTag2.RawTag := LTemplateTag1.RawTag;

                    LTemplateTag2.RawTagEx := LTemplateTag1.RawTagEx;

                    LTemplateTag2.TagValue := '';

                    liTagIndex := LTemplate.AddTemplateTag(LTemplateTag2);

                    LCodeGeneratorItem2 := LCodeGenerator.AddTag(LTemplateTag2);

                    if liStartTagIndex = 0 then
                      liStartTagIndex := liTagIndex;
                    liEndTagIndex := liTagIndex;

                    If ((IsEndRepeat(LCodeGeneratorItem2) = False) and
                      (IsRepeat(LCodeGeneratorItem2) = False)) then
                    begin
                      LCodeGenerator.RunPropertyVariables(liTagIndex,
                        liTagIndex);
                      LCodeGenerator.RunInterpreter(liTagIndex, liTagIndex);
                    end;
                  end;
                end;

                Inc(liLineNoPos);
              end;

              Inc(Y);

              if Y = LiValue then
                Break;
            until False;

            LStartNavigate.HasRun := true;
          end
        else
          FoOutput.LogError('Syntax Error: Block EndRepeat without Repeat.');
        end
        else
          FoOutput.LogError('Syntax Error: Block EndRepeat without Repeat.');
      end;
  end;
end;

function TInterpreter.GetCodeGeneratorItemBySourceLineNo(ASourceLineNo: Integer;
  Var APos: Integer): TCodeGeneratorItem;
Var
  Z: Integer;
  LCodeGeneratorItem: TCodeGeneratorItem;
begin
  Result := NIL;

  for Z := APos to TCodeGenerator(FoCodeGenerator)
    .oCodeGeneratorList.Count - 1 do
  begin
    LCodeGeneratorItem := TCodeGeneratorItem(TCodeGenerator(FoCodeGenerator)
      .oCodeGeneratorList.Items[Z]);

    if LCodeGeneratorItem.oTemplateTag.SourceLineNo = ASourceLineNo then
    begin
      Result := LCodeGeneratorItem;

      APos := Z + 1;

      Break;
    end;
  end;

  if Z > APos then
    APos := Z;

end;

function TInterpreter.DoIF(aTokens: tTokenProcessor; Var aIndex: Integer;
  aTagType: TTagType; Var ASkipPOs: Integer): string;
Var
  lStatementParser: tStatementParser;
  // lTokens : tTokenProcessor;
  LExpressionParser: tExpressionParser;
  lbNegitiveFlag: Boolean;
  liPos, liLineNoPos: Integer;
  liStartPos1, liEndPos1, liStartPos2, liEndPos2: Integer;
  LStartNavigate, FNavigate: TNavigate;
  liLastSourceNo, I, X, Y, Z, A: Integer;
  LCodeGeneratorItem3, LCodeGeneratorItem2, LCodeGeneratorItem1
    : TCodeGeneratorItem;
  LTemplateTag1, LTemplateTag2: TTemplateTag;
  LTemplate: TNovusTemplate;
  liSkipPos, liTagIndex: Integer;
  LCodeGenerator: TCodeGenerator;
  LsToken: String;
  LsValue: String;
  lxVariable: TVariable;
  lyVariable: TVariable;
  LiValue: Integer;
  liLineCount: Integer;
  lsTagValue: String;
  liStartTagIndex, liEndTagIndex, liTagIndexCounter, liLastEndSourceLineNo,
    liLastNextSourceLineNo, liNextSourceLineNo1, liNextSourceLineNo2,
    liStartSourceLineNo, liSourceLineCount, liEndSourceLineNo: Integer;
  lbEqual: Boolean;
  lbIsTag: Boolean;
begin
  Result := '';

  case aTagType of
    ttif:
      begin
        If Uppercase(GetNextToken(aIndex, aTokens, true, 0)) = 'IF' then
        begin
          If GetNextToken(aIndex, aTokens, False, 0) = '(' then
          begin
            Try
              lStatementParser := tStatementParser.Create(FoOutput);

              LsToken := GetNextToken(aIndex, aTokens, false, 0);
              if LsToken <> ')' then
                lStatementParser.Add(Trim(LsToken));
              while Not aTokens.EOF do
              begin
                LsToken := GetNextToken(aIndex, aTokens, false, 0);
                if LsToken <> ')' then
                  lStatementParser.Add(Trim(LsToken));
              end;

              ResetToEnd(aTokens, aIndex);

              if LsToken <> ')' then
              begin
                FoOutput.LogError('Syntax Error: lack ")"');

                Exit;
              end;

              Inc(fiLevelCounter, 1);

              FNavigate := TNavigate.Create;
              FNavigate.NavigateType := ltif;
              FNavigate.NavigatePosType := lpStart;

              FNavigate.Level := fiLevelCounter;
              FNavigate.CodeGeneratorItem := FoCodeGeneratorItem;

              liStartPos1 := FoCodeGeneratorItem.oTemplateTag.TagIndex;

              Inc(liStartPos1, 1);

              liEndPos1 := FindEndNavigateIndexPos(liStartPos1, 'if', 'endif');

              FoCodeGeneratorItem.oTemplateTag.TagValue := cDeleteLine;

              ASkipPOs := liEndPos1;

              FNavigate.StatementParser := lStatementParser;

              FNavigateList.Add(FNavigate);
            Finally
              // ResetToEnd(aTokens, aIndex);
            End;

          end
          else
            FoOutput.LogError('Syntax Error: lack "("');

        end
        else
          FoOutput.LogError('Syntax Error: lack "IF"');
      end;
    ttendif:
      begin
        If Uppercase(GetNextToken(aIndex, aTokens, true, 0)) = 'ENDIF' then
        begin
          ASkipPOs := 0;

          LStartNavigate := FindNavigateLevel(ltif, fiLevelCounter);

          if Assigned(LStartNavigate) then
          begin

            liStartPos1 :=
              (LStartNavigate.CodeGeneratorItem As TCodeGeneratorItem)
              .oTemplateTag.TagIndex;

            Inc(liStartPos1, 1);

            liStartSourceLineNo :=
              (LStartNavigate.CodeGeneratorItem As TCodeGeneratorItem)
              .oTemplateTag.SourceLineNo;

            liEndPos1 := (FoCodeGeneratorItem As TCodeGeneratorItem)
              .oTemplateTag.TagIndex;
            Dec(liEndPos1, 1);

            liEndSourceLineNo := (FoCodeGeneratorItem As TCodeGeneratorItem)
              .oTemplateTag.SourceLineNo;
            Dec(liEndSourceLineNo, 1);

            LCodeGenerator := (FoCodeGenerator As TCodeGenerator);

            LTemplate := LCodeGenerator.oTemplate;

            liLastNextSourceLineNo := liStartSourceLineNo;

            FNavigate := NIL;

            I := 0;

            liLastEndSourceLineNo := (liEndSourceLineNo - liStartSourceLineNo);

            Repeat
              liPos := 0;

              lbIsTag := False;
              While (liPos < TCodeGenerator(FoCodeGenerator)
                .oCodeGeneratorList.Count) do
              begin
                LCodeGeneratorItem1 := GetCodeGeneratorItemBySourceLineNo
                  ((liLastNextSourceLineNo + I) + 1, liPos);

                if Assigned(LCodeGeneratorItem1) then
                begin
                  lbIsTag := true;
                  LTemplateTag1 := LCodeGeneratorItem1.oTemplateTag;

                  liTagIndex := LTemplateTag1.TagIndex;

                  lbEqual := False;
                  Try
                    lbEqual := LStartNavigate.StatementParser.IsEqual;

                    if Trim(LStartNavigate.StatementParser.
                      ErrorStatementMessage) <> '' then
                      FoOutput.LogError('Syntax Error: ' +
                        LStartNavigate.StatementParser.ErrorStatementMessage);
                  Except
                    FoOutput.LogError('Syntax Error: ' +
                      LStartNavigate.StatementParser.ErrorStatementMessage);
                  End;

                  if lbEqual then
                  begin
                    LCodeGenerator.RunPropertyVariables(liTagIndex, liTagIndex);
                    LCodeGenerator.RunInterpreter(liTagIndex, liTagIndex);
                  end
                  else
                  begin
                    LTemplateTag1.TagValue := cDeleteLine;

                  end;

                  if Assigned(LCodeGeneratorItem2) then
                  begin
                    If ((IsEndIf(LCodeGeneratorItem2) = False) and
                      (IsIf(LCodeGeneratorItem2) = False)) then
                    begin
                      If IsEndIf(LCodeGeneratorItem1) then
                      begin
                        FNavigate := FindNavigateLevel(ltif, fiLevelCounter);

                        liLastEndSourceLineNo := liEndSourceLineNo + 1;
                        liSourceLineCount :=
                          (liEndSourceLineNo - liStartSourceLineNo);

                        LCodeGeneratorItem1.oTemplateTag.TagValue :=
                          cDeleteLine;

                        Break;
                      end;
                    end;
                  end;
                end;
              end;

              if lbIsTag = False then
              begin
                if Not lbEqual then
                  LTemplate.OutputDoc.strings[liStartSourceLineNo + I] :=
                    cDeleteLine;
              end;

              Inc(I);
              if I > (liLastEndSourceLineNo - 1) then
                Break;
            until False;

            ResetToEnd(aTokens, aIndex);
          end
          else
            FoOutput.LogError('Syntax Error: lack "IF"');
        end
        else
          FoOutput.LogError('Syntax Error: lack "ENDIF"');
      end;
  end;
end;

function TInterpreter.DoLog(aTokens: tTokenProcessor; Var aIndex: Integer;
  aTagType: TTagType; Var ASkipPOs: Integer): string;
Var
  lsLog: String;
begin
  Result := '';

  case aTagType of
    ttLog:
      begin
        If Uppercase(GetNextToken(aIndex, aTokens, true, 0)) = 'LOG' then
        begin
          If GetNextToken(aIndex, aTokens, False, 0) = '(' then
          begin
            lsLog := GetNextToken(aIndex, aTokens, False, 0);

            if GetNextToken(aIndex, aTokens, False, 0) = ')' then
            begin
              FoOutput.Log(lsLog);

              ResetToEnd(aTokens, aIndex);

              Exit;
            end
            else
              ooutput.LogError('Syntax Error: lack ")"');

          end
          else
            FoOutput.LogError('Syntax Error: lack "("');

        end
        else
          FoOutput.LogError('Syntax Error: lack "LOG"');
      end;
  end;
end;

function TInterpreter.DoComment(aTokens: tTokenProcessor; Var aIndex: Integer;
  aTagType: TTagType; Var ASkipPos: Integer): string;
Var
  lsComment: String;
begin
  Result := '';

  case aTagType of
    ttComment:
      begin
        If GetNextToken(aIndex, aTokens, true, 0) = 'REM' then
        begin
          ResetToEnd(aTokens, aIndex);

          Exit;

        end
        else
          FoOutput.LogError('Syntax Error: lack "REM"');
      end;
  end;
end;

function TInterpreter.FindNavigateLinkID(aNavigateType: TNavigateType;
  aID: string): TNavigate;
Var
  I: Integer;
  FNavigate: TNavigate;
begin
  Result := NIL;

  for I := 0 to FNavigateList.Count - 1 do
  begin
    FNavigate := TNavigate(FNavigateList.Items[I]);

    if (FNavigate.NavigateType = aNavigateType) and (FNavigate.LinkID = aID)
    then
    begin
      Result := FNavigate;
      Break;
    end;
  end;
end;


function TInterpreter.FindNavigate(aID: String) : TNavigate;
Var
  I: Integer;
  FNavigate: TNavigate;
begin
  Result := NIL;

  for I := 0 to FNavigateList.Count - 1 do
  begin
    FNavigate := TNavigate(FNavigateList.Items[I]);

    if (FNavigate.LinkID = aID)
    then
    begin
      Result := FNavigate;
      Break;
    end;
  end;
end;

function TInterpreter.FindNavigateLevel(aNavigateType: TNavigateType;
  aLevel: Integer): TNavigate;
Var
  I: Integer;
  FNavigate: TNavigate;
begin
  Result := NIL;

  for I := 0 to FNavigateList.Count - 1 do
  begin
    FNavigate := TNavigate(FNavigateList.Items[I]);

    if (FNavigate.NavigateType = aNavigateType) and (FNavigate.Level = aLevel)
    then
    begin
      Result := FNavigate;
      Break;
    end;
  end;
end;

function TInterpreter.ParseVariable(aTokens: tTokenProcessor;
  Var aIndex: Integer; ASubCommand: Boolean = False): String;
Var
  FVariable1, FVariable2: TVariable;
  lsVariableName1, lsVariableName2: String;
  lVariableI, lVariableX: TVariable;
  LsValue: String;
  LStr: STring;
  liSkipPos: Integer;
  FOut: Boolean;
  fbIsIf: Boolean;
  fsProperty: string;

  function GetToken: String;
  begin
    Result := '';

    Inc(aIndex);

    if (aIndex <= aTokens.Count - 1) then
      Result := GetNextTag(aTokens, aIndex, liSkipPos, true);

  end;


  procedure AddTokenValue(aToken: String);
  begin
     if Not Assigned(FVariable1) then
       begin
         lsVariableName1 := tVariables.CleanVariableName(aTokens[0]);

         FVariable1 := (foProjectItem as TProjectItem).oVariables.GetVariableByName(lsVariableName1);
       end;

     if Not Assigned(FVariable1) then Exit;

     If TNovusStringUtils.IsNumeric(aToken) then
        FVariable1.Value := FVariable1.Value +
          TNovusStringUtils.Str2Int(aToken)
      else
        begin
          if Not FVariable1.IsObject then
            FVariable1.Value := FVariable1.Value + aToken
          else
            FoOutput.LogError('Syntax Error: Cannot add a Object');
        end;
   end;

begin
  Result := '';
  FOut := False;
  fbIsIf := False;

  FVariable1 := nil;

  lsVariableName1 := tVariables.CleanVariableName(aTokens[aIndex]);

  fbIsIf := False;
  if (Trim(Uppercase(aTokens[0])) = 'IF') then
  begin
    FOut := true;
    fbIsIf := true;
  end
  else if (aTokens[0] = '=') then
    FOut := true;

  If (GetToken = '=') and (fbIsIf = False) then
  begin
    lVariableI := oVariables.GetVariableByName(lsVariableName1);

    if Not Assigned(lVariableI) then
      begin
        if (foProjectItem as TProjectItem).oProperties.IsPropertyExists(lsVariableName1) then
          begin
            fsProperty := (foProjectItem as TProjectItem).oProperties.GetProperty(lsVariableName1);

            lVariableI := oVariables.AddVariable(lsVariableName1, fsProperty);
          end;
      end;

    if Not Assigned(lVariableI) then
    begin
      While(aIndex < aTokens.Count - 1) do
        begin
           LsValue := GetToken;

            LsValue := tTokenParser.ParseToken(Self, LsValue,
              (foProjectItem as TProjectItem), (* TCodeGenerator(FoCodeGenerator)
                .oVariables, *) FoOutput, aTokens, aIndex,
              TCodeGenerator(FoCodeGenerator).oProject);

           if lsValue = '+' then
             begin
               AddTokenValue(GetToken);


             end
           else
           If TNovusStringUtils.IsNumeric(LsValue) then
            begin
              if Pos('.', LsValue) > 0 then
                begin
                  if Trim(lsVariableName1) <> '' then AddVariable(lsVariableName1, TNovusStringUtils.Str2Float(LsValue))
                end
              else
                begin
                  if Trim(lsVariableName1) <> '' then AddVariable(lsVariableName1, TNovusStringUtils.Str2Int(LsValue));
                end;
            end
            else
              if Trim(lsVariableName1) <> '' then  AddVariable(lsVariableName1, LsValue);

           lsVariableName1 := '';
        end;


    end
    else
    begin
      LsValue := GetToken;

      lVariableX := NIL;
      if Pos('$', LsValue) = 1 then
      begin
        lsVariableName2 := tVariables.CleanVariableName(LsValue);

        lVariableX := oVariables.GetVariableByName(lsVariableName2);
      end;

      FVariable1 := lVariableI;

      if Assigned(lVariableX) then
      begin
        FVariable2 := lVariableX;
        FVariable1.Value := FVariable2.Value;
      end
      else
      begin
        if FVariable1.IsObject then
        begin
          // foOutput.Log(lsValue);

        end
        else If TNovusStringUtils.IsNumeric(LsValue) then
        begin
          if Pos('.', LsValue) > 0 then
            FVariable1.Value := TNovusStringUtils.Str2Float(LsValue)
          else
            FVariable1.Value := TNovusStringUtils.Str2Int(LsValue);
        end
        else
          FVariable1.Value := LsValue;
        // else If TNovusStringUtils.IsAlphaStr(LsValue) then
        // begin
        // FVariable1.Value := LsValue;
        ///
        // end;
      end;

      if fbIsIf then
      begin
        if Assigned(FVariable1) then
          Result := FVariable1.Value;

        Exit;
      end;

      LStr := GetToken;

      If LStr = '-' then
      begin
        LsValue := GetToken;

        If TNovusStringUtils.IsNumeric(LsValue) then
          FVariable1.Value := FVariable1.Value -
            TNovusStringUtils.Str2Int(LsValue)
        else
          FoOutput.LogError('Syntax Error: Is not a number');
      end
      else If LStr = '+' then
      begin
        lsValue := GetToken;

        AddTokenValue(lsValue);


       While(aIndex < aTokens.Count - 1) do
        begin
           LsValue := GetToken;

           LsValue := tTokenParser.ParseToken(Self, LsValue,
              (foProjectItem as TProjectItem), (* TCodeGenerator(FoCodeGenerator)
                .oVariables, *) FoOutput, aTokens, aIndex,
              TCodeGenerator(FoCodeGenerator).oProject);

           if lsValue = '+' then
             begin
               AddTokenValue(GetToken);
             end
           else
             begin
               FoOutput.LogError('Syntax Error: lack "+"');
               break;
             end;
         end;

        (*
         LsValue := GetToken;

        If TNovusStringUtils.IsNumberStr(LsValue) then
          FVariable1.Value := FVariable1.Value +
            TNovusStringUtils.Str2Int(LsValue)
        else
          FoOutput.LogError('Syntax Error: Is not a number');
          *)

      end;
    end;
  end
  else
  begin
    If FOut = true then
    begin
      lVariableI := oVariables.GetVariableByName(lsVariableName1);
      if Assigned(lVariableI) then
      begin
        FVariable1 := lVariableI;
        Result := FVariable1.Value;
      end
      else
      begin
        if not((foProjectItem as TProjectItem).oProperties.IsPropertyExists
          (lsVariableName1)) then
        begin
          FoOutput.LogError('Syntax Error: variable "' + lsVariableName1 +
            '" not defined');

          FoOutput.Failed := true;
        end
        else
        begin
          Result := ((foProjectItem as TProjectItem).oProperties.GetProperty
            (lsVariableName1));
        end;

      end;

    end
     else
       FoOutput.LogError('Syntax Error: lack "="');
  end;
end;


procedure TInterpreter.AddVariable(AVariableName: String; AValue: Variant);
begin
  (foProjectItem as TProjectItem).oVariables.AddVariable(AVariableName, AValue);
end;

function TInterpreter.Execute(aCodeGeneratorItem: TCodeGeneratorItem;
  Var ASkipPos: Integer): String;
Var
  FIndex: Integer;
  FOut: Boolean;
  lsVariableName: string;
begin
  Result := '';

  FOut := False;

  FoCodeGeneratorItem := aCodeGeneratorItem;

  Self.oTokens :=  FoCodeGeneratorItem.oTokens;

  FIndex := 0;

  if foTokens.strings[0] = '=' then
  begin
    FOut := true;
    FIndex := 1;
  end;

  if FOut = true then
  begin
    Result := GetNextTag(oTokens, FIndex, ASkipPOs)
  end
  else
  begin
    Result := '';
    GetNextTag(oTokens, FIndex, ASkipPOs);
  end;
end;

function TInterpreter.LanguageFunctions(AFunction: string;
  ADataType: String): String;
begin
  // Result := (foProjectItem as TProjectItem).oCodeGenerator.oLanguage.ReadXML(Afunction, ADataType);
end;

(*
  function TInterpreter.CommandSyntaxIndex(aCommand: String): Integer;
  Var
  I: Integer;
  begin
  Result := -1;

  For I := 1 to Length(csCommamdSyntax) do
  begin
  if Uppercase(csCommamdSyntax[I]) = Uppercase(aCommand) then
  begin
  Result := I;

  Break;
  end;
  end;
  end;
*)
function TInterpreter.GetNextToken(Var aIndex: Integer;
  aTokens: tTokenProcessor; aIgnoreTokenParser: Boolean;
  ASkipPos: Integer): String;
Var
  I: Integer;
  LVariable: TVariable;
  liSkipPos: Integer;
  lsNextToken: String;
begin
  lsNextToken := aTokens.GetNextToken(aIndex);

  if Not aIgnoreTokenParser then
    Result := ParseToken(lsNextToken, aIndex, aTokens, ASkipPOs)
  else
    Result := lsNextToken;

  if Result = oTokens.strings[aIndex] then
    Inc(aIndex);

  // if AIndex = ATokens.Count then
  // AIndex := ATokens.Count - 1;

  aTokens.TokenIndex := aIndex;
end;


function TInterpreter.GetNextToken(Var aIndex: Integer;
  aTokens: tTokenProcessor): String;
Var
  I: Integer;
  LVariable: TVariable;
  liSkipPos: Integer;
begin
  Result := '';

  Inc(aIndex);

  if aIndex = aTokens.Count then
    aIndex := aTokens.Count - 1;

  Result := GetNextTag(aTokens, aIndex, liSkipPos, true);

  if Pos('$', Result) = 1 then
  begin
    LVariable := oVariables.GetVariableByName
      (tVariables.CleanVariableName(Result));
    if Not Assigned(LVariable) then
      FoOutput.LogError('Syntax Error: variable ' + Result +
        ' cannot be found.');
  end;
end;


function TInterpreter.GetVariables: tVariables;
begin
  Result := (foProjectItem as TProjectItem).oVariables;
end;

(*
  function TInterpreter.VariableExistsIndex(AVariableName: String): Integer;
  begin
  Result := (foProjectItem as TProjectItem).oVariables.VariableExistsIndex
  (AVariableName)
  end;

  function TInterpreter.GetVariableByIndex(aIndex: Integer): TVariable;
  begin
  Result := (foProjectItem as TProjectItem)
  .oVariables.GetVariableByIndex(aIndex);
  end;
*)

function TInterpreter.FindEndNavigateIndexPos(aIndex: Integer;
  aStartTagName, aEndTagName: string): Integer;
Var
  I: Integer;
  LCodeGeneratorItem: TCodeGeneratorItem;
  LCodeGeneratorList: tNovusList;
  LTemplateTag: TTemplateTag;
  iCount: Integer;
begin
  Result := -1;

  LCodeGeneratorList := (FoCodeGenerator As TCodeGenerator).oCodeGeneratorList;

  iCount := 0;
  for I := aIndex to LCodeGeneratorList.Count - 1 do
  begin
    LCodeGeneratorItem := TCodeGeneratorItem(LCodeGeneratorList.Items[I]);

    if IsInterpreterTagType(LCodeGeneratorItem.TagType) then
    begin
      LTemplateTag := LCodeGeneratorItem.oTemplateTag;

      if Pos(Uppercase(aStartTagName), Uppercase(LTemplateTag.TagName)) = 1 then
      begin
        Inc(iCount);
      end
      else if (Uppercase(LTemplateTag.TagName) = Uppercase(aEndTagName)) and
        (iCount = 0) then
      begin
        Result := I;

        Exit;
      end
      else if (LTemplateTag.TagName = aEndTagName) and (iCount > 0) then
      begin
        Dec(iCount);
      end;
    end;
  end;
end;

function TInterpreter.FindNavigatePos(aIndex: Integer;
  aStartTagName, aEndTagName: string): TNavigatePos;
Var
  I: Integer;
  LCodeGeneratorItem: TCodeGeneratorItem;
  LCodeGeneratorList: tNovusList;
  LTemplateTag: TTemplateTag;
  iCount: Integer;
begin
  Result.SkipPos := -1;
  Result.ID := '';
  Result.IsNested := False;

  LCodeGeneratorList := (FoCodeGenerator As TCodeGenerator).oCodeGeneratorList;

  iCount := 0;
  for I := aIndex to LCodeGeneratorList.Count - 1 do
  begin
    LCodeGeneratorItem := TCodeGeneratorItem(LCodeGeneratorList.Items[I]);

    if IsInterpreterTagType(LCodeGeneratorItem.TagType) then
    begin
      LTemplateTag := LCodeGeneratorItem.oTemplateTag;

      if Pos(Uppercase(aStartTagName), Uppercase(LTemplateTag.TagName)) = 1 then
      begin
        Inc(iCount);

        Result.IsNested := true;
      end
      else if (Uppercase(LTemplateTag.TagName) = Uppercase(aEndTagName)) and
        (iCount = 0) then
      begin
        Result.SkipPos := I;
        Result.ID := LCodeGeneratorItem.ID;

        Exit;
      end
      else if (LTemplateTag.TagName = aEndTagName) and (iCount > 0) then
      begin
        Dec(iCount);
      end;
    end;
  end;
end;

function TInterpreter.IsEndRepeat(aCodeGeneratorItem: TObject): Boolean;
begin
  Result := (TCodeGeneratorItem(aCodeGeneratorItem).TagType = ttendrepeat);
end;

function TInterpreter.IsEndIf(aCodeGeneratorItem: TObject): Boolean;
begin
  Result := (TCodeGeneratorItem(aCodeGeneratorItem).TagType = ttendif);
end;

function TInterpreter.IsIf(aCodeGeneratorItem: TObject): Boolean;
begin
  Result := (TCodeGeneratorItem(aCodeGeneratorItem).TagType = ttif);
end;

function TInterpreter.IsIf(aToken: string): Boolean;
begin
 Result := (ttIf = TTagParser.ParseTagType(foProjectItem, FoCodeGenerator,
      aToken, FoOutput, true));
end;

function TInterpreter.IsRepeat(aCodeGeneratorItem: TObject): Boolean;
begin
  Result := (TCodeGeneratorItem(aCodeGeneratorItem).TagType = ttrepeat);
end;

constructor TNavigate.Create;
begin
  inherited Create;

  fiSkipPos := 0;
  fsID := '';
  fsLinkID := '';
  fbHasRun := False;
end;

destructor TNavigate.Destroy;
begin
  if Assigned(fStatementParser) then
    fStatementParser.Free;

  inherited;
end;

end.
