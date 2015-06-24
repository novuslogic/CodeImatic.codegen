unit DMZenCodeGen;

interface

uses
  SysUtils, Classes, NovusTemplate, Config, DBSchema, NovusFileUtils,
  Properties, JScriptEngine, NovusStringUtils, Snippits, dialogs,
  CodeGenerator, MessagesLog, NovusVersionUtils, Project, AppEvnts,
  ProjectConfig;

type
  TDM = class(TDataModule)
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
    procedure ApplicationEventsException(Sender: TObject; E: Exception);
  private
    { Private declarations }
    foProject: tProject;
    foDBSchema: TDBSchema;
    foSnippits : tSnippits;
    foProperties: tProperties;
    foConnections: tConnections;
    foTemplate: TNovusTemplate;
    foCodeGenerator: tCodeGenerator;
  public
    { Public declarations }
    procedure RunCodeGenerator;

    property oProject: TProject
      read foProject
      write foProject;

    property oConnections: tConnections
       read foConnections
       write foConnections;

    Property oProperties: tProperties
      read foProperties
      write foProperties;

    Property oSnippits: tSnippits
      read foSnippits
      write foSnippits;

    property oDBSchema: TDBSchema
      read  foDBSchema
      write  foDBSchema;
  end;

var
  DM: TDM;

implementation

{$R *.dfm}

procedure TDM.ApplicationEventsException(Sender: TObject; E: Exception);
begin
  //Showmessage('yes');
end;

procedure TDM.DataModuleCreate(Sender: TObject);
begin
  RunCodeGenerator;
end;

procedure TDM.DataModuleDestroy(Sender: TObject);
begin
//
end;

procedure TDM.RunCodeGenerator;
Var
  liIndex, i, x: integer;
  FTemplateTag: TTemplateTag;
  bOK: Boolean;
  lsPropertieVariable: String;
  FMesaagesLog: tMessagesLog;
  loProjectItem: tProjectItem;
begin
  foProject := tProject.Create;

  foProject.LoadProjectFile(oConfig.ProjectFileName, oConfig.ProjectConfigFileName);

  if foProject.oProjectConfig.IsLoaded then
    FMesaagesLog := tMessagesLog.Create(foProject.oProjectConfig.Parseproperties(foProject.MessageslogPath) + oConfig.MessageslogFile, foProject.OutputConsole)
  else
    FMesaagesLog := tMessagesLog.Create(foProject.MessageslogPath + oConfig.MessageslogFile, foProject.OutputConsole);

  if not FMesaagesLog.OpenLog(true) then
    begin
      foProject.Free;

      WriteLn(FMesaagesLog.Filename + ' log file cannot be created.');

      Exit;
    end;

  FMesaagesLog.WriteLog('Zcodegen - © Copyright Novuslogic Software 2011 - 2015 All Rights Reserved');
  FMesaagesLog.WriteLog('Version: ' + TNovusVersionUtils.GetFullVersionNumber);

  FMesaagesLog.WriteLog('Project:' + foProject.ProjectFileName);
  if (foProject.oProjectConfig.ProjectConfigFileName <> '') then
    FMesaagesLog.WriteLog('Projectconfig:' + foProject.oProjectConfig.ProjectConfigFileName);


  for I := 0 to foProject.oProjectItemList.Count - 1 do
    begin
      loProjectItem := tProjectItem(foProject.oProjectItemList.items[i]);

      FMesaagesLog.WriteLog('Project Item:' + loProjectItem.ItemName);

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

      Try
        if foProject.oProjectConfig.IsLoaded then
          loProjectItem.SnippitsFile := foProject.oProjectConfig.Parseproperties(loProjectItem.SnippitsFile);
      Except
        FMesaagesLog.Writelog('SnippitsFile Projectconfig error.');

        Break;
      End;

      if loProjectItem.SnippitsFile <> '' then
        begin
          if Not FileExists(loProjectItem.SnippitsFile) then
             begin
               FMesaagesLog.WriteLog('snippits ' + loProjectItem.SnippitsFile + ' cannot be found.');

               Continue;
             end;
        end;

      If Not TNovusFileUtils.IsFileInUse(loProjectItem.OutputFile) then
        begin
          foProperties := tProperties.Create;
          foSnippits := tSnippits.Create;
          foDBSchema := TDBSchema.Create;

          foTemplate := TNovusTemplate.Create;

          foTemplate.StartToken := '<';
          foTemplate.EndToken := '>';
          foTemplate.SecondToken := '%';

          if loProjectItem.PropertiesFile <> '' then
            begin
              foProperties.oProject := foProject;
              foProperties.oMessagesLog :=FMesaagesLog;
              foProperties.XMLFileName := loProjectItem.PropertiesFile;
              foProperties.Retrieve;
            end;

          if loProjectItem.SnippitsFile <> '' then
            begin
              foSnippits.XMLFileName := loProjectItem.SnippitsFile;
              foSnippits.Retrieve;
            end;

          if FileExists(oConfig.dbschemafilename) then
            begin
              foDBSchema.XMLFilename := oConfig.dbschemafilename;
              foDBSchema.Retrieve;
            end;

          foTemplate.TemplateDoc.LoadFromFile(loProjectItem.TemplateFile);

          foTemplate.ParseTemplate;

          FMesaagesLog.WriteLog('Template:' + loProjectItem.TemplateFile);


          FMesaagesLog.WriteLog('Output:' + loProjectItem.OutPutFile);

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
          foSnippits.Free;
          foDBSchema.Free;

          foCodeGenerator.Free;
        end
      else
        FMesaagesLog.WriteLog('Output:' + loProjectItem.OutPutFile + ' is read only or file in use.');
    end;

  FMesaagesLog.CloseLog;

  FMesaagesLog.Free;

  foProject.Free;
end;



end.
