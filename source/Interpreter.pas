unit Interpreter;

interface

Uses
  Classes, EParser, SysUtils, DB, NovusStringUtils, Output,
  NovusList, Variants, Variables, XMLList, Dialogs, NovusGUIDEx;

const
  csCommamdSyntax: array[1..24] of String = (
    'fieldnamebyindex',
    'fieldtypebyindex',
    'lower',
    'upper',
    'uplower',
    'fieldtypetodatatype' ,
    'cleardatatype',
    'repeat',
    'endrepeat',
    'fieldcount',
    'pred',
    'blankline',
    'tablecount',
    'tablenamebyindex',
    'fieldassql',
    'delimiter' ,
    'reservelist' ,
    'rlist',
    'list',
    'listcount',
    'listname',
    'newguid',
    'rlistformat',
    'fieldbyname'
  );

Type
  TLoopType = (ltrepeat, ltendrepeat);

  TLoopPos = (lpStart, lpEnd);

  TLoop = Class(TObject)
  protected
    FLoopType: tLoopType;
    FLoopPos: TLoopPos;
    fiID: Integer;
    FCodeGeneratorDetails : TObject;
    FiValue: Integer;
    FbNegitiveFlag: Boolean;
  private
  public
    property LoopPos: TLoopPos
      read FLoopPos
      write FLoopPos;

    property LoopType: tLoopType
      read FLoopType
      write FLoopType;

    property ID: INteger
      read fiID
      write fiID;

    property CodeGeneratorDetails : TObject
      read FCodeGeneratorDetails
      write FCodeGeneratorDetails;

    property Value: Integer
       read fiValue
       write fiValue;

    property NegitiveFlag: Boolean
      read FbNegitiveFlag
      write FbNegitiveFlag;

  End;


  TInterpreter = Class(Tobject)
  protected
    fbIsFailedInterpreter: Boolean;
    FCodeGenerator: tObject;
    fiLoopCounter: Integer;
    fLoopList: tNovusList;
    FTokens: tStringList;
    FOutput: TOutput;
    FCodeGeneratorDetails : TObject;
  private
    procedure FailedInterpreter;
    function IsRepeat(ACodeGeneratorDetails: TObject): Boolean;
    function IsEndRepeat(ACodeGeneratorDetails: TObject): Boolean;
    function FindEndRepeatIndexPos(AIndex: INteger): INteger;
    function FindLoop(ALoopType:TLoopType; ALoopID: Integer): TLoop;
    function GetVariableName(AVariableName: String): String;
    function GetNextCommand(ATokens: tStringList; Var AIndex: Integer; Var ASkipPOs: Integer;ASubCommand: Boolean = False;ASubVariable:Boolean = False ): String;
    procedure AddVariable(AVariableName: String;AValue: Variant);

    function FieldFunctions(ATokens: tStringList; Var AIndex: Integer; ACommandIndex: Integer): string;
    function FieldAsSQL(ATokens: tStringList; Var AIndex: Integer): string;
    function Delimiter(ATokens: tStringList; Var AIndex: Integer): string;
    function Reservelist(ATokens: tStringList; Var AIndex: Integer; ACommandIndex: Integer): string;
    function XMLlistIndex(ATokens: tStringList; Var AIndex: Integer): string;
    function XMLListName(ATokens: tStringList; Var AIndex: Integer): string;
    function XMLlistCount(ATokens: tStringList; Var AIndex: Integer): string;

    function TableFunctions(ATokens: tStringList; Var AIndex: Integer; ACommandIndex: Integer): string;

    function ParseVariable(ATokens: tStringList; Var AIndex: Integer;ASubCommand: Boolean = False): String;

    function GetNextToken(Var AIndex: Integer; ATokens: tStringlist): String;

    function Functions(ATokens: tStringList; Var AIndex: Integer; ACommandIndex: Integer): String;
    function Procedures(ATokens: tStringList; Var AIndex: Integer; ACommandIndex: Integer): String;

    function FieldTypeToDataType(AFieldType: String): String;
    function ClearDataType(ADataType: String): String;

    function VariableExistsIndex(AVariableName: String): Integer;
    function GetVariableByIndex(AIndex: Integer): TVariable;

    function LoopFunctions(ATokens: tStringList; Var AIndex: Integer; ACommandIndex: Integer; Var ASkipPos: Integer): string;
  public
    constructor Create(ACodeGenerator: TObject; AOutput: TOutput); virtual;
    destructor Destroy; override;

    function CommandSyntaxIndexByTokens(ATokens: TStringList): Integer;
    function CommandSyntaxIndex(ACommand: String): integer;

    function Execute(ACodeGeneratorDetails: tObject; Var ASkipPos: Integer) : String;
    function LanguageFunctions(AFunction: string; ADataType: String): String;

    property IsFailedInterpreter: Boolean
      read fbIsFailedInterpreter
      write fbIsFailedInterpreter;
  End;

implementation

