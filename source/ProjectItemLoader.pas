unit ProjectItemLoader;

interface

Uses NovusBO, JvSimpleXml, Project, SysUtils, ProjectItem, NovusFileUtils,
  Loader, Output,  NovusStringUtils,
  variants;

Type
  TProjectItemLoader = class(TLoader)
  protected
  private
    foOutput: tOutput;
    foProject: Tproject;
    foProjectItem: TProjectItem;
  public
    constructor Create(aProject: Tproject; aProjectItem: TProjectItem;
      aNode: TJvSimpleXmlElem; aOutput: tOutput);
    destructor Destroy;

    function Load: boolean; override;

    {
    class function LoadProjectItemName(aProject: Tproject; aItemName: String;
      aProjectItem: TProjectItem): boolean;
    }

    class function LoadProjectItem(aProject: Tproject;
      aProjectItem: TProjectItem; aNode: TJvSimpleXmlElem;
      aOutput: tOutput): boolean;
  end;

implementation

Uses novusSimpleXML;

constructor TProjectItemLoader.Create(aProject: Tproject;
  aProjectItem: TProjectItem; aNode: TJvSimpleXmlElem; aOutput: tOutput);
begin
  RootNode := aNode;

  foOutput := aOutput;

  foProject := aProject;
  foProjectItem := aProjectItem;
end;

destructor TProjectItemLoader.Destroy;
begin
  //
end;

class function TProjectItemLoader.LoadProjectItem(aProject: Tproject;
  aProjectItem: TProjectItem; aNode: TJvSimpleXmlElem;
  aOutput: tOutput): boolean;
var
  loProjectItemLoader: TProjectItemLoader;
begin


  Try
    loProjectItemLoader := TProjectItemLoader.Create(aProject, aProjectItem,
      aNode, aOutput);

    Result := loProjectItemLoader.Load;
  Finally
    loProjectItemLoader.Free;
  End;
end;

{
class function TProjectItemLoader.LoadProjectItemName(aProject: Tproject;
  aItemName: String; aProjectItem: TProjectItem): boolean;
Var
  fJvSimpleXmlElem: TJvSimpleXmlElem;
  Index: Integer;
  FNode: TJvSimpleXmlElem;
begin
  Result := False;

  Try
    fJvSimpleXmlElem := TnovusSimpleXML.FindNodeByValue
      (aProject.oXMLDocument.Root, 'projectitem', 'name', aItemName);

    If Assigned(fJvSimpleXmlElem) then
    begin
    //  aProjectItem.XmlElem := fJvSimpleXmlElem;

      Index := 0;
      if Assigned(TnovusSimpleXML.FindNode(fJvSimpleXmlElem, 'template', Index))
      then
      begin
        Index := 0;
        aProjectItem.TemplateFile := TnovusSimpleXML.FindNode(fJvSimpleXmlElem,
          'template', Index).Value;

      end;

      Index := 0;
      if Assigned(TnovusSimpleXML.FindNode(fJvSimpleXmlElem, 'source', Index))
      then
      begin
        Index := 0;
        aProjectItem.TemplateFile := TnovusSimpleXML.FindNode(fJvSimpleXmlElem,
          'source', Index).Value;
      end;

      Index := 0;
      if Assigned(TnovusSimpleXML.FindNode(fJvSimpleXmlElem, 'properties',
        Index)) then
      begin
        Index := 0;
        aProjectItem.propertiesFile := TnovusSimpleXML.FindNode
          (fJvSimpleXmlElem, 'properties', Index).Value;
      end;

      Index := 0;
      if Assigned(TnovusSimpleXML.FindNode(fJvSimpleXmlElem, 'postprocessor',
        Index)) then
      begin
        Index := 0;
        aProjectItem.postprocessor :=
          Uppercase(TnovusSimpleXML.FindNode(fJvSimpleXmlElem, 'postprocessor',
          Index).Value);
      end;

      Index := 0;
      if Assigned(TnovusSimpleXML.FindNode(fJvSimpleXmlElem, 'overrideoutput',
        Index)) then
      begin
        Index := 0;
        if Uppercase(TnovusSimpleXML.FindNode(fJvSimpleXmlElem,
          'overrideoutput', Index).Value) = 'TRUE' then
          aProjectItem.overrideoutput := True
        else
          aProjectItem.overrideoutput := False;
      end
      else
        aProjectItem.overrideoutput := False;

      Index := 0;
      if Assigned(TnovusSimpleXML.FindNode(fJvSimpleXmlElem, 'output', Index))
      then
      begin
        Index := 0;
        aProjectItem.OutputFile := TnovusSimpleXML.FindNode(fJvSimpleXmlElem,
          'output', Index).Value;
      end;
    end;
  Finally
    Result := True;
  end;
end;
}
function TProjectItemLoader.Load: boolean;
Var
  FNodeLoader,
  FRootNodeLoader,
  FSrcFileNodeLoader,
  FSrcFltNodeLoader,
  FSrcTmpNodeLoader,
  FTmpFilesNodeLoader,
  FFltFilesNodeLoader: tNodeLoader;
  lsName: string;
  lsFullPathname,
  lspostprocessor: string;
