unit DBSchema;

interface

Uses Classes, NovusList, NovusTemplate, NovusStringParser, SysUtils,
     NovusStringUtils, SDEngine, NovusSQLDirUtils, NovusUtilities,
     DB, SDCommon, Output, NovusXMLBO, JvSimpleXml;

Type
   TFieldType = class(Tobject)
   private
     fsSQLType: String;
     fsSQLFormat: String;
   protected
   public
     property SQLType: String
       read fsSQLtype
       write fsSQLType;

     property SQLFormat: String
        read fsSQLFormat
        write fsSQLFormat;
   end;

   TFieldDesc = Class(tObject)
   protected
      fsFieldName: String;
      fsTypeName: String;
      fiPrecision: integer;
      fiScale: integer;
      fiColumn_Length: Integer;
   private
   public
     constructor Create; virtual;

     property FieldName: String
       read fsFieldName
       write fsFieldName;

     property TypeName: String
       read fsTypeName
       write fsTypeName;

     property Precision: integer
       read fiPrecision
       write fiPrecision;

     property Scale: integer
       read fiScale
       write fiScale;

     property Column_Length: Integer
       read fiColumn_Length
       write fiColumn_Length;

   End;

   tDBSchema = class(TNovusXMLBO)
   private
   protected
   public
     function GetTypeName(AFieldDesc: TFieldDesc; AAuxDriver: String): String;
     function GetFieldType(AFieldDesc: TFieldDesc; AAuxDriver: String):TFieldType;
   end;

   tConnectionItem = class(Tobject)
   protected
     foPlugins: TObject;
     FoOutput: TOutput;
     FTableNames: tStringlist;
     FDatabase: tSDDatabase;
     fsAuxDriver: String;
     fsDriverName: string;
     fsConnectionname: string;
     fsServer: string;
     fsDatabase: string;
     fsUserID: string;
     fsPassword: string;
     fsParams: String;
     fsSQLLibrary: String;
     fiPort: Integer;
   private
     function GetConnected: Boolean;
     function GetTableNames: tStringList;
   public
     constructor Create(AOutput: TOutput; aPlugins: TObject); virtual;
     destructor  Destroy; override;

     function TableCount: Integer;

     function JustTableNamebyIndex(AIndex: Integer): String;
     function TableExists(ATableName: String): Boolean;
     function FieldByIndex(ATableName: String; AIndex: Integer): TFieldDesc;
     function FieldByName(ATableName: String; AFieldName: String): TFieldDesc;
     function FieldCount(ATableName: String): Integer;
     function GetFieldDesc(aDataSet: tDataSet): tFieldDesc;

     procedure SetupDatabase;

     property Connected: Boolean
       read GetConnected;

     property TableNames: tStringList
       Read GetTablenames;

     property Connectionname: string
       read fsConnectionname
       write fsConnectionname;

     property Server: string
       read fsServer
       write fsServer;

     property Database: string
        read fsDatabase
        write fsDatabase;

     property UserID: string
       read fsUserId
       write fsUserId;

     property Password: string
       read fsPassword
       write fsPassword;

     property DriverName: string
       read fsDriverName
       write fsDriverName;

     property AuxDriver: String
       read fsAuxDriver
       write fsAuxDriver;

     property  Params: String
       read fsParams
       write fsParams;

     property SQLLibrary: String
       read fsSQLLibrary
       write fsSQLLibrary;

     property Port: Integer
        read fiPort
        write fiPort;

     property oPlugins: TObject
       read foPlugins
       write foPlugins;
   end;

   tConnections = class(Tobject)
   protected
   private
     fOutput: TOutput;
     fConnectionList: tNovusList;
   public
     constructor Create(aOutput: TOutput); virtual;
     destructor  Destroy; override;

     function FindConnectionName(AConnectionName: String): TConnectionItem;

     procedure  AddConnection(aConnectionItem: tConnectionItem);
   end;


implementation

Uses Runtime, ProjectItem, Plugins, Plugin;

constructor tConnections.Create;
begin
  inherited Create;

  fOutput := AOutput;

  fConnectionList := tNovusList.Create(tConnectionItem);
end;

destructor tConnections.Destroy;
begin
  fConnectionList.Free;

  inherited Destroy;
end;


function tConnections.FindConnectionName(AConnectionName: String): tConnectionItem;
Var
  I: Integer;
  lConnectionDetails: tConnectionItem;
begin
  Result := NIL;

  for I := 0 to fConnectionList.Count - 1 do
   begin
     lConnectionDetails := tConnectionItem(fConnectionList.Items[i]);

     If Uppercase(Trim(lConnectionDetails.Connectionname)) = Uppercase(Trim(AConnectionName)) then
       begin
         Result := lConnectionDetails;
         Break;
       end;
   end;