Uses
  NovusTemplate,
  CodeGenerator,
  reservelist,
  DBSchema,
  DMZenCodeGen;


constructor TInterpreter.Create;
begin
  inherited Create;

  FCodeGenerator := ACodeGenerator;

  fLoopList := tNovusList.Create(TLoop);

  FOutput := AOutput;

  fiLoopCounter := 0;
end;

destructor TInterpreter.Destroy;
begin
  fLoopList.Free;

  inherited;
end;

function TInterpreter.FieldFunctions(ATokens: tStringList; Var AIndex: Integer; ACommandIndex: Integer): string;
Var
  lConnectionDetails: tConnectionDetails;
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

      lConnectionDetails := DM.oConnections.FindConnectionName(FConnectionName);
      if Assigned(lConnectionDetails) then
        begin
          FTableName := GetNextToken(AIndex, ATokens);

          If lConnectionDetails.TableExists(FTableName) then
            begin
              if ((ACommandIndex = 0) or (ACommandIndex = 1)) then
                begin
                  LStr := GetNextToken(AIndex, ATokens);

                  if TNovusStringUtils.IsNumberStr(LStr) then
                     begin
                        FFieldIndex := StrToint(LStr);

                        FFieldDesc := lConnectionDetails.FieldByIndex(FTableName, FFieldIndex);

                        if Assigned(FFieldDesc) then
                          begin
                            if GetNextToken(AIndex, ATokens) = ')' then
                              begin
                                case ACommandIndex of
                                  0: Result := FFieldDesc.FieldName;
                                  1: begin
                                       fFieldType := DM.oDBSchema.GetFieldType(FFieldDesc, lConnectionDetails.AuxDriver);

                                       Result := fFieldType.SqlType;

                                       fFieldType.Free;
                                     end;
                                end;

                                FFieldDesc.Free;

                                Exit;
                              end
                            else
                              FOutput.WriteLog('Incorrect syntax: lack ")"');
                          end
                        else
                          begin
                            FOutput.WriteLog('Error: Field cannot be found.');
                            FailedInterpreter;
                          end;
                     end
                   else
                     begin
                       FOutput.WriteLog('Incorrect syntax: Index is not a number ');

                     end;
                end
              else
                begin
                  case ACommandIndex of
                    2: Result := IntToStr(lConnectionDetails.FieldCount(FTableName));

                    3: begin
                         LStr := GetNextToken(AIndex, ATokens);

                         FFieldDesc := lConnectionDetails.FieldByName(FTableName, LStr);

                         if Assigned(FFieldDesc) then
                           begin
                             if GetNextToken(AIndex, ATokens) = ')' then
                                Result := FFieldDesc.FieldName;

                             FFieldDesc.Free;

                             Exit;
                            end
                          else
                             begin
                               FOutput.WriteLog('Error: Field cannot be found.');
                               FailedInterpreter;
                             end;
                        end;
                  end;
               end;
            end
          else
            begin
              FOutput.WriteLog('Error: Table cannot be found "'+ FTableName+ '"');
              FailedInterpreter;
            end;

          end
        else
          begin
            FOutput.WriteLog('Error: Connectioname cannot be found "'+ FConnectionName + '"');

            FailedInterpreter;
          end;
        end
     else
       begin
         FOutput.WriteLog('Incorrect syntax: lack "("');

       end;
end;

function TInterpreter.Delimiter(ATokens: tStringList; Var AIndex: Integer): string;
Var
  lConnectionDetails: tConnectionDetails;
  lsStr,
  lsDelimiter: String;
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

          if TNovusStringUtils.IsNumberStr(LsStr) then
            begin
              liDelimiterCounter := StrToint(LsStr);

              lsStr := GetNextToken(AIndex, ATokens);

              if TNovusStringUtils.IsNumberStr(LsStr) then
                begin
                  liDelimiterLength := StrToint(LsStr);

                  if GetNextToken(AIndex, ATokens) = ')' then
                    begin
                      result := lsDelimiter;
                      if liDelimiterCounter = liDelimiterLength then Result := '';
                    end
                  else
                    FOutput.WriteLog('Incorrect syntax: lack ")"');
                end
              else
                FOutput.WriteLog('Incorrect syntax: delimiter length is not a number ');

            end
          else
            FOutput.WriteLog('Incorrect syntax: delimiter counter is not a number ');

        end
      else
         FOutput.WriteLog('Incorrect syntax: delimiter is blank.');
    end
     else
       begin
         FOutput.WriteLog('Incorrect syntax: lack "("');

       end;
end;

function TInterpreter.reservelist(ATokens: tStringList; Var AIndex: Integer; ACommandIndex: Integer): string;
Var
  lConnectionDetails: tConnectionDetails;
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

              result := lsWord;
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
             result := lsWord;
          end;
        end
     else
       begin
         FOutput.WriteLog('Incorrect syntax: lack "("');

       end;
end;

