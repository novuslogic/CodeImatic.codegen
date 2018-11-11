unit Interpreter;

interface

Uses
  Classes, ExpressionParser, SysUtils, DB, NovusStringUtils, Output,
  NovusList, Variants, Variables, XMLList, NovusGUIDEx, TokenProcessor;

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

  TInterpreter = Class(TObject)
  protected
    FoCodeGenerator: TObject;
    fiLoopCounter: Integer;
    fLoopList: tNovusList;
    FoTokens: tTokenProcessor;
    FOutput: TOutput;
  //  FoCodeGeneratorItem: TObject;
    foProjectItem: TObject;
  private
    //function ParseCommand(aCommand: string): string;

    function plugintag(aTokens: tTokenProcessor; Var aIndex: Integer): string;
    function IsRepeat(ACodeGeneratorItem: TObject): Boolean;
    function IsEndRepeat(ACodeGeneratorItem: TObject): Boolean;
    function FindEndRepeatIndexPos(AIndex: Integer): Integer;
    function FindLoop(ALoopType: TLoopType; ALoopID: Integer): TLoop;

    function GetNextTag(ATokens: tTokenProcessor; Var AIndex: Integer;
      Var ASkipPOs: Integer; ASubCommand: Boolean = False;
      ASubVariable: Boolean = False): String;
    procedure AddVariable(AVariableName: String; AValue: Variant);

    //function FieldFunctions(ATokens: tTokenProcessor; Var AIndex: Integer;
    //  ACommandIndex: Integer): string;
   // function FieldAsSQL(ATokens: tTokenProcessor; Var AIndex: Integer): string;
    function Delimiter(ATokens: tTokenProcessor; Var AIndex: Integer): string;
    function Reservelist(ATokens: tTokenProcessor; Var AIndex: Integer;
      ACommandIndex: Integer): string;
    function XMLlistIndex(ATokens: tTokenProcessor;
      Var AIndex: Integer): string;
    function XMLListName(ATokens: tTokenProcessor; Var AIndex: Integer): string;
    function XMLlistCount(ATokens: tTokenProcessor;
      Var AIndex: Integer): string;

      (*
    function TableFunctions(ATokens: tTokenProcessor; Var AIndex: Integer;
      ACommandIndex: Integer): string;
      *)

    function ParseVariable(ATokens: tTokenProcessor; Var AIndex: Integer;
      ASubCommand: Boolean = False): String;

    function Functions(ATokens: tTokenProcessor; Var AIndex: Integer;
      ACommandIndex: Integer): String;


    //function Procedures(ATokens: tTokenProcessor; Var AIndex: Integer;
    //  ACommandIndex: Integer): String;

    //function FieldTypeToDataType(AFieldType: String): String;
    //function ClearDataType(ADataType: String): String;

    function VariableExistsIndex(AVariableName: String): Integer;
    function GetVariableByIndex(AIndex: Integer): TVariable;

    function LoopFunctions(ATokens: tTokenProcessor; Var AIndex: Integer;
      ACommandIndex: Integer; Var ASkipPOs: Integer): string;
  public
    constructor Create(ACodeGenerator: TObject; AOutput: TOutput;
      aProjectItem: TObject); virtual;
    destructor Destroy; override;

    function GetNextToken(Var AIndex: Integer;
      ATokens: tTokenProcessor): String;

    function CommandSyntaxIndexByTokens(ATokens: tTokenProcessor): Integer;
    function CommandSyntaxIndex(aCommand: String): Integer;

    function Execute(aTokens: tTokenProcessor; Var ASkipPOs: Integer): String;
    function LanguageFunctions(AFunction: string; ADataType: String): String;


    property  oTokens: tTokenProcessor read foTokens write foTokens;
    //property oCodeGeneratorItem: TObject read FoCodeGeneratorItem
    //  write FoCodeGeneratorItem;
  End;

implementation

Uses
  NovusTemplate,
  CodeGenerator,
  Reservelist,
  DataProcessor,
  runtime,
  ProjectItem,
  TokenParser,
  TagParser,
  TagType,
  CodeGeneratorItem;

constructor TInterpreter.Create;
begin
  inherited Create;

  foProjectItem := aProjectItem;

  FoCodeGenerator := ACodeGenerator;

  fLoopList := tNovusList.Create(TLoop);

  FOutput := AOutput;

  fiLoopCounter := 0;
