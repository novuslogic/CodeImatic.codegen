unit ProjectItemFolder;

interface

uses Output, ProjectItem, Project, Classes, Sysutils, NovusFileUtils, NovusStringUtils;

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

uses Processor, System.IOUtils, Plugin;

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
          loProcessorPlugin := aSourceFile.oProcessorPlugin;

          loProcessor:= TProcessor.Create(foOutput, foProject, foProjectItem, loProcessorPlugin,
            aSourceFile.FullPathname,
            aSourceFile.DestFullPathname,
            aSourceFile.FullPathname );

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
            foOutput.Log('output copy file: ' + aSourceFile.DestFullPathname );

            TFile.Copy(aSourceFile.FullPathname, aSourceFile.DestFullPathname, foProjectItem.overrideoutput);
          end
       else
         begin
           if not DirectoryExists(aSourceFile.DestFullPathname) then
             begin
               foOutput.Log('output create folder: ' + aSourceFile.DestFullPathname);

               CreateDir(aSourceFile.DestFullPathname );
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
            loSourceFile := foProjectItem.oSourceFiles.AddFile(Path + Rec.Name, Rec.Name);

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
