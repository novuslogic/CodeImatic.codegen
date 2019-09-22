unit ProjectConfigLoader;

interface

uses XMLList, NovusTemplate, SysUtils, NovusSimpleXML, JvSimpleXml, novuslist,
  NovusStringUtils, NovusEnvironment, NovusFileUtils, Loader, DataProcessor,
  Output;

type
  tProjectConfigLoader = Class(TLoader)
  private
  protected
    foPlugins: tObject;
    foOutput: tOutput;
    FoRootNodeLoader: tNodeLoader;
    foProject: tXMLlist;
    fConnectionNameList: tNovuslist;
    fsSearchPath: String;
    fsworkingdirectory: String;
    fsOutputPath:String;
    fsTemplatepath: String;
    fsProjectConfigFileName: String;
    fsDBSchemaPath: String;
    fsLanguagesPath: String;
    foConnections: tConnections;
  public
    constructor Create(aProject: TXMLlist; aOutput: tOutput );
    destructor Destroy; override;

    function Load: boolean; override;

    procedure LoadProjectConfig(aWorkingdirectory: string);

    function IspropertyExists(aPropertyName: String): boolean;
    function Getproperties(aPropertyName: String): String;

    function GetSearchPath: String;
    function GetTemplatepath: String;
    function GetDBSchemaPath: String;
    function GetLanguagesPath: String;
    function Getworkingdirectory: string;
    function GetOutputPath: String;

    procedure LoadConnections;

    function CreateProperty(aPropertyName: String): boolean;

    function SetProperty(aPropertyName: String; aValue: String): boolean;
    function DeleteProperty(aPropertyName: String): boolean;

    property SearchPath: String read fsSearchPath write fsSearchPath;

    property Workingdirectory: string
      read Getworkingdirectory;

    property TemplatePath: String
        read GettemplatePath;

    property DBSchemaPath: String
         read GetDBSchemaPath;

    property LanguagesPath: String
         read GetLanguagesPath;

    property Outputpath: string
        read GetOutputPath;

    property oPlugins: TObject
        read foPlugins
        write foPlugins;

    property oConnections: tConnections
       read foConnections
       write foConnections;
  End;

implementation

Uses ProjectParser, Project;

constructor tProjectConfigLoader.Create(aProject: TXMLlist; aOutput: tOutput );
begin
  foProject := aProject;
  foOutput := aOutput;

  foConnections:= tConnections.Create(aOutput);
end;

destructor tProjectConfigLoader.Destroy;
begin
  inherited;

  fConnectionNameList.Free;
end;

function tProjectConfigLoader.GetWorkingdirectory: String;
var
  lsworkingdirectory: string;
begin
  lsworkingdirectory := Trim(Getproperties('workingdirectory'));

  Result := '';
  if lsworkingdirectory <> '' then
    Result := IncludeTrailingPathDelimiter(lsworkingdirectory);
end;


function tProjectConfigLoader.GetTemplatepath: String;
begin
  if Trim(fsTemplatePath) = '' then
    fsTemplatePath := TNovusFileUtils.TrailingBackSlash( Getproperties('templatepath'));
  if Trim(fsTemplatePath) = '' then
    fsTemplatePath := TNovusFileUtils.TrailingBackSlash(Getproperties('sourcepath'));

  Result := fsTemplatePath;
end;

function tProjectConfigLoader.GetDBSchemaPath: String;
begin
  if Trim(fsDBSchemaPath) = '' then
    fsDBSchemaPath := TNovusFileUtils.TrailingBackSlash( Getproperties('DBSchemaPath'));

  Result := fsDBSchemaPath;
end;

function tProjectConfigLoader.GetLanguagesPath: String;
begin
  if Trim(fsLanguagesPath) = '' then
    fsLanguagesPath := TNovusFileUtils.TrailingBackSlash( Getproperties('LanguagesPath'));

  Result := fsLanguagesPath;
end;


function tProjectConfigLoader.GetOutputPath: string;
begin

  if Trim(fsOutputPath) = '' then
    fsOutputPath := TNovusFileUtils.TrailingBackSlash( Getproperties('outputpath'));

  Result := fsOutputPath;
end;


procedure tProjectConfigLoader.LoadProjectConfig(aWorkingdirectory: string);
begin
  Load;

  fsSearchPath := GetSearchPath;
  fsworkingdirectory := GetWorkingdirectory;
  if Trim(fsworkingdirectory) = '' then
    fsworkingdirectory := aWorkingdirectory;

end;

function tProjectConfigLoader.GetSearchPath: String;
begin
  Result := TNovusFileUtils.TrailingBackSlash(Getproperties('searchpath'));
end;

function tProjectConfigLoader.Getproperties(aPropertyName: string): String;
Var
  FPropertiesNodeLoader,
  FNodeLoader: TNodeLoader;
