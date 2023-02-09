unit ProjectItemFolder;

interface

uses Output, ProjectItem, Project, Classes, Sysutils, NovusFileUtils, NovusStringUtils,
     System.IOUtils;

type
  tProjectItemFolder = class(tObject)
  private
  protected
    foProject: TProject;
    foOutput: TOutput;
    foProjectItem: tProjectItem;
    procedure GetAllSubFolders(aFolder: String);
    function DoProcessor(aSourceFile: tSourceFile) : boolean;
  public
    constructor Create(AOutput: TOutput; aProject: TProject;
      aProjectItem: tProjectItem);
    destructor Destroy;

    function Execute: boolean;
  end;

implementation

uses Processor, Plugin, Plugins;

constructor tProjectItemFolder.Create(AOutput: TOutput; aProject: TProject;
  aProjectItem: tProjectItem);
begin
  foProject := aProject;

  foOutput := AOutput;

  foProjectItem := aProjectItem;
end;

destructor tProjectItemFolder.Destroy;
begin
  inherited;
end;

function tProjectItemFolder.Execute: boolean;
begin
  Result := true;

  try
    if foProjectItem.deleteoutput then
     begin
       if DirectoryExists(foProjectItem.OutputFile) then
         begin
           FoOutput.Log('output folder ' + foProjectItem.OutputFile + ' Deleted.');
           Try
             TDirectory.Delete(foProjectItem.OutputFile, true);
           Except
             fooutput.LogError('Failed remove output folder' + foProjectItem.OutputFile);

             result := false;

             Exit;
           end;

         end;
     end;

    if DirectoryExists(foProjectItem.oSourceFiles.Folder) then
    begin
      foOutput.Log('Adding Sourcefolder:' +foProjectItem.ItemFolder );

      GetAllSubFolders(foProjectItem.oSourceFiles.Folder);

      Result := True;
    end
    else
    begin
      foOutput.LogError('Cannot find Sourcefolder:' +foProjectItem.oSourceFiles.Folder );

      Result := False;
    end;

  Except
    Result := False;
  end;

end;

function tProjectItemFolder.DoProcessor(aSourceFile: tSourceFile) : boolean;
Var
  loProcessor: TProcessor;
  loProcessorplugin: TProcessorPlugin;
begin
  Try
    result := true;

    if aSourceFile.IsFiltered then
      begin
        foOutput.Log(aSourceFile.FullPathname + ' - Filtered' );

        Exit;
      end;

    if aSourceFile.IsTemplateFile then
      begin
        Try
          if not DirectoryExists
            (Sysutils.ExtractFilePath(aSourceFile.DestFullPathname)) then
          begin
            foOutput.Log('create folder: ' + Sysutils.ExtractFilePath
              (aSourceFile.DestFullPathname));

            Try
              TDirectory.CreateDirectory
                (Sysutils.ExtractFilePath(aSourceFile.DestFullPathname));
            Except
              foOutput.LogError('failed creating folder: ' +
                Sysutils.ExtractFilePath(aSourceFile.DestFullPathname));

              Result := false;

              Exit;
            end;
          end;


          foOutput.Log('process template file: ' + aSourceFile.DestFullPathname );

          loProcessor:= TProcessor.Create(foOutput, foProject, foProjectItem, aSourceFile.Processor,
            aSourceFile.FullPathname,
            aSourceFile.DestFullPathname,
            aSourceFile.FullPathname,
            (foProject.oPlugins as tPlugins),
            aSourceFile.oNodeLoader);

          result := loProcessor.Execute;

        Finally
          loProcessor.Free;
        End;
      end
    else
     begin
       if not aSourceFile.IsFolder then
         begin
           if (not foProjectItem.overrideoutput) and
                FileExists(aSourceFile.DestFullPathname) then
              begin
                FoOutput.Log('output ' + TNovusStringUtils.JustFilename
                  (aSourceFile.DestFullPathname) + ' exists - Override Output option off.');

                Exit;
              end;

            if not DirectoryExists(SysUtils.ExtractFilePath(aSourceFile.DestFullPathname)) then
              begin
                foOutput.Log('create folder: ' + SysUtils.ExtractFilePath(aSourceFile.DestFullPathname));

               Try
                 TDirectory.CreateDirectory(SysUtils.ExtractFilePath(aSourceFile.DestFullPathname) );
               Except
                 foOutput.LogError('failed creating folder: ' + SysUtils.ExtractFilePath(aSourceFile.DestFullPathname));

                 Result := False;

                 Exit;
               end;
             end;

            foOutput.Log('copy file: ' + aSourceFile.DestFullPathname );

            TFile.Copy(aSourceFile.FullPathname, aSourceFile.DestFullPathname, foProjectItem.overrideoutput);
          end
       else
         begin
           if not DirectoryExists(aSourceFile.DestFullPathname) then
             begin
               foOutput.Log('create folder: ' + aSourceFile.DestFullPathname);

               Try
                 TDirectory.CreateDirectory(aSourceFile.DestFullPathname );
               Except
                  foOutput.LogError('failed creating folder: ' + aSourceFile.DestFullPathname);

                  Result := False;

                  Exit;
                end;
             end;

         end;

      end;
  Except
    foOutput.InternalError;

    Result := False;

  End;


end;

procedure tProjectItemFolder.GetAllSubFolders(aFolder: String);
var
  Path: String;
  Rec: TSearchRec;
  loSourceFile: tSourceFile;
begin
  try
    Path := IncludeTrailingBackslash(aFolder);
    if FindFirst(Path + '*.*', faDirectory, Rec) = 0 then
      try
        repeat
          if (Rec.Name <> '.') and (Rec.Name <> '..') then
          begin
            loSourceFile := foProjectItem.oSourceFiles.AddFile(Path + Rec.Name, Rec.Name, ((Rec.Attr AND faDirectory) = faDirectory));

            if Not DoProcessor(loSourceFile) then ;

            GetAllSubFolders(Path + Rec.Name);
          end;
        until FindNext(Rec) <> 0;
      finally
        FindClose(Rec);
      end;
  except
    foOutput.InternalError;
  end;
end;

end.