end;

destructor TInterpreter.Destroy;
begin
  fLoopList.Free;

  inherited;
end;

(*
function TInterpreter.FieldFunctions(ATokens: tTokenProcessor;
  Var AIndex: Integer; ACommandIndex: Integer): string;
Var
  lConnectionItem: tConnectionItem;
  FFieldDesc: tFieldDesc;

  FConnectionName: String;
  FTableName: String;
  FFieldIndex: Integer;
  LStr: String;
  FFieldType: tFieldType;
begin
  Result := '';

  If GetNextToken(AIndex, ATokens) = '(' then
  begin
    FConnectionName := GetNextToken(AIndex, ATokens);

    lConnectionItem := (foProjectItem as TProjectItem)
      .oProject.oProjectConfig.oConnections.FindConnectionName(FConnectionName);

    if Assigned(lConnectionItem) then
    begin
      if lConnectionItem.Connected then
      begin
        FTableName := GetNextToken(AIndex, ATokens);

        If lConnectionItem.TableExists(FTableName) then
        begin
          if ((ACommandIndex = 0) or (ACommandIndex = 1)) then
          begin
            LStr := GetNextToken(AIndex, ATokens);

            if TNovusStringUtils.IsNumberStr(LStr) then
            begin
              FFieldIndex := StrToint(LStr);

              FFieldDesc := lConnectionItem.FieldByIndex(FTableName,
                FFieldIndex);

              if Assigned(FFieldDesc) then
              begin
                if GetNextToken(AIndex, ATokens) = ')' then
                begin
                  case ACommandIndex of
                    0:
                      Result := FFieldDesc.FieldName;
                    1:
                      begin
                        // this need to be fixed
                        // fFieldType := (foProjectItem as TProjectItem).oDBSchema.GetFieldType(FFieldDesc, lConnectionItem.AuxDriver);
                        FFieldType := lConnectionItem.oDBSchema.GetFieldType
                          (FFieldDesc, lConnectionItem.AuxDriver);

                        FFieldType.Free;
                      end;
                  end;

                  FFieldDesc.Free;

                  Exit;
                end
                else
                  FOutput.Log('Incorrect syntax: lack ")"');
              end
              else
              begin
                FOutput.LogError('Error: Field cannot be found.');
              end;
            end
            else
            begin
              FOutput.Log('Incorrect syntax: Index is not a number ');

            end;
          end
          else
          begin
            case ACommandIndex of
              2:
                Result := IntToStr(lConnectionItem.FieldCount(FTableName));

              3:
                begin
                  LStr := GetNextToken(AIndex, ATokens);

                  FFieldDesc := lConnectionItem.FieldByName(FTableName, LStr);

                  if Assigned(FFieldDesc) then
                  begin
                    if GetNextToken(AIndex, ATokens) = ')' then
                      Result := FFieldDesc.FieldName;

                    FFieldDesc.Free;

                    Exit;
                  end
                  else
                  begin
                    FOutput.LogError('Error: Field cannot be found.');

                  end;
                end;
            end;
          end;
        end
        else
        begin
          FOutput.LogError('Error: Table cannot be found "' + FTableName + '"');
        end;

      end
      else
      begin
        FOutput.LogError('Error: Connectioname "' + FConnectionName +
          '" connected.');
      end;
    end
    else
    begin
      FOutput.LogError('Error: Connectioname cannot be found "' +
        FConnectionName + '"');
    end;
  end
  else
  begin
    FOutput.Log('Incorrect syntax: lack "("');

  end;
end;
*)
function TInterpreter.Delimiter(ATokens: tTokenProcessor;
  Var AIndex: Integer): string;
Var
  lConnectionItem: tConnectionItem;
  lsStr, lsDelimiter: String;
  liDelimiterCounter: Integer;
  liDelimiterLength: Integer;

