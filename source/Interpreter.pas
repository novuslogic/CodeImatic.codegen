unit Interpreter;

interface

Uses
  Classes, ExpressionParser, SysUtils, DB, NovusStringUtils, Output,
  NovusList, Variants, Variables, XMLList, NovusGUIDEx, TokenProcessor, TagType,
  CodeGeneratorItem, TokenParser, ProjectItem;

const
  csCommamdSyntax: array [1 .. 25] of String = ('fieldnamebyindex',
    'fieldtypebyindex', 'lower', 'upper', 'uplower', 'fieldtypetodatatype',
    'cleardatatype', 'repeat', 'endrepeat', 'fieldcount', 'pred', 'blankline',
    'tablecount', 'tablenamebyindex', 'fieldassql', 'delimiter', 'reservelist',
    'rlist', 'list', 'listcount', 'listname', 'newguid', 'rlistformat',
    'fieldbyname', 'FieldByIndex');

Type
  TLoopType = (ltrepeat, ltendrepeat);

  TLoopPos = (lpStart, lpEnd);

  TLoop = Class(TObject)
  protected
    FLoopType: TLoopType;
    FLoopPos: TLoopPos;
    fiID: Integer;
    FoCodeGeneratorItem: TObject;
    FiValue: Integer;
    FbNegitiveFlag: Boolean;
  private
  public
    property LoopPos: TLoopPos read FLoopPos write FLoopPos;

    property LoopType: TLoopType read FLoopType write FLoopType;

    property ID: Integer read fiID write fiID;

    property CodeGeneratorItem: TObject read FoCodeGeneratorItem
      write FoCodeGeneratorItem;

    property Value: Integer read FiValue write FiValue;

    property NegitiveFlag: Boolean read FbNegitiveFlag write FbNegitiveFlag;

  End;

  TInterpreter = Class(tTokenParser)
  protected
    FoCodeGenerator: TObject;
    fiLoopCounter: Integer;
    fLoopList: tNovusList;
   // FoTokens: tTokenProcessor;
 //   foOutput: TOutput;
    FoCodeGeneratorItem: TCodeGeneratorItem;
   // foProjectItem: TObject;
  private
    function DoPluginTag(aTokens: tTokenProcessor; Var aIndex: Integer): string;
    function IsRepeat(ACodeGeneratorItem: TObject): Boolean;
    function IsEndRepeat(ACodeGeneratorItem: TObject): Boolean;
    function FindEndRepeatIndexPos(AIndex: Integer): Integer;
    function FindLoop(ALoopType: TLoopType; ALoopID: Integer): TLoop;

    function GetNextTag(ATokens: tTokenProcessor; Var AIndex: Integer;
      Var ASkipPOs: Integer; ASubCommand: Boolean = False;
      ASubVariable: Boolean = False): String;
    procedure AddVariable(AVariableName: String; AValue: Variant);

    //function Delimiter(ATokens: tTokenProcessor; Var AIndex: Integer): string;
    function Reservelist(ATokens: tTokenProcessor; Var AIndex: Integer;
      ACommandIndex: Integer): string;
    function XMLlistIndex(ATokens: tTokenProcessor;
      Var AIndex: Integer): string;
    function XMLListName(ATokens: tTokenProcessor; Var AIndex: Integer): string;
    function XMLlistCount(ATokens: tTokenProcessor;
      Var AIndex: Integer): string;

    function ParseVariable(ATokens: tTokenProcessor; Var AIndex: Integer;
      ASubCommand: Boolean = False): String;

    function VariableExistsIndex(AVariableName: String): Integer;
    function GetVariableByIndex(AIndex: Integer): TVariable;

    function DoRepeat(ATokens: tTokenProcessor; Var AIndex: Integer;
      aTagType: TTagType; Var ASkipPOs: Integer): string;

    function DoIF(ATokens: tTokenProcessor; Var AIndex: Integer;
      aTagType: TTagType; Var ASkipPOs: Integer): string;
  public
    constructor Create(aCodeGenerator: TObject; aOutput: TOutput;
        aProjectItem: TProjectItem); overload;

    destructor Destroy; override;

    function ParseToken(aToken: string; var aIndex: Integer; aTokens: tTokenProcessor; aSkipPos: integer) : String;

    function GetNextToken(Var AIndex: Integer;
      ATokens: tTokenProcessor; aIgnoreTokenParser: Boolean = false;aSkipPos: integer = 0): String;

    function GetNextTokenA(Var AIndex: Integer;
      ATokens: tTokenProcessor): String;

    //function DoTagTypeInterpreter(ATokens: tTokenProcessor): TTagType;
    function CommandSyntaxIndex(aCommand: String): Integer;

    function Execute(aCodeGeneratorItem: tCodeGeneratorItem; Var ASkipPos: Integer): String;
    function LanguageFunctions(AFunction: string; ADataType: String): String;

    property  oTokens: tTokenProcessor read foTokens write foTokens;
 End;

