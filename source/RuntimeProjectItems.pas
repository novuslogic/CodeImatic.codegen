unit RuntimeProjectItems;

interface

Uses Output, ProjectItem, NovusFileUtils, Project, ProjectconfigParser,
  SysUtils,
  NovusStringUtils, System.IOUtils;

type
  tRuntimeProjectItems = class
  protected
  private
    foOutput: TOutput;
    foProject: TProject;
  public
    constructor Create(aOutput: TOutput; aProject: TProject);
    destructor Destroy;

    function RunProjectItems: boolean;
  end;

implementation

constructor tRuntimeProjectItems.Create;
begin
  foOutput := aOutput;
  foProject := aProject;
end;

destructor tRuntimeProjectItems.Destroy;
begin

end;

function tRuntimeProjectItems.RunProjectItems: boolean;
Var
  loProjectItem: tProjectItem;
  I: Integer;
begin
  Try
    Result := true;

    for I := 0 to foProject.oProjectItemList.Count - 1 do
    begin
      loProjectItem := tProjectItem(foProject.oProjectItemList.items[I]);

      if loProjectItem.ItemName <> '' then
      begin
        foOutput.Log('Project Item: ' + loProjectItem.Name);

        Try
          if foProject.oProjectConfig.IsLoaded then
            loProjectItem.templateFile :=
              tProjectconfigParser.ParseProjectconfig
              (loProjectItem.templateFile, foProject, foOutput);

          if TNovusFileUtils.IsValidFolder(loProjectItem.templateFile) then
            loProjectItem.templateFile := TNovusFileUtils.TrailingBackSlash
              (loProjectItem.templateFile) + loProjectItem.ItemName;
        Except
          foOutput.Log('TemplateFile Projectconfig error.');

          Break;
        End;

        if Not FileExists(loProjectItem.templateFile) then
        begin
          foOutput.Log('template ' + loProjectItem.templateFile +
            ' cannot be found.');

          foOutput.Failed := true;

          Continue;
        end;
      end
      else
      begin
        loProjectItem.ItemFolder := tProjectconfigParser.ParseProjectconfig
          (loProjectItem.ItemFolder, foProject, foOutput);

        if not TNovusFileUtils.IsValidFolder(loProjectItem.ItemFolder) then
        begin
          foOutput.Log('Folder ' + loProjectItem.ItemFolder +
            ' cannot be found.');

          foOutput.Failed := true;

          Continue;
        end;

        loProjectItem.oSourceFiles.Folder :=
          tProjectconfigParser.ParseProjectconfig
          (loProjectItem.oSourceFiles.Folder, foProject, foOutput);

        if not TNovusFileUtils.IsValidFolder(loProjectItem.oSourceFiles.Folder)
        then
        begin
          foOutput.Log('Sourcefiles.Folder ' + loProjectItem.oSourceFiles.Folder
            + ' cannot be found.');

          foOutput.Failed := true;

          Continue;
        end;
      end;

      Try
        if foProject.oProjectConfig.IsLoaded then
          loProjectItem.OutputFile := tProjectconfigParser.ParseProjectconfig
            (loProjectItem.OutputFile, foProject, foOutput);

        if TNovusFileUtils.IsValidFolder(loProjectItem.OutputFile) then
        begin
          // if ExtractFilename(loProjectItem.OutputFile) = '' then
          loProjectItem.OutputFile := TNovusFileUtils.TrailingBackSlash
            (loProjectItem.OutputFile) + loProjectItem.ItemName;
        end;
      Except
        foOutput.Log('Output Projectconfig error.');

        Break;
      End;

      if Not DirectoryExists(TNovusStringUtils.JustPathname
        (loProjectItem.OutputFile)) then
      begin
        if not foProject.Createoutputdir then
        begin
          foOutput.Log('output ' + TNovusStringUtils.JustPathname
            (loProjectItem.OutputFile) + ' directory cannot be found.');

          Continue;
        end
        else
        begin
          if Not CreateDir(TNovusStringUtils.JustPathname
            (loProjectItem.OutputFile)) then
          begin
            foOutput.Log('output ' + TNovusStringUtils.JustPathname
              (loProjectItem.OutputFile) + ' directory cannot be created.');

            Continue;
          end;

        end;
      end;

      if not loProjectItem.deleteoutput then
      begin
        if (not loProjectItem.overrideoutput) and
          FileExists(loProjectItem.OutputFile) then
        begin
          foOutput.Log('output ' + TNovusStringUtils.JustFilename
            (loProjectItem.OutputFile) +
            ' exists - Override Output option off.');

          Continue;
        end;
      end
      else
      begin
        if FileExists(loProjectItem.OutputFile) then
        begin
          foOutput.Log('output ' + TNovusStringUtils.JustFilename
            (loProjectItem.OutputFile) + ' Deleted.');

          TFile.Delete(loProjectItem.OutputFile);
        end;
      end;

      Try
        if foProject.oProjectConfig.IsLoaded then
          loProjectItem.propertiesFile :=
            tProjectconfigParser.ParseProjectconfig
            (loProjectItem.propertiesFile, foProject, foOutput);
      Except
        foOutput.Log('PropertiesFile Projectconfig error.');

        Break;
      End;

      if loProjectItem.propertiesFile <> '' then
      begin
        if Not FileExists(loProjectItem.propertiesFile) then
        begin
          foOutput.LogError('properties ' + loProjectItem.propertiesFile +
            ' cannot be found.');

          Continue;
        end;
      end;

      If (TNovusFileUtils.IsFileInUse(loProjectItem.OutputFile) = false) or
        (TNovusFileUtils.IsFileReadonly(loProjectItem.OutputFile) = false) then
      begin
        loProjectItem.Execute;
      end
      else
        foOutput.Log('Output: ' + loProjectItem.OutputFile +
          ' is read only or file in use.');
    end;
  Except
    foOutput.InternalError;
    Result := false;
  End;
end;

end.