function TInterpreter.XMLListIndex(ATokens: tStringList; Var AIndex: Integer): string;
Var
  lConnectionDetails: tConnectionDetails;
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
          result := lsStr;

          loXMLlist := NIL;
          if FileExists(lsStr) then
            begin
              loXMLlist := tXMLlist.Create;

              loXMLlist.XMLFileName := lsStr;
              loXMLlist.Retrieve;

              lsStr := GetNextToken(AIndex, ATokens);
              if lsStr <> '' then
                begin
                  if TNovusStringUtils.IsNumberStr(LsStr) then
                    begin
                      Result := loXMLlist.GetValueByIndex(StrToInt(LsStr));
                    end
                  else
                    FOutput.WriteLog('Incorrect syntax: Index is not a number ');

                end
              else
                 FOutput.WriteLog('Incorrect syntax: Index is blank.');

              if Assigned(loXMLlist) then loXMLlist.Free;

            end
          else
            begin
              FOutput.WriteLog('Error: List filname cannot be found.');
              FailedInterpreter;
            end;

        end
      else
         FOutput.WriteLog('Incorrect syntax: List is blank.');
    end
     else
       begin
         FOutput.WriteLog('Incorrect syntax: lack "("');

       end;


  if GetNextToken(AIndex, ATokens) <> ')' then
     FOutput.WriteLog('Incorrect syntax: lack ")"');
end;

function TInterpreter.XMLListName(ATokens: tStringList; Var AIndex: Integer): string;
Var
  lConnectionDetails: tConnectionDetails;
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
          result := lsStr;

          loXMLlist := NIL;
          if FileExists(lsStr) then
            begin
              loXMLlist := tXMLlist.Create;

              loXMLlist.XMLFileName := lsStr;
              loXMLlist.Retrieve;

              lsStr := GetNextToken(AIndex, ATokens);
              if lsStr <> '' then
                begin
                  if TNovusStringUtils.IsNumberStr(LsStr) then
                    begin
                      Result := loXMLlist.GetNameByIndex(StrToInt(LsStr));
                    end
                  else
                    FOutput.WriteLog('Incorrect syntax: Index is not a number ');

                end
              else
                 FOutput.WriteLog('Incorrect syntax: Index is blank.');

              if Assigned(loXMLlist) then loXMLlist.Free;

            end
          else
            begin
              FOutput.WriteLog('Error: List filname cannot be found.');
              FailedInterpreter;
            end;

        end
      else
         FOutput.WriteLog('Incorrect syntax: List is blank.');
    end
     else
       begin
         FOutput.WriteLog('Incorrect syntax: lack "("');

       end;


  if GetNextToken(AIndex, ATokens) <> ')' then
     FOutput.WriteLog('Incorrect syntax: lack ")"');
end;

function TInterpreter.XMLListCount(ATokens: tStringList; Var AIndex: Integer): string;
Var
  lConnectionDetails: tConnectionDetails;
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
          result := lsStr;

          loXMLlist := NIL;
          if FileExists(lsStr) then
            begin
              loXMLlist := tXMLlist.Create;

              loXMLlist.XMLFileName := lsStr;
              loXMLlist.Retrieve;

              Result := IntToStr(loXMLlist.GetCount);

              if Assigned(loXMLlist) then loXMLlist.Free;

            end
          else
            begin
              FOutput.WriteLog('Error: List filname cannot be found.');
              FailedInterpreter;
            end;

        end
      else
         FOutput.WriteLog('Incorrect syntax: List is blank.');
    end
     else
       begin
         FOutput.WriteLog('Incorrect syntax: lack "("');

       end;
end;





function TInterpreter.TableFunctions(ATokens: tStringList; Var AIndex: Integer; ACommandIndex: Integer): string;
Var
  lConnectionDetails: tConnectionDetails;
  FFieldDesc: tFieldDesc;

  FConnectionName: String;
  FTableName: String;
  FTableIndex: Integer;
  LStr: String;
begin
  Result := '';

  If GetNextToken(AIndex, ATokens) = '(' then
    begin
      FConnectionName := GetNextToken(AIndex, ATokens);

      lConnectionDetails := DM.oConnections.FindConnectionName(FConnectionName);
      if Assigned(lConnectionDetails) then
        begin
          case ACommandIndex of
            0: Result := IntToStr(lConnectionDetails.TableCount);
            1: begin
                 LStr := GetNextToken(AIndex, ATokens);

                 if TNovusStringUtils.IsNumberStr(LStr) then
                    begin
                       FTableIndex := StrToint(LStr);

                       If lConnectionDetails.TableCount > 0 then
                         begin
                           Result := lConnectionDetails.JustTableNamebyIndex(FTableIndex);
                         end
                       else
                         begin
                           FOutput.WriteLog('Error: Tablename cannot be found.');
                           FailedInterpreter;
                         end;
                      end
                   else
                     begin
                       FOutput.WriteLog('Incorrect syntax: Index is not a number ');

                     end;
               end;
          end;
        end
      else
         begin
            FOutput.WriteLog('Error: Connectioname cannot be found "'+ FConnectionName + '"');
            FailedInterpreter;
          end;
       end
     else
       begin
         FOutput.WriteLog('Incorrect syntax: lack "("');

       end;
