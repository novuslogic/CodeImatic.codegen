unit CodeGenerator;

interface

Uses Classes, NovusTemplate, NovusList, ExpressionParser, SysUtils,
  Config, NovusStringUtils, Interpreter, Language, Project,
  Output, Variables, NovusUtilities, CodeGeneratorItem, tagtype,
  NovusBO, NovusFileUtils, Template, ScriptEngine;

Const
  cDeleteLine = '{%DELETELINE%}';
  cBlankline = '{%BLANKLINE%}';

Type
  TCodeGenerator = class(TObject)
  protected
    FScript: TStringList;
    foProcessorPlugin: TObject;
    fProject: tProject;
    fVariables: tVariables;
    fOutput: tOutput;
    FLanguage: tLanguage;
    fsLanguage: String;
    FInterpreter: tInterpreter;
    fProjectItem: TObject;
    FoTemplate: TTemplate;
    FCodeGeneratorList: TNovusList;
    Flayout: TObject;
    fsRenderBodyTag: string;
    fsInputFilename: string;
    fsSourceFilename: String;
  private
    function DoInternalCodeBehine(aFilename: string): boolean;
    procedure DoInternalCode(aScript: String);
    procedure DoPluginTags;
    procedure DoLanguage;
    procedure DoConnections;
    function DoPreProcessor: boolean;
    procedure DoCodeBehine;
    procedure DoCodeTags;
    procedure DoScriptEngine;
    procedure DoPostProcessor(var aOutputFile: string);
    function DoIncludes: boolean;
    function DoPreLayout: boolean;
    function DoPostLayout: boolean;
    procedure DoProperties;
    procedure DoTrimLines;
    procedure DoSpecialTags;
    procedure DoInternalSpecialTags(const aStrings: TStrings);
    function PassTemplateTags(aClearRun: boolean = false): boolean;
    function DoInternalIncludes(aTagType: TTagType = ttInclude): boolean;
    function LocalWorkingdirectory: String;
  public
    constructor Create(ATemplate: TTemplate; AOutput: tOutput;
      aProject: tProject; aProjectItem: TObject; aProcessorPlugin: TObject;
      aInputFilename: string;
      aSourceFilename: String); virtual;

    destructor Destroy; override;

    function IsNonOutputCommandonly(ASourceLineNo: Integer): boolean;

    procedure RunPropertyVariables(AStartPos, AEndPos: Integer);

    function InsertTagValue(aTagValue: String; aTagName: String): boolean;

    function AddTag(ATemplateTag: TTemplateTag): TCodeGeneratorItem;

    procedure RunInterpreter(AStartPos, AEndPos: Integer);

    property Language: String read fsLanguage write fsLanguage;

    property oLanguage: tLanguage read FLanguage write FLanguage;

    property oVariables: tVariables read fVariables write fVariables;

    property oOutput: tOutput read fOutput write fOutput;

    function IsInterpreter(ATokens: TstringList): boolean;

    function Execute(aOutputFilename: String): boolean;

    property CodeGeneratorList: TNovusList read FCodeGeneratorList
      write FCodeGeneratorList;

    property oTemplate: TTemplate read FoTemplate write FoTemplate;

    property oProject: tProject read fProject write fProject;

    property RenderBodyTag: string read fsRenderBodyTag write fsRenderBodyTag;
  end;

implementation

uses runtime, TokenParser, ProjectItemLoader, ProjectItem, Processor,
  TagTypeParser, Plugin;

constructor TCodeGenerator.Create;
begin
  inherited Create;

  foProcessorPlugin := aProcessorPlugin;

  fsInputFilename := aInputFilename;

  fProjectItem := aProjectItem;

  fProject := aProject;

  fsSourceFilename:= aSourceFileName;

  fVariables := tVariables.Create;

  fOutput := AOutput;

  FoTemplate := ATemplate;

  FCodeGeneratorList := TNovusList.Create(TCodeGeneratorItem);

  FInterpreter := tInterpreter.Create(Self, fOutput, fProjectItem);

  FLanguage := tLanguage.Create;

  FScript := TstringList.Create;

  Flayout := NIL;
end;

destructor TCodeGenerator.Destroy;
begin
  if Assigned(Flayout) then
    Flayout.Free;

  fVariables.Free;

  FLanguage.Free;

  FInterpreter.Free;

  FCodeGeneratorList.Free;

  FScript.Free;

  inherited;