begin
  Result := '';

  If GetNextToken(AIndex, ATokens) = '(' then
  begin
    lsDelimiter := GetNextToken(AIndex, ATokens);

    if lsDelimiter <> '' then
    begin
      lsStr := GetNextToken(AIndex, ATokens);

      if TNovusStringUtils.IsNumberStr(lsStr) then
      begin
        liDelimiterCounter := StrToint(lsStr);

        lsStr := GetNextToken(AIndex, ATokens);

        if TNovusStringUtils.IsNumberStr(lsStr) then
        begin
          liDelimiterLength := StrToint(lsStr);

          if GetNextToken(AIndex, ATokens) = ')' then
          begin
            Result := lsDelimiter;
            if liDelimiterCounter = liDelimiterLength then
              Result := '';
          end
          else
            FOutput.Log('Incorrect syntax: lack ")"');
        end
        else
          FOutput.Log('Incorrect syntax: delimiter length is not a number ');

      end
      else
        FOutput.Log('Incorrect syntax: delimiter counter is not a number ');

    end
    else
      FOutput.Log('Incorrect syntax: delimiter is blank.');
  end
  else
  begin
    FOutput.Log('Incorrect syntax: lack "("');

  end;
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

  If GetNextToken(AIndex, ATokens) = '(' then
  begin
    lsFilename := GetNextToken(AIndex, ATokens);

    lsWord := GetNextToken(AIndex, ATokens);

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
          lsFormatOption := GetNextToken(AIndex, ATokens);

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
    FOutput.Log('Incorrect syntax: lack "("');

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

  If GetNextToken(AIndex, ATokens) = '(' then
  begin
    lsStr := GetNextToken(AIndex, ATokens);

    if lsStr <> '' then
    begin
      Result := lsStr;

      loXMLlist := NIL;
      if FileExists(lsStr) then
      begin
        loXMLlist := tXMLlist.Create;

        loXMLlist.XMLFileName := lsStr;
        loXMLlist.Retrieve;

        lsStr := GetNextToken(AIndex, ATokens);
        if lsStr <> '' then
        begin
          if TNovusStringUtils.IsNumberStr(lsStr) then
          begin
            Result := loXMLlist.GetValueByIndex(StrToint(lsStr));
          end
          else
            FOutput.Log('Incorrect syntax: Index is not a number ');

        end
        else
          FOutput.Log('Incorrect syntax: Index is blank.');

        if Assigned(loXMLlist) then
          loXMLlist.Free;

      end
      else
      begin
        FOutput.LogError('Error: List filname cannot be found.');

      end;

    end
    else
      FOutput.Log('Incorrect syntax: List is blank.');
  end
  else
  begin
    FOutput.Log('Incorrect syntax: lack "("');

  end;

  if GetNextToken(AIndex, ATokens) <> ')' then
    FOutput.Log('Incorrect syntax: lack ")"');
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

  If GetNextToken(AIndex, ATokens) = '(' then
  begin
    lsStr := GetNextToken(AIndex, ATokens);

    if lsStr <> '' then
    begin
      Result := lsStr;

      loXMLlist := NIL;
      if FileExists(lsStr) then
      begin
        loXMLlist := tXMLlist.Create;

        loXMLlist.XMLFileName := lsStr;
        loXMLlist.Retrieve;

        lsStr := GetNextToken(AIndex, ATokens);
        if lsStr <> '' then
        begin
          if TNovusStringUtils.IsNumberStr(lsStr) then
          begin
            Result := loXMLlist.GetNameByIndex(StrToint(lsStr));
          end
          else
            FOutput.Log('Incorrect syntax: Index is not a number ');

        end
        else
          FOutput.Log('Incorrect syntax: Index is blank.');

        if Assigned(loXMLlist) then
          loXMLlist.Free;

      end
      else
      begin
        FOutput.LogError('Error: List filname cannot be found.');

      end;

    end
    else
      FOutput.Log('Incorrect syntax: List is blank.');
  end
  else
  begin
    FOutput.Log('Incorrect syntax: lack "("');

  end;

  if GetNextToken(AIndex, ATokens) <> ')' then
    FOutput.Log('Incorrect syntax: lack ")"');
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

  If GetNextToken(AIndex, ATokens) = '(' then
  begin
    lsStr := GetNextToken(AIndex, ATokens);

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
        FOutput.LogError('Error: List filname cannot be found.');

      end;

    end
    else
      FOutput.Log('Incorrect syntax: List is blank.');
  end
  else
  begin
    FOutput.Log('Incorrect syntax: lack "("');

  end;
end;