end;


function TInterpreter.GetNextCommand(ATokens: tStringList; Var AIndex: Integer;Var ASkipPos: INteger;ASubCommand: Boolean = False;ASubVariable:Boolean = False): String;
begin
  Result := '';
  if ASubCommand then
     Result := ATokens[AIndex];
  try
    case CommandSyntaxIndex(ATokens[AIndex]) of
      1: Result := FieldFunctions(ATokens,AIndex, 0);
      2: Result := FieldFunctions(ATokens,AIndex, 1);
      3: Result := Functions(ATokens,AIndex, 0);
      4: Result := Functions(ATokens,AIndex, 1);
      5: Result := Functions(ATokens,AIndex, 2);
      6: result := Functions(ATokens,AIndex, 3);
      7: result := Functions(ATokens,AIndex, 4);
      8: Result := LoopFunctions(ATokens,AIndex, 0, ASkipPos);
      9: Result := LoopFunctions(ATokens,AIndex, 1, ASkipPos);
      10: Result := FieldFunctions(ATokens,AIndex, 2);
      11: Result := Functions(ATokens,AIndex, 5);
      12: result := procedures(ATokens,AIndex, 0);
      13: Result := TableFunctions(ATokens,AIndex, 0);
      14: Result := TableFunctions(ATokens,AIndex, 1);
      15: result := FieldAsSQL(ATokens,AIndex);
      16: result := Delimiter(ATokens,AIndex);
      17, 18: result := Reservelist(ATokens,AIndex, 0);
      19: result := XMLlistIndex(ATokens,AIndex);
      20: result := XMLlistCount(ATokens,AIndex);
      21: result := XMLlistName(ATokens,AIndex);
      22: result := procedures(ATokens,AIndex, 1);
      23: result := Reservelist(ATokens,AIndex, 1);
      24: Result := FieldFunctions(ATokens,AIndex, 3);
    end;

    if Not ASubCommand then
      begin
        if Pos('$', ATokens[AIndex]) = 1  then
          Result := ParseVariable(ATokens, AIndex)
      end;
  Except
    FOutput.WriteExceptLog;
    FailedInterpreter;
  end;
end;

function TInterpreter.LoopFunctions(ATokens: tStringList; Var AIndex: Integer; ACommandIndex: Integer; Var ASkipPos: Integer): string;
Var
  lbNegitiveFlag: Boolean;
  liPos,
  liLineNoPos: Integer;
  liStartPos1, liEndPos1,
  liStartPos2, liEndPos2: Integer;
  LStartLoop,
  FLoop: tLoop;
  liLastSourceNo, I, X, Y, Z, A: Integer;
  LCodeGeneratorDetails3,
  LCodeGeneratorDetails2,
  LCodeGeneratorDetails1: tCodeGeneratorDetails;
  LTemplateTag1, LTemplateTag2: TTemplateTag;
  LTemplate: TNovusTemplate;
  liSkipPos,
  liTagIndex: Integer;
  LCodeGenerator: TCodeGenerator;
  LsValue: String;
  LiValue: Integer;
  liLineCount: INteger;
  lsTagValue: String;
  liStartTagIndex,
  liEndTagIndex,
  liTagIndexCounter,
  liLastEndSourceLineNo,
  liLastNextSourceLineNo,
  liNextSourceLineNo1,
  liNextSourceLineNo2,
  liStartSourceLineNo,
  liSourceLineCount,
  liEndSourceLineNo: Integer;

  function GetCodeGeneratorDetailsBySourceLineNo(ASourceLineNo: Integer; Var APos: Integer): tCodeGeneratorDetails;
  Var
    z: integer;
    LCodeGeneratorDetails: tCodeGeneratorDetails;
  begin
    Result := NIL;

    for z := APos to tCodeGenerator(FCodeGenerator).CodeGeneratorList.Count - 1 do
      begin
        LCodeGeneratorDetails := tCodeGeneratorDetails(tCodeGenerator(FCodeGenerator).CodeGeneratorList.Items[z]);

        if LCodeGeneratorDetails.oTemplateTag.SourceLineNo = ASourceLineNo then
          begin
            Result := LCodeGeneratorDetails;

            APos := z + 1;

            Break;
          end;
      end;

    if Z > aPos then aPos := z;

  end;