end;

function TCodeGenerator.InsertTagValue(aTagValue: string;
  aTagName: string): boolean;
Var
  I: Integer;
  FoTemplateTag: TTemplateTag;
  FCodeGeneratorItem: TCodeGeneratorItem;
begin
  for I := 0 to FCodeGeneratorList.Count - 1 do
  begin
    FCodeGeneratorItem := TCodeGeneratorItem(FCodeGeneratorList.Items[I]);

    FoTemplateTag := FCodeGeneratorItem.oTemplateTag;

    if Uppercase(FoTemplateTag.TagName) = Uppercase(aTagName) then
      FoTemplateTag.TagValue := aTagValue;
  end;

end;

function TCodeGenerator.AddTag(ATemplateTag: TTemplateTag)
  : TCodeGeneratorItem;
Var
  lCodeGeneratorItem: TCodeGeneratorItem;
begin
  Result := NIL;

  lCodeGeneratorItem := TCodeGeneratorItem.Create(fProjectItem, Self);

  lCodeGeneratorItem.oTemplateTag := ATemplateTag;

  lCodeGeneratorItem.Execute;

  if lCodeGeneratorItem.tagtype <> ttUnknown then
  begin
    FCodeGeneratorList.Add(lCodeGeneratorItem);

    Result := lCodeGeneratorItem;
  end
  else
    lCodeGeneratorItem.Free;

end;

function TCodeGenerator.IsInterpreter(ATokens: TstringList): boolean;
begin
  Result := (FInterpreter.CommandSyntaxIndexByTokens(ATokens) <> -1);
end;

procedure TCodeGenerator.RunInterpreter;
Var
  LiSkipPos1, LiSkipPos2: Integer;
  lsTagValue: String;
  I, X: Integer;
  LTemplateTag1, LTemplateTag2: TTemplateTag;
  LCodeGeneratorItem1, LCodeGeneratorItem2: TCodeGeneratorItem;
  liLastSourceNo: Integer;
  liTagIndex: Integer;
begin
  liLastSourceNo := 0;
  LiSkipPos1 := 0;

  for I := AStartPos to AEndPos do
  begin
    if LiSkipPos1 <> 0 then
      if LiSkipPos1 > I then
        Continue;

    LCodeGeneratorItem1 := TCodeGeneratorItem
      (FCodeGeneratorList.Items[I]);

    if LCodeGeneratorItem1.tagtype = ttInterpreter then
    begin
      lsTagValue := FInterpreter.Execute(LCodeGeneratorItem1, LiSkipPos1);

      LTemplateTag1 := LCodeGeneratorItem1.oTemplateTag;

      LTemplateTag1.TagValue := lsTagValue;
    end;
  end;
end;

function TCodeGenerator.PassTemplateTags(aClearRun: boolean = false): boolean;
Var
  I: Integer;
  FoTemplateTag: TTemplateTag;
begin
  Try
    if aClearRun then
    begin
      Try
        FCodeGeneratorList.Clear; // Clearing need to be backup

        FoTemplate.ParseTemplate;
      Finally
      End;

    end;

    Result := true;

    for I := 0 to FoTemplate.TemplateTags.Count - 1 do
    begin
      FoTemplateTag := TTemplateTag(FoTemplate.TemplateTags.Items[I]);

      AddTag(FoTemplateTag);
    end;
  Except
    fOutput.Errors := true;
    fOutput.Failed := true;

    fOutput.Log('Error Line No:' + IntToStr(FoTemplateTag.SourceLineNo) +
      ' Position: ' + IntToStr(FoTemplateTag.SourcePos));

    Result := false;

    Exit;
  End;
end;

function TCodeGenerator.Execute;
var
  I: Integer;
  FoTemplateTag: TTemplateTag;
