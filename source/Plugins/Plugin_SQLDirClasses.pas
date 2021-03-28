unit Plugin_SQLDirClasses;

interface

uses Classes,Plugin, NovusPlugin, NovusVersionUtils, Project,
    Output, SysUtils, System.Generics.Defaults,  runtime, Config,
    APIBase, NovusGUID, CodeGeneratorItem, FunctionsParser, ProjectItem,
    Variables, NovusFileUtils, SDEngine, DataProcessor, NovusSQLDirUtils, DB,
    SDCommon;


type
  TSQLDirConnection = class(TConnection)
  private
    fSDDatabase: TSDDatabase;
    fSDSession: tSDSession;
  protected
     function GetConnected: Boolean; override;
     procedure SetConnected(value: boolean); override;
  public
    constructor Create(aOutput: tOutput); override;
    destructor Destroy; override;

    property Database: TSDDatabase read fSDDatabase;
    property Session: tSDSession read fSDSession;
  end;


  tPlugin_SQLDirBase = class(TDataProcessorPlugin)
  private
  protected
  public
    constructor Create(aOutput: tOutput; aPluginName: String; aProject: TProject; aConfigPlugin: tConfigPlugin); override;
    destructor Destroy; override;

    function CreateConnection: TConnection; override;
    procedure ApplyConnection(aConnectionItem: TConnectionItem; aConnection: tConnection); override;
    function GetTableNames(aConnection: tConnection; aTableNames: tStringList): tStringList; override;
    function FieldCount(aConnection: tConnection;aTableName: String): Integer; override;
    function FieldByIndex(aConnection: tConnection; aTableName: String; AIndex: Integer): TFieldDesc; override;
    function GetFieldDesc(aDataSet: tDataSet; aAuxDriver: string): tFieldDesc; override;
    function FieldByName(aConnection: tConnection;aTableName: String; aFieldName: String): TFieldDesc; override;
  end;

  TPlugin_SQLDir = class( TSingletonImplementation, INovusPlugin, IExternalPlugin)
  private
  protected
    foProject: TProject;
    FPlugin_SQLDir: tPlugin_SQLDirBase;
  public
    function GetPluginName: string; safecall;

    procedure Initialize; safecall;
    procedure Finalize; safecall;

    property PluginName: string read GetPluginName;

    function CreatePlugin(aOutput: tOutput; aProject: Tproject; aConfigPlugin: TConfigPlugin): TPlugin; safecall;
  end;

function GetPluginObject: INovusPlugin; stdcall;

implementation

var
  _Plugin_SQLDir: TPlugin_SQLDir = nil;

constructor tPlugin_SQLDirBase.Create(aOutput: tOutput; aPluginName: String; aProject: TProject; aConfigPlugin: tConfigPlugin);
begin
  Inherited Create(aOutput,aPluginName, aProject, aConfigPlugin);
end;


destructor  tPlugin_SQLDirBase.Destroy;
Var
  I: Integer;
begin
  
  Inherited;
end;

// Plugin_SQLDir
function tPlugin_SQLDir.GetPluginName: string;
begin
  Result := 'SQLDIR';
end;

procedure tPlugin_SQLDir.Initialize;
begin
end;

function tPlugin_SQLDir.CreatePlugin(aOutput: tOutput; aProject: TProject; aConfigPlugin: TConfigPlugin): TPlugin; safecall;
begin
  foProject := aProject;

  FPlugin_SQLDir := tPlugin_SQLDirBase.Create(aOutput, GetPluginName, foProject, aConfigPlugin);

  Result := FPlugin_SQLDir;
end;


procedure tPlugin_SQLDir.Finalize;
begin
  //if Assigned(FPlugin_SQLDir) then FPlugin_SQLDir.Free;
end;

// tPlugin_SQLDirBase


function tPlugin_SQLDirBase.CreateConnection: TConnection;
begin
  Result := TSQLDirConnection.Create(foOutput);
end;

procedure tPlugin_SQLDirBase.ApplyConnection(aConnectionItem: TConnectionItem; aConnection: tConnection);
var
  lsAliasName: string;
  lsSQLLibrary: String;
  lParams: tStringList;
  I: Integer;
begin

  Try
    lParams := tStringList.Create;

    lParams.Text := aConnectionItem.Params;

    TNovusSQLDirUtils.SetupSDDatabase(TSQLDirConnection(aConnection).Database,
                     aConnectionItem.Server,
                     aConnectionItem.Database,
                     aConnectionItem.Connectionname,
                     TSDServerType(TNovusSQLDirUtils.GetServerTypeAsInteger(aConnectionItem.AuxDriver)),
                     aConnectionItem.UserID,
                     aConnectionItem.Password,
                     lParams,
                     aConnectionItem.SQLLibrary,
                     False,
                     aConnectionItem.Port);
  Finally
    lParams.Free;
  End;