end;


procedure tConnections.AddConnection(aConnectionItem: tConnectionItem);
begin
  if not Assigned(aConnectionItem) then exit;

  aConnectionItem.SetupDatabase;

  fConnectionList.Add(aConnectionItem);
end;

// ConnectionList

constructor tConnectionItem.Create;
begin
  inherited Create;

  foPlugins := aPlugins;

  FoOutput := aOutput;

  FTableNames := tStringList.Create;

  FDatabase := tSDDatabase.Create(NIL);

end;

destructor tConnectionItem.Destroy;
begin
  FDatabase.Connected := False;

  FDatabase.Free;

  FTableNames.Free;


  inherited Destroy;
end;

(*
function GetDBSchemaPlugin(aPluginName)
begin
  if (foPlugins as TPlugins).IsPluginNameExists(fsProcessor) then
        begin
          foPlugin := (foPlugins as TPlugins).FindPlugin(fsProcessor);

          if (foPlugin Is TProcessorPlugin) then
            begin
               foprocessorPlugin := TProcessorPlugin(foPlugin);
            end;
        end;

*)

procedure tConnectionItem.SetupDatabase;
Var
  lStringList: tStringList;
  I: Integer;
  loPlugin: TPlugin;
begin
  loPlugin := (foPlugins as TPlugins).FindPlugin(DriverName);
  if Not Assigned(loPlugin) then
    begin
      foOutput.LogError('Error: Cannot find Plugin DBSchema Driver [' + DriverName + ']' );

      Exit;
    end;



  (loPlugin as TDBSchemaPlugin).SetupDatabase;



  lStringList := tStringList.Create;

  lStringList.Text := fsParams;

  TNovusSQLDirUtils.SetupSDDatabase(FDatabase,
                     fsServer,
                     fsDatabase,
                     fsConnectionname,
                     TSDServerType(TNovusSQLDirUtils.GetServerTypeAsInteger(fsAuxDriver)),
                     fsUserID,
                     fsPassword,
                     lStringList,
                     fsSQLLibrary,
                     False,
                     fiPort);

  lStringList.Free;
end;


function tConnectionItem.TableCount: Integer;
begin
  GetTableNames;

  Result := FTableNames.Count;
end;

function tConnectionItem.GetConnected: Boolean;
begin
  Result := False;

  If Not Assigned(fDatabase) Then Exit;

  Try
    FDatabase.Connected := True;

    Result := True;
  Except
    FoOutput.Log('Error: ' + fsConnectionname + ' - ' + TNovusUtilities.GetExceptMess);

    Result := False;
  End;
end;

function tConnectionItem.JustTableNamebyIndex(AIndex: Integer): String;
begin
  if Pos('.', TableNames[AIndex]) > -1 then
    Result :=  Copy(TableNames[AIndex], Pos('.', TableNames[AIndex]) + 1, Length(TableNames[AIndex]))
  else TableNames[AIndex];
end;

function tConnectionItem.TableExists(ATableName: String): Boolean;
Var
  I: Integer;
begin
  Result := false;

  for I := 0 to TableNames.Count - 1 do
    begin
      if (pos(Uppercase(Trim(ATableName)), Uppercase(TableNames[i])) > 0) then
        begin
          Result := True;

          Break;
        end;
    end;
end;

function tConnectionItem.GetFieldDesc(aDataSet: tDataSet): tFieldDesc;
begin
  Result := TFieldDesc.Create;

  Result.TypeName := '';

  Result.FieldName := aDataSet.FieldByName('COLUMN_NAME').AsString;

  Result.TypeName := aDataSet.FieldByName('COLUMN_TYPENAME').AsString;

  Result.Precision := aDataSet.FieldByName('COLUMN_PRECISION').AsInteger;

  Result.Scale := Abs(aDataSet.FieldByName('COLUMN_SCALE').Asinteger);

  Result.Column_Length := aDataSet.FieldByName('COLUMN_LENGTH').Asinteger;



  // This need t be fixed
  //Result.TypeName := (foProjectItem as tProjectItem).oDBSchema.GetTypeName(Result, fsAuxDriver);

end;


function tConnectionItem.FieldByIndex(ATableName: String; AIndex: Integer): TFieldDesc;
Var
  I: INteger;
  cmd: TDataSet;
  FFieldDesc: TFieldDesc;
begin
  Result := NIL;

  cmd := FDatabase.GetSchemaInfo(stColumns, Uppercase(ATableName));

  I := 0;

  if Assigned( cmd ) then
    try
      cmd.First;
      While(Not cmd.Eof) do
        begin
          if I = AIndex then
            begin
              Result := GetFieldDesc(Cmd);

              Break;
            end;

          Inc(I);

          cmd.Next;
        end;

    Finally
      Cmd.Free;
    end;