begin
  Try
    // Pass 1
    Result := false;

    If Not PassTemplateTags then
      Exit;

    DoProperties;

    DoPluginTags;

    RunPropertyVariables(0, (FCodeGeneratorList.Count - 1));

    DoIncludes;

    DoCodeBehine;

    DoCodeTags;

    DoScriptEngine;

    DoPreProcessor;

    // Pass 2
    if DoPreLayout then
      DoPostLayout;

    DoLanguage;

    DoProperties;

    DoPluginTags;

    RunPropertyVariables(0, (FCodeGeneratorList.Count - 1));

    DoConnections;

    RunInterpreter(0, (FCodeGeneratorList.Count - 1));

    DoTrimLines;

    FoTemplate.InsertAllTagValues;

    DoSpecialTags;

    if Trim(aOutputFilename) <> '' then
      DoPostProcessor(aOutputFilename);

    Result := true;
  Except
    fOutput.Log(TNovusUtilities.GetExceptMess);

    fOutput.Failed := true;

    Result := false;

    Exit;
  End;

  if Trim(aOutputFilename) <> '' then
  begin
{$I-}
    Try
      if not fOutput.Failed then
        FoTemplate.OutputDoc.SaveToFile(aOutputFilename, TEncoding.Unicode);
    Except
      fOutput.Log('Save Error: ' + aOutputFilename + ' - ' +
        TNovusUtilities.GetExceptMess);
    end;
{$I+}
  end;
end;

procedure TCodeGenerator.DoPostProcessor(var aOutputFile: string);
begin
  oRuntime.oPlugins.PostProcessor((fProjectItem as TProjectItem), FoTemplate,
    aOutputFile, (foProcessorPlugin as TProcessorPlugin));
end;

function TCodeGenerator.IsNonOutputCommandonly(ASourceLineNo: Integer): boolean;
Var
  I, X: Integer;
  lCodeGeneratorItem: TCodeGeneratorItem;
  LTemplateTag: TTemplateTag;
begin
  Result := false;

  for I := 0 to FCodeGeneratorList.Count - 1 do
  begin
    lCodeGeneratorItem := TCodeGeneratorItem(FCodeGeneratorList.Items[I]);

    if lCodeGeneratorItem.tagtype = ttInterpreter then
    begin
      LTemplateTag := lCodeGeneratorItem.oTemplateTag;

      if LTemplateTag.SourceLineNo = ASourceLineNo then
      begin
        if LTemplateTag.TagName[1] <> '=' then
          Result := true
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
  lCodeGeneratorItem: TCodeGeneratorItem;
  LTemplateTag: TTemplateTag;
begin
  //
  for I := 0 to FoTemplate.TemplateDoc.Count - 1 do
  begin
    if IsNonOutputCommandonly(I) = true then
    begin
      LStr := FoTemplate.TemplateDoc.Strings[I - 1];

      for X := 0 to FCodeGeneratorList.Count - 1 do
      begin
        lCodeGeneratorItem := TCodeGeneratorItem
          (FCodeGeneratorList.Items[X]);

        if lCodeGeneratorItem.tagtype = ttInterpreter then
        begin
          LTemplateTag := lCodeGeneratorItem.oTemplateTag;

          if LTemplateTag.SourceLineNo = I then
            System.Delete(LStr, Pos(LTemplateTag.RawTagEx, LStr),
              Length(LTemplateTag.RawTagEx));
        end;
      end;

      if Trim(LStr) = '' then
      begin
        for X := 0 to FCodeGeneratorList.Count - 1 do
        begin
          lCodeGeneratorItem := TCodeGeneratorItem
            (FCodeGeneratorList.Items[X]);

          if lCodeGeneratorItem.tagtype = ttInterpreter then
          begin
            LTemplateTag := lCodeGeneratorItem.oTemplateTag;

            if LTemplateTag.SourceLineNo = I then
              LTemplateTag.TagValue := cDeleteLine;
          end;
        end;
      end;

    end;
  end;
end;

procedure TCodeGenerator.DoSpecialTags;
begin
  DoInternalSpecialTags(FoTemplate.OutputDoc);
end;

procedure TCodeGenerator.DoInternalSpecialTags(const aStrings: TStrings);
Var
  loTemplate: TTemplate;
  I: Integer;
  LTemplateTag: TTemplateTag;
begin
  try
    loTemplate := TTemplate.CreateTemplate;
    loTemplate.TemplateDoc.Text := aStrings.Text;
    loTemplate.StartToken := '{';
    loTemplate.EndToken := '}';

    loTemplate.ParseTemplate;

    I := 0;
    While (loTemplate.TemplateTags.Count > I) do
    begin
      LTemplateTag := TTemplateTag(loTemplate.TemplateTags.Items[I]);

      if LTemplateTag.RawTagEx = cBlankline then
      begin
        loTemplate.TemplateDoc.Strings[LTemplateTag.SourceLineNo - 1] := '';

        loTemplate.ParseTemplate;

        Dec(I);
      end
      else if LTemplateTag.RawTagEx = cDeleteLine then
      begin
        loTemplate.TemplateDoc.Delete(LTemplateTag.SourceLineNo - 1);

        loTemplate.ParseTemplate;

        Dec(I);
      end;

      Inc(I);
    end;
    loTemplate.InsertAllTagValues;
    aStrings.Text := loTemplate.OutputDoc.Text;
  finally
    loTemplate.Free;
  end;