end;


function tPlugin_SQLDirBase.GetTableNames(aConnection: tConnection; aTableNames: tStringList): tStringList;
begin
  Result := NIL;
  if not Assigned(aTableNames) then Exit;

  if aTableNames.Count = 0 then
     TSQLDirConnection(aConnection).Database.GetTableNames('', false,  aTableNames);

  Result := aTableNames;
end;

function tPlugin_SQLDirBase.FieldByIndex(aConnection: tConnection; aTableName: String; AIndex: Integer): TFieldDesc;
Var
  I: Integer;
  FDataSet: TDataSet;
  FFieldDesc: TFieldDesc;
begin
  result := NIL;

  FDataSet := TSQLDirConnection(aConnection).Database.GetSchemaInfo(stColumns, Uppercase(aTableName));

  I := 0;

  if Assigned( FDataSet ) then
    try
      FDataSet.First;
      While(Not FDataSet.Eof) do
        begin
          if I = AIndex then
            begin
              Result := GetFieldDesc(FDataSet, aConnection.AuxDriver);

              Break;
            end;

          Inc(I);

          FDataSet.Next;
        end;

    Finally
      FDataSet.Free;
    end;
end;

function tPlugin_SQLDirBase.GetFieldDesc(aDataSet: tDataSet; aAuxDriver: string): tFieldDesc;
begin
  Result := NIL;

  if Not Assigned(aDataSet) then Exit;

  Result := TFieldDesc.Create;

  Result.TypeName := '';

  Result.FieldName := aDataSet.FieldByName('COLUMN_NAME').AsString;

  Result.TypeName := aDataSet.FieldByName('COLUMN_TYPENAME').AsString;

  Result.Precision := aDataSet.FieldByName('COLUMN_PRECISION').AsInteger;

  Result.Scale := Abs(aDataSet.FieldByName('COLUMN_SCALE').Asinteger);

  Result.Column_Length := aDataSet.FieldByName('COLUMN_LENGTH').Asinteger;

  Result.TypeName := oDBSchema.GetTypeName(Result, aAuxDriver);
end;

function tPlugin_SQLDirBase.FieldByName(aConnection: tConnection;aTableName: String; aFieldName: String): TFieldDesc;
Var
  FDataSet: TDataSet;
  FFieldDesc: TFieldDesc;
begin
  Result := NIL;

  FDataSet := TSQLDirConnection(aConnection).Database.GetSchemaInfo(stColumns, Uppercase(ATableName));

  if Assigned( FDataSet ) then
    try
      If FDataSet.Locate('COLUMN_NAME',AFieldName, [loCaseInsensitive]) then
        Result := GetFieldDesc(FDataSet, aConnection.AuxDriver);
    Finally
      FDataSet.Free;
    end;
end;


function tPlugin_SQLDirBase.FieldCount(aConnection: tConnection;aTableName: String): Integer;
Var
  FDataSet: TDataSet;
begin
  Result := -1;

  FDataSet := TSQLDirConnection(aConnection).Database.GetSchemaInfo(stColumns, Uppercase(ATableName));


  if Assigned( FDataSet) then
    try
      Result := FDataSet.RecordCount;

    Finally
      FDataSet.Free;
    end;

end;


// TSQLDirConnection

function  TSQLDirConnection.GetConnected: Boolean;
begin
  result := fSDDatabase.Connected;
end;


procedure  TSQLDirConnection.SetConnected(value: boolean);
begin
  Try
    fSDDatabase.Connected := Value;
  Except
    foOutput.WriteExceptLog;

  End;
end;

constructor TSQLDirConnection.Create(aOutput: tOutput);
begin
  Inherited create(aOutput);

  fSDSession := tSDSession.Create(NIL);

  fSDSession.AutoSessionName := True;

  fSDDatabase := TSDDatabase.Create(NIL);

  fSDDatabase.SessionName := fSDSession.SessionName;
end;

destructor TSQLDirConnection.Destroy;
begin
  If Assigned(fSDDatabase) then fSDDatabase.Free;
  If Assigned(fSDSession) then fSDSession.Free;
end;


function GetPluginObject: INovusPlugin;
begin
  if (_Plugin_SQLDir = nil) then _Plugin_SQLDir := TPlugin_SQLDir.Create;
  result := _Plugin_SQLDir;
end;

exports
  GetPluginObject name func_GetPluginObject;

initialization
  begin
    _Plugin_SQLDir := nil;
  end;

finalization
  FreeAndNIL(_Plugin_SQLDir);

end.


