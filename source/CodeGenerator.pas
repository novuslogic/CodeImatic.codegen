unit CodeGenerator;

interface

Uses Classes, NovusTemplate, NovusList, ExpressionParser, SysUtils,
  Config, NovusStringUtils, Interpreter, Language, Project,
  Output, Variables, NovusUtilities, CodeGeneratorItem, tagtype,
  NovusBO, NovusFileUtils, Template, PascalScript, System.IOUtils, Plugin,
  {TokenProcessor,} Loader, ProjectItem;

Const
  cDeleteLine = '{%DELETELINE%}';
  cBlankline = '{%BLANKLINE%}';

Type
  TCodeGenerator = class(TObject)
  protected
    FoNodeLoader: tNodeLoader;
    FScript: TStringList;
    foProcessorPlugin: TObject;
    foProject: tProject;
   // foVariables: tVariables;
    foOutput: tOutput;
    FLanguage: tLanguage;
    fsLanguage: String;
    FoInterpreter: tInterpreter;
    foProjectItem: TProjectItem;
    FoTemplate: TTemplate;
    FCodeGeneratorList: TNovusList;
    Folayout: TObject;
    fsRenderBodyTag: string;
    fsInputFilename: string;
    fsSourceFilename: String;
    fsDefaultOutputFilename: String;
  private
    function GetScriptFilename: string;
    function DoInternalCodeBehine(aFilename: string): boolean;
    procedure DoInternalCode(aScript: String;
      aCodeGeneratorItem: TCodeGeneratorItem);
    procedure DoPluginTags;
    procedure DoLanguage;
   // procedure DoConnections;
    function DoPreProcessor: tProcessorItem;
    procedure DoCodeBehine;
    procedure DoCodeTags;
    function DoScriptEngine: boolean;
    function DoPostProcessor(aProcessorItem: tProcessorItem;
      aTemplateFile: String; var aOutputFilename: string): TPluginReturn;
    procedure DoConvert(aProcessorItem: tProcessorItem; aTemplateFile: String;
      var aOutputFilename: string);

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
    constructor Create(aTemplate: TTemplate; AOutput: tOutput;
      aProject: tProject; aProjectItem: TProjectItem; aProcessorPlugin: TObject;
      aInputFilename: string; aSourceFilename: String); //virtual;

    destructor Destroy; override;

    function DoOutputFilename(aTemplateFile: string; aOutputFilename: string;
      aProcesorItem: tProcessorItem): boolean;

    function Pass1: Boolean;

    function IsNonOutputCommandonly(ASourceLineNo: Integer): boolean;

    procedure RunPropertyVariables(AStartPos, AEndPos: Integer);

    function InsertTagValue(aTagValue: String; aTagName: String): boolean;

    function AddTag(ATemplateTag: TTemplateTag): TCodeGeneratorItem;

    procedure RunInterpreter(AStartPos, AEndPos: Integer);

    property Language: String read fsLanguage write fsLanguage;

    property oLanguage: tLanguage read FLanguage write FLanguage;

    property oOutput: tOutput read foOutput write foOutput;

    function Execute(aOutputFilename: String; aDolayout: boolean = false): boolean;

    property oCodeGeneratorList: TNovusList read FCodeGeneratorList
      write FCodeGeneratorList;

    property oTemplate: TTemplate read FoTemplate write FoTemplate;

    property oProject: tProject read foProject write foProject;

    property RenderBodyTag: string read fsRenderBodyTag write fsRenderBodyTag;

    property DefaultOutputFilename: String read fsDefaultOutputFilename
      write fsDefaultOutputFilename;

    property oNodeLoader: tNodeLoader
      read FoNodeLoader write FoNodeLoader;
  end;

implementation

uses runtime, TokenProcessor, TokenParser, ProjectItemLoader, {ProjectItem,} Processor,
  TagParser, Plugins;

constructor TCodeGenerator.Create;
begin
  inherited Create;

  fsDefaultOutputFilename := '';

  foProcessorPlugin := aProcessorPlugin;

  fsInputFilename := aInputFilename;

  foProjectItem := aProjectItem;

  foProject := aProject;

  fsSourceFilename := aSourceFilename;

  foOutput := AOutput;

  FoTemplate := aTemplate;

  FCodeGeneratorList := TNovusList.Create(TCodeGeneratorItem);

  FoInterpreter := tInterpreter.Create(Self, foOutput, foProjectItem);

  FLanguage := tLanguage.Create;

  FScript := TStringList.Create;

  Folayout := NIL;
