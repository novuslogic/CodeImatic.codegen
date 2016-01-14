unit projectconfig;

interface

uses XMLList, NovusTemplate, SysUtils, NovusSimpleXML, JvSimpleXml, novuslist,
     NovusStringUtils;

type
   TConnectionName = class
   private
     fsConnectionname: string;
     fsAuxdriver: string;
     fsServer: string;
     fsDatabase: string;
     fsUserID: string;
     fsPassword: string;
     fsSQLLibrary: string;
     fsparams: string;
   protected
   public
     property Connectionname: string
       read fsConnectionname
       write fsConnectionname;

     property Auxdriver: string
       read fsAuxdriver
       write fsAuxdriver;

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

   end;


   tProjectConfig = Class(TXMLList)
   private
   protected
     fConnectionNameList: tNovuslist;
     fsTemplatepath: String;
     fsProjectConfigFileName: String;
   public
      constructor Create; override;
      destructor Destroy; override;

      procedure LoadProjectConfigFile(aProjectConfigFilename: String);
      procedure LoadConnectionNameList;
      function Parseproperties(aInput: String): String;
      function FindConnectionName(AConnectionName: String): TConnectionName;

      property ProjectConfigFileName: String
        read fsProjectConfigFileName
        write fsProjectConfigFileName;

      property ConnectionNameList: tNovuslist
        read fConnectionNameList
        write fConnectionNameList;

      property TemplatePath: String
        read fstemplatePath
        write fstemplatepath;


   End;


implementation

constructor tProjectConfig.Create;
begin
  inherited;

  fConnectionNameList:= tNovuslist.Create(TConnectionName);
end;

destructor tProjectConfig.Destroy;
begin
  inherited;

  fConnectionNameList.Free;
end;

procedure TProjectConfig.LoadProjectConfigFile(aProjectConfigFilename: String);
begin
  XMLFileName := aProjectConfigFilename;
  Retrieve;

  ProjectConfigFileName := aProjectConfigFilename;

  LoadConnectionNameList;

  fsTemplatePath := TNovusStringUtils.TrailingBackSlash(GetFieldAsString(oXMLDocument.Root, 'templatepath'));
end;

function TProjectConfig.Parseproperties(aInput: String): String;
Var
  loTemplate: tNovusTemplate;
  I: INteger;
  FTemplateTag: TTemplateTag;
begin
  result := aInput;

  if aInput = '' then Exit;

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

  loTemplate.Free;
end;

procedure TProjectConfig.LoadConnectionNameList;
Var
  lConnectionName: TConnectionName;

  lsConnectionName: string;
  fXmlElemlConnectionName,
  fXmlElemlDriver: TJvSimpleXmlElem;
  liIndex, i: Integer;
begin
  fConnectionNameList.Clear;

  liIndex := 0;


  fXmlElemlConnectionName := TNovusSimpleXML.FindNode(self.oXMLDocument.Root, 'Connectionname',liIndex);
  While(fXmlElemlConnectionName <> nil) do
    begin
      if fXmlElemlConnectionName.Properties.count > 0 then
        begin
          // ConnectionName
          lConnectionName := TConnectionName.Create;
          lConnectionName.Connectionname := fXmlElemlConnectionName.Properties[0].Value;

          // Driver
          fXmlElemlDriver := fXmlElemlConnectionName.Items[0];

          lConnectionName.Auxdriver := GetFieldAsString(fXmlElemlDriver, 'Auxdriver');
          lConnectionName.Server := GetFieldAsString(fXmlElemlDriver, 'Server');
          lConnectionName.Database := GetFieldAsString(fXmlElemlDriver, 'Database');
          lConnectionName.UserID := GetFieldAsString(fXmlElemlDriver, 'UserID');
          lConnectionName.Password := GetFieldAsString(fXmlElemlDriver, 'Password');
          lConnectionName.SQLLibrary := GetFieldAsString(fXmlElemlDriver, 'SQLLibrary');
          lConnectionName.params := GetFieldAsString(fXmlElemlDriver, 'params');

          fConnectionNameList.Add(lConnectionName);

          fXmlElemlConnectionName := TNovusSimpleXML.FindNode(self.oXMLDocument.Root, 'Connectionname',liIndex);
        end
          else fXmlElemlConnectionName := NIL;
    end;

end;


function TProjectConfig.FindConnectionName(AConnectionName: String): TConnectionName;
Var
  I: Integer;
  lConnectionName: TConnectionName;
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

end.
