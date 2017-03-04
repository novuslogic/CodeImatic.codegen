unit Project;

interface

Uses NovusXMLBO, Classes, SysUtils, NovusStringUtils, NovusBO, NovusList,
     JvSimpleXml, NovusSimpleXML, XMLlist, ProjectConfig, NovusFileUtils;

Type
  TProjectItem = class(TNovusBO)
  protected
  private
    fsItemName: String;
    fsOutputFile: String;
    fsTemplateFile: String;
    fsPropertiesFile: String;
    fboverrideoutput: Boolean;
    fsPostprocessor: string;
  Public
    property PropertiesFile: String
       read fsPropertiesFile
       write fsPropertiesFile;

    property TemplateFile: String
      read fsTemplateFile
      write fsTemplateFile;

    property OutputFile: String
       read fsOutputFile
       write fsOutputFile;

    property overrideoutput: Boolean
      read fboverrideoutput
      write fboverrideoutput;

    property ItemName: String
      read fsItemName
      write fsItemName;

    property PostProcessor: String
      read fsPostProcessor
      write fsPostProcessor;
  end;


  TProject = class(TXMLlist)
  protected
  private
    fbcreateoutputdir: Boolean;
    foProjectConfig: TProjectConfig;
    foProjectItemList: TNovusList;
    fsBasePath: String;
    fsTemplatePath: String;
    fsProjectFilename: String;
    fbOutputConsole: Boolean;
  public
    constructor Create; override;
    destructor Destroy; override;


    function GetBasePath: String;
    function GetOutputConsole: Boolean;
    function GetCreateoutputdir: Boolean;

    function GetWorkingdirectory: String;

    function LoadProjectFile(aProjectFilename: String; aProjectConfigFilename: String): boolean;
    function LoadProjectItem(aItemName: String; aProjectItem: TProjectItem): Boolean;

    property oProjectItemList: TNovusList
      read foProjectItemList
      write foProjectItemList;

    property ProjectFileName: String
      read fsProjectFileName
      write fsProjectFileName;

    property BasePath: string
      read fsBasePath
      write fsBasePath;

    property  OutputConsole: Boolean
      read  fbOutputConsole
      write fbOutputConsole;

   property Createoutputdir: Boolean
      read fbcreateoutputdir
      write fbcreateoutputdir;

    property oProjectConfig: TProjectConfig
      read foProjectConfig
      write foProjectConfig;

  end;

implementation


constructor TProject.Create;
begin
  inherited Create;

  foProjectConfig := TProjectConfig.Create;

  foProjectItemList:= TNovusList.Create(TProjectItem);

end;

destructor TProject.Destroy;
begin
  foProjectConfig.Free;

  foProjectItemList.Free;

  inherited;
end;

function TProject.LoadProjectItem(aItemName: String; aProjectItem: TProjectItem): Boolean;
Var
  fJvSimpleXmlElem: TJvSimpleXmlElem;
  Index: Integer;
  FNode: TJvSimpleXmlElem;