implementation

Uses
  NovusTemplate,
  CodeGenerator,
  Reservelist,
  DataProcessor,
  runtime,
  TagParser;

constructor TInterpreter.Create(ACodeGenerator: TObject; aOutput: TOutput;
        aProjectItem: TProjectItem);
begin
  inherited Create;

  foProjectItem := aProjectItem;

  FoCodeGenerator := ACodeGenerator;

  fLoopList := tNovusList.Create(TLoop);

  FoOutput := AOutput;

  fiLoopCounter := 0;
end;

destructor TInterpreter.Destroy;
begin
  fLoopList.Free;

  inherited;
end;


function TInterpreter.Reservelist(ATokens: tTokenProcessor; Var AIndex: Integer;
  ACommandIndex: Integer): string;
Var
  lConnectionItem: tConnectionItem;
  lsFilename: String;
  loreservelist: treservelist;
  lsWord: String;
  lsFormatOption: String;
begin
  Result := '';

  If GetNextTokenA(AIndex, ATokens) = '(' then
  begin
    lsFilename := GetNextTokenA(AIndex, ATokens);

    lsWord := GetNextTokenA(AIndex, ATokens);

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
          lsFormatOption := GetNextTokenA(AIndex, ATokens);

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
    foOutput.Log('Incorrect syntax: lack "("');

  end;
end;

function TInterpreter.XMLlistIndex(ATokens: tTokenProcessor;
  Var AIndex: Integer): string;
Var
  lConnectionItem: tConnectionItem;
  lsStr: String;
  loXMLlist: tXMLlist;
  lsDelimiter: string;
  liDelimiterCounter, liDelimiterLength: Integer;
begin
  Result := '';

  If GetNextTokenA(AIndex, ATokens) = '(' then
  begin
    lsStr := GetNextTokenA(AIndex, ATokens);

    if lsStr <> '' then
    begin
      Result := lsStr;

      loXMLlist := NIL;
      if FileExists(lsStr) then
      begin
        loXMLlist := tXMLlist.Create;

        loXMLlist.XMLFileName := lsStr;
        loXMLlist.Retrieve;

        lsStr := GetNextTokenA(AIndex, ATokens);
        if lsStr <> '' then
        begin
          if TNovusStringUtils.IsNumberStr(lsStr) then
          begin
            Result := loXMLlist.GetValueByIndex(StrToint(lsStr));
          end
          else
            foOutput.Log('Incorrect syntax: Index is not a number ');

        end
        else
          foOutput.Log('Incorrect syntax: Index is blank.');

        if Assigned(loXMLlist) then
          loXMLlist.Free;

      end
      else
      begin
        foOutput.LogError('Error: List filname cannot be found.');

      end;

    end
    else
      foOutput.Log('Incorrect syntax: List is blank.');
  end
  else
  begin
    foOutput.Log('Incorrect syntax: lack "("');

  end;

  if GetNextTokenA(AIndex, ATokens) <> ')' then
    foOutput.Log('Incorrect syntax: lack ")"');
end;

function TInterpreter.XMLListName(ATokens: tTokenProcessor;
  Var AIndex: Integer): string;