end;

destructor TCodeGenerator.Destroy;
begin
  if Assigned(Folayout) then
    Folayout.Free;

  //foVariables.Free;

  FLanguage.Free;

  FoInterpreter.Free;

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

function TCodeGenerator.AddTag(ATemplateTag: TTemplateTag): TCodeGeneratorItem;
Var
  lCodeGeneratorItem: TCodeGeneratorItem;
begin
  Result := NIL;

  lCodeGeneratorItem := TCodeGeneratorItem.Create(foProjectItem, Self,
    (*foVariables, *) foProject);

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

    LCodeGeneratorItem1 := TCodeGeneratorItem(FCodeGeneratorList.Items[I]);
   
    if IsInterpreterTagType(LCodeGeneratorItem1.tagtype) then
    begin
      lsTagValue := FoInterpreter.Execute(LCodeGeneratorItem1,  LiSkipPos1);

      LTemplateTag1 := LCodeGeneratorItem1.oTemplateTag;

      LTemplateTag1.TagValue := lsTagValue;
    end;
  end;
end;

function TCodeGenerator.PassTemplateTags(aClearRun: boolean = false): boolean;
Var
  I, fiIndex: Integer;
  FoTemplateTag: TTemplateTag;
  FSourceTemplateTags: TTemplateTags;
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
    foOutput.Errors := true;
    foOutput.Failed := true;

    foOutput.Log('Error Line No:' + IntToStr(FoTemplateTag.SourceLineNo) +
      ' Position: ' + IntToStr(FoTemplateTag.SourcePos));

    Result := false;

    Exit;
  End;
end;

function TCodeGenerator.Pass1: Boolean;
begin
  Result := true;

  Try
    If Not PassTemplateTags then
    begin
      Result := False;

      Exit;
    end;

    DoProperties;

    RunPropertyVariables(0, (FCodeGeneratorList.Count - 1));

    DoIncludes;

    DoCodeBehine;

    DoCodeTags;

    if Trim(FScript.text) <> '' then
      if not DoScriptEngine then
        begin
          Result := False;

          Exit;
        end;
  Except
    foOutput.Internalerror;
    Result := False;
  End;

end;


function TCodeGenerator.Execute;
var
  FoProcesorItem: tProcessorItem;
begin
  Try
    DefaultOutputFilename := aOutputFilename;

    Result := false;

    FoProcesorItem := NIL;

    FoProcesorItem := DoPreProcessor;
     if Assigned(FoProcesorItem) then
       FoProcesorItem.DefaultOutputFilename := DefaultOutputFilename;

    // Pass 1
    if Not Pass1 then Exit;

    // Pass 2
    if DoPreLayout then
      DoPostLayout;

    DoLanguage;

    DoProperties;

    RunPropertyVariables(0, (FCodeGeneratorList.Count - 1));

    RunInterpreter(0, (FCodeGeneratorList.Count - 1));

    DoTrimLines;

    FoTemplate.InsertAllTagValues;

    DoSpecialTags;

    Result := true;
  Except
    foOutput.Log(TNovusUtilities.GetExceptMess);

    foOutput.Failed := true;

    Result := false;

    Exit;
  End;

  Result := DoOutputFilename(fsSourceFilename, aOutputFilename, FoProcesorItem);

  if Result then
  begin
    if Trim(aOutputFilename) <> '' then
      DoConvert(FoProcesorItem, aOutputFilename, aOutputFilename);
  end;
end;

function TCodeGenerator.DoOutputFilename(aTemplateFile: String;
  aOutputFilename: string; aProcesorItem: tProcessorItem): boolean;
var
  fEncoding: TEncoding;
  lsNewOutputFilename: String;