end;

function tConnectionItem.FieldByName(ATableName: String; AFieldName: String): TFieldDesc;
Var
  I: INteger;
  cmd: TDataSet;
  FFieldDesc: TFieldDesc;
begin

  Result := NIL;

  cmd := FDatabase.GetSchemaInfo(stColumns, Uppercase(ATableName));

  if Assigned( cmd ) then
    try
      If cmd.Locate('COLUMN_NAME',AFieldName, [loCaseInsensitive]) then
        Result := GetFieldDesc(Cmd);
    Finally
      Cmd.Free;
    end;
end;

function tConnectionItem.FieldCount(ATableName: String): Integer;
Var
  I: INteger;
  cmd: TDataSet;
  FFieldDesc: TFieldDesc;
begin
  Result := -1;

  cmd := FDatabase.GetSchemaInfo(stColumns, Uppercase(ATableName));

  I := 0;

  if Assigned( cmd ) then
    try
      Result := cmd.RecordCount;

    Finally
      Cmd.Free;
    end;
end;


function tConnectionItem.GetTableNames: tStringList;
Var
  I: Integer;
begin
  if FTableNames.Count = 0 then
    FDatabase.GetTableNames('', false, FTableNames);

  Result := FTableNames;
end;


// FieldDesc

constructor TFieldDesc.Create;
begin
  inherited Create;

  fsFieldName := '';
end;

// DBSchema

function TDBSchema.GetFieldType(AFieldDesc: TFieldDesc; aAuxDriver: String): TFieldType;
Var
  fJvSimpleXmlElem1,  fJvSimpleXmlElem2 : TJvSimpleXmlElem;
  liIndex: Integer;
begin
  Result := TFieldType.Create;
  Result.SQLType := AFieldDesc.TypeName;

  liIndex := 0;
  fJvSimpleXmlElem1 := FindNode(oXMLDocument.Root.Items[0], Uppercase(aAuxDriver), liIndex);

  If Assigned(fJvSimpleXmlElem1) then
    begin
      liIndex := 0;

      fJvSimpleXmlElem2 := FindNode(fJvSimpleXmlElem1, Uppercase(AFieldDesc.TypeName), liIndex);

      if assigned(fJvSimpleXmlElem2) then
        begin
          Result.SQLType :=  GetFieldAsString(fJvSimpleXmlElem2,'sqltype');
          Result.SQLFormat :=  GetFieldAsString(fJvSimpleXmlElem2,'sqlformat');
        end;
    end;
end;


function TDBSchema.GetTypeName(AFieldDesc: TFieldDesc; aAuxDriver: String): String;
Var
  fJvSimpleXmlElem1,  fJvSimpleXmlElem2, fJvSimpleXmlElem3 : TJvSimpleXmlElem;
  liIndex: Integer;
  lsPrecision: String;
  lsScale: String;
  liFieldLength: Integer;
begin
  Result := AFieldDesc.TypeName;

  if Assigned(oXMLDocument.Root.Items[1]) then
    begin
    liIndex := 0;
    fJvSimpleXmlElem1 := FindNode(oXMLDocument.Root.Items[1], Uppercase(AauxDriver), liIndex);

    If Assigned(fJvSimpleXmlElem1) then
      begin
        liIndex := 0;

        fJvSimpleXmlElem2 := FindNode(fJvSimpleXmlElem1, Uppercase(AFieldDesc.TypeName), liIndex);

        if assigned(fJvSimpleXmlElem2) then
          begin
            liIndex := 0;

            fJvSimpleXmlElem3 := FindNode(fJvSimpleXmlElem2, 'FieldLength', liIndex);

            if Not Assigned(fJvSimpleXmlElem3) then
              begin
                Result := Trim(fJvSimpleXmlElem2.Value);

                Exit;
              end;


            while assigned(fJvSimpleXmlElem3) do
              begin
                lsPrecision := Trim(fJvSimpleXmlElem3.Properties.Item[0].Value);
                lsScale := trim(fJvSimpleXmlElem3.Properties.item[1].Value);

                liFieldLength := AFieldDesc.Precision;
                If AFieldDesc.Precision = 0 then
                  liFieldLength := AFieldDesc.Column_Length;

                If (liFieldLength = StrToInt(lsPrecision)) and
                   (AFieldDesc.Scale = StrToInt(lsScale)) then
                  begin
                    Result := Trim(fJvSimpleXmlElem3.Value);

                    Exit;
                  end;

                fJvSimpleXmlElem3 := FindNode(fJvSimpleXmlElem2, 'FieldLength', liIndex);
              end;
          end;
      end;
    end;
end;
end.