begin
  Result := '';
  if Trim(aPropertyName) = '' then
    Exit;

  FPropertiesNodeLoader := GetNode(FoRootNodeLoader, 'properties');
  if FPropertiesNodeLoader.IsExists then
    begin
      FNodeLoader := GetNode(FPropertiesNodeLoader , aPropertyName);
      if FNodeLoader.IsExists then
         Result := GetValue(FNodeLoader.Value)
    end;


  Result :=   tProjectParser.ParseProject(GetValue(FNodeLoader.Value),  (foProject as TProject), foOutput);

  // Result := GetValue(FNodeLoader.Value);

end;

function tProjectConfigLoader.IspropertyExists(aPropertyName: String): boolean;
Var
  FNodeLoader: TNodeLoader;
begin
  Result := False;

  if Trim(aPropertyName) = '' then
    Exit;

  FNodeLoader := GetNode(FoRootNodeLoader, aPropertyName);
  Result := FNodeLoader.IsExists;
end;

function tProjectConfigLoader.CreateProperty(aPropertyName: String): boolean;
Var
  FNodeLoader: TNodeLoader;
begin
  Result := False;

  FNodeLoader := GetNode(FoRootNodeLoader, aPropertyName);
  if not FNodeLoader.IsExists then
    begin
      FoRootNodeLoader.Node.Items.Add(Lowercase(aPropertyName));

      Result := foProject.Post;
    end;
end;

function tProjectConfigLoader.SetProperty(aPropertyName: String;
  aValue: String): boolean;
Var
  FNodeLoader: TNodeLoader;
begin
  Result := false;

  FNodeLoader := GetNode(FoRootNodeLoader, aPropertyName);
  if FNodeLoader.IsExists then
    begin
      FNodeLoader.Value := aValue;

      Result := foProject.Post;
    end;
end;

function tProjectConfigLoader.DeleteProperty(aPropertyName: String): boolean;
Var
  FNodeLoader: TNodeLoader;
begin
  Result := False;

  FNodeLoader := GetNode(FoRootNodeLoader, aPropertyName);
  if FNodeLoader.IsExists then
    begin
      FoRootNodeLoader.Node.Items.Delete(FNodeLoader.Node.Name);

      Result := foProject.Post;
    end;
end;

function tProjectConfigLoader.Load: boolean;
begin
  Result := false;
  RootNode := foProject.GetNode('projectconfig');
  if RootNode = Nil then Exit;

  FoRootNodeLoader := GetRootNode;

  Result := True;
end;

procedure tProjectConfigLoader.LoadConnections;
Var
  loConnectionItem: tConnectionItem;
  lsConnectionName: string;
  fXmlElemlConnectionName,
  fXmlElemlDriver: TJvSimpleXmlElem;
  liIndex, i: Integer;
begin
  if not  Assigned(foConnections) then Exit;

  foConnections.oPlugins := foPlugins;

  liIndex := 0;

  fXmlElemlConnectionName := TNovusSimpleXML.FindNode(RootNode, 'Connectionname',liIndex);
  While(fXmlElemlConnectionName <> nil) do
    begin
      if fXmlElemlConnectionName.Properties.count > 0 then
        begin
          loConnectionItem := tConnectionItem.Create(foOutput, foPlugins);
          loConnectionItem.Connectionname := fXmlElemlConnectionName.Properties.Value('name');
          fxmlelemldriver := fxmlelemlconnectionname.items[0];
          if Assigned(fxmlelemldriver) then
            begin
              loConnectionItem.drivername := fxmlelemldriver.Properties.Value('name');
              if Trim(loConnectionItem.drivername) <> '' then
                begin
                  loConnectionItem.auxdriver := getfieldasstring(fxmlelemldriver, 'auxdriver');
                  loConnectionItem.server := getfieldasstring(fxmlelemldriver, 'server');
                  loConnectionItem.database := getfieldasstring(fxmlelemldriver, 'database');
                  loConnectionItem.userid := getfieldasstring(fxmlelemldriver, 'userid');
                  loConnectionItem.password := getfieldasstring(fxmlelemldriver, 'password');
                  loConnectionItem.sqllibrary := getfieldasstring(fxmlelemldriver, 'sqllibrary');
                  loConnectionItem.params := getfieldasstring(fxmlelemldriver, 'params');
                  loConnectionItem.port := getfieldasinteger(fxmlelemldriver, 'port');
                end;
            end;


          foConnections.AddConnection(loConnectionItem);

          fXmlElemlConnectionName := TNovusSimpleXML.FindNode(RootNode, 'Connectionname',liIndex);
        end
          else fXmlElemlConnectionName := NIL;
    end;

end;


end.