begin
  Result := true;

  if Trim(aOutputFilename) <> '' then
  begin
    if TNovusFileUtils.IsOnlyFolder(aOutputFilename) then
      begin
        if DirectoryExists(aOutputFilename) then
          begin
            lsNewOutputFilename :=  TNovusFileUtils.TrailingBackSlash(aOutputFilename) + foProjectItem.ItemName;

            foOutput.Log('Using Projectitem name for output: [' + lsNewOutputFilename +']');

            aOutputFilename := lsNewOutputFilename;
          end
       else
         begin
           Result := False;

           foOutput.LogError('Output Folder doesn''t exists ['+ TNovusFileUtils.TrailingBackSlash(aOutputFilename)+ ']');


           Exit;
         end;
     end;

{$I-}
    Try
      DoPostProcessor(aProcesorItem, fsSourceFilename, aOutputFilename);

      fEncoding := NIL;

      if TNovusFileUtils.IsTextFile(aTemplateFile, fEncoding) = -1 then
      begin
        Result := false;

        foOutput.LogError('Save Error: ' + aOutputFilename +
          ' - IsTextFile Failed');

        Exit;
      end;

      if not foOutput.Failed then
        if fEncoding = NIL then
          FoTemplate.OutputDoc.SaveToFile(aOutputFilename, TEncoding.Unicode)
        else
          FoTemplate.OutputDoc.SaveToFile(aOutputFilename, fEncoding);

    Except
      Result := false;

      foOutput.LogError('Save Error: ' + aOutputFilename + ' - ' +
        TNovusUtilities.GetExceptMess);
    end;
{$I+}
  end;
end;

function TCodeGenerator.DoPostProcessor(aProcessorItem: tProcessorItem;
  aTemplateFile: String; var aOutputFilename: string):TPluginReturn;
begin
  oRuntime.oPlugins.PostProcessor(aProcessorItem,
    (foProjectItem as TProjectItem), FoTemplate, aTemplateFile, aOutputFilename,
    (foProcessorPlugin as TProcessorPlugin));
end;

procedure TCodeGenerator.DoConvert(aProcessorItem: tProcessorItem;
  aTemplateFile: String; var aOutputFilename: string);
begin
  oRuntime.oPlugins.Convert(aProcessorItem, (foProjectItem as TProjectItem),
    FoTemplate, aTemplateFile, aOutputFilename,
    (foProcessorPlugin as TProcessorPlugin));
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

    if (IsInterpreterTagType(lCodeGeneratorItem.tagtype)) then
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
        lCodeGeneratorItem := TCodeGeneratorItem(FCodeGeneratorList.Items[X]);

        if IsInterpreterTagType(lCodeGeneratorItem.tagtype) then
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
          lCodeGeneratorItem := TCodeGeneratorItem(FCodeGeneratorList.Items[X]);

          if IsInterpreterTagType(lCodeGeneratorItem.tagtype) then
          begin
            LTemplateTag := lCodeGeneratorItem.oTemplateTag;

            if (lCodeGeneratorItem.tagtype = ttInterpreter) then
              begin
               if LTemplateTag.SourceLineNo = I then
                 LTemplateTag.TagValue := cDeleteLine;
              end
            else LTemplateTag.TagValue := cDeleteLine;

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

   for i:= aStrings.count-1 downto 0 do
     begin
       if pos(cDeleteLine, aStrings[i])> 0 then
           aStrings.delete(i)
       else
       if pos(cBlankLine, aStrings[i])> 0 then
           aStrings[i] := '';

      end;

  (*
  try
    loTemplate := TTemplate.CreateTemplate;
    loTemplate.TemplateDoc.text := aStrings.text;
    loTemplate.StartToken := '{';
    loTemplate.EndToken := '}';

    loTemplate.ParseTemplate;

    I := 0;
    While (loTemplate.TemplateTags.Count > I) do
    begin
      LTemplateTag := TTemplateTag(loTemplate.TemplateTags.Items[I]);

      if ((LTemplateTag.RawTagEx = cBlankline) or
        (LTemplateTag.TagValue = cBlankline)) then
      begin
        loTemplate.TemplateDoc.Strings[LTemplateTag.SourceLineNo - 1] := '';

        loTemplate.ParseTemplate;

        Dec(I);
      end
      else if ((LTemplateTag.RawTagEx = cDeleteLine) or
        (LTemplateTag.TagValue = cDeleteLine)) then
      begin
        loTemplate.TemplateDoc.Delete(LTemplateTag.SourceLineNo - 1);

        loTemplate.ParseTemplate;

        Dec(I);
      end;

      Inc(I);
    end;
    loTemplate.InsertAllTagValues;
    aStrings.text := loTemplate.OutputDoc.text;
  finally
    loTemplate.Free;
  end;
  *)
