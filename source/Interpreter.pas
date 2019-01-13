unit Interpreter;

interface

Uses
  Classes, ExpressionParser, SysUtils, DB, NovusStringUtils, Output,
  NovusList, Variants, Variables, XMLList, NovusGUIDEx, TokenProcessor, TagType,
  CodeGeneratorItem, TokenParser, ProjectItem, StatementParser;

const
  csCommamdSyntax: array [1 .. 25] of String = ('fieldnamebyindex',
    'fieldtypebyindex', 'lower', 'upper', 'uplower', 'fieldtypetodatatype',
    'cleardatatype', 'repeat', 'endrepeat', 'fieldcount', 'pred', 'blankline',
    'tablecount', 'tablenamebyindex', 'fieldassql', 'delimiter', 'reservelist',
    'rlist', 'list', 'listcount', 'listname', 'newguid', 'rlistformat',
    'fieldbyname', 'FieldByIndex');

Type
  TNavigateType = (ltrepeat, ltendrepeat, ltif, ltendif);

  TNavigatePos = (lpStart, lpEnd);

  TNavigate = Class(TObject)
  protected
    fStatementParser: tStatementParser;
    FLoopType: TNavigateType;
    FLoopPos: TNavigatePos;
    fiID: Integer;
    FoCodeGeneratorItem: TObject;
    FiValue: Integer;
    FbNegitiveFlag: Boolean;
  private
  public
    constructor Create; overload;
    destructor Destroy; override;

    property LoopPos: TNavigatePos read FLoopPos write FLoopPos;

    property LoopType: TNavigateType read FLoopType write FLoopType;

    property ID: Integer read fiID write fiID;

    property CodeGeneratorItem: TObject read FoCodeGeneratorItem
      write FoCodeGeneratorItem;

    property Value: Integer read FiValue write FiValue;

    property NegitiveFlag: Boolean read FbNegitiveFlag write FbNegitiveFlag;

    property StatementParser: tStatementParser read fStatementParser
      write fStatementParser;

  End;

  TInterpreter = Class(tTokenParser)
  protected
    FoCodeGenerator: TObject;
    fiLoopCounter: Integer;
    FNavigateList: tNovusList;

    FoCodeGeneratorItem: TCodeGeneratorItem;

  private
    function DoPluginTag(aTokens: tTokenProcessor; Var aIndex: Integer): string;

    function IsEndIf(aCodeGeneratorItem: TObject): Boolean;
    function IsRepeat(aCodeGeneratorItem: TObject): Boolean;
    function IsEndRepeat(aCodeGeneratorItem: TObject): Boolean;
    function IsIf(aCodeGeneratorItem: TObject): Boolean;

    function FindEndNavigateIndexPos(aIndex: Integer;
      aStartTagName, aEndTagName: string): Integer;
    function FindNavigateID(ALoopType: TNavigateType; ALoopID: Integer)
      : TNavigate;

    function GetNextTag(aTokens: tTokenProcessor; Var aIndex: Integer;
      Var ASkipPOs: Integer; ASubCommand: Boolean = False;
      ASubVariable: Boolean = False): String;
    procedure AddVariable(AVariableName: String; AValue: Variant);

    // function Delimiter(ATokens: tTokenProcessor; Var AIndex: Integer): string;
    function Reservelist(aTokens: tTokenProcessor; Var aIndex: Integer;
      ACommandIndex: Integer): string;
    function XMLlistIndex(aTokens: tTokenProcessor;
      Var aIndex: Integer): string;
    function XMLListName(aTokens: tTokenProcessor; Var aIndex: Integer): string;
    function XMLlistCount(aTokens: tTokenProcessor;
      Var aIndex: Integer): string;

    function ParseVariable(aTokens: tTokenProcessor; Var aIndex: Integer;
      ASubCommand: Boolean = False): String;

    function VariableExistsIndex(AVariableName: String): Integer;
    function GetVariableByIndex(aIndex: Integer): TVariable;

    function GetCodeGeneratorItemBySourceLineNo(ASourceLineNo: Integer;
      Var APos: Integer): TCodeGeneratorItem;

    function DoRepeat(aTokens: tTokenProcessor; Var aIndex: Integer;
      aTagType: TTagType; Var ASkipPOs: Integer): string;

    function DoIF(aTokens: tTokenProcessor; Var aIndex: Integer;
      aTagType: TTagType; Var ASkipPOs: Integer): string;
  public
    constructor Create(aCodeGenerator: TObject; aOutput: TOutput;
      aProjectItem: TProjectItem); overload;

    destructor Destroy; override;

    function ParseToken(aToken: string; var aIndex: Integer;
      aTokens: tTokenProcessor; ASkipPOs: Integer): String;

    procedure ResetToEnd(aTokens: tTokenProcessor; var aIndex: Integer);

    function GetNextToken(Var aIndex: Integer; aTokens: tTokenProcessor;
      aIgnoreTokenParser: Boolean = False; ASkipPOs: Integer = 0): String;

    function GetNextTokenA(Var aIndex: Integer;
      aTokens: tTokenProcessor): String;

    // function DoTagTypeInterpreter(ATokens: tTokenProcessor): TTagType;
    function CommandSyntaxIndex(aCommand: String): Integer;

    function Execute(aCodeGeneratorItem: TCodeGeneratorItem;
      Var ASkipPOs: Integer): String;
    function LanguageFunctions(AFunction: string; ADataType: String): String;

    property oTokens: tTokenProcessor read foTokens write foTokens;
  End;