end;

procedure TCodeGenerator.RunPropertyVariables;
Var
  I, X, Y: Integer;
  FoTemplateTag: TTemplateTag;
  lsPropertieVariable: String;
  lsVariableResult: String;
  FCodeGeneratorItem: TCodeGeneratorItem;
  FVariable: TVariable;
begin
  for I := AStartPos to AEndPos do
  begin
    FCodeGeneratorItem := TCodeGeneratorItem(FCodeGeneratorList.Items[I]);

    FoTemplateTag := FCodeGeneratorItem.oTemplateTag;

    // Default Property value
    if FCodeGeneratorItem.tagtype = ttVariableCmdLine then
    begin
      if FCodeGeneratorItem.Tokens.Count > 1 then
      begin
        FVariable := oConfig.oVariablesCmdLine.GetVariableByName
          (FCodeGeneratorItem.Tokens[1]);
        if Assigned(FVariable) then
          FoTemplateTag.TagValue := FVariable.Value;
      end;
    end
    else if FCodeGeneratorItem.tagtype = ttConfigProperties then
    begin
      if FCodeGeneratorItem.Tokens.Count > 1 then
        FoTemplateTag.TagValue := fProject.oProjectConfig.Getproperties
          (FCodeGeneratorItem.Tokens[1]);
    end
    else if FCodeGeneratorItem.tagtype = ttprojectitem then
    begin
      if FCodeGeneratorItem.Tokens.Count > 1 then
        FoTemplateTag.TagValue := (fProjectItem as TProjectItem)
          .GetProperty(FCodeGeneratorItem.Tokens[1], fProject);
    end
    else if (FCodeGeneratorItem.tagtype = ttProperty) or
      (FCodeGeneratorItem.tagtype = ttPropertyEx) then
    begin
      if (FCodeGeneratorItem.tagtype = ttProperty) then
        FoTemplateTag.TagValue := (fProjectItem as TProjectItem)
          .oProperties.GetProperty(FoTemplateTag.TagName)
      else if (FCodeGeneratorItem.tagtype = ttPropertyEx) then
      begin
        FoTemplateTag.TagValue := (fProjectItem as TProjectItem)
          .oProperties.GetProperty(FCodeGeneratorItem.Token2)

      end;
    end;

    for X := 0 to (fProjectItem as TProjectItem)
      .oProperties.NodeNames.Count - 1 do
    begin
      lsPropertieVariable := '$$' + Uppercase((fProjectItem as TProjectItem)
        .oProperties.NodeNames.Strings[X]);

      If Pos(lsPropertieVariable, Uppercase(FoTemplateTag.TagName)) > 0 then
      begin
        lsVariableResult := (fProjectItem as TProjectItem)
          .oProperties.GetProperty((fProjectItem as TProjectItem)
          .oProperties.NodeNames.Strings[X]);

        if FCodeGeneratorItem.tagtype = ttConnection then
        begin
          for Y := 0 to FCodeGeneratorItem.Tokens.Count - 1 do
            If Pos(lsPropertieVariable,
              Uppercase(FCodeGeneratorItem.Tokens[Y])) > 0 then
              FCodeGeneratorItem.Tokens[Y] := TNovusStringUtils.ReplaceStr
                (FCodeGeneratorItem.Tokens[Y], lsPropertieVariable,
                lsVariableResult, true);

        end
        else if FCodeGeneratorItem.tagtype = ttInterpreter then
        begin
          for Y := 0 to FCodeGeneratorItem.Tokens.Count - 1 do
            If Pos(lsPropertieVariable,
              Uppercase(FCodeGeneratorItem.Tokens[Y])) > 0 then
              FCodeGeneratorItem.Tokens[Y] := TNovusStringUtils.ReplaceStr
                (FCodeGeneratorItem.Tokens[Y], lsPropertieVariable,
                '' + lsVariableResult + '', true);

        end;
      end
    end;
  end;

end;