function TInterpreter.plugintag(aTokens: tTokenProcessor; Var aIndex: Integer): string;
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
      lsNextToken, FOutput, true);

    if fTagType = ttplugintag then
      begin
        result := Plugintag(ATokens, AIndex);


      end
    else
    if (CommandSyntaxIndex(lsNextToken) <> 0) then
    begin
      case CommandSyntaxIndex(lsNextToken) of
        //1:
        //  Result := FieldFunctions(ATokens, AIndex, 0);
       // 2:
        //  Result := FieldFunctions(ATokens, AIndex, 1);
        3:
          Result := Functions(ATokens, AIndex, 0);
        4:
          Result := Functions(ATokens, AIndex, 1);
        5:
          Result := Functions(ATokens, AIndex, 2);
        6:
          Result := Functions(ATokens, AIndex, 3);
        7:
          Result := Functions(ATokens, AIndex, 4);
        8:
          Result := LoopFunctions(ATokens, AIndex, 0, ASkipPOs);
        9:
          Result := LoopFunctions(ATokens, AIndex, 1, ASkipPOs);
       // 10:
       //   Result := FieldFunctions(ATokens, AIndex, 2);
        11:
          Result := Functions(ATokens, AIndex, 5);
        //12:
        //  Result := Procedures(ATokens, AIndex, 0);
        //13:
         // Result := TableFunctions(ATokens, AIndex, 0);
        //14:
        //  Result := TableFunctions(ATokens, AIndex, 1);
       // 15:
      //    Result := FieldAsSQL(ATokens, AIndex);
        16:
          Result := Delimiter(ATokens, AIndex);
        17, 18:
          Result := Reservelist(ATokens, AIndex, 0);
        19:
          Result := XMLlistIndex(ATokens, AIndex);
        20:
          Result := XMLlistCount(ATokens, AIndex);
        21:
          Result := XMLListName(ATokens, AIndex);
       // 22:
       //   Result := Procedures(ATokens, AIndex, 1);
        23:
          Result := Reservelist(ATokens, AIndex, 1);
      //  24:
      //    Result := FieldFunctions(ATokens, AIndex, 3);
        25:
         // Result := FieldFunctions(ATokens, AIndex, 0);
      end;
    end;

    if Not ASubCommand then
    begin
      if Pos('$$', ATokens[AIndex]) = 1 then
        Result := tTokenParser.ParseToken(Self, ATokens[AIndex],
          (foProjectItem as TProjectItem), (*TCodeGenerator(FoCodeGenerator)
          .oVariables, *)FOutput, ATokens, AIndex,
          TCodeGenerator(FoCodeGenerator).oProject)
      else
      if Pos('$', ATokens[AIndex]) = 1 then
        Result := ParseVariable(ATokens, AIndex)
    end;
  Except
    FOutput.InternalError;
  end;
end;

