unit ProjectFolder;

interface

uses Output, ProjectItem, Project, Classes, Sysutils, NovusFileUtils;

type
  tProjectFolder = class(tObject)
  private
  protected
    foProject: TProject;
    foOutput: TOutput;
    foProjectItem: tProjectItem;
    procedure GetAllSubFolders(aFolder: String);
  public
    constructor Create(AOutput: TOutput; aProject: TProject;
      aProjectItem: tProjectItem);
    destructor Destroy;

    function Execute: boolean;
  end;

implementation

constructor tProjectFolder.Create(AOutput: TOutput; aProject: TProject;
  aProjectItem: tProjectItem);
begin
  foProject := aProject;

  foOutput := AOutput;

  foProjectItem := aProjectItem;
end;

destructor tProjectFolder.Destroy;
begin
  inherited;
end;

function tProjectFolder.Execute: boolean;
begin
  Result := true;

  try
    if DirectoryExists(foProjectItem.oSourceFiles.Folder) then
    begin
      GetAllSubFolders(foProjectItem.oSourceFiles.Folder);

      Result := True;
    end
    else
    begin
      foOutput.LogError('Cannot find Sourcefolder:' +foProjectItem.ItemFolder );

      Result := False;
    end;

  Except
    Result := False;
  end;

end;

procedure tProjectFolder.GetAllSubFolders(aFolder: String);
var
  Path: String;
  Rec: TSearchRec;

begin
  try
    Path := IncludeTrailingBackslash(aFolder);
    if FindFirst(Path + '*.*', faDirectory, Rec) = 0 then
      try
        repeat
          if (Rec.Name <> '.') and (Rec.Name <> '..') then
          begin
            foProjectItem.oSourceFiles.AddFile(Path + Rec.Name);

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
