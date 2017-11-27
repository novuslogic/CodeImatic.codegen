unit ProjectItemLoader;

interface

Uses NovusBO, JvSimpleXml, Project, SysUtils, ProjectItem, NovusFileUtils,
  Loader, Output,  NovusStringUtils,Plugins;

Type
  TProjectItemLoader = class(TLoader)
  protected
  private
    foOutput: tOutput;
    foProject: Tproject;
    foProjectItem: TProjectItem;
    foPlugins: tPlugins;
  public
    constructor Create(aProject: Tproject; aProjectItem: TProjectItem;
      aNode: TJvSimpleXmlElem; aOutput: tOutput; aPlugins: tPlugins);
    destructor Destroy;

    function Load: boolean; override;

    function GetValue(aValue: String): String; override;

    class function LoadProjectItem(aProject: Tproject;
      aProjectItem: TProjectItem; aNode: TJvSimpleXmlElem;
      aOutput: tOutput; aPlugins: tPlugins): boolean;
  end;

implementation

Uses novusSimpleXML, ProjectconfigParser;

constructor TProjectItemLoader.Create(aProject: Tproject;
  aProjectItem: TProjectItem; aNode: TJvSimpleXmlElem; aOutput: tOutput;
     aPlugins: tPlugins);
begin
  RootNode := aNode;

  foOutput := aOutput;

  foPlugins:=  aPlugins;

  foProject := aProject;
  foProjectItem := aProjectItem;
end;

destructor TProjectItemLoader.Destroy;
begin
  //
end;

class function TProjectItemLoader.LoadProjectItem(aProject: Tproject;
  aProjectItem: TProjectItem; aNode: TJvSimpleXmlElem;
  aOutput: tOutput; aPlugins: tPlugins): boolean;
var
  loProjectItemLoader: TProjectItemLoader;
begin


  Try
    loProjectItemLoader := TProjectItemLoader.Create(aProject, aProjectItem,
      aNode, aOutput, aPlugins);

    Result := loProjectItemLoader.Load;
  Finally
    loProjectItemLoader.Free;
  End;
end;


function TProjectItemLoader.Load: boolean;
Var
  FNodeLoader,
  FRootNodeLoader,
  FSrcFileNodeLoader,
  FSrcFltNodeLoader,
  FSrcTmpNodeLoader,
  FTmpFilesNodeLoader,
  FprocessorNodeLoader,
  FFltFilesNodeLoader: tNodeLoader;
  lsName: string;
  lsFullPathname,
  lsprocessor: string;