end;

procedure TCodeGenerator.RunPropertyVariables;
Var
  I, X, Y: Integer;
  FoTemplateTag: TTemplateTag;
  lsPropertieVariable: String;
  lsVariableResult: String;
  FCodeGeneratorItem: TCodeGeneratorItem;
  FVariable: TVariable;
  FTagParser : TTagParser;
  fTagType: tTagType;
  liSkipPos: Integer;
  lsTagName: String;
begin
  for I := AStartPos to AEndPos do
  begin
    FCodeGeneratorItem := TCodeGeneratorItem(FCodeGeneratorList.Items[I]);

    FoTemplateTag := FCodeGeneratorItem.oTemplateTag;

    // Default Property value
    if FCodeGeneratorItem.tagtype = ttVariableCmdLine then
    begin
      if FCodeGeneratorItem.oTokens.Count > 1 then
      begin
        FVariable := oConfig.oVariablesCmdLine.GetVariableByName
          (FCodeGeneratorItem.oTokens[1]);
        if Assigned(FVariable) then
          FoTemplateTag.TagValue := FVariable.Value;
      end;
    end
  (*
    else if FCodeGeneratorItem.tagtype = ttConfigProperties then
    begin
      if FCodeGeneratorItem.oTokens.Count > 1 then
        FoTemplateTag.TagValue := foProject.oProjectConfig.Getproperties
          (FCodeGeneratorItem.oTokens[1]);
    end *)
    else if FCodeGeneratorItem.tagtype = ttprojectitem then
    begin
      if FCodeGeneratorItem.oTokens.Count > 1 then
        FoTemplateTag.TagValue := (foProjectItem as TProjectItem)
          .GetProperty(FCodeGeneratorItem.oTokens[1], foProject);
    end
    else if (FCodeGeneratorItem.tagtype = ttProperty) or
      (FCodeGeneratorItem.tagtype = ttPropertyEx) then
    begin
      if (FCodeGeneratorItem.tagtype = ttProperty) then
        begin
          lsTagName := '';
          if FCodeGeneratorItem.tagtype = ttProperty then
            lsTagName := FoTemplateTag.TagName
          else
          if (FCodeGeneratorItem.tagtype = ttPropertyEx) then
            begin
              if FCodeGeneratorItem.oTokens.Count > 1 then
                lsTagName := FCodeGeneratorItem.oTokens[1];
            end;

          liSkipPos := 0;
          fTagType := TTagParser.ParseTagType(foProjectItem, nil, lsTagName, foOutput, false);
          if fTagType = ttInterpreter then
            FoTemplateTag.TagValue := FoInterpreter.Execute(FCodeGeneratorItem, liSkipPos)
          else
           FoTemplateTag.TagValue := (foProjectItem as TProjectItem)
             .oProperties.GetProperty(lsTagName);
        end
        (*
      else if (FCodeGeneratorItem.tagtype = ttPropertyEx) then
      begin
        if FCodeGeneratorItem.oTokens.Count > 1 then
          FoTemplateTag.TagValue := (foProjectItem as TProjectItem)
            .oProperties.GetProperty(FCodeGeneratorItem.oTokens[1])
      end;
      *)
    end;

    for X := 0 to (foProjectItem as TProjectItem)
      .oProperties.NodeNames.Count - 1 do
    begin
      lsPropertieVariable := '$$' + Uppercase((foProjectItem as TProjectItem)
        .oProperties.NodeNames.Strings[X]);

      If Pos(lsPropertieVariable, Uppercase(FoTemplateTag.TagName)) > 0 then
      begin
        lsVariableResult := (foProjectItem as TProjectItem)
          .oProperties.GetProperty((foProjectItem as TProjectItem)
          .oProperties.NodeNames.Strings[X]);

        if FCodeGeneratorItem.tagtype = ttConnection then
        begin
          for Y := 0 to FCodeGeneratorItem.oTokens.Count - 1 do
            If Pos(lsPropertieVariable, Uppercase(FCodeGeneratorItem.oTokens[Y]
              )) > 0 then
              FCodeGeneratorItem.oTokens[Y] := TNovusStringUtils.ReplaceStr
                (FCodeGeneratorItem.oTokens[Y], lsPropertieVariable,
                lsVariableResult, true);

        end
        else if FCodeGeneratorItem.tagtype = ttInterpreter then
        begin
          for Y := 0 to FCodeGeneratorItem.oTokens.Count - 1 do
            If Pos(lsPropertieVariable, Uppercase(FCodeGeneratorItem.oTokens[Y]
              )) > 0 then
              FCodeGeneratorItem.oTokens[Y] := TNovusStringUtils.ReplaceStr
                (FCodeGeneratorItem.oTokens[Y], lsPropertieVariable,
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
  fiIndex: Integer;
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

      fiIndex := 0;
      fsLanguage := tTokenParser.ParseToken(Self, FCodeGeneratorItem.oTokens[2],
        (foProjectItem as TProjectItem), (*foVariables, *) foOutput, NIL, fiIndex,
        foProject);

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
  FIncludeTemplate: TStringList;
  fiIndex: Integer;
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
          FoTemplateTag.RawTag, (foProjectItem as TProjectItem), foProject,
          (*foVariables,*) foOutput);

        case FCodeGeneratorItem.tagtype of
          ttlayout:
            begin;
              if Uppercase(FTokenProcessor.GetNextToken) = 'LAYOUT' then
              begin
                if FTokenProcessor.IsNextTokenEquals then
                begin
                  lsTempIncludeFilename := FTokenProcessor.GetNextToken;
                  if lsTempIncludeFilename = '' then
                    foOutput.LogError('LAYOUT: Filename not found.');

                  lsRenderBodyTag := FTokenProcessor.GetNextToken;
                  if lsRenderBodyTag = '' then
                    foOutput.LogError('LAYOUT: RenderBodyTag not found.')

                end
                else
                  foOutput.LogError('LAYOUT: Equals symbol not found.');

              end
              else
                foOutput.LogError('LAYOUT: Tag not found.');
            end;

          ttInclude:
            begin
              if Uppercase(FTokenProcessor.GetNextToken) = 'INCLUDE' then
              begin
                if FTokenProcessor.IsNextTokenEquals then
                begin
                  lsTempIncludeFilename := FTokenProcessor.GetNextToken;
                  if lsTempIncludeFilename = '' then
                    foOutput.LogError('INCLUDE: Filename not found.');

                end
                else
                  foOutput.LogError('INCLUDE: Equals symbol not found.');
              end;
            end;

        end;
      Finally
        if lsTempIncludeFilename <> '' then
          lsIncludeFilename := TNovusFileUtils.TrailingBackSlash
            (foProject.oProjectConfigLoader.TemplatePath) + lsTempIncludeFilename;

        if Assigned(FTokenProcessor) then
          FTokenProcessor.Free;
      End;

      if FileExists(lsIncludeFilename) then
      begin
        if FCodeGeneratorItem.tagtype = TTagType.ttInclude then
        begin
          LineNo := FoTemplateTag.SourceLineNo - 1;

          Try
            FIncludeTemplate := TStringList.Create;

            FIncludeTemplate.LoadFromFile(lsIncludeFilename);

            // Pre Processor
            // oRuntime.oPlugins.PreProcessor(lsIncludeFilename, FIncludeTemplate);

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
          Folayout := TProcessor.Create(foOutput, foProject,
            (foProjectItem as TProjectItem), '', '', '', lsIncludeFilename,
            (oProject.oPlugins as tPlugins));

          (Folayout as TProcessor).InputFilename := lsIncludeFilename;
          (Folayout as TProcessor).OutputFilename := '';
          (Folayout as TProcessor).oCodeGenerator.RenderBodyTag :=
            lsRenderBodyTag;

          Result := (Folayout as TProcessor).Execute(true);

        end;
      end
      else
      begin
        Result := false;

        if FCodeGeneratorItem.tagtype = TTagType.ttInclude then
          foOutput.Log('Cannot find include file=' + lsIncludeFilename)
        else if FCodeGeneratorItem.tagtype = TTagType.ttlayout then
          foOutput.Log('Cannot find layout file=' + lsIncludeFilename);

        foOutput.Errors := true;
        foOutput.Failed := true;

        foOutput.Log('Error Line No:' + IntToStr(FoTemplateTag.SourceLineNo) +
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

function TCodeGenerator.DoPreProcessor: tProcessorItem;
begin
  Result := NIL;
  if fsInputFilename = '' then
    Exit;

  Result := oRuntime.oPlugins.PreProcessor(foProjectItem,
    fsInputFilename, FoTemplate,
    (foProcessorPlugin as TProcessorPlugin),
    foNodeLoader,
    Self);
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
      FCodeGeneratorItem := TCodeGeneratorItem(FCodeGeneratorList.Items[I]);

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
        FTokenProcessor := tTokenParser.ParseSimpleToken(FoTemplateTag.RawTag,
          foOutput);

        if Uppercase(FTokenProcessor.GetNextToken) = 'CODE' then
        begin
          if FTokenProcessor.IsNextTokenEquals then
          begin
            lsScript := FTokenProcessor.GetNextToken;
            if Trim(lsScript) = '' then
              foOutput.LogError('CODE: Empty script.')
            else
            begin
              DoInternalCode(lsScript, FCodeGeneratorItem);

            end;
          end
          else
            foOutput.LogError('CODE: Equals symbol not found.');
        end;

      Finally
        FTokenProcessor.Free;
      End;

    end;
  end;
end;

function TCodeGenerator.DoScriptEngine: boolean;
begin

  if (Pos('UNIT', Uppercase(FScript.Strings[0])) = 0) and
    (Pos('BEGIN', Uppercase(FScript.Strings[0])) = 0) then
    FScript.Insert(0, 'begin');

  if Pos('END.', Uppercase(FScript.text)) = 0 then
    FScript.Add('end.');

 

  Result := oRuntime.oScriptEngine.ExecuteScript(FScript.text);

end;

function TCodeGenerator.GetScriptFilename: string;
begin
  Result := TNovusStringUtils.JustPathname(fsSourceFilename) + '_' +
    TPath.GetFileNameWithoutExtension(fsSourceFilename) + '.pas';
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
          FoTemplateTag.RawTag, (foProjectItem as TProjectItem), foProject,
          (*foVariables,*) foOutput);

        if Uppercase(FTokenProcessor.GetNextToken) = 'CODEBEHINE' then
        begin
          if FTokenProcessor.IsNextTokenEquals then
          begin
            lsFilename := FTokenProcessor.GetNextToken;
            if lsFilename = '' then
              foOutput.LogError('CODEBEHINE: Filename not found.')
            else
            begin
              DoInternalCodeBehine(lsFilename);

            end;
          end
          else
            foOutput.LogError('CODEBEHINE: Equals symbol not found.');
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
  lsTagName: string;
  fVariable: tVariable;