implementation

Uses
  NovusTemplate,
  CodeGenerator,
  Reservelist,
  DataProcessor,
  runtime,
  TagParser;

constructor TInterpreter.Create(aCodeGenerator: TObject; aOutput: TOutput;
  aProjectItem: TProjectItem);
begin
  inherited Create;

  foProjectItem := aProjectItem;

  FoCodeGenerator := aCodeGenerator;

  oVariables := foProjectItem.oVariables;

  FNavigateList := tNovusList.Create(TNavigate);

  FoOutput := aOutput;

  fiLoopCounter := 0;
end;

destructor TInterpreter.Destroy;
begin
  FNavigateList.Free;

  inherited;
end;

function TInterpreter.Reservelist(aTokens: tTokenProcessor; Var aIndex: Integer;
  ACommandIndex: Integer): string;
Var
  lConnectionItem: tConnectionItem;
  lsFilename: String;
  loreservelist: treservelist;
  lsWord: String;
  lsFormatOption: String;
begin
  Result := '';

  If GetNextTokenA(aIndex, aTokens) = '(' then
  begin
    lsFilename := GetNextTokenA(aIndex, aTokens);

    lsWord := GetNextTokenA(aIndex, aTokens);

    If lsWord <> '' then
    begin
      If FileExists(lsFilename) then
      begin
        loreservelist := treservelist.Create;

        loreservelist.XMLFileName := lsFilename;
        loreservelist.Retrieve;

        Result := lsWord;
        if loreservelist.IsReserveWordExists(lsWord) then
          Result := loreservelist.GetReserveWord(lsWord);

        If ACommandIndex = 1 then
        begin
          lsFormatOption := GetNextTokenA(aIndex, aTokens);

          Result := Format(Result, [lsFormatOption]);
        end;

        loreservelist.Free;
      end
      else
        Result := lsWord;
    end;
  end
  else
  begin
    FoOutput.Log('Incorrect syntax: lack "("');

  end;
end;

function TInterpreter.XMLlistIndex(aTokens: tTokenProcessor;
  Var aIndex: Integer): string;
Var
  lConnectionItem: tConnectionItem;
  lsStr: String;
  loXMLlist: tXMLlist;
  lsDelimiter: string;
  liDelimiterCounter, liDelimiterLength: Integer;
begin
  Result := '';

  If GetNextTokenA(aIndex, aTokens) = '(' then
  begin
    lsStr := GetNextTokenA(aIndex, aTokens);

    if lsStr <> '' then
    begin
      Result := lsStr;

      loXMLlist := NIL;
      if FileExists(lsStr) then
      begin
        loXMLlist := tXMLlist.Create;

        loXMLlist.XMLFileName := lsStr;
        loXMLlist.Retrieve;

        lsStr := GetNextTokenA(aIndex, aTokens);
        if lsStr <> '' then
        begin
          if TNovusStringUtils.IsNumberStr(lsStr) then
          begin
            Result := loXMLlist.GetValueByIndex(StrToint(lsStr));
          end
          else
            FoOutput.Log('Incorrect syntax: Index is not a number ');

        end
        else
          FoOutput.Log('Incorrect syntax: Index is blank.');

        if Assigned(loXMLlist) then
          loXMLlist.Free;

      end
      else
      begin
        FoOutput.LogError('Error: List filname cannot be found.');

      end;

    end
    else
      FoOutput.Log('Incorrect syntax: List is blank.');
  end
  else
  begin
    FoOutput.Log('Incorrect syntax: lack "("');

  end;

  if GetNextTokenA(aIndex, aTokens) <> ')' then
    FoOutput.Log('Incorrect syntax: lack ")"');
