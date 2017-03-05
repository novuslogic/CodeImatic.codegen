unit CodeGenerator;

interface


Uses Classes, NovusTemplate, NovusList, EParser, SysUtils,
     Config, NovusStringUtils, Interpreter, Language, Project,
     Output, Variables, NovusUtilities;

Const
  cDeleteLine = '##DELETELINE##';
  cBlankline = '##BLANKLINE##';

Type
  TCodeGenerator = class;

  TTagType = (ttProperty, ttConnection, ttInterpreter, ttLanguage, ttInclude, ttUnknown, ttplugintag);

  TCodeGeneratorDetails = class(TObject)
  protected
    foProject: tProject;
    fsDefaultTagName: String;
    FCodeGenerator: TCodeGenerator;
    FTagType: tTagType;
    FEParser: tFEParser;
    FTemplateTag: TTemplateTag;
    FTokens: tStringlist;
    LiLoopID: Integer;
  private
  public
    constructor Create; virtual;
    destructor Destroy; override;

    procedure Execute;

    property oCodeGenerator: TCodeGenerator
      read FCodeGenerator
      write FCodeGenerator;

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
  end;

  TCodeGenerator = class(TObject)
  protected
    fProject: tProject;
    fVariables: tVariables;
    fOutput : tOutput;
    FLanguage: tLanguage;
    fsLanguage: String;
    FInterpreter : tInterpreter;
    fProjectItem: tProjectItem;
    FTemplate: tNovusTemplate;
    FCodeGeneratorList: TNovusList;
  private
    procedure DoPluginTags;
    procedure DoLanguage;
    procedure DoConnections;
    function  DoIncludes: Boolean;
    procedure DoProperties;
    procedure DoTrimLines;
    procedure DoDeleteLines;
    procedure DoPostProcessorPlugins(var aOutputFile: string);
    function PassTemplateTags(aClearRun: Boolean = false): Boolean;
    function DoInternalIncludes: Boolean;
    function GetGlobalPropertyValue(aToken: String): String;
  public
    constructor Create(ATemplate: TNovusTemplate; AOutput: TOutput; aProject: tProject; aProjectItem: tProjectItem); virtual;
    destructor Destroy; override;

    function IsNonOutputCommandonly(ASourceLineNo: Integer): Boolean;

    procedure RunPropertyVariables(AStartPos, AEndPos: Integer);

    function AddTag(ATemplateTag: TTemplateTag): TCodeGeneratorDetails;

    procedure RunInterpreter(AStartPos, AEndPos: Integer);

    property Language: String
      read fsLanguage
      write fsLanguage;

    property oLanguage: tLanguage
       read fLanguage
       write FLanguage;

    property oVariables: tVariables
       read fVariables
       write FVariables;

    property oOutput : tOutput
      read fOutput
      write fOutput;

    function IsInterpreter(ATokens: TstringList): boolean;

    function GetTagType(ATokens: TstringList): TTagType;

    procedure Execute(aOutputFile: String);

    property CodeGeneratorList: tNovusList
      read FCodeGeneratorList
      write FCodeGeneratorList;

    property Template: TNovusTemplate
      read FTemplate
      write FTemplate;
  end;



implementation


uses runtime;


constructor TCodeGenerator.Create;
begin
  inherited Create;

  fProjectItem:= aProjectItem;

  fProject := aProject;

  fVariables := tVariables.Create;

  FOutput := AOutput;

  FTemplate := ATemplate;

  FCodeGeneratorList := TNovusList.Create(TCodeGeneratorDetails);

  FInterpreter := tInterpreter.Create(Self, FOutput);

  FLanguage :=  tLanguage.Create;
end;

destructor TCodeGenerator.Destroy;
begin
  fVariables.Free;

  FLanguage.Free;

  FInterpreter.Free;

  FCodeGeneratorList.Free;

  inherited;
end;

function TCodeGenerator.AddTag(ATemplateTag: TTemplateTag): TCodeGeneratorDetails;
Var
  lCodeGeneratorDetails: TCodeGeneratorDetails;