procedure TCodeGenerator.DoLanguage;
Var
  I: Integer;
  FoTemplateTag: TTemplateTag;
  FCodeGeneratorItem: TCodeGeneratorItem;
  FiIndex: Integer;
begin
  for I := 0 to FCodeGeneratorList.Count - 1 do
  begin
    FCodeGeneratorItem := TCodeGeneratorItem(FCodeGeneratorList.Items[I]);

    if FCodeGeneratorItem.tagtype = ttLanguage then
    begin
      FoTemplateTag := FCodeGeneratorItem.oTemplateTag;

      If (FoTemplateTag.RawTagEx = FoTemplate.OutputDoc.Strings
        [FoTemplateTag.SourceLineNo - 1]) then
        FoTemplateTag.TagValue := cDeleteLine;

      FiIndex := 0;
      fsLanguage := tTokenParser.ParseToken(Self,
        FCodeGeneratorItem.Tokens[2], (fProjectItem as TProjectItem),
        fVariables, fOutput, NIL, FiIndex, fProject);

      if FileExists(oConfig.Languagespath + fsLanguage + '.xml') then
      begin
        FLanguage.XMLFileName := oConfig.Languagespath + fsLanguage + '.xml';
        FLanguage.LoadXML;

        FLanguage.Language := fsLanguage;
      end
      else
        oOutput.Log('Language: ' + fsLanguage + ' not supported');
    end;
  end;
end;

function TCodeGenerator.DoInternalIncludes(aTagType: TTagType): boolean;
Var
  I, X, LineNo: Integer;
  FCodeGeneratorItem: TCodeGeneratorItem;
  FoTemplateTag: TTemplateTag;
  lsTempIncludeFilename, lsIncludeFilename: String;
  FIncludeTemplate: TstringList;
  FiIndex: Integer;
  FTokenProcessor: tTokenProcessor;
  lsOutputTag: String;
  lsRenderBodyTag: String;
begin
  for I := 0 to FCodeGeneratorList.Count - 1 do
  begin
    Result := false;

    FCodeGeneratorItem := TCodeGeneratorItem(FCodeGeneratorList.Items[I]);

    lsIncludeFilename := '';

    if FCodeGeneratorItem.tagtype = aTagType then
    begin
      Try
        Result := true;

        FoTemplateTag := FCodeGeneratorItem.oTemplateTag;

        if FoTemplateTag.TagValue = cDeleteLine then
          Exit;

        If (FoTemplateTag.RawTagEx = FoTemplate.OutputDoc.Strings
          [FoTemplateTag.SourceLineNo - 1]) then
          FoTemplateTag.TagValue := cDeleteLine;

        FTokenProcessor := tTokenParser.ParseExpressionToken(Self,
          FoTemplateTag.RawTag, (fProjectItem as TProjectItem), fProject,
          fVariables, fOutput);

        case FCodeGeneratorItem.tagtype of
          ttlayout:
            begin;
              if Uppercase(FTokenProcessor.GetNextToken) = 'LAYOUT' then
              begin
                if FTokenProcessor.IsNextTokenEquals then
                begin
                  lsTempIncludeFilename := FTokenProcessor.GetNextToken;
                  if lsTempIncludeFilename = '' then
                    fOutput.LogError('LAYOUT: Filename not found.');

                  lsRenderBodyTag := FTokenProcessor.GetNextToken;
                  if lsRenderBodyTag = '' then
                    fOutput.LogError('LAYOUT: RenderBodyTag not found.')

                end
                else
                  fOutput.LogError('LAYOUT: Equals symbol not found.');

              end
              else
                fOutput.LogError('LAYOUT: Tag not found.');
            end;

          ttInclude:
            begin
              if Uppercase(FTokenProcessor.GetNextToken) = 'INCLUDE' then
              begin
                if FTokenProcessor.IsNextTokenEquals then
                begin
                  lsTempIncludeFilename := FTokenProcessor.GetNextToken;
                  if lsTempIncludeFilename = '' then
                    fOutput.LogError('INCLUDE: Filename not found.');

                end
                else
                  fOutput.LogError('INCLUDE: Equals symbol not found.');
              end;
            end;

        end;
      Finally
        if lsTempIncludeFilename <> '' then
          lsIncludeFilename := TNovusFileUtils.TrailingBackSlash
            (fProject.oProjectConfig.TemplatePath) + lsTempIncludeFilename;

        if Assigned(FTokenProcessor) then
          FTokenProcessor.Free;
      End;

      if FileExists(lsIncludeFilename) then
      begin
        if FCodeGeneratorItem.tagtype = TTagType.ttInclude then
        begin
          LineNo := FoTemplateTag.SourceLineNo - 1;

          Try
            FIncludeTemplate := TstringList.Create;

            FIncludeTemplate.LoadFromFile(lsIncludeFilename);

            // Pre Processor
            oRuntime.oPlugins.PreProcessor(lsIncludeFilename, FIncludeTemplate);

            FoTemplate.TemplateDoc.Delete(LineNo);

            for X := 0 to FIncludeTemplate.Count - 1 do
            begin
              FoTemplate.TemplateDoc.Insert(LineNo,
                FIncludeTemplate.Strings[X]);

              Inc(LineNo);
            end;
          Finally
            FIncludeTemplate.Free;
          End;

          if Not PassTemplateTags(true) then
            Result := false;
        end
        else if FCodeGeneratorItem.tagtype = TTagType.ttlayout then
        begin
          Flayout := TProcessor.Create(fOutput, fProject,
            (fProjectItem as TProjectItem), NIL, '', '', lsIncludeFilename);

          (Flayout as TProcessor).InputFilename := lsIncludeFilename;
          (Flayout as TProcessor).OutputFilename := '';
          (Flayout as TProcessor).oCodeGenerator.RenderBodyTag :=
            lsRenderBodyTag;

          Result := (Flayout as TProcessor).Execute;

        end;
      end
      else
      begin
        Result := false;

        if FCodeGeneratorItem.tagtype = TTagType.ttInclude then
          fOutput.Log('Cannot find include file=' + lsIncludeFilename)
        else if FCodeGeneratorItem.tagtype = TTagType.ttlayout then
          fOutput.Log('Cannot find layout file=' + lsIncludeFilename);

        fOutput.Errors := true;
        fOutput.Failed := true;

        fOutput.Log('Error Line No:' + IntToStr(FoTemplateTag.SourceLineNo) +
          ' Position: ' + IntToStr(FoTemplateTag.SourcePos));
      end;

      Break;
    end;
  end;