end;

function TInterpreter.XMLListName(aTokens: tTokenProcessor;
  Var aIndex: Integer): string;
Var
  lConnectionItem: tConnectionItem;
  lsStr: String;
  loXMLlist: tXMLlist;
  lsDelimiter: string;
  liDelimiterCounter, liDelimiterLength: Integer;
begin
  Result := '';

  If GetNextTokenA(aIndex, aTokens) = '(' then
  begin
    lsStr := GetNextTokenA(aIndex, aTokens);

    if lsStr <> '' then
    begin
      Result := lsStr;

      loXMLlist := NIL;
      if FileExists(lsStr) then
      begin
        loXMLlist := tXMLlist.Create;

        loXMLlist.XMLFileName := lsStr;
        loXMLlist.Retrieve;

        lsStr := GetNextTokenA(aIndex, aTokens);
        if lsStr <> '' then
        begin
          if TNovusStringUtils.IsNumberStr(lsStr) then
          begin
            Result := loXMLlist.GetNameByIndex(StrToint(lsStr));
          end
          else
            FoOutput.Log('Incorrect syntax: Index is not a number ');

        end
        else
          FoOutput.Log('Incorrect syntax: Index is blank.');

        if Assigned(loXMLlist) then
          loXMLlist.Free;

      end
      else
      begin
        FoOutput.LogError('Error: List filname cannot be found.');

      end;

    end
    else
      FoOutput.Log('Incorrect syntax: List is blank.');
  end
  else
  begin
    FoOutput.Log('Incorrect syntax: lack "("');

  end;

  if GetNextTokenA(aIndex, aTokens) <> ')' then
    FoOutput.Log('Incorrect syntax: lack ")"');
end;

function TInterpreter.XMLlistCount(aTokens: tTokenProcessor;
  Var aIndex: Integer): string;
Var
  lConnectionItem: tConnectionItem;
  lsStr: String;
  loXMLlist: tXMLlist;
  lsDelimiter: string;
  liDelimiterCounter, liDelimiterLength: Integer;
begin
  Result := '0';

  If GetNextTokenA(aIndex, aTokens) = '(' then
  begin
    lsStr := GetNextTokenA(aIndex, aTokens);

    if lsStr <> '' then
    begin
      Result := lsStr;

      loXMLlist := NIL;
      if FileExists(lsStr) then
      begin
        loXMLlist := tXMLlist.Create;

        loXMLlist.XMLFileName := lsStr;
        loXMLlist.Retrieve;

        Result := IntToStr(loXMLlist.GetCount);

        if Assigned(loXMLlist) then
          loXMLlist.Free;

      end
      else
      begin
        FoOutput.LogError('Error: List filname cannot be found.');

      end;

    end
    else
      FoOutput.Log('Incorrect syntax: List is blank.');
  end
  else
  begin
    FoOutput.Log('Incorrect syntax: lack "("');

  end;
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

    fTagType := TTagParser.ParseTagType(foProjectItem, FoCodeGenerator, aToken,
      FoOutput, true);

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
      Result := DoIF(aTokens, aIndex, ttendif, ASkipPOs);

    if (CommandSyntaxIndex(aToken) <> 0) then
    begin
      case CommandSyntaxIndex(aToken) of

        // 16:
        // Result := Delimiter(ATokens, AIndex);
        17, 18:
          Result := Reservelist(aTokens, aIndex, 0);
        19:
          Result := XMLlistIndex(aTokens, aIndex);
        20:
          Result := XMLlistCount(aTokens, aIndex);
        21:
          Result := XMLListName(aTokens, aIndex);

        23:
          Result := Reservelist(aTokens, aIndex, 1);

      end;
    end;

    if Pos('$$', aTokens[aIndex]) = 1 then
      Result := tTokenParser.ParseToken(Self, aTokens[aIndex],
        (foProjectItem as TProjectItem), FoOutput, aTokens, aIndex,
        TCodeGenerator(FoCodeGenerator).oProject)
    else if Pos('$', aTokens[aIndex]) = 1 then
      Result := ParseVariable(aTokens, aIndex);

  Except
    FoOutput.InternalError;
  end;