begin
  Result := NIL;

  lCodeGeneratorDetails := TCodeGeneratorDetails.Create;

  lCodeGeneratorDetails.oTemplateTag := ATemplateTag;

  lCodeGeneratorDetails.oCodeGenerator := Self;

  lCodeGeneratorDetails.Execute;

  if lCodeGeneratorDetails.TagType <> ttUnknown then
    begin
      FCodeGeneratorList.Add(lCodeGeneratorDetails);

      Result := lCodeGeneratorDetails;
    end
  else
    lCodeGeneratorDetails.Free;

end;

function TCodeGenerator.GetTagType(ATokens: TstringList): TTagType;
Var
  lsToken: String;
begin
  if ATokens.count = 0 then
    begin
      result := ttunknown;

      exit;
    end;

  lsToken := Uppercase(ATokens.Strings[0]);

  if lsToken= '' then
    result := ttunknown
  else
  if lsToken = 'LANGUAGE' then
    Result := ttlanguage
  else
  if lsToken = 'CONNECTION' then
    Result := ttConnection
  else
  if lsToken = 'INCLUDE' then
    result := ttInclude
  else
  if oRuntime.oProperties.IsPropertyExists(lsToken) then
    Result := ttProperty
  else
    Result := ttInterpreter;
end;

function TCodeGenerator.IsInterpreter(ATokens: TstringList): boolean;
begin
  Result := (FInterpreter.CommandSyntaxIndexByTokens(ATokens) <> -1);
end;


procedure TCodeGenerator.RunInterpreter;
Var
  LiSkipPos1, LiSkipPos2: Integer;
  lsTagValue: String;
  I, X: integer;
  LTemplateTag1, LTemplateTag2: TTemplateTag;
  LCodeGeneratorDetails1, LCodeGeneratorDetails2: TCodeGeneratorDetails;
  liLastSourceNo: Integer;
  liTagIndex: Integer;
begin
  liLastSourceNo := 0;
  liSkipPos1 := 0;

  for I := AStartPos to AEndPos do
    begin
      if LiSKipPos1 <> 0 then
         if LiSkipPOs1 > i then Continue;

       LCodeGeneratorDetails1 := TCodeGeneratorDetails(FCodeGeneratorList.Items[i]);

       if LCodeGeneratorDetails1.tagType = ttInterpreter then
          begin
            lsTagValue := FInterpreter.Execute(LCodeGeneratorDetails1, liSkipPos1);

            if FInterpreter.IsFailedInterpreter then
              begin
                FOutput.WriteLog('Line Number: ' + IntToStr(I));

                Break;
              end;

            LTemplateTag1 := LCodeGeneratorDetails1.oTemplateTag;

            LTemplateTag1.TagValue := lsTagValue;
          end;
      end;
end;

function TCodeGenerator.PassTemplateTags(aClearRun: Boolean = false): Boolean;
Var
  I: Integer;
  FTemplateTag: TTemplateTag;
begin
  Try
    if aClearRun then
      begin
        FCodeGeneratorList.Clear;

        FTemplate.ParseTemplate;
      end;

    Result := True;

    for I  := 0 to FTemplate.TemplateTags.Count - 1 do
      begin
        FTemplateTag := TTemplateTag(FTemplate.TemplateTags.Items[I]);

        AddTag(FTemplateTag);
      end;
    Except
      FOutput.Errors := True;
      FOutput.Failed := True;

      FOutput.WriteLog('Error Line No:' + IntToStr(FTemplateTag.SourceLineNo) + ' Position: ' +  IntToStr(FTemplateTag.SourcePos));

      Result := False;

      Exit;
    End;
end;

procedure TCodeGenerator.Execute;
var
  I: integer;
  FTemplateTag: TTemplateTag;
begin
  Try
    // Pass 1
    If Not PassTemplateTags then Exit;

    DoProperties;

    DoPluginTags;

    RunPropertyVariables(0,(FCodeGeneratorList.Count - 1));

    DoIncludes;


    // Pass 2

    DoLanguage;

    DoProperties;

    RunPropertyVariables(0,(FCodeGeneratorList.Count - 1));

    DoConnections;

    RunInterpreter(0, (FCodeGeneratorList.Count - 1));

    DoTrimLines;

    FTemplate.InsertAllTagValues;

    DoDeleteLines;

    DoPostProcessorPlugins(aOutputFile);

  Except
    FOutput.WriteLog(TNovusUtilities.GetExceptMess);

    FOutput.Failed := true;

    Exit;
  End;


  {$I-}

  Try
    if not FOutput.Failed then
      FTemplate.OutputDoc.SaveToFile(aOutputFile, TEncoding.Unicode);
  Except
    FOutput.WriteLog('Save Error: ' + aOutputFile + ' - ' + TNovusUtilities.GetExceptMess);
  end;
  {$I+}