begin
  for I := 0 to FCodeGeneratorList.Count - 1 do
  begin
    FCodeGeneratorItem := TCodeGeneratorItem(FCodeGeneratorList.Items[I]);

    lsTagName := '';

    case FCodeGeneratorItem.tagtype of
      ttProperty:
        begin
          FoTemplateTag := FCodeGeneratorItem.oTemplateTag;
          lsTagName := FoTemplateTag.TagName;

          FoTemplateTag.TagValue := (foProjectItem as TProjectItem)
            .oProperties.GetProperty(lsTagName);

        end;
      ttPropertyEx:
        begin
          FoTemplateTag := FCodeGeneratorItem.oTemplateTag;

          if FCodeGeneratorItem.oTokens.Count > 1 then
            begin
              lsTagName := FCodeGeneratorItem.oTokens[1];

              FoTemplateTag.TagValue := (foProjectItem as TProjectItem)
               .oProperties.GetProperty(lsTagName);
            end;
        end;
      ttConfigProperties:
        begin
          FoTemplateTag := FCodeGeneratorItem.oTemplateTag;

          if FCodeGeneratorItem.oTokens.Count > 1 then
            begin
              if Assigned(foProject) then
                begin
                  lsTagName := FCodeGeneratorItem.oTokens[1];

                  FoTemplateTag.TagValue := foProject.oProjectConfigLoader.Getproperties(lsTagName);
                end;
            end;
        end;