end;

function TInterpreter.GetNextTag(aTokens: tTokenProcessor; Var aIndex: Integer;
  Var ASkipPOs: Integer; ASubCommand: Boolean = False;
  ASubVariable: Boolean = False): String;
Var
  lsNextToken: string;
  fTagType: TTagType;
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
      Result := DoIF(aTokens, aIndex, ttendif, ASkipPOs);

    if (CommandSyntaxIndex(lsNextToken) <> 0) then
    begin
      case CommandSyntaxIndex(lsNextToken) of

        // 16:
        // Result := Delimiter(ATokens, AIndex);
        17, 18:
          Result := Reservelist(aTokens, aIndex, 0);
        19:
          Result := XMLlistIndex(aTokens, aIndex);
        20:
          Result := XMLlistCount(aTokens, aIndex);
        21:
          Result := XMLListName(aTokens, aIndex);

        23:
          Result := Reservelist(aTokens, aIndex, 1);

      end;
    end;

    if Not ASubCommand then
    begin
      if Pos('$$', aTokens[aIndex]) = 1 then
        Result := tTokenParser.ParseToken(Self, aTokens[aIndex],
          (foProjectItem as TProjectItem), (* TCodeGenerator(FoCodeGenerator)
            .oVariables, *) FoOutput, aTokens, aIndex,
          TCodeGenerator(FoCodeGenerator).oProject)
      else if Pos('$', aTokens[aIndex]) = 1 then
        Result := ParseVariable(aTokens, aIndex)
    end;

  Except
    FoOutput.InternalError;
  end;
end;

function TInterpreter.DoRepeat(aTokens: tTokenProcessor; Var aIndex: Integer;
  aTagType: TTagType; Var ASkipPOs: Integer): string;