end;


procedure TCodeGenerator.DoPostProcessorPlugins(var aOutputFile: string);
begin
  oRuntime.oPlugins.PostProcessor(fProjectItem, fTemplate, aOutputFile);
end;

function TCodeGenerator.IsNonOutputCommandOnly(ASourceLineNo: Integer): Boolean;
Var
  I, X: INteger;
  LCodeGeneratorDetails : TCodeGeneratorDetails;
  LTemplateTag: TTemplateTag;
begin
  Result := False;

  for I := 0 to FCodeGeneratorList.Count - 1 do
   begin
     LCodeGeneratorDetails := TCodeGeneratorDetails(FCodeGeneratorList.Items[i]);

     if LCodeGeneratorDetails.tagType = ttInterpreter then
       begin
         LTemplateTag := LCodeGeneratorDetails.oTemplateTag;

         if LTemplateTag.SourceLineNo = ASourceLineNo then
           begin
             if LTemplateTag.TagName[1] <> '=' then
               Result := True
             else
               Result := false;
           end;
       end;
   end;
end;


procedure TCodeGenerator.DoTrimLines;
Var
  I, X: Integer;
  LStr: String;
  LCodeGeneratorDetails : TCodeGeneratorDetails;
  LTemplateTag: TTemplateTag;
begin
//
  for I := 0 to FTemplate.TemplateDoc.Count -1 do
    begin
      if IsNonOutputCommandOnly(i) = True then
        begin
          LStr := FTemplate.TemplateDoc.Strings[i-1];

          for X := 0 to FCodeGeneratorList.Count - 1 do
            begin
              LCodeGeneratorDetails := TCodeGeneratorDetails(FCodeGeneratorList.Items[x]);

              if LCodeGeneratorDetails.tagType = ttInterpreter then
                begin
                  LTemplateTag := LCodeGeneratorDetails.oTemplateTag;

                  if LTemplateTag.SourceLineNo = I then
                    System.Delete(LStr, Pos(LTemplateTag.RawTagEx, LStr), Length(LTemplateTag.RawTagEx));
                end;
            end;

          if Trim(LStr) = '' then
            begin
              for X := 0 to FCodeGeneratorList.Count - 1 do
                begin
                  LCodeGeneratorDetails := TCodeGeneratorDetails(FCodeGeneratorList.Items[x]);

                  if LCodeGeneratorDetails.tagType = ttInterpreter then
                    begin
                      LTemplateTag := LCodeGeneratorDetails.oTemplateTag;

                      if LTemplateTag.SourceLineNo = I then
                        LTemplateTag.TagValue := cDeleteline;
                    end;
                end;
            end;

        end;
    end;
end;

procedure TCodeGenerator.DoDeleteLines;
Var
  I: Integer;
begin
  i := 0;
  While(FTemplate.OutputDoc.Count > i)  do
    begin
      If Trim(FTemplate.OutputDoc.Strings[i]) = cDeleteLine then
        begin
          FTemplate.OutputDoc.Delete(i);

          Dec(i);
        end;

       Inc(i);
     end;
end;

procedure TCodeGenerator.RunPropertyVariables;
Var
  I,X, Y: integer;
  FTemplateTag: TTemplateTag;
  lsPropertieVariable: String;
  lsVariableResult: String;
  FCodeGeneratorDetails: TCodeGeneratorDetails;