begin
  Result := False;

  Try
    fJvSimpleXmlElem  := TnovusSimpleXML.FindNodeByValue(oXMLDocument.Root, 'projectitem', 'name', aItemName);

    If Assigned(fJvSimpleXmlElem) then
      begin
        Index := 0;
        if assigned(TNovusSimpleXML.FindNode(fJvSimpleXmlElem, 'template', Index)) then
          begin
            Index := 0;
            aProjectItem.TemplateFile := TNovusSimpleXML.FindNode(fJvSimpleXmlElem, 'template', Index).Value;
          end;

        if assigned(TNovusSimpleXML.FindNode(fJvSimpleXmlElem, 'source', Index)) then
          begin
            Index := 0;
            aProjectItem.TemplateFile := TNovusSimpleXML.FindNode(fJvSimpleXmlElem, 'source', Index).Value;
          end;

        Index := 0;
        if Assigned(TNovusSimpleXML.FindNode(fJvSimpleXmlElem, 'properties', Index)) then
          begin
            Index := 0;
            aProjectItem.propertiesFile := TNovusSimpleXML.FindNode(fJvSimpleXmlElem, 'properties', Index).Value;
          end;

          Index := 0;
        if Assigned(TNovusSimpleXML.FindNode(fJvSimpleXmlElem, 'postprocessor', Index)) then
          begin
            Index := 0;
            aProjectItem.postprocessor := Uppercase(TNovusSimpleXML.FindNode(fJvSimpleXmlElem, 'postprocessor', Index).Value);
          end;

        Index := 0;
        if Assigned(TNovusSimpleXML.FindNode(fJvSimpleXmlElem, 'overrideoutput', Index)) then
          begin
            Index := 0;
            if Uppercase(TNovusSimpleXML.FindNode(fJvSimpleXmlElem, 'overrideoutput', Index).Value) = 'TRUE' then
              aProjectItem.overrideoutput := True
            else
               aProjectItem.overrideoutput := false;
          end
        else aProjectItem.overrideoutput := false;

        Index := 0;
        if assigned(TNovusSimpleXML.FindNode(fJvSimpleXmlElem, 'output', Index)) then
          begin
            Index := 0;
            aProjectItem.OutputFile := TNovusSimpleXML.FindNode(fJvSimpleXmlElem, 'output', Index).Value;
          end;
      end;
  Finally
    Result := True;
  end;
end;

function TProject.GetWorkingdirectory: String;
var
  lsWorkingdirectory: String;
begin
  Result := '';

  lsWorkingdirectory := Trim(foProjectConfig.workingdirectory);

  if lsWorkingdirectory <> '' then
    lsWorkingdirectory :=  IncludeTrailingPathDelimiter(foProjectConfig.workingdirectory);

  if (Not DirectoryExists(lsWorkingdirectory))  or (Trim(lsWorkingdirectory) = '') then
    lsWorkingdirectory := IncludeTrailingPathDelimiter(TNovusFileUtils.AbsoluteFilePath(ProjectFileName));

  result := lsWorkingdirectory;
end;


function TProject.GetBasePath: String;
var
  lsOutputpath: string;
begin
  lsOutputpath := TNovusFileUtils.TrailingBackSlash(GetFieldAsString(oXMLDocument.Root, 'outputpath'));

  if Trim(lsOutputpath) = '' then
    lsOutputpath := TNovusFileUtils.TrailingBackSlash(GetFieldAsString(oXMLDocument.Root, 'messageslogpath'));

  if Trim(lsOutputPath) = '' then
    lsOutputPath := GetWorkingdirectory;

  if lsOutputpath <> '' then
    Result := TNovusStringUtils.TrailingBackSlash(lsOutputpath);
end;

function TProject.GetOutputConsole: Boolean;
begin
  Result := GetFieldAsBoolean(oXMLDocument.Root, 'outputconsole');
end;

function TProject.LoadProjectFile(aProjectFilename: String; aProjectConfigFilename: String): boolean;
Var
  fJvSimpleXmlElem: TJvSimpleXmlElem;
  Index: Integer;
  loProjectItem: TProjectItem;
begin
  XMLFileName := aProjectFilename;
  ProjectFileName := aProjectFilename;

  Result := Retrieve;
  if not Result then exit;

  fsBasePath := GetBasePath;

  fbOutputConsole := GetoutputConsole;
  fbCreateoutputdir := GetCreateoutputdir;



  //Project Items
  Index := 0;
  fJvSimpleXmlElem  := TNovusSimpleXML.FindNode(oXMLDocument.Root, 'projectitem', Index);
  While(fJvSimpleXmlElem <> NIL) do
    begin
      loProjectItem:= TProjectItem.Create;

      loProjectItem.ItemName := fJvSimpleXmlElem.Properties[0].Value;

      LoadProjectItem(loProjectItem.ItemName, loProjectItem);

      oProjectItemList.Add(loProjectItem);

      fJvSimpleXmlElem  := TNovusSimpleXML.FindNode(oXMLDocument.Root, 'projectitem', Index);
    end;

end;

function TProject.GetCreateoutputdir: Boolean;
begin
  Result := GetFieldAsBoolean(oXMLDocument.Root, 'Createoutputdir');
end;



end.