function TInterpreter.LoopFunctions(ATokens: tTokenProcessor;
  Var AIndex: Integer; ACommandIndex: Integer; Var ASkipPOs: Integer): string;
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

  case ACommandIndex of
    0:
      begin
        If GetNextToken(AIndex, ATokens) = '(' then
        begin
          LsValue := GetNextToken(AIndex, ATokens);

          if TNovusStringUtils.IsNumberStr(LsValue) then
          begin
            if GetNextToken(AIndex, ATokens) = ')' then
            begin
              Inc(fiLoopCounter, 1);

              FLoop := TLoop.Create;

              FLoop.LoopType := ltrepeat;
              FLoop.LoopPos := lpStart;
              FLoop.ID := fiLoopCounter;

            // Need to fix
           //   FLoop.CodeGeneratorItem := FoCodeGeneratorItem;

              FLoop.NegitiveFlag := (StrToint(LsValue) < 0);

              FLoop.Value := 0;
              If StrToint(LsValue) > 0 then
                FLoop.Value := StrToint(LsValue);

              fLoopList.Add(FLoop);


              // Need To fix
           //   liStartPos1 := (FoCodeGeneratorItem As tCodeGeneratorItem)
           //     .oTemplateTag.TagIndex;

              Inc(liStartPos1, 1);

              liEndPos1 := FindEndRepeatIndexPos(liStartPos1);

              ASkipPOs := liEndPos1;
            end
            else
              FOutput.Log('Incorrect syntax: lack ")"');

          end
          else
            FOutput.Log('Incorrect syntax: Index is not a number ');

        end
        else
          FOutput.Log('Incorrect syntax: lack "("');
      end;
    1:
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


          // Need to fix
        //liEndPos1 := (FoCodeGeneratorItem As tCodeGeneratorItem)
        //  .oTemplateTag.TagIndex;
        //Dec(liEndPos1, 1);

        //liEndSourceLineNo := (FoCodeGeneratorItem As tCodeGeneratorItem)
        //  .oTemplateTag.SourceLineNo;
        //Dec(liEndSourceLineNo, 1);

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

              If LCodeGeneratorItem1.TagType = ttInterpreter then;
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
          (*
            if Not Assigned(FLoop) then
            begin
            liTagIndexCounter := liStartTagIndex ;
            for Z := 0 to (LiEndTagIndex - liStartTagIndex)  do
            begin
            LCodeGenerator.RunPropertyVariables(liTagIndexCounter ,liTagIndexCounter);
            LCodeGenerator.RunInterpreter(liTagIndexCounter ,liTagIndexCounter );

            Inc(liTagIndexCounter);
            end;
            end;
          *)
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
        .oVariables,*) FOutput, ATokens, AIndex, TCodeGenerator(FoCodeGenerator)
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
        If TNovusStringUtils.IsNumberStr(LsValue) then
        begin
          if Pos('.', LsValue) > 0 then
            FVariable1.Value := TNovusStringUtils.Str2Float(LsValue)
          else
            FVariable1.Value := TNovusStringUtils.Str2Int(LsValue);
        end
        else If TNovusStringUtils.IsAlphaStr(LsValue) then
        begin
          FVariable1.Value := LsValue;

        end;
      end;

      LStr := GetToken;

      If LStr = '-' then
      begin
        LsValue := GetToken;

        If TNovusStringUtils.IsNumberStr(LsValue) then
          FVariable1.Value := FVariable1.Value -
            TNovusStringUtils.Str2Int(LsValue)
        else
          FOutput.Log('Incorrect syntax: Is not a number');
      end
      else If LStr = '+' then
      begin
        LsValue := GetToken;

        If TNovusStringUtils.IsNumberStr(LsValue) then
          FVariable1.Value := FVariable1.Value +
            TNovusStringUtils.Str2Int(LsValue)
        else
          FOutput.Log('Incorrect syntax: Is not a number');
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
        FOutput.Log('Syntax error: "' + lsVariableName1 + '" not defined');
        FOutput.Failed := true;
      end;

    end
    else
      FOutput.Log('Incorrect syntax: lack "="');
  end;
end;

procedure TInterpreter.AddVariable(AVariableName: String; AValue: Variant);
begin
  (foProjectItem as TProjectItem).oVariables.AddVariable
    (AVariableName, AValue);
end;

function TInterpreter.Execute(aTokens: tTokenProcessor;
  Var ASkipPOs: Integer): String;
Var
  FIndex: Integer;
  FOut: Boolean;
  fsScript: string;
  lbIsFailedCompiled: Boolean;
begin
  Result := '';

  FOut := False;

  FoTokens := aTokens;

  //FoCodeGeneratorItem := ACodeGeneratorItem;

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

function TInterpreter.CommandSyntaxIndexByTokens
  (ATokens: tTokenProcessor): Integer;
Var
  I, X: Integer;
  lEParser: TExpressionParser;
  lTokens: tStringList;
begin
  Result := -1;

  For I := 1 to Length(csCommamdSyntax) do
  begin
    Try
      lEParser := TExpressionParser.Create;
      lTokens := tStringList.Create;

      lEParser.Expr := csCommamdSyntax[I];

      lEParser.ListTokens(lTokens);

      for X := 0 to ATokens.Count - 1 do
      begin
        if Uppercase(lTokens[0]) = Uppercase(ATokens[X]) then
        begin
          Result := I;

          Exit;
        end;
      end;
    Finally
      if Assigned(lEParser) then
        lEParser.Free;

      if Assigned(lTokens) then
        lTokens.Free;
    End;
  end;
end;

function TInterpreter.Functions(ATokens: tTokenProcessor; Var AIndex: Integer;
  ACommandIndex: Integer): String;
Var
  LStr: String;