begin
  for I := AStartPos to AEndPos do
   begin
     FCodeGeneratorDetails := TCodeGeneratorDetails(FCodeGeneratorList.Items[i]);

     FTemplateTag := FCodeGeneratorDetails.oTemplateTag;

     // Default Property value
     if FCodeGeneratorDetails.TagType = ttProperty then
       FTemplateTag.TagValue:= oRuntime.oProperties.GetProperty(FTemplateTag.TagName);


     for x := 0 to oRuntime.oProperties.NodeNames.Count - 1 do
      begin
        lsPropertieVariable := '$$' + Uppercase(oRuntime.oProperties.NodeNames.Strings[x]);

        If pos(lsPropertieVariable, Uppercase(FTemplateTag.TagName)) > 0 then
          begin
            lsVariableResult := oRuntime.oProperties.GetProperty(oRuntime.oProperties.NodeNames.Strings[x]);

            if FCodeGeneratorDetails.TagType = ttConnection then
              begin
                for Y := 0 to FCodeGeneratorDetails.Tokens.Count -1 do
                  If pos(lsPropertieVariable, Uppercase(FCodeGeneratorDetails.Tokens[y])) > 0 then
                    FCodeGeneratorDetails.Tokens[y] := TNovusStringUtils.ReplaceStr(FCodeGeneratorDetails.Tokens[y],  lsPropertieVariable, lsVariableResult, true);

              end
           else
           if FCodeGeneratorDetails.TagType = ttInterpreter then
              begin
                for Y := 0 to FCodeGeneratorDetails.Tokens.Count -1 do
                  If pos(lsPropertieVariable, Uppercase(FCodeGeneratorDetails.Tokens[y])) > 0 then
                    FCodeGeneratorDetails.Tokens[y] := TNovusStringUtils.ReplaceStr(FCodeGeneratorDetails.Tokens[y],  lsPropertieVariable, ''+ lsVariableResult + '', true);

              end;
           end
      end;
   end;

end;

procedure TCodeGenerator.DoLanguage;
Var
  I: integer;
  FTemplateTag: TTemplateTag;
  FCodeGeneratorDetails: TCodeGeneratorDetails;
begin
  for I := 0 to FCodeGeneratorList.Count - 1 do
   begin
      FCodeGeneratorDetails := TCodeGeneratorDetails(FCodeGeneratorList.Items[i]);

      if FCodeGeneratorDetails.tagType = ttLanguage then
        begin
          FTemplateTag := FCodeGeneratorDetails.oTemplateTag;

          If (FTemplateTag.RawTagEx = FTemplate.OutputDoc.Strings[FTemplateTag.SourceLineNo - 1]) then
            FTemplateTag.TagValue := cDeleteLine;

          fsLanguage := GetGlobalPropertyValue(FCodeGeneratorDetails.Tokens[2]);

          if FileExists(oConfig.Languagespath + fsLanguage + '.xml') then
            begin
              FLanguage.XMLFileName := oConfig.Languagespath+ fsLanguage + '.xml';
              FLanguage.LoadXML;

              FLanguage.Language := fsLanguage;
            end
          else oOutput.WriteLog('Language: ' + fsLanguage + ' not supported');
        end;
   end;
end;

function TCodeGenerator.GetGlobalPropertyValue(aToken: String): String;
begin
  If Copy(aToken, 1, 2) = '$$' then
    Result := oRuntime.oProperties.GetProperty(Copy(aToken, 3, Length(aToken) ))
  else Result := aToken;
end;


function TCodeGenerator.DoInternalIncludes: Boolean;
Var
  I, X, LineNo: integer;
  FCodeGeneratorDetails: TCodeGeneratorDetails;
  FTemplateTag: TTemplateTag;
  lsIncludeFilename: String;
  FIncludeTemplate: TStringList;