Var
  lbNegitiveFlag: Boolean;
  liPos, liLineNoPos: Integer;
  liStartPos1, liEndPos1, liStartPos2, liEndPos2: Integer;
  LStarTNavigate, FLoop: TNavigate;
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
        If GetNextTokenA(aIndex, aTokens) = '(' then
        begin
          LsValue := GetNextTokenA(aIndex, aTokens);

          if TNovusStringUtils.IsNumberStr(LsValue) then
          begin
            if GetNextTokenA(aIndex, aTokens) = ')' then
            begin
              Inc(fiLoopCounter, 1);

              FLoop := TNavigate.Create;

              FLoop.LoopType := ltrepeat;
              FLoop.LoopPos := lpStart;
              FLoop.ID := fiLoopCounter;

              FLoop.CodeGeneratorItem := FoCodeGeneratorItem;

              FLoop.NegitiveFlag := (StrToint(LsValue) < 0);

              FLoop.Value := 0;
              If StrToint(LsValue) > 0 then
                FLoop.Value := StrToint(LsValue);

              FNavigateList.Add(FLoop);

              liStartPos1 := FoCodeGeneratorItem.oTemplateTag.TagIndex;

              Inc(liStartPos1, 1);

              liEndPos1 := FindEndNavigateIndexPos(liStartPos1, 'repeat',
                'endrepeat');

              FoCodeGeneratorItem.oTemplateTag.TagValue := cDeleteLine;

              ASkipPOs := liEndPos1;
            end
            else
              FoOutput.Log('Incorrect syntax: lack ")"');

          end
          else
            FoOutput.Log('Incorrect syntax: Index is not a number ');

        end
        else
          FoOutput.Log('Incorrect syntax: lack "("');
      end;
    ttendrepeat:
      begin
        ASkipPOs := 0;

        LStarTNavigate := FindNavigateID(ltrepeat, fiLoopCounter);

        LiValue := LStarTNavigate.Value;
        lbNegitiveFlag := LStarTNavigate.NegitiveFlag;

        liStartPos1 := (LStarTNavigate.CodeGeneratorItem As TCodeGeneratorItem)
          .oTemplateTag.TagIndex;
        Inc(liStartPos1, 1);

        liStartSourceLineNo :=
          (LStarTNavigate.CodeGeneratorItem As TCodeGeneratorItem)
          .oTemplateTag.SourceLineNo;

        liEndPos1 := (FoCodeGeneratorItem As TCodeGeneratorItem)
          .oTemplateTag.TagIndex;
        Dec(liEndPos1, 1);

        liEndSourceLineNo := (FoCodeGeneratorItem As TCodeGeneratorItem)
          .oTemplateTag.SourceLineNo;
        Dec(liEndSourceLineNo, 1);

        for I := liStartPos1 to liEndPos1 do
        begin
          LCodeGeneratorItem1 :=
            TCodeGeneratorItem(TCodeGenerator(FoCodeGenerator)
            .oCodeGeneratorList.Items[I]);
          LCodeGeneratorItem1.LoopId := fiLoopCounter;
        end;

        LCodeGenerator := (FoCodeGenerator As TCodeGenerator);

        LTemplate := LCodeGenerator.oTemplate;

        liLastNextSourceLineNo := liStartSourceLineNo;

        FLoop := NIL;

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
                If IsEndRepeat(LCodeGeneratorItem1) then
                begin
                  FLoop := FindNavigateID(ltrepeat, fiLoopCounter);

                  liLastEndSourceLineNo := liEndSourceLineNo + 1;
                  liSourceLineCount :=
                    (liEndSourceLineNo - liStartSourceLineNo);

                  Break;
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

        if Not Assigned(FLoop) then
        begin
          liLastEndSourceLineNo := liEndSourceLineNo;

          if ((FindEndNavigateIndexPos(liStartPos1, 'repeat', 'endrepeat') +
            liStartPos1) < (liEndSourceLineNo - liStartSourceLineNo)) then
            liSourceLineCount := (liEndSourceLineNo - liStartSourceLineNo) -
              ((FindEndNavigateIndexPos(liStartPos1, 'repeat', 'endrepeat') +
              liStartPos1) + 1)
          else
            liSourceLineCount := (liEndSourceLineNo - liStartSourceLineNo) - 1;
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

            While (liPos < TCodeGenerator(FoCodeGenerator)
              .oCodeGeneratorList.Count) do
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
                  LCodeGenerator.RunPropertyVariables(liTagIndex, liTagIndex);
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
  LStarTNavigate, FNavigate: TNavigate;
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