//      lsTagName


//      FoTemplateTag.TagValue
    end;
  end;
end;

procedure TCodeGenerator.DoPluginTags;
Var
  liIndex, I: Integer;
  FoTemplateTag: TTemplateTag;
  FCodeGeneratorItem: TCodeGeneratorItem;
  lsTagValue, lsToken: String;
  lsToken1, lsToken2: String;
begin
  for I := 0 to FCodeGeneratorList.Count - 1 do
  begin
    FCodeGeneratorItem := TCodeGeneratorItem(FCodeGeneratorList.Items[I]);

    if (FCodeGeneratorItem.tagtype = ttPluginTag) then
    begin
      FoTemplateTag := FCodeGeneratorItem.oTemplateTag;

      if FCodeGeneratorItem.oTokens.Count > 1 then
      begin
        FCodeGeneratorItem.TokenIndex := 0;

        lsToken1 := FCodeGeneratorItem.GetNextToken;
        lsToken2 := FCodeGeneratorItem.GetNextToken;

        if oRuntime.oPlugins.IsTagExists(lsToken1, lsToken2) then
        begin
          FoTemplateTag.TagValue := oRuntime.oPlugins.GetTag(lsToken1, lsToken2,
            FCodeGeneratorItem.oTokens, (*FCodeGeneratorItem.TokenIndex - 1,*) TProjectItem(foProjectItem));
        end;
      end
      else
        FoTemplateTag.TagValue := '';
    end;
  end;