end;

function TCodeGenerator.DoIncludes: boolean;
Var
  lOK: boolean;
begin
  lOK := DoInternalIncludes;

  While (lOK = true) do
    lOK := DoInternalIncludes;
end;

function TCodeGenerator.DoPreProcessor: boolean;
var
  FPreProcessorTemplate: TstringList;
begin
  Result := false;
  if fsInputFilename = '' then
    Exit;

  Try
    FPreProcessorTemplate := TstringList.Create;

    FPreProcessorTemplate.Text := FoTemplate.TemplateDoc.Text;

    Result := oRuntime.oPlugins.PreProcessor(fsInputFilename,
      FPreProcessorTemplate);

    if Result then
    begin
      FoTemplate.TemplateDoc.Text := FPreProcessorTemplate.Text;

      if Not PassTemplateTags(true) then
        Result := false;
    end;

  Finally
    FPreProcessorTemplate.Free;
  End;
end;

function TCodeGenerator.DoPreLayout: boolean;
var
  FCodeGeneratorItem: TCodeGeneratorItem;
  FoTemplateTag: TTemplateTag;
  I: Integer;
begin
  if RenderBodyTag = '' then
    Result := DoInternalIncludes(ttlayout)
  else
  begin
    for I := 0 to FCodeGeneratorList.Count - 1 do
    begin
      FCodeGeneratorItem := TCodeGeneratorItem
        (FCodeGeneratorList.Items[I]);

      FoTemplateTag := FCodeGeneratorItem.oTemplateTag;

      if Uppercase(FoTemplateTag.TagName) = Uppercase(RenderBodyTag) then
      begin
        FoTemplateTag.TagValue := FoTemplate.StartToken + FoTemplate.SecondToken
          + Uppercase(RenderBodyTag) + FoTemplate.SecondToken +
          FoTemplate.EndToken;

        Break;
      end;

    end;
  end;
end;

procedure TCodeGenerator.DoCodeTags;
var
  FCodeGeneratorItem: TCodeGeneratorItem;
  FoTemplateTag: TTemplateTag;
  I: Integer;
  FTokenProcessor: tTokenProcessor;
  lsScript: String;