begin
  Result := '';

  case aTagType of
    ttif:
      begin
        If Uppercase(GetNextToken(aIndex, aTokens, true)) = 'IF' then
        begin
          If GetNextToken(aIndex, aTokens, False) = '(' then
          begin
            Try
              lStatementParser := tStatementParser.Create;

              LsToken := GetNextToken(aIndex, aTokens);
              if LsToken <> ')' then
                lStatementParser.Add(LsToken);
              while Not aTokens.EOF do
              begin
                LsToken := GetNextToken(aIndex, aTokens);
                if LsToken <> ')' then
                  lStatementParser.Add(LsToken);
              end;

              ResetToEnd(aTokens, aIndex);

              if LsToken <> ')' then
              begin
                FoOutput.Log('Incorrect syntax: lack ")"');

                Exit;
              end;

              Inc(fiLoopCounter, 1);

              FNavigate := TNavigate.Create;
              FNavigate.LoopType := ltif;
              FNavigate.LoopPos := lpStart;

              FNavigate.ID := fiLoopCounter;
              FNavigate.CodeGeneratorItem := FoCodeGeneratorItem;

              liStartPos1 := FoCodeGeneratorItem.oTemplateTag.TagIndex;

              Inc(liStartPos1, 1);

              liEndPos1 := FindEndNavigateIndexPos(liStartPos1, 'if', 'endif');

              FoCodeGeneratorItem.oTemplateTag.TagValue := cDeleteLine;

              ASkipPOs := liEndPos1;

              FNavigate.StatementParser := lStatementParser;

              FNavigateList.Add(FNavigate);
            Finally
              //
            End;

          end
          else
            FoOutput.Log('Incorrect syntax: lack "("');

        end
        else
          FoOutput.Log('Incorrect syntax: lack "IF"');
      end;
    ttendif:
      begin
        If Uppercase(GetNextToken(aIndex, aTokens, true)) = 'ENDIF' then
        begin
          ASkipPOs := 0;

          LStarTNavigate := FindNavigateID(ltif, fiLoopCounter);

          liStartPos1 :=
            (LStarTNavigate.CodeGeneratorItem As TCodeGeneratorItem)
            .oTemplateTag.TagIndex;


          Inc(liStartPos1, 1);

          liStartSourceLineNo :=
            (LStarTNavigate.CodeGeneratorItem As TCodeGeneratorItem)
            .oTemplateTag.SourceLineNo;

          liEndPos1 := (FoCodeGeneratorItem As TCodeGeneratorItem)
            .oTemplateTag.TagIndex;
          Dec(liEndPos1, 1);

          //(FoCodeGeneratorItem As TCodeGeneratorItem).oTemplateTag.TagValue := 'AAA';

          liEndSourceLineNo := (FoCodeGeneratorItem As TCodeGeneratorItem)
            .oTemplateTag.SourceLineNo;
          Dec(liEndSourceLineNo, 1);

          for I := liStartPos1 to liEndPos1 do
          begin
            LCodeGeneratorItem1 :=
              TCodeGeneratorItem(TCodeGenerator(FoCodeGenerator)
              .oCodeGeneratorList.Items[I]);
            LCodeGeneratorItem1.LoopId := fiLoopCounter;
          end;

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

                if LStarTNavigate.StatementParser.IsEqual then
                  LCodeGenerator.RunInterpreter(liTagIndex, liTagIndex)
                else
                  LTemplateTag1.TagValue := cDeleteLine;

                If ((IsEndIf(LCodeGeneratorItem2) = False) and
                  (IsIf(LCodeGeneratorItem2) = False)) then
                begin
                   If IsEndIf(LCodeGeneratorItem1) then
                    begin
                      FNavigate := FindNavigateID(ltif, fiLoopCounter);

                      liLastEndSourceLineNo := liEndSourceLineNo + 1;
                      liSourceLineCount :=
                        (liEndSourceLineNo - liStartSourceLineNo);

                      LCodeGeneratorItem1.oTemplateTag.TagValue := cDeleteLine;

                      Break;
                    end;
                end;
              end;
            end;

            Inc(I);
            if I > (liLastEndSourceLineNo - 1) then
              Break;
          until False;

          ResetToEnd(aTokens, aIndex);
        end
        else
          FoOutput.Log('Incorrect syntax: lack "ENDIF"');
      end;
  end;
end;

function TInterpreter.FindNavigateID(ALoopType: TNavigateType; ALoopID: Integer)
  : TNavigate;
Var
  I: Integer;
  FLoop: TNavigate;
begin
  Result := NIL;

  for I := 0 to FNavigateList.Count - 1 do
  begin
    FLoop := TNavigate(FNavigateList.Items[I]);

    if (FLoop.LoopType = ALoopType) and (FLoop.ID = ALoopID) then
    begin
      Result := FLoop;
      Break;
    end;
  end;
end;

function TInterpreter.ParseVariable(aTokens: tTokenProcessor;
  Var aIndex: Integer; ASubCommand: Boolean = False): String;
Var
  FVariable1, FVariable2: TVariable;
  lsVariableName1, lsVariableName2: String;
  I, X: Integer;
  LsValue: String;
  LStr: STring;
  liSkipPos: Integer;
  FOut: Boolean;

  function GetToken: String;
  begin
    Result := '';

    Inc(aIndex);

    if (aIndex <= aTokens.Count - 1) then
      Result := GetNextTag(aTokens, aIndex, liSkipPos, true);
  end;

