{$I Zcodegen.inc}
unit Runtime;

interface

uses
  SysUtils, Classes, NovusTemplate, Config, DBSchema, NovusFileUtils,
  Properties, NovusStringUtils, Snippits,  Plugins,
  CodeGenerator, Output, NovusVersionUtils, Project, ProjectItem,
  ProjectConfig;

type
   tRuntime = class
   protected
   private
     fsworkingdirectory: string;
     foPlugins: TPlugins;
     foProject: tProject;
    // foDBSchema: TDBSchema;
    // foProperties: tProperties;
    // foConnections: tConnections;
    // foTemplate: TNovusTemplate;
     //foCodeGenerator: tCodeGenerator;
   public
     function RunEnvironment: Integer;

     function GetVersion(aIndex:Integer): string;


     property oProject: TProject
      read foProject
      write foProject;

     property oPlugins: TPlugins
       read foPlugins
       write foPlugins;

//     property oConnections: tConnections
//         read foConnections
//         write foConnections;
//
//     Property oProperties: tProperties
//        read foProperties
//        write foProperties;
//
//     property oDBSchema: TDBSchema
//        read  foDBSchema
//        write  foDBSchema;
   end;

Var
  oRuntime: tRuntime;

implementation

uses ProjectconfigParser;



function tRuntime.RunEnvironment: Integer;
Var
  liIndex, i, x: integer;
  FTemplateTag: TTemplateTag;
  bOK: Boolean;
  lsPropertieVariable: String;
  FOutput: TOutput;
  loProjectItem: tProjectItem;