Var
  lConnectionItem: tConnectionItem;
  lsStr: String;
  loXMLlist: tXMLlist;
  lsDelimiter: string;
  liDelimiterCounter, liDelimiterLength: Integer;
begin
  Result := '';

  If GetNextTokenA(AIndex, ATokens) = '(' then
  begin
    lsStr := GetNextTokenA(AIndex, ATokens);

    if lsStr <> '' then
    begin
      Result := lsStr;

      loXMLlist := NIL;
      if FileExists(lsStr) then
      begin
        loXMLlist := tXMLlist.Create;

        loXMLlist.XMLFileName := lsStr;
        loXMLlist.Retrieve;

        lsStr := GetNextTokenA(AIndex, ATokens);
        if lsStr <> '' then
        begin
          if TNovusStringUtils.IsNumberStr(lsStr) then
          begin
            Result := loXMLlist.GetNameByIndex(StrToint(lsStr));
          end
          else
            foOutput.Log('Incorrect syntax: Index is not a number ');

        end
        else
          foOutput.Log('Incorrect syntax: Index is blank.');

        if Assigned(loXMLlist) then
          loXMLlist.Free;

      end
      else
      begin
        foOutput.LogError('Error: List filname cannot be found.');

      end;

    end
    else
      foOutput.Log('Incorrect syntax: List is blank.');
  end
  else
  begin
    foOutput.Log('Incorrect syntax: lack "("');

  end;

  if GetNextTokenA(AIndex, ATokens) <> ')' then
    foOutput.Log('Incorrect syntax: lack ")"');
end;

function TInterpreter.XMLlistCount(ATokens: tTokenProcessor;
  Var AIndex: Integer): string;
Var
  lConnectionItem: tConnectionItem;
  lsStr: String;
  loXMLlist: tXMLlist;
  lsDelimiter: string;
  liDelimiterCounter, liDelimiterLength: Integer;
begin
  Result := '0';

  If GetNextTokenA(AIndex, ATokens) = '(' then
  begin
    lsStr := GetNextTokenA(AIndex, ATokens);

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
        foOutput.LogError('Error: List filname cannot be found.');

      end;

    end
    else
      foOutput.Log('Incorrect syntax: List is blank.');
  end
  else
  begin
    foOutput.Log('Incorrect syntax: lack "("');

  end;
end;


function TInterpreter.DoPluginTag(aTokens: tTokenProcessor; Var aIndex: Integer): string;
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
       Result := oRuntime.oPlugins.GetTag(lsToken1, lsToken2,
            aTokens, tProjectItem(foProjectItem));
     end;

  aIndex := aTokens.TokenIndex ;
end;

function TInterpreter.ParseToken(aToken: string; var aIndex: Integer; aTokens: tTokenProcessor; aSkipPos: integer) : String;
var
  fTagType: TTagType;