begin
  for I := 0 to FCodeGeneratorList.Count - 1 do
  begin
    FCodeGeneratorItem := TCodeGeneratorItem(FCodeGeneratorList.Items[I]);

    if (FCodeGeneratorItem.tagtype = ttCode) then
    begin
      FoTemplateTag := FCodeGeneratorItem.oTemplateTag;

      if FoTemplateTag.TagValue = cDeleteLine then
        Exit;

      FoTemplateTag.TagValue := cDeleteLine;

      Try
        FTokenProcessor := tTokenParser.ParseSimpleToken(FoTemplateTag.RawTag, fOutput);

        if Uppercase(FTokenProcessor.GetNextToken) = 'CODE' then
        begin
          if FTokenProcessor.IsNextTokenEquals then
          begin
            lsScript := FTokenProcessor.GetNextToken;
            if Trim(lsScript) = '' then
              fOutput.LogError('CODE: Empty script.')
            else
              begin
                DoInternalCode(lsScript);

              end;
          end
          else
            fOutput.LogError('CODE: Equals symbol not found.');
        end;

      Finally
        FTokenProcessor.Free;
      End;
    end;
  end;
end;

procedure TCodeGenerator.DoScriptEngine;
begin
  if Trim(FScript.text) = '' then Exit;



  oRuntime.oScriptEngine.ExecuteScript(FScript.text)
end;


procedure TCodeGenerator.DoCodeBehine;
var
  FCodeGeneratorItem: TCodeGeneratorItem;
  FoTemplateTag: TTemplateTag;
  I: Integer;
  FTokenProcessor: tTokenProcessor;
  lsFilename: String;
begin
  for I := 0 to FCodeGeneratorList.Count - 1 do
  begin
    FCodeGeneratorItem := TCodeGeneratorItem(FCodeGeneratorList.Items[I]);

    if (FCodeGeneratorItem.tagtype = ttCodeBehine) then
    begin
      FoTemplateTag := FCodeGeneratorItem.oTemplateTag;

      if FoTemplateTag.TagValue = cDeleteLine then
        Exit;

      FoTemplateTag.TagValue := cDeleteLine;

      Try
        FTokenProcessor := tTokenParser.ParseExpressionToken(Self,
          FoTemplateTag.RawTag, (fProjectItem as TProjectItem), fProject,
          fVariables, fOutput);

        if Uppercase(FTokenProcessor.GetNextToken) = 'CODEBEHINE' then
        begin
          if FTokenProcessor.IsNextTokenEquals then
          begin
            lsFilename := FTokenProcessor.GetNextToken;
            if lsFilename = '' then
              fOutput.LogError('CODEBEHINE: Filename not found.')
            else
              begin
                DoInternalCodeBehine(lsfilename);

              end;
          end
          else
            fOutput.LogError('CODEBEHINE: Equals symbol not found.');
        end;

      Finally
        FTokenProcessor.Free;
      End;
    end;
  end;
end;

procedure TCodeGenerator.DoProperties;
Var
  I: Integer;
  FoTemplateTag: TTemplateTag;
  FCodeGeneratorItem: TCodeGeneratorItem;
begin
  for I := 0 to FCodeGeneratorList.Count - 1 do
  begin
    FCodeGeneratorItem := TCodeGeneratorItem(FCodeGeneratorList.Items[I]);

    if FCodeGeneratorItem.tagtype = ttProperty then
    begin
      FoTemplateTag := FCodeGeneratorItem.oTemplateTag;

      FoTemplateTag.TagValue := (fProjectItem as TProjectItem)
        .oProperties.GetProperty(FoTemplateTag.TagName);
    end
    else if FCodeGeneratorItem.tagtype = ttPropertyEx then
    begin
      FoTemplateTag := FCodeGeneratorItem.oTemplateTag;

      FoTemplateTag.TagValue := (fProjectItem as TProjectItem)
        .oProperties.GetProperty(FCodeGeneratorItem.Token2);
    end;
  end;
end;

procedure TCodeGenerator.DoPluginTags;
Var
  I: Integer;
  FoTemplateTag: TTemplateTag;
  FCodeGeneratorItem: TCodeGeneratorItem;