begin
  foProject := tProject.Create;
  foProject.oProjectConfig.ProjectConfigFileName := oConfig.ProjectConfigFileName;

  fsworkingdirectory := TNovusFileUtils.TrailingBackSlash(ExtractFilePath(oConfig.ProjectConfigFileName));
  if Trim(fsworkingdirectory) = '' then
     fsworkingdirectory := TNovusFileUtils.TrailingBackSlash(TNovusFileUtils.AbsoluteFilePath(oConfig.ProjectConfigFileName));

  if Trim(TNovusStringUtils.JustFilename(oConfig.ProjectConfigFileName)) = trim(oConfig.ProjectConfigFileName) then
      foProject.oProjectConfig.ProjectConfigFileName := fsworkingdirectory + oConfig.ProjectConfigFileName;

  if not foProject.oProjectConfig.LoadProjectConfigFile(foProject.oProjectConfig.ProjectConfigFileName) then
    begin
      if Not FileExists(foProject.oProjectConfig.ProjectConfigFileName) then
        begin
          writeln ('Projectconfig missing: ' +  foProject.oProjectConfig.ProjectConfigFileName);

          foProject.Free;

          Exit;
        end;

      writeln ('Loading errror Projectconfig: ' +  foProject.oProjectConfig.ProjectConfigFileName);

      foProject.Free;

      Exit;
    end;

  Foutput := tOutput.Create('');

  foProject.LoadProjectFile(oConfig.ProjectFileName, oConfig.ProjectConfigFileName, Foutput);

  if foProject.oProjectConfig.IsLoaded then
    Foutput.InitLog(tProjectconfigParser.ParseProjectconfig(foProject.BasePath, foProject) + oConfig.OutputlogFilename, foProject.OutputConsole, oConfig.ConsoleOutputOnly)
  else
    Foutput.InitLog(foProject.BasePath + oConfig.OutputlogFilename, foProject.OutputConsole, oConfig.ConsoleOutputOnly);


  if Not oConfig.ConsoleOutputOnly then
    begin
      Foutput.OpenLog(true);

      if not Foutput.IsFileOpen then
        begin
          foProject.Free;

          WriteLn(Foutput.Filename + ' log file cannot be created.');

          Exit;
        end;
    end;

  FOutput.Log('Zcodegen - © Copyright Novuslogic Software 2011 - 2017 All Rights Reserved');
  FOutput.Log('Version: ' + GetVersion(0));

  FOutput.Log('Project: ' + foProject.ProjectFileName);

  FOutput.Log('Project Config: ' + foProject.oProjectConfig.ProjectConfigFileName);

  if Trim(foProject.oProjectConfig.DBSchemaPath) <> '' then
    begin
      if Not FileExists(foProject.oProjectConfig.DBSchemaPath + 'DBSchema.xml') then
        begin
          FOutput.Log('DBSchema.xml path missing: ' +  foProject.oProjectConfig.DBSchemaPath);

          Exit;
        end;


      oConfig.dbschemafilename := foProject.oProjectConfig.DBSchemaPath + 'DBSchema.xml';

      FOutput.Log('DBSchema filename: ' + oConfig.dbschemafilename);
    end;

  if trim(foProject.oProjectConfig.LanguagesPath) <> '' then
    begin
      if Not DirectoryExists(foProject.oProjectConfig.LanguagesPath) then
         begin
           FOutput.Log('Languages path missing: ' +  foProject.oProjectConfig.LanguagesPath);

           Exit;
         end;

      oConfig.LanguagesPath := foProject.oProjectConfig.LanguagesPath;

      FOutput.Log('Languages path: ' + oConfig.LanguagesPath);
    end;


  foPlugins := TPlugins.Create(FOutput, foProject);

  foPlugins.LoadPlugins;

  foPlugins.BeforeCodeGen;



  for I := 0 to foProject.oProjectItemList.Count - 1 do
    begin
      loProjectItem := tProjectItem(foProject.oProjectItemList.items[i]);

      FOutput.Log('Project Item: ' + loProjectItem.ItemName);

      Try
        if foProject.oProjectConfig.IsLoaded then
          loProjectItem.templateFile := tProjectconfigParser.ParseProjectconfig(loProjectItem.templateFile, foProject);

          if TNovusFileUtils.IsValidFolder(loProjectItem.templateFile) then
            loProjectItem.templateFile := TNovusFileUtils.TrailingBackSlash(loProjectItem.templateFile) + loProjectItem.ItemName;
      Except
        FOutput.Log('TemplateFile Projectconfig error.');

        Break;
      End;

      if Not FileExists(loProjectItem.templateFile) then
        begin
          FOutput.Log('template ' + loProjectItem.templateFile + ' cannot be found.');

          Foutput.Failed := True;

          Continue;
        end;

      Try
        if foProject.oProjectConfig.IsLoaded then
          loProjectItem.OutputFile := tProjectconfigParser.ParseProjectconfig(loProjectItem.OutputFile, foProject);

          if TNovusFileUtils.IsValidFolder(loProjectItem.OutputFile) then
            begin
              //if ExtractFilename(loProjectItem.OutputFile) = '' then
                loProjectItem.OutputFile := TNovusFileUtils.TrailingBackSlash(loProjectItem.OutputFile) + loProjectItem.ItemName;
            end;
      Except
        FOutput.Log('OutputFile Projectconfig error.');

        Break;
      End;


     if Not DirectoryExists(TNovusStringUtils.JustPathname(loProjectItem.OutputFile)) then
        begin
          if not foProject.Createoutputdir then
            begin
              FOutput.Log('output ' + tnovusstringutils.justpathname(loprojectitem.outputfile) + ' directory cannot be found.');

              continue;
            end
          else
             begin
               if Not  CreateDir(TNovusStringUtils.JustPathname(loProjectItem.OutputFile)) then
                 begin
                   FOutput.Log('output ' + tnovusstringutils.justpathname(loprojectitem.outputfile) + ' directory cannot be created.');

                   continue;
                 end;

             end;
        end;


      if (not loProjectItem.overrideoutput) and FileExists(loProjectItem.OutputFile) then
       begin
         FOutput.Log('output ' + TNovusStringUtils.JustFilename(loProjectItem.OutputFile) + ' exists - Override Output option off.');

         Continue;
       end;

      Try
        if foProject.oProjectConfig.IsLoaded then
          loProjectItem.propertiesFile := tProjectconfigParser.ParseProjectconfig(loProjectItem.propertiesFile, foProject);
      Except
        FOutput.Log('PropertiesFile Projectconfig error.');

        Break;
      End;

      if loProjectItem.propertiesFile <> '' then
        begin
         if Not FileExists(loProjectItem.propertiesFile) then
            begin
              FOutput.Log('properties ' + loProjectItem.propertiesFile + ' cannot be found.');

              Continue;
            end;
        end;

      If (TNovusFileUtils.IsFileInUse(loProjectItem.OutputFile) = false) or
         (TNovusFileUtils.IsFileReadonly(loProjectItem.OutputFile) = false) then
        begin
          loProjectItem.Execute;

          (*
          foProperties := tProperties.Create;

          foDBSchema := TDBSchema.Create;

          foTemplate := TNovusTemplate.Create;

          foTemplate.StartToken := '<';
          foTemplate.EndToken := '>';
          foTemplate.SecondToken := '%';
          *)
          (*
          if loProjectItem.PropertiesFile <> '' then
            begin
              foProperties.oProject := foProject;
              foProperties.oOutput :=Foutput;
              foProperties.XMLFileName := loProjectItem.PropertiesFile;
              foProperties.Retrieve;
            end;

          if FileExists(oConfig.dbschemafilename) then
            begin
              foDBSchema.XMLFilename := oConfig.dbschemafilename;
              foDBSchema.Retrieve;
            end;

          foTemplate.TemplateDoc.LoadFromFile(loProjectItem.TemplateFile);

          foTemplate.ParseTemplate;

          FOutput.Log('Template: ' + loProjectItem.TemplateFile);

          FOutput.Log('Output: ' + loProjectItem.OutPutFile);

          FOutput.Log('Build started ' + Foutput.FormatedNow);

          foConnections := tConnections.Create(Foutput, foProject.oProjectConfig);

          foCodeGenerator := tCodeGenerator.Create(foTemplate, Foutput, foProject, loProjectItem);

          foCodeGenerator.Execute(loProjectItem.OutPutFile);

          if Not Foutput.Failed then
            begin
              if Not Foutput.Errors then
                FOutput.Log('Build succeeded ' + Foutput.FormatedNow)
              else
                FOutput.Log('Build with errors ' + Foutput.FormatedNow);
            end
          else
            FOutput.LogError('Build failed ' + Foutput.FormatedNow);
                        (*
          FreeandNil(foConnections);

          FreeandNil(foTemplate);
          FreeandNil(foProperties);
          FreeandNil(foDBSchema);

          FreeandNil(foCodeGenerator);
          *)
        end
      else
        FOutput.Log('Output: ' + loProjectItem.OutPutFile + ' is read only or file in use.');
    end;

  //FreeandNil(foConnections);

  //FreeandNil(foTemplate);
  //FreeandNil(foProperties);
  //FreeandNil(foDBSchema);

  //FreeandNil(foCodeGenerator);

  if Not Foutput.Failed then foPlugins.AfterCodeGen;

  foPlugins.UnLoadPlugins;

  foPlugins.Free;

  if Not oConfig.ConsoleOutputOnly then
    Foutput.CloseLog;

  Foutput.Free;

  foProject.Free;
end;

function tRuntime.GetVersion(aIndex:Integer): string;
begin
  case aIndex of
    0: Result := TNovusVersionUtils.GetFullVersionNumber;
    1: Result := TNovusVersionUtils.GetProductName + ' ' + TNovusVersionUtils.GetFullVersionNumber;
  end;
end;



Initialization
  oRuntime := tRuntime.Create;

finalization
  oRuntime.Free;


end.