begin
  Result := '';

  case ACommandIndex of
   0: begin
        If GetNextToken(AIndex, ATokens) = '(' then
          begin
            LsValue := GetNextToken(AIndex, ATokens);

            if TNovusStringUtils.IsNumberStr(LsValue) then
              begin
                if GetNextToken(AIndex, ATokens) = ')' then
                  begin
                    Inc(fiLoopCounter, 1);

                    FLoop := tLoop.Create;

                    FLoop.LoopType := ltrepeat;
                    FLoop.LoopPos := lpStart;
                    FLoop.ID := fiLoopCounter;
                    FLoop.CodeGeneratorDetails := FCodeGeneratorDetails;

                    FLoop.NegitiveFlag := (StrToInt(LsValue) < 0);

                    FLoop.Value := 0;
                    If StrToInt(LsValue) > 0 then
                      FLoop.Value := StrToInt(LsValue);

                    fLoopList.Add(FLoop);

                    liStartPos1 := (FCodeGeneratorDetails As tCodeGeneratorDetails).oTemplateTag.TagIndex;

                    Inc(liStartPos1, 1);

                    liEndPos1 := FindEndRepeatIndexPos(liStartPos1);

                    ASkipPos := LiEndPos1;
                  end
                else
                  FOutput.WriteLog('Incorrect syntax: lack ")"');

              end
            else
              FOutput.WriteLog('Incorrect syntax: Index is not a number ');

          end
        else
          FOutput.WriteLog('Incorrect syntax: lack "("');
      end;
   1: begin
        ASkipPos := 0;

        LStartLoop := FindLoop(ltrepeat, fiLoopCounter);

        LiValue := LStartLoop.Value;
        lbNegitiveFlag := LStartLoop.NegitiveFlag;

        liStartPos1 := (LStartLoop.CodeGeneratorDetails As tCodeGeneratorDetails).oTemplateTag.TagIndex;
        Inc(liStartPos1, 1);

        liStartSourceLineNo := (LStartLoop.CodeGeneratorDetails As tCodeGeneratorDetails).oTemplateTag.SourceLineNo;

        liEndPos1 := (FCodeGeneratorDetails As tCodeGeneratorDetails).oTemplateTag.TagIndex;
        Dec(liEndPos1, 1);

        liEndSourceLineNo := (FCodeGeneratorDetails As tCodeGeneratorDetails).oTemplateTag.SourceLineNo;
        Dec(liEndSourceLineNo, 1);

        for I := liStartPos1 to liEndPos1 do
          begin
            LCodeGeneratorDetails1 := tCodeGeneratorDetails(tCodeGenerator(FCodeGenerator).CodeGeneratorList.Items[i]);
            LCodeGeneratorDetails1.LoopId := fiLoopCounter;
          end;

        LCodeGenerator := (FCodeGenerator As TCodeGenerator);

        LTemplate := LCodeGenerator.Template;

        liLastNextSourceLineNo := liStartSourceLineNo;

        FLoop := NIL;

        I := 0;

        liLastEndSourceLineNo := (liEndSourceLineNo - liStartSourceLineNo);

        Repeat
          liPos := 0;

          While(liPos < tCodeGenerator(FCodeGenerator).CodeGeneratorList.Count) do
            begin
              LCodeGeneratorDetails1 := GetCodeGeneratorDetailsBySourceLineNo((liLastNextSourceLineNo + i) + 1, liPos);

              if Assigned(LCodeGeneratorDetails1) then
                begin
                  LTemplateTag1 := LCodeGeneratorDetails1.oTemplateTag;

                  liTagIndex := LTemplateTag1.TagIndex;

                  LCodeGenerator.RunPropertyVariables(liTagIndex ,liTagIndex );

                  LCodeGenerator.RunInterpreter(liTagIndex ,liTagIndex );

                  If LCodeGeneratorDetails1.TagType = ttInterpreter then ;
                    begin
                      If IsEndRepeat(LCodeGeneratorDetails1) then
                        begin
                          FLoop := FindLoop(ltrepeat, fiLoopCounter);

                          liLastEndSourceLineNo := liEndSourceLineNo + 1;
                          liSourceLineCount := (liEndSourceLineNo - liStartSourceLineNo);

                          Break;
                        end;
                    end;
                end;
            end;

          Inc(i);
          if I > (liLastEndSourceLineNo -1) then Break;
        until false;

        if LiValue = 0 then
          begin
            If lbNegitiveFlag then
              begin
                For a := 0 to liLastEndSourceLineNo do
                  begin
                    LTemplate.OutputDoc.strings[liStartSourceLineNo + a] := '';
                  end;
               end;

            Exit;
          end;

        if Not Assigned(FLoop) then
          begin
            liLastEndSourceLineNo := liEndSourceLineNo;

            if ((FindEndRepeatIndexPos(liStartPos1) + liStartPos1) < (liEndSourceLineNo - liStartSourceLineNo)) then
              liSourceLineCount := (liEndSourceLineNo - liStartSourceLineNo) -((FindEndRepeatIndexPos(liStartPos1) + liStartPos1) + 1)
            else liSourceLineCount := (liEndSourceLineNo - liStartSourceLineNo)-1;
          end;

        liLineNoPos := 0;
        Y := 0;
        repeat
          liStartTagIndex := 0;
          liEndTagIndex := 0;

          for i := 0 to liSourceLineCount do
            begin
              liNextSourceLineNo1 := liLastEndSourceLineNo + liLineNoPos;

              LTemplate.InsertLineNo(liNextSourceLineNo1, LTemplate.TemplateDoc.Strings[liStartSourceLineNo + i]);

              liPos := 0;

              While(liPos < tCodeGenerator(FCodeGenerator).CodeGeneratorList.Count) do
                begin
                  LCodeGeneratorDetails1 := GetCodeGeneratorDetailsBySourceLineNo((liStartSourceLineNo + i) + 1, liPos);
                  if Assigned(LCodeGeneratorDetails1) then
                    begin
                      LTemplateTag1 := LCodeGeneratorDetails1.oTemplateTag;

                      LTemplateTag2 := tTemplatetag.Create(NIL);

                      LTemplateTag2.SourceLineNo := liNextSourceLineNo1+1;

                      LTemplateTag2.SourcePos := LTemplateTag1.SourcePos;

                      LTemplateTag2.TagName := LTemplateTag1.TagName;
                      LTemplateTag2.RawTag := LTemplateTag1.RawTag;

                      LTemplateTag2.RawTagEx :=  LTemplateTag1.RawTagEx;

                      LTemplateTag2.TagValue := '';

                      liTagIndex := LTemplate.AddTemplateTag(LTemplateTag2);

                      LCodeGeneratorDetails2 := LCodeGenerator.AddTag(LTemplateTag2);

                      if liStartTagIndex = 0 then
                        liStartTagIndex := liTagIndex;
                      LiEndTagIndex := liTagIndex;

                      If ((IsEndRepeat(LCodeGeneratorDetails2)= False) and (IsRepeat(LCodeGeneratorDetails2)= False)) then
                        begin
                          LCodeGenerator.RunPropertyVariables(liTagIndex ,liTagIndex );
                          LCodeGenerator.RunInterpreter(liTagIndex ,liTagIndex );
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

            if Y = LiValue then Break;
        until false;


      end;
  end;
