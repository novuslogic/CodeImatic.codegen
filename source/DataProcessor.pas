unit DataProcessor;

interface

Uses Classes, NovusList, NovusTemplate, NovusStringParser, SysUtils,
     NovusStringUtils, {SDEngine,} NovusSQLDirUtils, NovusUtilities,
     DB, {SDCommon,} Output, NovusXMLBO, JvSimpleXml;

Type
   TConnection = class(TObject)
   private
   protected
     foOutput: tOutput;
     function GetConnected: Boolean; virtual;
     procedure SetConnected(value: boolean); virtual;
   public
      constructor Create(aOutput: tOutput); virtual;
      destructor Destroy; virtual;

      property Connected: Boolean read GetConnected write SetConnected;
   end;


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
     function GetFieldType(AFieldDesc: TFieldDesc; AAuxDriver: String): TFieldType;
   end;

   tConnectionItem = class(Tobject)
   protected
     foConnection: tConnection;
     foPlugin: TObject;
     FoOutput: TOutput;
     FTableNames: tStringlist;
    // FDatabase: tSDDatabase;
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
     function TableExists(aTableName: String): Boolean;
     function FieldByIndex(aTableName: String; AIndex: Integer): TFieldDesc;
     function FieldByName(aTableName: String; AFieldName: String): TFieldDesc;
     function FieldCount(aTableName: String): Integer;
     function GetFieldDesc(aDataSet: tDataSet): tFieldDesc;

     procedure CreateConnection;

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

     property oPlugin: TObject
        read foPlugin
        write foPlugin;

     property oConnection: tConnection
       read foConnection
       write foConnection;
   end;

   tConnections = class(Tobject)
   protected
   private
     foPlugins: TObject;
     foOutput: TOutput;
     fConnectionList: tNovusList;
   public
     constructor Create(aOutput: TOutput); virtual;
     destructor  Destroy; override;

     function FindConnectionName(AConnectionName: String): TConnectionItem;

     function  AddConnection(aConnectionItem: tConnectionItem): boolean;

     property oPlugins: TObject
       read foPlugins
       write foPlugins;
   end;


implementation

Uses Runtime, ProjectItem, Plugins, Plugin;

constructor tConnections.Create;
begin
  inherited Create;

  foOutput := aOutput;

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


function tConnections.AddConnection(aConnectionItem: tConnectionItem): Boolean;
var
  loPlugin: tObject;
begin
  Result := False;

  if not Assigned(aConnectionItem) then exit;

  loPlugin := (foPlugins as TPlugins).FindPlugin(aConnectionItem.DriverName);
  if Not Assigned(loPlugin) then
    begin
      foOutput.LogError('Error: Cannot find DataProcessor Plugin [' + aConnectionItem.DriverName + ']' );

      Exit;
    end;

  aConnectionItem.foPlugin := loPlugin;

  aConnectionItem.CreateConnection;

  fConnectionList.Add(aConnectionItem);



end;

// ConnectionList

constructor tConnectionItem.Create;
begin
  inherited Create;

  FoOutput := aOutput;

  FTableNames := tStringList.Create;

  //FDatabase := tSDDatabase.Create(NIL);

end;

destructor tConnectionItem.Destroy;
begin
  //FDatabase.Connected := False;

  //FDatabase.Free;

  FTableNames.Free;


  inherited Destroy;
end;

procedure tConnectionItem.CreateConnection;
Var
  lStringList: tStringList;
  I: Integer;

begin
  foConnection := (foPlugin as tDataProcessorPlugin).CreateConnection;


  (foPlugin as tDataProcessorPlugin).ApplyConnection(self, foConnection);

end;


function tConnectionItem.TableCount: Integer;
begin
  GetTableNames;

  Result := FTableNames.Count;
end;

function tConnectionItem.GetConnected: Boolean;
begin
  Result := False;


  If Not Assigned(foConnection) Then Exit;

  Try
    foConnection.Connected := True;

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
  Result := (foPlugin as TDataProcessorPlugin).GetFieldDesc(aDataSet);

  (*
  Result := TFieldDesc.Create;

  Result.TypeName := '';

  Result.FieldName := aDataSet.FieldByName('COLUMN_NAME').AsString;

  Result.TypeName := aDataSet.FieldByName('COLUMN_TYPENAME').AsString;

  Result.Precision := aDataSet.FieldByName('COLUMN_PRECISION').AsInteger;

  Result.Scale := Abs(aDataSet.FieldByName('COLUMN_SCALE').Asinteger);

  Result.Column_Length := aDataSet.FieldByName('COLUMN_LENGTH').Asinteger;



  // This need t be fixed
  //Result.TypeName := (foProjectItem as tProjectItem).oDBSchema.GetTypeName(Result, fsAuxDriver);
  *)
end;


function tConnectionItem.FieldByIndex(aTableName: String; aIndex: Integer): TFieldDesc;
Var
  I: INteger;
  cmd: TDataSet;
  FFieldDesc: TFieldDesc;
begin
  Result := (foPlugin as TDataProcessorPlugin).FieldByIndex(foConnection, aTableName, aIndex);

(*

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
   *)
end;

function tConnectionItem.FieldByName(aTableName: String; aFieldName: String): TFieldDesc;
(*
Var
  I: INteger;
  cmd: TDataSet;
  FFieldDesc: TFieldDesc;
  *)
begin
  Result := (foPlugin as TDataProcessorPlugin).FieldByName(foConnection, aTableName, aFieldName);

  (*
  Result := NIL;

  cmd := FDatabase.GetSchemaInfo(stColumns, Uppercase(ATableName));

  if Assigned( cmd ) then
    try
      If cmd.Locate('COLUMN_NAME',AFieldName, [loCaseInsensitive]) then
        Result := GetFieldDesc(Cmd);
    Finally
      Cmd.Free;
    end;
    *)
end;

function tConnectionItem.FieldCount(aTableName: String): Integer;
Var
 // I: INteger;
  cmd: TDataSet;
  //FFieldDesc: TFieldDesc;
begin


 // Result := -1;

  Result := (foPlugin as TDataProcessorPlugin).FieldCount(foConnection, aTableName);

  (*
  cmd := FDatabase.GetSchemaInfo(stColumns, Uppercase(ATableName));

  I := 0;

  if Assigned( cmd ) then
    try
      Result := cmd.RecordCount;

    Finally
      Cmd.Free;
    end; *)
end;


function tConnectionItem.GetTableNames: tStringList;
Var
  I: Integer;
begin
  FTableNames := (foPlugin as TDataProcessorPlugin).GetTableNames(foConnection, FTableNames);

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

// TConnection

constructor TConnection.Create;
begin
  foOutput := aOutput;
end;

destructor TConnection.Destroy;
begin
end;

function TConnection.GetConnected: Boolean;
begin
  Result := False;
end;


procedure TConnection.SetConnected(value: boolean);
begin
end;



end.