begin
  Result := '';

  if GetNextToken(AIndex, ATokens) = '(' then
  begin
    LStr := GetNextToken(AIndex, ATokens);

    if GetNextToken(AIndex, ATokens) = ')' then
    begin
      case ACommandIndex of
     //   0:
      //    Result := Lowercase(LStr);
       // 1:
       //   Result := Uppercase(LStr);
       // 2:
        //  Result := TNovusStringUtils.UpLowerA(LStr, true);
       // 3:
        //  Result := FieldTypeToDataType(LStr);
       // 4:
        //  Result := ClearDataType(LStr);
        5:
          Result := IntToStr(Pred(StrToint(LStr)));
      end;
    end
    else
    begin
      FOutput.Log('Incorrect syntax: lack ")"');
    end;
  end
  else
  begin
    FOutput.Log('Incorrect syntax: lack "("');
  end;
end;

(*
function TInterpreter.Procedures(ATokens: tTokenProcessor; Var AIndex: Integer;
  ACommandIndex: Integer): String;
Var
  LStr: String;
begin
  Result := '';

  case ACommandIndex of
    0:
      Result := cBlankLine;
    1:
      Result := TGuidExUtils.NewGuidString;
  end;
end;
*)

(*
function TInterpreter.FieldTypeToDataType(AFieldType: String): String;
begin
  // Result := (foProjectItem as tProjectItem).oCodeGenerator.oLanguage.ReadXML('FieldTypeToDataType', AFieldType);
end;
*)

(*
function TInterpreter.ClearDataType(ADataType: String): String;
begin
  // Result := (foProjectItem as tProjectItem).oCodeGenerator.oLanguage.ReadXML('ClearDataType', ADataType);
end;
*)
function TInterpreter.GetNextToken(Var AIndex: Integer;
  ATokens: tTokenProcessor): String;
Var
  I: Integer;
  LVariable: TVariable;
  liSkipPos: Integer;
begin
  Result := '';

  Inc(AIndex);

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
      FOutput.Log('Syntax Error: variable ' + Result + ' cannot be found.');

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

(*
function TInterpreter.FieldAsSQL(ATokens: tTokenProcessor;
  Var AIndex: Integer): string;
Var
  lConnectionItem: tConnectionItem;
  FFieldDesc: tFieldDesc;

  FConnectionName: String;
  FTableName: String;
  FFieldIndex: Integer;
  LStr: String;
  FFieldType: tFieldType;
begin
  Result := '';

  If GetNextToken(AIndex, ATokens) = '(' then
  begin
    FConnectionName := GetNextToken(AIndex, ATokens);

    lConnectionItem := (foProjectItem as TProjectItem)
      .oProject.oProjectConfig.oConnections.FindConnectionName(FConnectionName);
    if Assigned(lConnectionItem) then
    begin
      FTableName := GetNextToken(AIndex, ATokens);

      If lConnectionItem.TableExists(FTableName) then
      begin
        LStr := GetNextToken(AIndex, ATokens);

        FFieldDesc := lConnectionItem.FieldByName(FTableName, LStr);

        if Assigned(FFieldDesc) then
        begin
          if GetNextToken(AIndex, ATokens) = ')' then
          begin
            FFieldType := lConnectionItem.oDBSchema.GetFieldType(FFieldDesc,
              lConnectionItem.AuxDriver);

            if FFieldType.SQLFormat = '' then
              Result := FFieldDesc.FieldName + ' ' + FFieldType.SqlType
            else
              Result := FFieldDesc.FieldName + ' ' +
                Format(FFieldType.SQLFormat, [FFieldDesc.Column_Length]);

            FFieldType.Free;
            FFieldDesc.Free;

            Exit;
          end
          else
          begin
            FOutput.LogError('Incorrect syntax: lack ")"');

          end;
        end
        else
        begin
          FOutput.LogError('Error: Field cannot be found.');
        end;
      end
      else
      begin
        FOutput.LogError('Error: Table cannot be found "' + FTableName + '"');

      end;

    end
    else
    begin
      FOutput.LogError('Error: Connectioname cannot be found "' +
        FConnectionName + '"');

    end;
  end
  else
  begin
    FOutput.LogError('Incorrect syntax: lack "("');

  end;
end;
*)
(*
function TInterpreter.ParseCommand(aCommand: string): String;
begin
  Result := aCommand;
end;
*)

end.
