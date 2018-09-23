unit projectconfig;

interface

uses XMLList, NovusTemplate, SysUtils, NovusSimpleXML, JvSimpleXml, novuslist,
     NovusStringUtils, NovusFileUtils, NovusEnvironment, DBSchema, output;

type
   (*
   TConnectionName = class
   private
     fsConnectionname: string;
     fsDriverName: string;
     fsAuxdriver: string;
     fsServer: string;
     fsDatabase: string;
     fsUserID: string;
     fsPassword: string;
     fsSQLLibrary: string;
     fsparams: string;
     fiPort: Integer;
   protected
   public
     property Connectionname: string
       read fsConnectionname
       write fsConnectionname;

     property Auxdriver: string
       read fsAuxdriver
       write fsAuxdriver;

     property DriverName: string
       read fsDriverName
       write fsDriverName;

     property Server: string
       read fsServer
       write fsServer;

     property Database: string
       read fsDatabase
       write fsDatabase;

     property UserID: string
       read fsUserID
       write fsUserID;

     property Password: string
       read fsPassword
       write fsPassword;

     property SQLLibrary: string
       read fsSQLLibrary
       write fsSQLLibrary;

     property params: string
       read fsparams
       write fsparams;

     property Port: Integer
       read fiPort
       write fiPort;
   end;
   *)

   tProjectConfig = Class(TXMLList)
   private
   protected
     foPlugins: tObject;
     foOutput: tOutput;
     foConnections: tConnections;
     fsSearchPath: String;
     fsOutputPath:String;
     //fConnectionNameList: tNovuslist;
     fsTemplatepath: String;
     fsProjectConfigFileName: String;
     fsDBSchemaPath: String;
     fsLanguagesPath: String;
     fsworkingdirectory: string;

     function GetTemplatepath: String;
     function GetDBSchemaPath: String;
     function GetLanguagesPath: String;
     function Getworkingdirectory: string;
     function GetOutputPath: String;
     function GetSearchPath: String;
   public
      constructor Create(aOutput: tOutput); overload;
      destructor Destroy; override;

      function Loadproperties(aPropertyName: String): String;
      function LoadProjectConfigFile(aProjectConfigFilename: String): Boolean;
      procedure LoadConnections;
      function Parseproperties(aInput: String): String;
      function GetProperties(aPropertyName: String): String;

      //function FindConnectionName(AConnectionName: String): TConnectionName;

      property ProjectConfigFileName: String
        read fsProjectConfigFileName
        write fsProjectConfigFileName;

    //  property ConnectionNameList: tNovuslist
     //   read fConnectionNameList
     //   write fConnectionNameList;

      property oConnections: tConnections read foConnections write foConnections;

      property TemplatePath: String
        read GettemplatePath;

      property DBSchemaPath: String
         read GetDBSchemaPath;

      property LanguagesPath: String
         read GetLanguagesPath;

      property workingdirectory: string
        read Getworkingdirectory;

      property Outputpath: string
        read GetOutputPath;

      property SearchPath: string
        read GetSearchPath;

      property oPlugins: TObject
        read foPlugins
        write foPlugins;
   End;


implementation

constructor tProjectConfig.Create(aOutput: tOutput);
begin
  inherited Create;

  foOutput := aOutput;

  foConnections:= tConnections.Create(foOutput);
end;

destructor tProjectConfig.Destroy;
begin
  inherited;

  foConnections.Free;

  //fConnectionNameList.Free;
end;

function TProjectConfig.LoadProjectConfigFile(aProjectConfigFilename: String): Boolean;
Var
  liIndex: integer;
begin
  Try
    XMLFileName := aProjectConfigFilename;
    Result := Retrieve;
    if not Result then Exit;

    ProjectConfigFileName := aProjectConfigFilename;

    //LoadConnections;
  Except
    Result := False;
  End;
end;

function TProjectConfig.Parseproperties(aInput: String): String;
Var
  loTemplate: tNovusTemplate;
  I: INteger;
  FTemplateTag: TTemplateTag;
