unit Project;

interface

Uses NovusXMLBO, Classes, SysUtils, NovusStringUtils, NovusBO, NovusList,NovusFileUtils,
     JvSimpleXml, NovusSimpleXML, XMLlist, ProjectConfig, Output;


Type
  TProject = class(TXMLlist)
  protected
  private
    foOutput: TOutput;
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

    function LoadProjectFile(aProjectFilename: String; aProjectConfigFilename: String; aOutput: TOutput): boolean;

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

uses Runtime, ProjectConfigParser, ProjectItem, ProjectItemLoader;


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
    Result := TNovusFileUtils.TrailingBackSlash(lsOutputpath);
end;

function TProject.GetOutputConsole: Boolean;
begin
  Result := GetFieldAsBoolean(oXMLDocument.Root, 'outputconsole');
end;

function TProject.LoadProjectFile(aProjectFilename: String; aProjectConfigFilename: String; aOutput: TOutput): boolean;
Var
  fNodeProjectItem: TJvSimpleXmlElem;
  Index: Integer;
  loProjectItem: TProjectItem;
begin
  foOutput := aOutput;

  XMLFileName := aProjectFilename;
  ProjectFileName := aProjectFilename;

  Result := Retrieve;
  if not Result then exit;

  fsBasePath := GetBasePath;

  fbOutputConsole := GetoutputConsole;
  fbCreateoutputdir := GetCreateoutputdir;

  //Project Items
  Index := 0;
  fNodeProjectItem  := TNovusSimpleXML.FindNode(oXMLDocument.Root, 'projectitem', Index);
  While(fNodeProjectItem <> NIL) do
    begin
      loProjectItem:= TProjectItem.Create(self, foOutput, fNodeProjectItem);

      (*
      if fJvSimpleXmlElem.Properties.Count > 0 then
        begin
          if uppercase(fJvSimpleXmlElem.Properties[0].Name) = 'FOLDER' then
            loProjectItem.ItemFolder := fJvSimpleXmlElem.Properties[0].Value
          else
          if uppercase(fJvSimpleXmlElem.Properties[0].Name) = 'NAME' then
            loProjectItem.ItemName := fJvSimpleXmlElem.Properties[0].Value
          else
            loProjectItem.ItemName := fJvSimpleXmlElem.Properties[0].Value;
        end;
      *)
      if TProjectItemLoader.LoadProjectItem(Self, loProjectItem, fNodeProjectItem, foOutput) then
        oProjectItemList.Add(loProjectItem);


      (*
      if loProjectItem.ItemName <> '' then
        TProjectItemLoader.LoadProjectItemName(Self, loProjectItem.ItemName, loProjectItem)
      else
        TProjectItemLoader.LoadProjectItemFolder(Self, loProjectItem.ItemFolder, loProjectItem);
      *)



      fNodeProjectItem  := TNovusSimpleXML.FindNode(oXMLDocument.Root, 'projectitem', Index);
    end;

end;

function TProject.GetCreateoutputdir: Boolean;
begin
  Result := GetFieldAsBoolean(oXMLDocument.Root, 'Createoutputdir');
end;







end.