begin
  Result := True;

  FRootNodeLoader := GetRootNode;

  if FRootNodeLoader.PropertyName = 'FOLDER' then
  begin
    foProjectItem.ItemFolder := GetValue(FrootNodeLoader.PropertyValue);
    foProjectItem.ProjectItemType := pitFolder;
  end
  else if FRootNodeLoader.PropertyName = 'NAME' then
  begin
    foProjectItem.ItemName := GetValue(FRootNodeLoader.PropertyValue);
    foProjectItem.ProjectItemType := pitItem;
  end
  else
  begin
    foOutput.LogError('projectitem.folder or projectitem.name required.');
    Result := False;

    exit;
  end;

  FNodeLoader := GetNode(FRootNodeLoader, 'properties');
  if FNodeLoader.IsExists then
    foProjectItem.propertiesFile := GetValue(FNodeLoader.Value);

  foProjectItem.overrideoutput := false;
  FNodeLoader := GetNode(FRootNodeLoader, 'overrideoutput');
  if FNodeLoader.IsExists then
    foProjectItem.overrideoutput := TNovusStringUtils.IsBoolean(GetValue(FNodeLoader.Value));

  foProjectItem.deleteoutput := false;
  FNodeLoader := GetNode(FRootNodeLoader, 'deleteoutput');
  if FNodeLoader.IsExists then
    foProjectItem.deleteoutput := TNovusStringUtils.StrToBoolean(GetValue(FNodeLoader.Value));

  FNodeLoader := GetNode(FRootNodeLoader, 'output');
  if FNodeLoader.IsExists then
    foProjectItem.OutputFile := GetValue(FNodeLoader.Value)
  else
   begin
    foOutput.LogError(foProjectItem.Name + ': projectitem.output required.');
    Result := False;
  end;

  if FRootNodeLoader.PropertyName = 'NAME' then
    begin
      FNodeLoader := GetNode(FRootNodeLoader, 'template');
      if FNodeLoader.IsExists then
       foProjectItem.TemplateFile := GetValue(FNodeLoader.Value);

      FNodeLoader := GetNode(FRootNodeLoader, 'source');
      if FNodeLoader.IsExists then
       foProjectItem.TemplateFile := GetValue(FNodeLoader.Value);
      if Trim(foProjectItem.TemplateFile) = '' then
         begin
           foOutput.LogError(foProjectItem.Name + ': projectitem.source or projectitem.template required.');
           Result := False;
         end;

      FprocessorNodeLoader := GetNode(FRootNodeLoader, 'processor');
      if FprocessorNodeLoader.IsExists then
        begin
          if (FprocessorNodeLoader.PropertyName = 'NAME') then
            foProjectItem.processor := FNodeLoader.PropertyValue
           else
             foProjectItem.processor := GetValue(FprocessorNodeLoader.Value);
        end;
    end
  else
  if FRootNodeLoader.PropertyName = 'FOLDER' then
    begin
      FSrcFileNodeLoader := GetNode(FRootNodeLoader, 'sourcefiles');
      if FSrcFileNodeLoader.IsExists then
        begin
          if FSrcFileNodeLoader.PropertyName = 'FOLDER' then
            begin
              foProjectItem.oSourceFiles.Folder := TNovusFileUtils.TrailingBackSlash(GetValue(FSrcFileNodeLoader.PropertyValue));
            end
          else
            begin
              foOutput.LogError(foProjectItem.Name + ': projectitem.sourcefiles.folder required.');
              Result := False;
            end;

          // templates
          FSrcTmpNodeLoader := GetNode(FSrcFileNodeLoader, 'templates');
          if FSrcTmpNodeLoader.IsExists then
            begin
              FTmpFilesNodeLoader := GetNode(FSrcTmpNodeLoader, 'file');
              while(FTmpFilesNodeLoader.IsExists <> false)  do
                begin
                  if (FTmpFilesNodeLoader.PropertyName = 'NAME') then
                     begin
                       lsFullPathname :=
                         GetValue(FTmpFilesNodeLoader.PropertyValue);

                       FprocessorNodeLoader := GetNode(FTmpFilesNodeLoader,
                         'processor');

                       if FprocessorNodeLoader.IsExists then
                         begin
                           if (FprocessorNodeLoader.PropertyName = 'NAME') then
                             lsprocessor := FprocessorNodeLoader.PropertyValue
                           else
                             lsprocessor := GetValue(FprocessorNodeLoader.Value);
                         end;

                       foProjectItem.oSourceFiles.oTemplates.AddFile
                         (foProjectItem.oSourceFiles.Folder + lsFullPathname,
                         lsFullPathname,
                         lsprocessor,
                         FprocessorNodeLoader);
                     end
                     else
                     begin
                       foOutput.LogError(foProjectItem.Name + ': projectitem.sourcefiles.templates.file.name required.');
                       Result := False;
                       break;
                     end;

                  FTmpFilesNodeLoader := GetNode(FSrcTmpNodeLoader, 'file', FTmpFilesNodeLoader.IndexPos);
                end;
             end;


          // filters
          FSrcFltNodeLoader := GetNode(FSrcFileNodeLoader, 'filters');
          if FSrcFltNodeLoader.IsExists then
            begin
              FFltFilesNodeLoader := GetNode(FSrcFltNodeLoader, 'file');
              while(FFltFilesNodeLoader.IsExists <> false)  do
                begin
                  if (FFltFilesNodeLoader.PropertyName = 'NAME') then
                     begin
                       lsFullPathname :=
                         GetValue(FFltFilesNodeLoader.PropertyValue);

                       foProjectItem.oSourceFiles.oFilters.AddFile
                         (foProjectItem.oSourceFiles.Folder + lsFullPathname,
                         lsFullPathname);
                     end
                   else
                     begin
                       foOutput.LogError(foProjectItem.Name + ': projectitem.sourcefiles.filters.file.name required.');
                       Result := False;
                       break;
                     end;

                  FFltFilesNodeLoader := GetNode(FSrcFltNodeLoader, 'file', FFltFilesNodeLoader.IndexPos);
                end;
            end;
        end;

    end;
end;

function TProjectItemLoader.GetValue(aValue: String): String;
begin
  Result := tProjectconfigParser.ParseProjectconfig
          (aValue, foProject, foOutput);
end;

end.