end;

function TInterpreter.GetVariableName(AVariableName: String): String;
begin
  Result := Copy(AVariableName, 2, Length(AVariableName));
end;


function TInterpreter.FindLoop(ALoopType:TLoopType; ALoopID: Integer): TLoop;
Var
  I: Integer;
  FLoop: tLoop;
begin
  Result := NIL;

  for I := 0 to fLoopList.Count - 1 do
    begin
      FLoop := TLoop(FLoopList.Items[i]);

      if (FLoop.LoopType = ALoopType) and (FLoop.ID = ALoopID) then
        begin
          Result := FLoop;
          break;
        end;
    end;
end;

function TInterpreter.ParseVariable(ATokens: tStringList; Var AIndex: Integer;ASubCommand: Boolean = False): String;
Var
  FVariable1,
  FVariable2: tVariable;
  lsVariableName1,
  lsVariableName2: String;
  I, X: Integer;
  lsValue: String;
  LStr: STring;
  LiSkipPos: Integer;
  FOut: Boolean;

  function GetToken: String;
   begin
     Result := '';

     Inc(AIndex);

     if (AIndex <= ATokens.Count - 1)  then
       Result := GetNextCommand(ATokens, AIndex, liSkipPos, True);
   end;
begin
  Result := '';
  FOut := False;

  lsVariableName1  := GetVariableName(ATokens[AIndex]);

  if ATokens[0] = '=' then FOut := True;

  If GetToken = '=' then
    begin
      I := VariableExistsIndex(lsVariableName1);

      if I = -1 then
        begin
          lsValue := GetToken;

          If TNovusStringUtils.IsNumberStr(lsValue) then
            begin
              if Pos('.', lsValue) > 0 then
                AddVariable(lsVariableName1,TNovusStringUtils.Str2Float(lsValue))
              else
                AddVariable(lsVariableName1,TNovusStringUtils.Str2Int(lsValue));
            end
          else
            AddVariable(lsVariableName1, lsValue);
          (*
          If TNovusStringUtils.IsAlphaStr(lsValue) then
            begin
              AddVariable(lsVariableName1, lsValue);

            end;
          *)
        end
      else
        begin
          lsValue := GetToken;

          X := -1;
          if Pos('$', lsValue) = 1 then
            begin
              lsVariableName2  := GetVariableName(lsValue);

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
              If TNovusStringUtils.IsNumberStr(lsValue) then
                begin
                  if Pos('.', lsValue) > 0 then
                    FVariable1.Value := TNovusStringUtils.Str2Float(lsValue)
                  else
                    FVariable1.Value := TNovusStringUtils.Str2Int(lsValue);
                end
              else
              If TNovusStringUtils.IsAlphaStr(lsValue) then
                begin
                  FVariable1.Value := lsValue;

                end;
            end;

           LStr := GetToken;

           If LStr = '-' then
            begin
              lsValue := GetToken;

              If TNovusStringUtils.IsNumberStr(lsValue) then
                FVariable1.Value := FVariable1.Value - TNovusStringUtils.Str2Int(lsValue)
              else
                FOutput.WriteLog('Incorrect syntax: Is not a number');
            end
          else
          If LStr = '+' then
            begin
              lsValue := GetToken;

              If TNovusStringUtils.IsNumberStr(lsValue) then
                FVariable1.Value := FVariable1.Value + TNovusStringUtils.Str2Int(lsValue)
              else
                FOutput.WriteLog('Incorrect syntax: Is not a number');
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
            FOutput.WriteLog('Syntax error: "' + lsVariableName1 + '" not defined');
        end
      else
        FOutput.WriteLog('Incorrect syntax: lack "="');
    end;