begin
  for I := 0 to FCodeGeneratorList.Count - 1 do
   begin
      Result := False;

      FCodeGeneratorDetails := TCodeGeneratorDetails(FCodeGeneratorList.Items[i]);

      if FCodeGeneratorDetails.tagType = ttInclude then
        begin
          Result := True;

          FTemplateTag := FCodeGeneratorDetails.oTemplateTag;

          If (FTemplateTag.RawTagEx = FTemplate.OutputDoc.Strings[FTemplateTag.SourceLineNo - 1]) then
            FTemplateTag.TagValue := cDeleteLine;

          lsIncludeFilename := fProject.oProjectConfig.TemplatePath + GetGlobalPropertyValue(FCodeGeneratorDetails.Tokens[2]);

          if FileExists(lsIncludeFilename) then
            begin
              LineNo := FTemplateTag.SourceLineNo -1;

              FIncludeTemplate:= TStringList.Create;

              FIncludeTemplate.LoadFromFile(lsIncludeFilename);

              //Post Processor
              oRuntime.oPlugins.PostProcessor(lsIncludeFilename, FIncludeTemplate);

              FTemplate.TemplateDoc.Delete(LineNo);

              for x := 0 to FIncludeTemplate.Count-1 do
                begin
                  FTemplate.TemplateDoc.Insert(LineNo, FIncludeTemplate.Strings[x]);

                  Inc(LineNo);
                end;

              FIncludeTemplate.Free;

              if Not PassTemplateTags(true) then  Result := False;
            end
          else
            begin
              Result := False;

              FOutput.WriteLog('Cannot find include file=' + lsIncludeFilename);

              FOutput.Errors := True;
              FOutput.Failed := True;

              FOutput.WriteLog('Error Line No:' + IntToStr(FTemplateTag.SourceLineNo) + ' Position: ' +  IntToStr(FTemplateTag.SourcePos));
            end;


          Break;
        end;
   end;
end;


function TCodeGenerator.DoIncludes: Boolean;
Var
  lOK: Boolean;
begin
  lOK := DoInternalIncludes;

  While(lOK = true) do
    lOK := DoInternalIncludes;
end;


procedure TCodeGenerator.DoProperties;
Var
  I: integer;
  FTemplateTag: TTemplateTag;
  FCodeGeneratorDetails: TCodeGeneratorDetails;
begin
  for I := 0 to FCodeGeneratorList.Count - 1 do
   begin
      FCodeGeneratorDetails := TCodeGeneratorDetails(FCodeGeneratorList.Items[i]);

      if FCodeGeneratorDetails.tagType = ttProperty then
        begin
          FTemplateTag := FCodeGeneratorDetails.oTemplateTag;

          FTemplateTag.TagValue := oRuntime.oProperties.GetProperty(FTemplateTag.TagName);
        end;
   end;
end;

procedure TCodeGenerator.DoPluginTags;
Var
  I: integer;
  FTemplateTag: TTemplateTag;
  FCodeGeneratorDetails: TCodeGeneratorDetails;
begin
  for I := 0 to FCodeGeneratorList.Count - 1 do
   begin
      FCodeGeneratorDetails := TCodeGeneratorDetails(FCodeGeneratorList.Items[i]);

      if (FCodeGeneratorDetails.tagType = ttInterpreter) then
        begin
          FTemplateTag := FCodeGeneratorDetails.oTemplateTag;

          if oRuntime.oPlugins.IsTagExists(FTemplateTag.TagName) then
            begin
              FCodeGeneratorDetails.tagType := ttplugintag;

              FTemplateTag.TagValue := oRuntime.oPlugins.GetTag(FTemplateTag.TagName);
            end;
        end;
   end;
end;

procedure TCodeGenerator.DoConnections;
Var
  I: integer;
  FTemplateTag: TTemplateTag;
  FCodeGeneratorDetails: TCodeGeneratorDetails;
begin
  for I := 0 to FCodeGeneratorList.Count - 1 do
   begin
      FCodeGeneratorDetails := TCodeGeneratorDetails(FCodeGeneratorList.Items[i]);

      if FCodeGeneratorDetails.tagType = ttConnection then
        begin
          FTemplateTag := FCodeGeneratorDetails.oTemplateTag;

          If (FTemplateTag.RawTagEx = FTemplate.OutputDoc.Strings[FTemplateTag.SourceLineNo - 1]) then
            FTemplateTag.TagValue := cDeleteLine;

          oRuntime.oConnections.AddConnection(FCodeGeneratorDetails);
        end;
   end;
end;

constructor TCodeGeneratorDetails.Create;
begin
  inherited Create;

  FEParser := TFEParser.Create;

  FTokens := tStringlist.Create;
end;

destructor TCodeGeneratorDetails.Destroy;
begin
  FEParser.Free;

  FTokens.Free;

  inherited;
end;

procedure TCodeGeneratorDetails.Execute;
begin
  fsDefaultTagName := oTemplateTag.TagName;

  FEParser.Expr := oTemplateTag.TagName;

  FEParser.ListTokens(FTokens);

  FTagType := FCodeGenerator.GetTagType(FTokens);
end;


end.