begin
   Try
     Result := aToken;

    fTagType := TTagParser.ParseTagType(foProjectItem, FoCodeGenerator,
      aToken, foOutput, true);

    if fTagType = ttplugintag then
      begin
        result := DoPluginTag(aTokens, AIndex);
      end
    else
    if fTagType = ttrepeat then
       Result := DoRepeat(ATokens, AIndex, ttRepeat, ASkipPos)
    else
    if fTagType = ttendrepeat then
       Result := DoRepeat(ATokens, AIndex, ttEndRepeat, ASkipPos)
    else
    if fTagType = ttif then
       Result := DoIF(ATokens, AIndex, ttif, ASkipPos)
    else
    if fTagType = ttendif then
       Result := DoIf(ATokens, AIndex, ttEndif, ASkipPos);


    if (CommandSyntaxIndex(aToken) <> 0) then
    begin
      case CommandSyntaxIndex(aToken) of

       // 16:
        //  Result := Delimiter(ATokens, AIndex);
        17, 18:
          Result := Reservelist(ATokens, AIndex, 0);
        19:
          Result := XMLlistIndex(ATokens, AIndex);
        20:
          Result := XMLlistCount(ATokens, AIndex);
        21:
          Result := XMLListName(ATokens, AIndex);

        23:
          Result := Reservelist(ATokens, AIndex, 1);

      end;
    end;


    if Pos('$$', ATokens[AIndex]) = 1 then
      Result := tTokenParser.ParseToken(Self, ATokens[AIndex],
        (foProjectItem as TProjectItem),
        foOutput, ATokens, AIndex,
        TCodeGenerator(FoCodeGenerator).oProject)
    else
    if Pos('$', ATokens[AIndex]) = 1 then
      Result := ParseVariable(ATokens, AIndex);


  Except
    foOutput.InternalError;
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
    Result := ATokens[AIndex];
  try
    lsNextToken := ATokens[AIndex];

    fTagType := TTagParser.ParseTagType(foProjectItem, FoCodeGenerator,
      lsNextToken, foOutput, true);


    if fTagType = ttplugintag then
      begin
        result := DoPluginTag(ATokens, AIndex);
      end
    else
    if fTagType = ttrepeat then
       Result := DoRepeat(ATokens, AIndex, ttRepeat, ASkipPos)
    else
    if fTagType = ttendrepeat then
       Result := DoRepeat(ATokens, AIndex, ttEndRepeat, ASkipPos)
    else
    if fTagType = ttif then
       Result := DoIF(ATokens, AIndex, ttif, ASkipPos)
    else
    if fTagType = ttendif then
       Result := DoIf(ATokens, AIndex, ttEndif, ASkipPos);


    if (CommandSyntaxIndex(lsNextToken) <> 0) then
    begin
      case CommandSyntaxIndex(lsNextToken) of

       // 16:
        //  Result := Delimiter(ATokens, AIndex);
        17, 18:
          Result := Reservelist(ATokens, AIndex, 0);
        19:
          Result := XMLlistIndex(ATokens, AIndex);
        20:
          Result := XMLlistCount(ATokens, AIndex);
        21:
          Result := XMLListName(ATokens, AIndex);

        23:
          Result := Reservelist(ATokens, AIndex, 1);




      end;
    end;

    if Not ASubCommand then
    begin
      if Pos('$$', ATokens[AIndex]) = 1 then
        Result := tTokenParser.ParseToken(Self, ATokens[AIndex],
          (foProjectItem as TProjectItem), (*TCodeGenerator(FoCodeGenerator)
          .oVariables, *)foOutput, ATokens, AIndex,
          TCodeGenerator(FoCodeGenerator).oProject)
      else
      if Pos('$', ATokens[AIndex]) = 1 then
        Result := ParseVariable(ATokens, AIndex)
    end;

  Except
    foOutput.InternalError;
  end;
end;

function TInterpreter.DoRepeat(ATokens: tTokenProcessor;
  Var AIndex: Integer; aTagType: TTagType; Var ASkipPOs: Integer): string;