begin
  Result := '';
  FOut := False;

  lsVariableName1 := TVariables.CleanVariableName(aTokens[aIndex]);

  if aTokens[0] = '=' then
    FOut := true;

  If GetToken = '=' then
  begin
    I := VariableExistsIndex(lsVariableName1);

    if I = -1 then
    begin
      LsValue := GetToken;

      LsValue := tTokenParser.ParseToken(Self, LsValue,
        (foProjectItem as TProjectItem), (* TCodeGenerator(FoCodeGenerator)
          .oVariables, *) FoOutput, aTokens, aIndex,
        TCodeGenerator(FoCodeGenerator).oProject);

      If TNovusStringUtils.IsNumberStr(LsValue) then
      begin
        if Pos('.', LsValue) > 0 then
          AddVariable(lsVariableName1, TNovusStringUtils.Str2Float(LsValue))
        else
          AddVariable(lsVariableName1, TNovusStringUtils.Str2Int(LsValue));
      end
      else
        AddVariable(lsVariableName1, LsValue);

    end
    else
    begin
      LsValue := GetToken;

      X := -1;
      if Pos('$', LsValue) = 1 then
      begin
        lsVariableName2 := TVariables.CleanVariableName(LsValue);

        X := VariableExistsIndex(lsVariableName2);
      end;

      FVariable1 := GetVariableByIndex(I);

      if X <> -1 then
      begin
        FVariable2 := GetVariableByIndex(X);
        FVariable1.Value := FVariable2.Value;
      end
      else
      begin
        if FVariable1.IsObject then
        begin
          // foOutput.Log(lsValue);

        end
        else If TNovusStringUtils.IsNumberStr(LsValue) then
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

      LStr := GetToken;

      If LStr = '-' then
      begin
        LsValue := GetToken;

        If TNovusStringUtils.IsNumberStr(LsValue) then
          FVariable1.Value := FVariable1.Value -
            TNovusStringUtils.Str2Int(LsValue)
        else
          FoOutput.Log('Incorrect syntax: Is not a number');
      end
      else If LStr = '+' then
      begin
        LsValue := GetToken;

        If TNovusStringUtils.IsNumberStr(LsValue) then
          FVariable1.Value := FVariable1.Value +
            TNovusStringUtils.Str2Int(LsValue)
        else
          FoOutput.Log('Incorrect syntax: Is not a number');
      end;
    end;
  end
  else
  begin
    If FOut = true then
    begin
      I := VariableExistsIndex(lsVariableName1);
      if I <> -1 then
      begin
        FVariable1 := GetVariableByIndex(I);
        Result := FVariable1.Value;
      end
      else
      begin
        FoOutput.Log('Syntax error: "' + lsVariableName1 + '" not defined');
        FoOutput.Failed := true;
      end;

    end
    else
      FoOutput.Log('Incorrect syntax: lack "="');
  end;
end;

procedure TInterpreter.AddVariable(AVariableName: String; AValue: Variant);
begin
  (foProjectItem as TProjectItem).oVariables.AddVariable(AVariableName, AValue);
end;

function TInterpreter.Execute(aCodeGeneratorItem: TCodeGeneratorItem;
  Var ASkipPOs: Integer): String;
Var
  FIndex: Integer;
  FOut: Boolean;
  fsScript: string;
  lbIsFailedCompiled: Boolean;
begin
  Result := '';

  FOut := False;

  FoCodeGeneratorItem := aCodeGeneratorItem;
  foTokens := FoCodeGeneratorItem.oTokens;

  FIndex := 0;
  if foTokens.strings[0] = '=' then
  begin
    FOut := true;
    FIndex := 1;
  end;

  if FOut = true then
  begin
    Result := GetNextTag(foTokens, FIndex, ASkipPOs)
  end
  else
  begin
    Result := '';
    GetNextTag(foTokens, FIndex, ASkipPOs);
  end;
end;

function TInterpreter.LanguageFunctions(AFunction: string;
  ADataType: String): String;
begin
  // Result := (foProjectItem as TProjectItem).oCodeGenerator.oLanguage.ReadXML(Afunction, ADataType);
end;

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

function TInterpreter.GetNextToken(Var aIndex: Integer;
  aTokens: tTokenProcessor; aIgnoreTokenParser: Boolean = False;
  ASkipPOs: Integer = 0): String;
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

function TInterpreter.GetNextTokenA(Var aIndex: Integer;
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
    I := VariableExistsIndex(TVariables.CleanVariableName(Result));
    if I <> -1 then
    begin
      LVariable := GetVariableByIndex(I);

      Result := LVariable.AsString;
    end
    else
      FoOutput.Log('Syntax Error: variable ' + Result + ' cannot be found.');

  end;
end;

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

function TInterpreter.IsRepeat(aCodeGeneratorItem: TObject): Boolean;
begin
  Result := (TCodeGeneratorItem(aCodeGeneratorItem).TagType = ttrepeat);
end;

constructor TNavigate.Create;
begin
  inherited Create;
end;

destructor TNavigate.Destroy;
begin
  if Assigned(fStatementParser) then
    fStatementParser.Free;

  inherited;
end;

end.