end;

procedure TInterpreter.AddVariable(AVariableName: String;AValue: Variant);
begin
  (FCodeGenerator As TCodeGenerator).oVariables.AddVariable(AVariableName,AValue);
end;

function TInterpreter.Execute(ACodeGeneratorDetails: tObject; Var ASkipPos: Integer) : String;
Var
  FIndex: Integer;
  Fout: Boolean;
begin
  Result := '';

  fbIsFailedInterpreter := False;

  Fout := False;

  FTokens := tCodeGeneratorDetails(ACodeGeneratorDetails).Tokens;

  FCodeGeneratorDetails := ACodeGeneratorDetails;

  FIndex := 0;
  if FTokens.Strings[0] = '=' then
    begin
      Fout := True;
      FIndex := 1;
    end;

  if Fout = True then
    begin
      Result := GetNextCommand(FTokens, FIndex, ASkipPos)
    end
  else
    begin
      Result := '';
      GetNextCommand(FTokens, FIndex, ASkipPos);
    end;
end;

function TInterpreter.LanguageFunctions(AFunction: string; ADataType: String): String;
begin
  Result := TCodeGeneratorDetails(FCodeGeneratorDetails).oCodeGenerator.oLanguage.ReadXML(Afunction, ADataType);
end;

function TInterpreter.CommandSyntaxIndex(ACommand: String): integer;
Var
  I: Integer;
begin
  Result := -1;

  For I := 1 to Length(csCommamdSyntax) do
    begin
     if Uppercase(csCommamdSyntax[i]) = Uppercase(ACommand) then
       begin
         Result := I;

         break;
       end;
    end;
end;



function TInterpreter.CommandSyntaxIndexByTokens(ATokens: TStringList): Integer;
Var
  I,X: Integer;
  lEParser: TFEParser;
  lTokens: tStringList;
begin
  Result := -1;

  For I := 1 to Length(csCommamdSyntax) do
    begin
      Try
      lEParser := TFEParser.Create;
      lTokens := tStringList.Create;

      lEParser.Expr := csCommamdSyntax[i];

      lEParser.ListTokens(lTokens);

      for x := 0 to ATokens.Count - 1 do
       begin
         if uppercase(lTokens[0]) = Uppercase(ATokens[x]) then
           begin
             Result := i;

             Exit;
           end;
       end;
      Finally
        if assigned(lEParser) then
          lEParser.Free;

        if Assigned(lTokens) then
          lTokens.Free;
      End;
    end;
end;

function TInterpreter.Functions(ATokens: tStringList; Var AIndex: Integer; ACommandIndex: Integer): String;
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
            0: Result := Lowercase(LStr);
            1: Result := Uppercase(LStr);
            2: Result := TNovusStringUtils.UpLowerA(LStr, True);
            3: Result := FieldTypeToDataType(LStr);
            4: Result := ClearDataType(LStr);
            5: Result := IntToStr(Pred(StrToInt(LStr)));
          end;
        end
      else
        begin
          FOutput.WriteLog('Incorrect syntax: lack ")"');
        end;
    end
  else
    begin
      FOutput.WriteLog('Incorrect syntax: lack "("');
    end;
end;

function TInterpreter.Procedures(ATokens: tStringList; Var AIndex: Integer; ACommandIndex: Integer): String;
Var
  LStr: String;
begin
  Result := '';

  case ACommandIndex of
    0: Result := cBlankLine;
    1: result := TGuidExUtils.NewGuidString;
  end;
end;

function TInterpreter.FieldTypeToDataType(AFieldType: String): String;
begin
  Result := TCodeGeneratorDetails(FCodeGeneratorDetails).oCodeGenerator.oLanguage.ReadXML('FieldTypeToDataType', AFieldType);
end;

function TInterpreter.ClearDataType(ADataType: String): String;
begin
  Result := TCodeGeneratorDetails(FCodeGeneratorDetails).oCodeGenerator.oLanguage.ReadXML('ClearDataType', ADataType);
end;

function TInterpreter.GetNextToken(Var AIndex: Integer; ATokens: tSTringlist): String;
Var
  I: Integer;
  LVariable: tVariable;
  LiSkipPos: Integer;