Var
  lbNegitiveFlag: Boolean;
  liPos, liLineNoPos: Integer;
  liStartPos1, liEndPos1, liStartPos2, liEndPos2: Integer;
  LStartLoop, FLoop: TLoop;
  liLastSourceNo, I, X, Y, Z, A: Integer;
  LCodeGeneratorItem3, LCodeGeneratorItem2, LCodeGeneratorItem1
    : tCodeGeneratorItem;
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
    Var APos: Integer): tCodeGeneratorItem;
  Var
    Z: Integer;
    LCodeGeneratorItem: tCodeGeneratorItem;
  begin
    Result := NIL;

    for Z := APos to TCodeGenerator(FoCodeGenerator)
      .oCodeGeneratorList.Count - 1 do
    begin
      LCodeGeneratorItem := tCodeGeneratorItem(TCodeGenerator(FoCodeGenerator)
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
    ttRepeat:
      begin
        If GetNextTokenA(AIndex, ATokens) = '(' then
        begin
          LsValue := GetNextTokenA(AIndex, ATokens);

          if TNovusStringUtils.IsNumberStr(LsValue) then
          begin
            if GetNextTokenA(AIndex, ATokens) = ')' then
            begin
              Inc(fiLoopCounter, 1);

              FLoop := TLoop.Create;

              FLoop.LoopType := ltrepeat;
              FLoop.LoopPos := lpStart;
              FLoop.ID := fiLoopCounter;

              FLoop.CodeGeneratorItem := FoCodeGeneratorItem;

              FLoop.NegitiveFlag := (StrToint(LsValue) < 0);

              FLoop.Value := 0;
              If StrToint(LsValue) > 0 then
                FLoop.Value := StrToint(LsValue);

              fLoopList.Add(FLoop);

              liStartPos1 := FoCodeGeneratorItem.oTemplateTag.TagIndex;

              Inc(liStartPos1, 1);

              liEndPos1 := FindEndRepeatIndexPos(liStartPos1);

              FoCodeGeneratorItem.oTemplateTag.TagValue := cDeleteLine;

              ASkipPOs := liEndPos1;
            end
            else
              foOutput.Log('Incorrect syntax: lack ")"');

          end
          else
            foOutput.Log('Incorrect syntax: Index is not a number ');

        end
        else
          foOutput.Log('Incorrect syntax: lack "("');
      end;
    ttEndRepeat:
      begin
        ASkipPOs := 0;

        LStartLoop := FindLoop(ltrepeat, fiLoopCounter);

        LiValue := LStartLoop.Value;
        lbNegitiveFlag := LStartLoop.NegitiveFlag;

        liStartPos1 := (LStartLoop.CodeGeneratorItem As tCodeGeneratorItem)
          .oTemplateTag.TagIndex;
        Inc(liStartPos1, 1);

        liStartSourceLineNo :=
          (LStartLoop.CodeGeneratorItem As tCodeGeneratorItem)
          .oTemplateTag.SourceLineNo;


         liEndPos1 := (FoCodeGeneratorItem As tCodeGeneratorItem)
           .oTemplateTag.TagIndex;
         Dec(liEndPos1, 1);

        liEndSourceLineNo := (FoCodeGeneratorItem As tCodeGeneratorItem)
          .oTemplateTag.SourceLineNo;
        Dec(liEndSourceLineNo, 1);

        for I := liStartPos1 to liEndPos1 do
        begin
          LCodeGeneratorItem1 :=
            tCodeGeneratorItem(TCodeGenerator(FoCodeGenerator)
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

              (*
              If (LCodeGeneratorItem1.TagType = ttInterpreter) or
                 (LCodeGeneratorItem1.TagType = ttRepeat) or
                 (LCodeGeneratorItem1.TagType = ttEndRepeat) then
                 *)
             if IsInterpreterTagType(LCodeGeneratorItem1.tagtype) then
              begin
                If IsEndRepeat(LCodeGeneratorItem1) then
                begin
                  FLoop := FindLoop(ltrepeat, fiLoopCounter);

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

          if ((FindEndRepeatIndexPos(liStartPos1) + liStartPos1) <
            (liEndSourceLineNo - liStartSourceLineNo)) then
            liSourceLineCount := (liEndSourceLineNo - liStartSourceLineNo) -
              ((FindEndRepeatIndexPos(liStartPos1) + liStartPos1) + 1)
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
function TInterpreter.DoIF(ATokens: tTokenProcessor;
  Var AIndex: Integer; aTagType: TTagType; Var ASkipPOs: Integer): string;
Var
  lTokens : tTokenProcessor;
  LExpressionParser: tExpressionParser;
  lbNegitiveFlag: Boolean;
  liPos, liLineNoPos: Integer;
  liStartPos1, liEndPos1, liStartPos2, liEndPos2: Integer;
  LStartLoop, FLoop: TLoop;
  liLastSourceNo, I, X, Y, Z, A: Integer;
  LCodeGeneratorItem3, LCodeGeneratorItem2, LCodeGeneratorItem1
    : tCodeGeneratorItem;
  LTemplateTag1, LTemplateTag2: TTemplateTag;
  LTemplate: TNovusTemplate;
  liSkipPos, liTagIndex: Integer;
  LCodeGenerator: TCodeGenerator;
  LsToken: String;
  lsValue: String;
  lxVariable: tVariable;
  lyVariable: tVariable;
  LiValue: Integer;
  liLineCount: Integer;
  lsTagValue: String;
  liStartTagIndex, liEndTagIndex, liTagIndexCounter, liLastEndSourceLineNo,
    liLastNextSourceLineNo, liNextSourceLineNo1, liNextSourceLineNo2,
    liStartSourceLineNo, liSourceLineCount, liEndSourceLineNo: Integer;

  function GetCodeGeneratorItemBySourceLineNo(ASourceLineNo: Integer;
    Var APos: Integer): tCodeGeneratorItem;
  Var
    Z: Integer;
    LCodeGeneratorItem: tCodeGeneratorItem;
  begin
    Result := NIL;

    for Z := APos to TCodeGenerator(FoCodeGenerator)
      .oCodeGeneratorList.Count - 1 do
    begin
      LCodeGeneratorItem := tCodeGeneratorItem(TCodeGenerator(FoCodeGenerator)
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
    ttIf:
      begin
       If Uppercase(GetNextToken(AIndex, ATokens, true)) = 'IF' then
         begin
           If GetNextToken(AIndex, ATokens) = '(' then
            begin
              LsToken := GetNextToken(AIndex, ATokens);
              while Not ATokens.EOF do
                begin







                  LsToken := GetNextToken(AIndex, ATokens);

                end;

               if AIndex = ATokens.Count then
                AIndex := ATokens.Count - 1;




              (*
              if TNovusStringUtils.IsNumberStr(LsValue) then
              begin
                if GetNextTokenA(AIndex, ATokens) = ')' then
                begin
                  Inc(fiLoopCounter, 1);

                  FLoop := TLoop.Create;

                  FLoop.LoopType := ltrepeat;
                  FLoop.LoopPos := lpStart;
                  FLoop.ID := fiLoopCounter;

                  FLoop.CodeGeneratorItem := FoCodeGeneratorItem;

                  FLoop.NegitiveFlag := (StrToint(LsValue) < 0);

                  FLoop.Value := 0;
                  If StrToint(LsValue) > 0 then
                    FLoop.Value := StrToint(LsValue);

                  fLoopList.Add(FLoop);

                  liStartPos1 := FoCodeGeneratorItem.oTemplateTag.TagIndex;

                  Inc(liStartPos1, 1);

                  liEndPos1 := FindEndRepeatIndexPos(liStartPos1);

                  FoCodeGeneratorItem.oTemplateTag.TagValue := cDeleteLine;

                  ASkipPOs := liEndPos1;
                end
                else
                  foOutput.Log('Incorrect syntax: lack ")"');

              end
              else
                foOutput.Log('Incorrect syntax: Index is not a number ');
               *)
            end
            else
              foOutput.Log('Incorrect syntax: lack "("');

         end
         else
           foOutput.Log('Incorrect syntax: lack "IF"');
      end;
    ttEndIf:
      begin
        (*
        ASkipPOs := 0;

        LStartLoop := FindLoop(ltrepeat, fiLoopCounter);

        LiValue := LStartLoop.Value;
        lbNegitiveFlag := LStartLoop.NegitiveFlag;

        liStartPos1 := (LStartLoop.CodeGeneratorItem As tCodeGeneratorItem)
          .oTemplateTag.TagIndex;
        Inc(liStartPos1, 1);

        liStartSourceLineNo :=
          (LStartLoop.CodeGeneratorItem As tCodeGeneratorItem)
          .oTemplateTag.SourceLineNo;


         liEndPos1 := (FoCodeGeneratorItem As tCodeGeneratorItem)
           .oTemplateTag.TagIndex;
         Dec(liEndPos1, 1);

        liEndSourceLineNo := (FoCodeGeneratorItem As tCodeGeneratorItem)
          .oTemplateTag.SourceLineNo;
        Dec(liEndSourceLineNo, 1);

        for I := liStartPos1 to liEndPos1 do
        begin
          LCodeGeneratorItem1 :=
            tCodeGeneratorItem(TCodeGenerator(FoCodeGenerator)
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


             if IsInterpreterTagType(LCodeGeneratorItem1.tagtype) then
              begin
                If IsEndRepeat(LCodeGeneratorItem1) then
                begin
                  FLoop := FindLoop(ltrepeat, fiLoopCounter);

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

          if ((FindEndRepeatIndexPos(liStartPos1) + liStartPos1) <
            (liEndSourceLineNo - liStartSourceLineNo)) then
            liSourceLineCount := (liEndSourceLineNo - liStartSourceLineNo) -
              ((FindEndRepeatIndexPos(liStartPos1) + liStartPos1) + 1)
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


function TInterpreter.FindLoop(ALoopType: TLoopType; ALoopID: Integer): TLoop;
Var
  I: Integer;
  FLoop: TLoop;
begin
  Result := NIL;

  for I := 0 to fLoopList.Count - 1 do
  begin
    FLoop := TLoop(fLoopList.Items[I]);

    if (FLoop.LoopType = ALoopType) and (FLoop.ID = ALoopID) then
    begin
      Result := FLoop;
      Break;
    end;
  end;
end;

function TInterpreter.ParseVariable(ATokens: tTokenProcessor;
  Var AIndex: Integer; ASubCommand: Boolean = False): String;
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

    Inc(AIndex);

    if (AIndex <= ATokens.Count - 1) then
      Result := GetNextTag(ATokens, AIndex, liSkipPos, true);
  end;

begin
  Result := '';
  FOut := False;

  lsVariableName1 := TVariables.CleanVariableName(ATokens[AIndex]);

  if ATokens[0] = '=' then
    FOut := true;

  If GetToken = '=' then
  begin
    I := VariableExistsIndex(lsVariableName1);

    if I = -1 then
    begin
      LsValue := GetToken;

      LsValue := tTokenParser.ParseToken(Self, LsValue,
        (foProjectItem as TProjectItem),(* TCodeGenerator(FoCodeGenerator)
        .oVariables,*) foOutput, ATokens, AIndex, TCodeGenerator(FoCodeGenerator)
        .oProject);

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
            //foOutput.Log(lsValue);

          end
       else
       If TNovusStringUtils.IsNumberStr(LsValue) then
        begin
          if Pos('.', LsValue) > 0 then
            FVariable1.Value := TNovusStringUtils.Str2Float(LsValue)
          else
            FVariable1.Value := TNovusStringUtils.Str2Int(LsValue);
        end
        else
          FVariable1.Value := LsValue;
        //else If TNovusStringUtils.IsAlphaStr(LsValue) then
        //begin
        //  FVariable1.Value := LsValue;
        ///
        //end;
      end;

      LStr := GetToken;

      If LStr = '-' then
      begin
        LsValue := GetToken;

        If TNovusStringUtils.IsNumberStr(LsValue) then
          FVariable1.Value := FVariable1.Value -
            TNovusStringUtils.Str2Int(LsValue)
        else
          foOutput.Log('Incorrect syntax: Is not a number');
      end
      else If LStr = '+' then
      begin
        LsValue := GetToken;

        If TNovusStringUtils.IsNumberStr(LsValue) then
          FVariable1.Value := FVariable1.Value +
            TNovusStringUtils.Str2Int(LsValue)
        else
          foOutput.Log('Incorrect syntax: Is not a number');
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
        foOutput.Log('Syntax error: "' + lsVariableName1 + '" not defined');
        foOutput.Failed := true;
      end;

    end
    else
      foOutput.Log('Incorrect syntax: lack "="');
  end;
end;

procedure TInterpreter.AddVariable(AVariableName: String; AValue: Variant);
begin
  (foProjectItem as TProjectItem).oVariables.AddVariable
    (AVariableName, AValue);
end;

function TInterpreter.Execute(aCodeGeneratorItem: tCodeGeneratorItem; Var ASkipPos: Integer): String;
Var
  FIndex: Integer;
  FOut: Boolean;
  fsScript: string;
  lbIsFailedCompiled: Boolean;
begin
  Result := '';

  FOut := False;

  FoCodeGeneratorItem := ACodeGeneratorItem;
  FoTokens := FoCodeGeneratorItem.oTokens;


  FIndex := 0;
  if FoTokens.strings[0] = '=' then
  begin
    FOut := true;
    FIndex := 1;
  end;

  if FOut = true then
  begin
    Result := GetNextTag(FoTokens, FIndex, ASkipPOs)
  end
  else
  begin
    Result := '';
    GetNextTag(FoTokens, FIndex, ASkipPOs);
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

function TInterpreter.GetNextToken(Var AIndex: Integer;
  ATokens: tTokenProcessor; aIgnoreTokenParser: Boolean = false;aSkipPos: integer = 0): String;
Var
  I: Integer;
  LVariable: TVariable;
  liSkipPos: Integer;
  lsNextToken: String;
begin
  lsNextToken := ATokens.GetNextToken(aIndex);

  if Not aIgnoreTokenParser then
     Result := ParseToken(lsNextToken, aIndex, aTokens, aSkipPos)
  else result := lsNextToken;

  if result = oTokens.Strings[aIndex] then
    Inc(AIndex);

  //if AIndex = ATokens.Count then
  //  AIndex := ATokens.Count - 1;

  ATokens.TokenIndex := aIndex;
end;




function TInterpreter.GetNextTokenA(Var AIndex: Integer;
  ATokens: tTokenProcessor): String;
Var
  I: Integer;
  LVariable: TVariable;
  liSkipPos: Integer;
begin
  Result := '';

  Inc(AIndex);

  if AIndex = ATokens.Count then
    AIndex := ATokens.Count - 1;

  Result := GetNextTag(ATokens, AIndex, liSkipPos, true);

  if Pos('$', Result) = 1 then
  begin
    I := VariableExistsIndex(TVariables.CleanVariableName(Result));
    if I <> -1 then
    begin
      LVariable := GetVariableByIndex(I);

      Result := LVariable.AsString;
    end
    else
      foOutput.Log('Syntax Error: variable ' + Result + ' cannot be found.');

  end;
end;

function TInterpreter.VariableExistsIndex(AVariableName: String): Integer;
begin
  Result := (foProjectItem as TProjectItem).oVariables.VariableExistsIndex
    (AVariableName)
end;

function TInterpreter.GetVariableByIndex(AIndex: Integer): TVariable;
begin
  Result := (foProjectItem as TProjectItem).oVariables.GetVariableByIndex(AIndex);
end;

function TInterpreter.FindEndRepeatIndexPos(AIndex: Integer): Integer;
Var
  I: Integer;
  LCodeGeneratorItem: tCodeGeneratorItem;
  LCodeGeneratorList: tNovusList;
  LTemplateTag: TTemplateTag;
  iCount: Integer;
begin
  Result := -1;

  LCodeGeneratorList := (FoCodeGenerator As TCodeGenerator).oCodeGeneratorList;

  iCount := 0;
  for I := AIndex to LCodeGeneratorList.Count - 1 do
  begin
    LCodeGeneratorItem := tCodeGeneratorItem(LCodeGeneratorList.Items[I]);

    if LCodeGeneratorItem.TagType = ttInterpreter then
    begin
      LTemplateTag := LCodeGeneratorItem.oTemplateTag;

      if Pos(csCommamdSyntax[8], LTemplateTag.TagName) = 1 then
      begin
        Inc(iCount);
      end
      else if (LTemplateTag.TagName = csCommamdSyntax[9]) and (iCount = 0) then
      begin
        Result := I;

        Exit;
      end
      else if (LTemplateTag.TagName = csCommamdSyntax[9]) and (iCount > 0) then
      begin
        Dec(iCount);
      end;
    end;
  end;
end;


function TInterpreter.IsEndRepeat(ACodeGeneratorItem: TObject): Boolean;
begin
  Result := (CommandSyntaxIndex(tCodeGeneratorItem(ACodeGeneratorItem)
    .oTokens[0]) = 9);
end;

function TInterpreter.IsRepeat(ACodeGeneratorItem: TObject): Boolean;
begin
  Result := (CommandSyntaxIndex(tCodeGeneratorItem(ACodeGeneratorItem)
    .oTokens[0]) = 8);
end;


end.