begin
  Result := True;

  FRootNodeLoader := GetRootNode;

  if FRootNodeLoader.PropertyName = 'FOLDER' then
  begin
    foProjectItem.ItemFolder := FrootNodeLoader.PropertyValue
  end
  else if FRootNodeLoader.PropertyName = 'NAME' then
  begin
    foProjectItem.ItemName := FRootNodeLoader.PropertyValue
  end
  else
  begin
    foOutput.LogError('projectitem.folder or projectitem.name required.');
    Result := False;

    exit;
  end;

  FNodeLoader := GetNode(FRootNodeLoader, 'properties');
  if FNodeLoader.IsExists then
    foProjectItem.propertiesFile := FNodeLoader.Value;

  foProjectItem.overrideoutput := false;
  FNodeLoader := GetNode(FRootNodeLoader, 'overrideoutput');
  if FNodeLoader.IsExists then
    foProjectItem.overrideoutput := TNovusStringUtils.IsBoolean(FNodeLoader.Value);

  FNodeLoader := GetNode(FRootNodeLoader, 'output');
  if FNodeLoader.IsExists then
   foProjectItem.OutputFile := FNodeLoader.Value
  else
   begin
    foOutput.LogError(foProjectItem.Name + ': projectitem.output required.');
    Result := False;
  end;

  if FRootNodeLoader.PropertyName = 'NAME' then
    begin
      FNodeLoader := GetNode(FRootNodeLoader, 'template');
      if FNodeLoader.IsExists then
       foProjectItem.TemplateFile := FNodeLoader.Value;

      FNodeLoader := GetNode(FRootNodeLoader, 'source');
      if FNodeLoader.IsExists then
       foProjectItem.TemplateFile := FNodeLoader.Value;
      if Trim(foProjectItem.TemplateFile) = '' then
         begin
           foOutput.LogError(foProjectItem.Name + ': projectitem.source or projectitem.template required.');
           Result := False;
         end;

      FNodeLoader := GetNode(FRootNodeLoader, 'postprocessor');
      if FNodeLoader.IsExists then
       foProjectItem.postprocessor := FNodeLoader.Value
    end;
  if FRootNodeLoader.PropertyName = 'FOLDER' then
    begin
      FSrcFileNodeLoader := GetNode(FRootNodeLoader, 'sourcefiles');
      if FSrcFileNodeLoader.IsExists then
        begin
          if FSrcFileNodeLoader.PropertyName = 'FOLDER' then
            foProjectItem.oSourceFiles.Folder := FSrcFileNodeLoader.PropertyValue
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
                       lsFullPathname := FTmpFilesNodeLoader.PropertyValue;

                       FNodeLoader := GetNode(FTmpFilesNodeLoader, 'postprocessor');
                       if FNodeLoader.IsExists then
                         lspostprocessor := FNodeLoader.Value;

                       foProjectItem.oSourceFiles.oTemplates.AddFile
                         (foProjectItem.oSourceFiles.Folder +
                         TNovusFileUtils.TrailingBackSlash(lsFullPathname), lspostprocessor);
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
                       lsFullPathname := FFltFilesNodeLoader.PropertyValue;

                        foProjectItem.oSourceFiles.oFilters.AddFile
                          (foProjectItem.oSourceFiles.Folder +
                          TNovusFileUtils.TrailingBackSlash(lsFullPathname));
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

end.