begin
  for I := 0 to FCodeGeneratorList.Count - 1 do
  begin
    FCodeGeneratorItem := TCodeGeneratorItem(FCodeGeneratorList.Items[I]);

    if (FCodeGeneratorItem.tagtype = ttPluginTag) then
    begin
      FoTemplateTag := FCodeGeneratorItem.oTemplateTag;

      if FCodeGeneratorItem.Tokens.Count > 1 then
      begin
        if oRuntime.oPlugins.IsTagExists(FCodeGeneratorItem.Tokens[0],
          FCodeGeneratorItem.Tokens[1]) then
        begin
          FoTemplateTag.TagValue := oRuntime.oPlugins.GetTag
            (FCodeGeneratorItem.Tokens[0], FCodeGeneratorItem.Tokens[1]);
        end;
      end
      else
        FoTemplateTag.TagValue := '';
    end;
  end;
end;

procedure TCodeGenerator.DoConnections;
Var
  I: Integer;
  FoTemplateTag: TTemplateTag;
  FCodeGeneratorItem: TCodeGeneratorItem;
begin
  for I := 0 to FCodeGeneratorList.Count - 1 do
  begin
    FCodeGeneratorItem := TCodeGeneratorItem(FCodeGeneratorList.Items[I]);

    if FCodeGeneratorItem.tagtype = ttConnection then
    begin
      FoTemplateTag := FCodeGeneratorItem.oTemplateTag;

      If (FoTemplateTag.RawTagEx = FoTemplate.OutputDoc.Strings
        [FoTemplateTag.SourceLineNo - 1]) then
        FoTemplateTag.TagValue := cDeleteLine;

      (fProjectItem as TProjectItem).oConnections.AddConnection
        (FCodeGeneratorItem);
    end;
  end;
end;

function TCodeGenerator.DoPostLayout;
Var
  loLayoutTemplate: TTemplate;
  LIndex: Integer;
  lsRenderBodyTag: string;
  I: Integer;
  lCodeGeneratorItem: TCodeGeneratorItem;
  LTemplateTag: TTemplateTag;
begin
  If Assigned(Flayout) then
  begin
    Try
      loLayoutTemplate := TTemplate.CreateTemplate(true);

      loLayoutTemplate.TemplateDoc.AddStrings((Flayout as TProcessor)
        .oCodeGenerator.oTemplate.OutputDoc);

      loLayoutTemplate.ParseTemplate;

      lsRenderBodyTag := Uppercase((Flayout as TProcessor)
        .oCodeGenerator.RenderBodyTag);

      LIndex := loLayoutTemplate.FindTagNameIndexOf(lsRenderBodyTag);
      if LIndex <> -1 then
      begin
        LIndex := loLayoutTemplate.FindTagNameIndexOf(lsRenderBodyTag);
        if LIndex <> -1 then
        begin
          LTemplateTag :=
            TTemplateTag(loLayoutTemplate.TemplateTags.Items[LIndex]);
          LTemplateTag.TagValue := FoTemplate.TemplateDoc.Text;
        end;

        loLayoutTemplate.InsertAllTagValues;
        FoTemplate.TemplateDoc.Text := loLayoutTemplate.OutputDoc.Text;

        if Not PassTemplateTags(true) then
          Result := false;

        for I := 0 to FCodeGeneratorList.Count - 1 do
        begin
          lCodeGeneratorItem := TCodeGeneratorItem
            (FCodeGeneratorList.Items[I]);

          if lCodeGeneratorItem.tagtype = ttlayout then
          begin
            LTemplateTag := lCodeGeneratorItem.oTemplateTag;

            LTemplateTag.TagValue := cDeleteLine;
          end;
        end;

      end;

    finally
      loLayoutTemplate.Free;
    end;
  end;
end;

function TCodeGenerator.LocalWorkingdirectory: String;
begin
  Result := TNovusFileUtils.TrailingBackSlash(ExtractFileDir(fsSourceFilename));
end;


function TCodeGenerator.DoInternalCodeBehine(aFilename: string): boolean;
var
  lsTempFilename: String;
begin
  Result := False;

  lsTempFilename := LocalWorkingdirectory + aFilename;

  if Not FileExists(lsTempFilename) then
    begin
      fOutput.LogError('CODEBEHINE: Filename not found [' +lsTempFilename + ']');

      Exit;
    end;

  Try
    Try
      FScript.LoadFromFile(lsTempFilename);
    Finally
    End;
  Except
    fOutput.InternalError;
  End;
end;

procedure TCodeGenerator.DoInternalCode(aScript: String);
begin
  fScript.Add(aScript);
end;

end.