begin
  result := aInput;

  if aInput = '' then Exit;

  Try
    loTemplate := tNovusTemplate.Create;


    loTemplate.StartToken := '[';
    loTemplate.EndToken := ']';
    loTemplate.SecondToken := '%';

    loTemplate.TemplateDoc.Text := Trim(aInput);

    loTemplate.ParseTemplate;

    For I := 0 to loTemplate.TemplateTags.Count -1 do
      begin
        FTemplateTag := TTemplateTag(loTemplate.TemplateTags.items[i]);

        FTemplateTag.TagValue := GetFirstNodeName(FTemplateTag.TagName, 'properties');
      end;

    loTemplate.InsertAllTagValues;

    Result := Trim(loTemplate.OutputDoc.Text);

  Finally
    loTemplate.Free;
  End;
end;

function TProjectConfig.Getproperties(aPropertyName: String): String;
begin
  result := aPropertyName;

  if aPropertyName = '' then Exit;

  Result := GetFirstNodeName(aPropertyName, 'properties');

  Result :=  tNovusEnvironment.ParseGetEnvironmentVar(Result,ETTToken2 );
  Result :=  tNovusEnvironment.ParseGetEnvironmentVar(Result, ETTToken1);
end;



function TProjectConfig.Loadproperties(aPropertyName: String): String;
var
  fXmlElemlproperties: TJvSimpleXmlElem;
  liIndex, i: Integer;
begin
  Result := '';

  liIndex := 0;
  fXmlElemlproperties := TNovusSimpleXML.FindNode(self.oXMLDocument.Root, 'properties',liIndex);
  if (fXmlElemlproperties <> nil) then
    begin
      Result := GetFieldAsString(fXmlElemlproperties, aPropertyName);
    end
  else
    begin
      // Old Properties

      Result := GetFieldAsString(self.oXMLDocument.Root, aPropertyName);
    end;

end;



procedure TProjectConfig.LoadConnections;
Var
  loConnectionItem: tConnectionItem;
  lsConnectionName: string;
  fXmlElemlConnectionName,
  fXmlElemlDriver: TJvSimpleXmlElem;
  liIndex, i: Integer;
begin

  liIndex := 0;

  fXmlElemlConnectionName := TNovusSimpleXML.FindNode(self.oXMLDocument.Root, 'Connectionname',liIndex);
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

          fXmlElemlConnectionName := TNovusSimpleXML.FindNode(self.oXMLDocument.Root, 'Connectionname',liIndex);
        end
          else fXmlElemlConnectionName := NIL;
    end;

end;


(*
function TProjectConfig.FindConnectionName(AConnectionName: String): TConnectionItem;
Var
  I: Integer;
  lConnectionItem: TConnectionItem;
begin
  Result := NIL;

  for I := 0 to fConnectionNameList.Count - 1 do
   begin
     lConnectionName := TConnectionName(fConnectionNameList.Items[i]);

     If Uppercase(Trim(lConnectionName.Connectionname)) = Uppercase(Trim(AConnectionName)) then
       begin
         Result := lConnectionName;
         Break;
       end;
   end;
end;
*)

function TProjectConfig.GetTemplatepath: String;
begin
  if Trim(fsTemplatePath) = '' then
    fsTemplatePath := TNovusFileUtils.TrailingBackSlash( Loadproperties('templatepath'));
  if Trim(fsTemplatePath) = '' then
    fsTemplatePath := TNovusFileUtils.TrailingBackSlash(Loadproperties('sourcepath'));

  Result := fsTemplatePath;
end;

function TProjectConfig.GetDBSchemaPath: String;
begin
  if Trim(fsDBSchemaPath) = '' then
    fsDBSchemaPath := TNovusFileUtils.TrailingBackSlash( Loadproperties('DBSchemaPath'));

  Result := fsDBSchemaPath;
end;

function TProjectConfig.GetLanguagesPath: String;
begin
  if Trim(fsLanguagesPath) = '' then
    fsLanguagesPath := TNovusFileUtils.TrailingBackSlash( Loadproperties('LanguagesPath'));

  Result := fsLanguagesPath;
end;

function TProjectConfig.Getworkingdirectory: string;
begin

  if Trim(fsworkingdirectory) = '' then
    fsworkingdirectory := TNovusFileUtils.TrailingBackSlash( Loadproperties('workingdirectory'));

  Result := fsworkingdirectory;
end;

function TProjectConfig.GetOutputPath: string;
begin

  if Trim(fsOutputPath) = '' then
    fsOutputPath := TNovusFileUtils.TrailingBackSlash( Loadproperties('outputpath'));

  Result := fsOutputPath;
end;

function tProjectConfig.GetSearchPath: String;
begin
  Result := TNovusFileUtils.TrailingBackSlash(Getproperties('searchpath'));
end;



end.
