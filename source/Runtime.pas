{$I Zcodegen.inc}
unit Runtime;

interface

uses
  SysUtils, Classes, NovusTemplate, Config, DBSchema, NovusFileUtils,
  Properties, NovusStringUtils, Snippits, dialogs,
  CodeGenerator, Output, NovusVersionUtils, Project, AppEvnts,
  ProjectConfig;

type
   tRuntime = class
   protected
   private
     foProject: tProject;
     foDBSchema: TDBSchema;
     foProperties: tProperties;
     foConnections: tConnections;
     foTemplate: TNovusTemplate;
     foCodeGenerator: tCodeGenerator;
   public
     function RunEnvironment: Boolean;

     property oProject: TProject
      read foProject
      write foProject;

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

function tRuntime.RunEnvironment: Boolean;
Var
  liIndex, i, x: integer;
  FTemplateTag: TTemplateTag;
  bOK: Boolean;
  lsPropertieVariable: String;
  FMesaagesLog: TOutput;
  loProjectItem: tProjectItem;
begin
  foProject := tProject.Create;

  foProject.oProjectConfig.ProjectConfigFileName := oConfig.ProjectConfigFileName;

  if Not FileExists(foProject.oProjectConfig.ProjectConfigFileName) then
    begin
      writeln ('Projectconfig missing: ' +  foProject.oProjectConfig.ProjectConfigFileName);

      Exit;
    end;

  if not foProject.oProjectConfig.LoadProjectConfigFile(foProject.oProjectConfig.ProjectConfigFileName) then
    begin
      writeln ('Loading errror Projectconfig: ' +  foProject.oProjectConfig.ProjectConfigFileName);

      Exit;
    end;

  foProject.LoadProjectFile(oConfig.ProjectFileName, oConfig.ProjectConfigFileName);

  if foProject.oProjectConfig.IsLoaded then
    FMesaagesLog := TOutput.Create(foProject.oProjectConfig.Parseproperties(foProject.OutputPath) + oConfig.OutputFile, foProject.OutputConsole)
  else
    FMesaagesLog := TOutput.Create(foProject.OutputPath + oConfig.OutputFile, foProject.OutputConsole);

  FMesaagesLog.OpenLog(true);

  if not FMesaagesLog.IsFileOpen then
    begin
      foProject.Free;

      WriteLn(FMesaagesLog.Filename + ' log file cannot be created.');

      Exit;
    end;

  FMesaagesLog.WriteLog('Zcodegen - © Copyright Novuslogic Software 2011 - 2016 All Rights Reserved');
  FMesaagesLog.WriteLog('Version: ' + TNovusVersionUtils.GetFullVersionNumber);

  FMesaagesLog.WriteLog('Project: ' + foProject.ProjectFileName);

  FMesaagesLog.WriteLog('Projectconfig: ' + foProject.oProjectConfig.ProjectConfigFileName);

  if Not FileExists(foProject.oProjectConfig.DBSchemaPath + 'DBSchema.xml') then
    begin
      FMesaagesLog.WriteLog('DBSchema.xml path missing: ' +  foProject.oProjectConfig.DBSchemaPath);

      Exit;
    end;

  oConfig.dbschemafilename := foProject.oProjectConfig.DBSchemaPath + 'DBSchema.xml';

  FMesaagesLog.WriteLog('DBSchema filename: ' + oConfig.dbschemafilename);

  if Not DirectoryExists(foProject.oProjectConfig.LanguagesPath) then
     begin
       FMesaagesLog.WriteLog('Languages path missing: ' +  foProject.oProjectConfig.LanguagesPath);

       Exit;
     end;

  oConfig.LanguagesPath := foProject.oProjectConfig.LanguagesPath;

  FMesaagesLog.WriteLog('Languages path: ' + oConfig.LanguagesPath);

  for I := 0 to foProject.oProjectItemList.Count - 1 do
    begin
      loProjectItem := tProjectItem(foProject.oProjectItemList.items[i]);

      FMesaagesLog.WriteLog('Project Item: ' + loProjectItem.ItemName);

      Try
        if foProject.oProjectConfig.IsLoaded then
          loProjectItem.templateFile := foProject.oProjectConfig.Parseproperties(loProjectItem.templateFile);
      Except
        FMesaagesLog.Writelog('TemplateFile Projectconfig error.');

        Break;
      End;

      if Not FileExists(loProjectItem.templateFile) then
        begin
          FMesaagesLog.WriteLog('template ' + loProjectItem.templateFile + ' cannot be found.');

          Continue;
        end;

      Try
        if foProject.oProjectConfig.IsLoaded then
          loProjectItem.OutputFile := foProject.oProjectConfig.Parseproperties(loProjectItem.OutputFile);
      Except
        FMesaagesLog.Writelog('OutputFile Projectconfig error.');

        Break;
      End;


     if Not DirectoryExists(TNovusStringUtils.JustPathname(loProjectItem.OutputFile)) then
        begin
          if not foProject.Createoutputdir then
            begin
              fmesaageslog.writelog('output ' + tnovusstringutils.justpathname(loprojectitem.outputfile) + ' ditrectory cannot be found.');

              continue;
            end
          else
             begin
               if Not  CreateDir(TNovusStringUtils.JustPathname(loProjectItem.OutputFile)) then
                 begin
                   fmesaageslog.writelog('output ' + tnovusstringutils.justpathname(loprojectitem.outputfile) + ' ditrectory cannot be created.');

                   continue;
                 end;

             end;
        end;


      if (not loProjectItem.overrideoutput) and FileExists(loProjectItem.OutputFile) then
       begin
         FMesaagesLog.WriteLog('output ' + TNovusStringUtils.JustFilename(loProjectItem.OutputFile) + ' exists - Override Output option off.');

         Continue;
       end;

      Try
        if foProject.oProjectConfig.IsLoaded then
          loProjectItem.propertiesFile := foProject.oProjectConfig.Parseproperties(loProjectItem.propertiesFile);
      Except
        FMesaagesLog.Writelog('PropertiesFile Projectconfig error.');

        Break;
      End;

      if loProjectItem.propertiesFile <> '' then
        begin
         if Not FileExists(loProjectItem.propertiesFile) then
            begin
              FMesaagesLog.WriteLog('properties ' + loProjectItem.propertiesFile + ' cannot be found.');

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
              foProperties.oOutput :=FMesaagesLog;
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

          FMesaagesLog.WriteLog('Template: ' + loProjectItem.TemplateFile);


          FMesaagesLog.WriteLog('Output: ' + loProjectItem.OutPutFile);

          FMesaagesLog.WriteLog('Build started ' + FMesaagesLog.FormatedNow);

          foConnections := tConnections.Create(FMesaagesLog, foProject.oProjectConfig);

          foCodeGenerator := tCodeGenerator.Create(foTemplate, FMesaagesLog, foProject);

          foCodeGenerator.Execute(loProjectItem.OutPutFile);

          if Not FMesaagesLog.Failed then
            begin
              if Not FMesaagesLog.Errors then
                FMesaagesLog.WriteLog('Build succeeded ' + FMesaagesLog.FormatedNow)
              else
                FMesaagesLog.WriteLog('Build with errors ' + FMesaagesLog.FormatedNow);
            end
          else
            FMesaagesLog.WriteLog('Build failed ' + FMesaagesLog.FormatedNow);

          foConnections.Free;

          foTemplate.Free;
          foProperties.Free;
          foDBSchema.Free;

          foCodeGenerator.Free;
        end
      else
        FMesaagesLog.WriteLog('Output: ' + loProjectItem.OutPutFile + ' is read only or file in use.');
    end;

  FMesaagesLog.CloseLog;

  FMesaagesLog.Free;

  foProject.Free;
end;


Initialization
  oRuntime := tRuntime.Create;

finalization
  oRuntime.Free;


end.