end;

(*
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

      (foProjectItem as TProjectItem).oConnections.AddConnection
        (FCodeGeneratorItem);
    end;
  end;
end;
*)

function TCodeGenerator.DoPostLayout;
Var
  loLayoutTemplate: TTemplate;
  LIndex: Integer;
  lsRenderBodyTag: string;
  I: Integer;
  lCodeGeneratorItem: TCodeGeneratorItem;
  LTemplateTag: TTemplateTag;
begin
  If Assigned(Folayout) then
  begin
    Try
      loLayoutTemplate := TTemplate.CreateTemplate(true);

      loLayoutTemplate.TemplateDoc.AddStrings((Folayout as TProcessor)
        .oCodeGenerator.oTemplate.OutputDoc);

      loLayoutTemplate.ParseTemplate;

      lsRenderBodyTag := Uppercase((Folayout as TProcessor)
        .oCodeGenerator.RenderBodyTag);

      LIndex := loLayoutTemplate.FindTagNameIndexOf(lsRenderBodyTag);
      if LIndex <> -1 then
      begin
        LIndex := loLayoutTemplate.FindTagNameIndexOf(lsRenderBodyTag);
        if LIndex <> -1 then
        begin
          LTemplateTag :=
            TTemplateTag(loLayoutTemplate.TemplateTags.Items[LIndex]);
          LTemplateTag.TagValue := FoTemplate.TemplateDoc.text;
        end;

        loLayoutTemplate.InsertAllTagValues;
        FoTemplate.TemplateDoc.text := loLayoutTemplate.OutputDoc.text;

        if Not PassTemplateTags(true) then
          Result := false;

        for I := 0 to FCodeGeneratorList.Count - 1 do
        begin
          lCodeGeneratorItem := TCodeGeneratorItem(FCodeGeneratorList.Items[I]);

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
  Result := false;

  lsTempFilename := LocalWorkingdirectory + aFilename;

  if Not FileExists(lsTempFilename) then
  begin
    foOutput.LogError('CODEBEHINE: Filename not found [' +
      lsTempFilename + ']');

    Exit;
  end;

  Try
    Try
      FScript.LoadFromFile(lsTempFilename);
    Finally
    End;
  Except
    foOutput.InternalError;
  End;
end;

procedure TCodeGenerator.DoInternalCode(aScript: String;
  aCodeGeneratorItem: TCodeGeneratorItem);
Var
  lsScript: String;
begin
  lsScript := aScript;

  FScript.Add(lsScript);
end;

end.