begin
  Result := '';

  Inc(AIndex);

  Result := GetNextCommand(ATokens, AIndex, LiSkipPos, True);

  if Pos('$', Result) = 1  then
    begin
      I := VariableExistsIndex(GetVariableName(Result));
      if I <> -1 then
        begin
          LVariable := GetVariablebyIndex(i);

          Result := LVariable.AsString;
        end
      else
        FOutput.WriteLog('Syntax Error: variable '+ result + ' cannot be found.');

    end ;
 // else
 // if DM.oProperties.IsPropertyExists(Result) then
 //   Result := DM.oProperties.GetProperty(Result);
 end;


function TInterpreter.VariableExistsIndex(AVariableName: String): Integer;
begin
  Result := (FCodeGenerator As TCodeGenerator).oVariables.VariableExistsIndex(AVariableName)
end;

function TInterpreter.GetVariableByIndex(AIndex: Integer): TVariable;
begin
  Result := (FCodeGenerator As TCodeGenerator).oVariables.GetVariableByIndex(AIndex)
end;


function TInterpreter.FindEndRepeatIndexPos(AIndex: INteger): INteger;
Var
  I: Integer;
  LCodeGeneratorDetails: TCodeGeneratorDetails;
  LCodeGeneratorList: tNovusList;
  LTemplateTag: TTemplateTag;
  iCount: Integer;
begin
  Result := -1;

  LCodeGeneratorList := (FCodeGenerator As TCodeGenerator).CodeGeneratorList;

  iCount := 0;
  for I := AIndex to LCodeGeneratorList.Count -1 do
    begin
      LCodeGeneratorDetails := TCodeGeneratorDetails(LCodeGeneratorList.Items[i]);

      if LCodeGeneratorDetails.tagType = ttInterpreter then
         begin
           LTemplateTag := LCodeGeneratorDetails.oTemplateTag;

           if Pos(csCommamdSyntax[8], LTemplateTag.TagName) = 1  then
             begin
               inc(iCount);
             end
           else
           if (LTemplateTag.TagName = csCommamdSyntax[9]) and (iCount = 0) then
             begin
               Result := I;

               Exit;
             end
           else
           if (LTemplateTag.TagName = csCommamdSyntax[9]) and (iCount > 0) then
             begin
               Dec(iCount);
             end;
         end;
    end;
end;


function TInterpreter.IsEndRepeat(ACodeGeneratorDetails: TObject): Boolean;
begin
  Result := (CommandSyntaxIndex(tCodeGeneratorDetails(ACodeGeneratorDetails).Tokens[0]) = 9);
end;

function TInterpreter.IsRepeat(ACodeGeneratorDetails: TObject): Boolean;
begin
  Result := (CommandSyntaxIndex(tCodeGeneratorDetails(ACodeGeneratorDetails).Tokens[0]) = 8);
end;

function TInterpreter.FieldAsSQL(ATokens: tStringList; Var AIndex: Integer): string;
Var
  lConnectionDetails: tConnectionDetails;
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

      lConnectionDetails := DM.oConnections.FindConnectionName(FConnectionName);
      if Assigned(lConnectionDetails) then
        begin
          FTableName := GetNextToken(AIndex, ATokens);

          If lConnectionDetails.TableExists(FTableName) then
            begin
              LStr := GetNextToken(AIndex, ATokens);

              FFieldDesc := lConnectionDetails.FieldByName(FTableName, LStr);

              if Assigned(FFieldDesc) then
                begin
                  if GetNextToken(AIndex, ATokens) = ')' then
                    begin
                      FFieldType := DM.oDBSchema.GetFieldType(FFieldDesc, lConnectionDetails.AuxDriver);

                      if FFieldType.SQLFormat = '' then
                        Result := FFieldDesc.FieldName + ' ' + FFieldType.SqlType
                      else
                        Result := FFieldDesc.FieldName + ' ' + Format(FFieldType.SqlFormat, [FFieldDesc.Column_Length]);

                      FFieldType.Free;
                      FFieldDesc.Free;

                      Exit;
                    end
                  else
                    FOutput.WriteLog('Incorrect syntax: lack ")"');
                end
                  else
                    begin
                      FOutput.WriteLog('Error: Field cannot be found.');
                      FailedInterpreter;
                    end;
            end
          else
            begin
              FOutput.WriteLog('Error: Table cannot be found "'+ FTableName+ '"');
              FailedInterpreter;
            end;

          end
        else
          begin
            FOutput.WriteLog('Error: Connectioname cannot be found "'+ FConnectionName + '"');

            FailedInterpreter;
          end;
        end
     else
       begin
         FOutput.WriteLog('Incorrect syntax: lack "("');

       end;
end;

procedure TInterpreter.FailedInterpreter;
begin
  FOutput.WriteLog('Failed Interpreter.');

  fbIsFailedInterpreter := True;

end;



end.
