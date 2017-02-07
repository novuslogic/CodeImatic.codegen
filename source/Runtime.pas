{$I Zcodegen.inc}
unit Runtime;

interface

uses
  SysUtils, Classes, NovusTemplate, Config, DBSchema, NovusFileUtils,
  Properties, NovusStringUtils, Snippits,  Plugins,
  CodeGenerator, Output, NovusVersionUtils, Project,
  ProjectConfig;

type
   tRuntime = class
   protected
   private
     foPlugins: TPlugins;
     foProject: tProject;
     foDBSchema: TDBSchema;
     foProperties: tProperties;
     foConnections: tConnections;
     foTemplate: TNovusTemplate;
     foCodeGenerator: tCodeGenerator;
   public
     function RunEnvironment: Integer;

     function GetVersion(aIndex:Integer): string;

     property oProject: TProject
      read foProject
      write foProject;

     property oPlugins: TPlugins
       read foPlugins
       write foPlugins;

     property oConnections: tConnections
         read foConnections
         write foConnections;

     Property oProperties: tProperties
        read foProperties
        write foProperties;

     property oDBSchema: TDBSchema
        read  foDBSchema
        write  foDBSchema;
   end;

Var
  oRuntime: tRuntime;




implementation

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

  foProject.LoadProjectFile(oConfig.ProjectFileName, oConfig.ProjectConfigFileName);

  if foProject.oProjectConfig.IsLoaded then
    Foutput := TOutput.Create(foProject.oProjectConfig.Parseproperties(foProject.OutputPath) + oConfig.OutputFile, foProject.OutputConsole)
  else
    Foutput := TOutput.Create(foProject.OutputPath + oConfig.OutputFile, foProject.OutputConsole);

  Foutput.OpenLog(true);

  if not Foutput.IsFileOpen then
    begin
      foProject.Free;

      WriteLn(Foutput.Filename + ' log file cannot be created.');

      Exit;
    end;

  Foutput.WriteLog('Zcodegen - © Copyright Novuslogic Software 2011 - 2017 All Rights Reserved');
  Foutput.WriteLog('Version: ' + GetVersion(0));

  Foutput.WriteLog('Project: ' + foProject.ProjectFileName);

  Foutput.WriteLog('Project Config: ' + foProject.oProjectConfig.ProjectConfigFileName);

  if Trim(foProject.oProjectConfig.DBSchemaPath) <> '' then
    begin
      if Not FileExists(foProject.oProjectConfig.DBSchemaPath + 'DBSchema.xml') then
        begin
          Foutput.WriteLog('DBSchema.xml path missing: ' +  foProject.oProjectConfig.DBSchemaPath);

          Exit;
        end;


      oConfig.dbschemafilename := foProject.oProjectConfig.DBSchemaPath + 'DBSchema.xml';

      Foutput.WriteLog('DBSchema filename: ' + oConfig.dbschemafilename);
    end;

  if trim(foProject.oProjectConfig.LanguagesPath) <> '' then
    begin
      if Not DirectoryExists(foProject.oProjectConfig.LanguagesPath) then
         begin
           Foutput.WriteLog('Languages path missing: ' +  foProject.oProjectConfig.LanguagesPath);

           Exit;
         end;

      oConfig.LanguagesPath := foProject.oProjectConfig.LanguagesPath;

      Foutput.WriteLog('Languages path: ' + oConfig.LanguagesPath);
    end;


  foPlugins := TPlugins.Create(FOutput);

  foPlugins.LoadPlugins;


  for I := 0 to foProject.oProjectItemList.Count - 1 do
    begin
      loProjectItem := tProjectItem(foProject.oProjectItemList.items[i]);

      Foutput.WriteLog('Project Item: ' + loProjectItem.ItemName);

      Try
        if foProject.oProjectConfig.IsLoaded then
          loProjectItem.templateFile := foProject.oProjectConfig.Parseproperties(loProjectItem.templateFile);

          if TNovusFileUtils.IsValidFolder(loProjectItem.templateFile) then
            loProjectItem.templateFile := TNovusFileUtils.TrailingBackSlash(loProjectItem.templateFile) + loProjectItem.ItemName;
      Except
        Foutput.Writelog('TemplateFile Projectconfig error.');

        Break;
      End;

      if Not FileExists(loProjectItem.templateFile) then
        begin
          Foutput.WriteLog('template ' + loProjectItem.templateFile + ' cannot be found.');

          Continue;
        end;

      Try
        if foProject.oProjectConfig.IsLoaded then
          loProjectItem.OutputFile := foProject.oProjectConfig.Parseproperties(loProjectItem.OutputFile);

          if TNovusFileUtils.IsValidFolder(loProjectItem.OutputFile) then
            loProjectItem.OutputFile := TNovusFileUtils.TrailingBackSlash(loProjectItem.OutputFile) + loProjectItem.ItemName;
      Except
        Foutput.Writelog('OutputFile Projectconfig error.');

        Break;
      End;


     if Not DirectoryExists(TNovusStringUtils.JustPathname(loProjectItem.OutputFile)) then
        begin
          if not foProject.Createoutputdir then
            begin
              Foutput.writelog('output ' + tnovusstringutils.justpathname(loprojectitem.outputfile) + ' ditrectory cannot be found.');

              continue;
            end
          else
             begin
               if Not  CreateDir(TNovusStringUtils.JustPathname(loProjectItem.OutputFile)) then
                 begin
                   Foutput.writelog('output ' + tnovusstringutils.justpathname(loprojectitem.outputfile) + ' ditrectory cannot be created.');

                   continue;
                 end;

             end;
        end;


      if (not loProjectItem.overrideoutput) and FileExists(loProjectItem.OutputFile) then
       begin
         Foutput.WriteLog('output ' + TNovusStringUtils.JustFilename(loProjectItem.OutputFile) + ' exists - Override Output option off.');

         Continue;
       end;

      Try
        if foProject.oProjectConfig.IsLoaded then
          loProjectItem.propertiesFile := foProject.oProjectConfig.Parseproperties(loProjectItem.propertiesFile);
      Except
        Foutput.Writelog('PropertiesFile Projectconfig error.');

        Break;
      End;

      if loProjectItem.propertiesFile <> '' then
        begin
         if Not FileExists(loProjectItem.propertiesFile) then
            begin
              Foutput.WriteLog('properties ' + loProjectItem.propertiesFile + ' cannot be found.');

              Continue;
            end;
        end;

      If (TNovusFileUtils.IsFileInUse(loProjectItem.OutputFile) = false) or
         (TNovusFileUtils.IsFileReadonly(loProjectItem.OutputFile) = false) then
        begin
          foProperties := tProperties.Create;

          foDBSchema := TDBSchema.Create;

          foTemplate := TNovusTemplate.Create;

          foTemplate.StartToken := '<';
          foTemplate.EndToken := '>';
          foTemplate.SecondToken := '%';

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

          Foutput.WriteLog('Template: ' + loProjectItem.TemplateFile);


          Foutput.WriteLog('Output: ' + loProjectItem.OutPutFile);

          Foutput.WriteLog('Build started ' + Foutput.FormatedNow);

          foConnections := tConnections.Create(Foutput, foProject.oProjectConfig);

          foCodeGenerator := tCodeGenerator.Create(foTemplate, Foutput, foProject);

          foCodeGenerator.Execute(loProjectItem.OutPutFile);

          if Not Foutput.Failed then
            begin
              if Not Foutput.Errors then
                Foutput.WriteLog('Build succeeded ' + Foutput.FormatedNow)
              else
                Foutput.WriteLog('Build with errors ' + Foutput.FormatedNow);
            end
          else
            Foutput.WriteLog('Build failed ' + Foutput.FormatedNow);

          foConnections.Free;

          foTemplate.Free;
          foProperties.Free;
          foDBSchema.Free;

          foCodeGenerator.Free;
        end
      else
        Foutput.WriteLog('Output: ' + loProjectItem.OutPutFile + ' is read only or file in use.');
    end;

  foPlugins.UnLoadPlugins;

  foPlugins.Free;

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
