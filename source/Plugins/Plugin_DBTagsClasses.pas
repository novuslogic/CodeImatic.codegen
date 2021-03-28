unit Plugin_DBTagsClasses;

interface

uses Classes,Plugin, NovusPlugin, NovusVersionUtils, Project,
    Output, SysUtils, System.Generics.Defaults,  runtime, Config, NovusStringUtils,
    APIBase, NovusGUID, CodeGeneratorItem, FunctionsParser, ProjectItem, TokenParser,
    Variables, NovusFileUtils, CodeGenerator, FieldFunctionParser, DataProcessor,
    TableFunctionParser, TokenProcessor, TagBasePlugin;


type
  TDBTag = class(tTagBasePlugin)
  private
  protected
  public
  end;

  TDBTag_FieldCount = class(TDBTag)
  private
  protected
    function GetTagName: String; override;
    procedure OnExecute(var aToken: String; aConnectionItem: tConnectionItem; aTableName: string; aTokenParser: tTokenParser);
  public
    function Execute(aProjectItem: tProjectItem;aTagName: string;aTokens: TTokenProcessor): String; override;
  end;

  TDBTag_FieldAsSQL = class(TDBTag)
  private
  protected
    function GetTagName: String; override;
    procedure OnExecute(var aToken: String; aConnectionItem: tConnectionItem; aTableName: string; aTokenParser: tTokenParser);
  public
    function Execute(aProjectItem: tProjectItem;aTagName: string;aTokens: TTokenProcessor): String; override;
  end;

  TDBTag_FieldNameByIndex = class(TDBTag)
  private
  protected
    function GetTagName: String; override;
    procedure OnExecute(var aToken: String; aConnectionItem: tConnectionItem; aTableName: string; aTokenParser: tTokenParser);
  public
    function Execute(aProjectItem: tProjectItem;aTagName: string;aTokens: TTokenProcessor): String; override;
  end;

  TDBTag_TableCount = class(TDBTag)
  private
  protected
    function GetTagName: String; override;
    procedure OnExecute(var aToken: String; aConnectionItem: tConnectionItem; aTableName: string; aTokenParser: tTokenParser);
  public
    function Execute(aProjectItem: tProjectItem;aTagName: string;aTokens: TTokenProcessor): String; override;
  end;

  TDBTag_Tablenamebyindex = class(TDBTag)
  private
  protected
    function GetTagName: String; override;
    procedure OnExecute(var aToken: String; aConnectionItem: tConnectionItem; aTableName: string; aTokenParser: tTokenParser);
  public
    function Execute(aProjectItem: tProjectItem;aTagName: string;aTokens: TTokenProcessor): String; override;
  end;

  TDBTag_FieldTypeByIndex = class(TDBTag)
  private
  protected
    function GetTagName: String; override;
    procedure OnExecute(var aToken: String; aConnectionItem: tConnectionItem; aTableName: string; aTokenParser: tTokenParser);
  public
    function Execute(aProjectItem: tProjectItem;aTagName: string;aTokens: TTokenProcessor): String; override;
  end;

  tDBTags = array of TDBTag;

  tPlugin_DBTagsBase = class(TTagsPlugin)
  private
  protected
    FDBTags: tDBTags;
  public
    constructor Create(aOutput: tOutput; aPluginName: String; aProject: TProject; aConfigPlugin: tConfigPlugin); override;
    destructor Destroy; override;

    function GetTag(aTagName: String; aTokens: TTokenProcessor; aProjectItem: TObject): String; override;
    function IsTagExists(aTagName: String): Integer; override;

  end;

  TPlugin_DBTags = class( TSingletonImplementation, INovusPlugin, IExternalPlugin)
  private
  protected
    foProject: TProject;
    FPlugin_DBTags: tPlugin_DBTagsBase;
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
  _Plugin_DBTags: TPlugin_DBTags = nil;

constructor tPlugin_DBTagsBase.Create(aOutput: tOutput; aPluginName: String; aProject: TProject; aConfigPlugin: tConfigPlugin);
begin
  Inherited Create(aOutput,aPluginName, aProject, aConfigPlugin);

  FDBTags:= tDBTags.Create(TDBTag_FieldCount.Create(aOutput),
        TDBTag_FieldNameByIndex.Create(aOutput),
        TDBTag_FieldTypeByIndex.Create(aOutput),
        TDBTag_TableCount.Create(aOutput),
        TDBTag_Tablenamebyindex.Create(aOutput),
        TDBTag_FieldAsSQL.Create(aOutput)) ;
end;


destructor  tPlugin_DBTagsBase.Destroy;
Var
  I: Integer;
begin
  for I := 0 to Length(FDBTags) -1 do
   begin
     FDBTags[i].Free;
     FDBTags[i] := NIL;
   end;

  FDBTags := NIL;
  Inherited;
end;

// Plugin_DBTags
function tPlugin_DBTags.GetPluginName: string;
begin
  Result := 'DB';
end;

procedure tPlugin_DBTags.Initialize;
begin
end;

function tPlugin_DBTags.CreatePlugin(aOutput: tOutput; aProject: TProject; aConfigPlugin: TConfigPlugin): TPlugin; safecall;
begin
  foProject := aProject;

  FPlugin_DBTags := tPlugin_DBTagsBase.Create(aOutput, GetPluginName, foProject, aConfigPlugin);

  Result := FPlugin_DBTags;
end;


procedure tPlugin_DBTags.Finalize;
begin
  //if Assigned(FPlugin_DBTags) then FPlugin_DBTags.Free;
end;

// tPlugin_DBTagsBase
function tPlugin_DBTagsBase.GetTag(aTagName: String; aTokens: TTokenProcessor; aProjectItem: TObject): String;
Var
  liIndex: Integer;
begin
  Result := '';
  liIndex := IsTagExists(aTagName);
  if liIndex = -1 then
   begin
     oOutput.LogError('Cannot find db.' + aTagname);

     Exit;
   end;

  Result := FDBTags[liIndex].Execute((aProjectItem as tProjectItem), aTagName, aTokens);
end;

function tPlugin_DBTagsBase.IsTagExists(aTagName: String): Integer;
Var
  I: Integer;
begin
  Result := -1;
  if aTagName = '' then Exit;

  for I := 0 to Length(FDBTags) -1 do
   begin
     if Uppercase(Trim(aTagName)) = Uppercase(Trim(FDBTags[i].TagName)) then
       begin
         Result := i;

         Break;
       end;
   end;
end;


function GetPluginObject: INovusPlugin;
begin
  if (_Plugin_DBTags = nil) then _Plugin_DBTags := TPlugin_DBTags.Create;
  result := _Plugin_DBTags;
end;

//  TDBTag_FieldCount
function TDBTag_FieldCount.GetTagName: String;
begin
  Result := 'FIELDCOUNT';
end;

procedure TDBTag_FieldCount.OnExecute(var aToken: String; aConnectionItem: tConnectionItem; aTableName: string; aTokenParser: tTokenParser);
begin
  aToken := IntToStr(aConnectionItem.FieldCount(aTableName));
end;


function TDBTag_FieldCount.Execute(aProjectItem: tProjectItem;aTagName: string;aTokens: TTokenProcessor): String;
var
  LFieldFunctionParser: tFieldFunctionParser;
begin

  Try
    Try
      LFieldFunctionParser:= tFieldFunctionParser.Create(aProjectItem, aTokens, oOutput, aTagName);

      LFieldFunctionParser.OnExecute := OnExecute;

      Result := LFieldFunctionParser.Execute(aProjectItem);
    Finally
      LFieldFunctionParser.Free;
    End;
  Except
    oOutput.InternalError;
  End;
end;

//  TDBTag_FieldNameByIndex
function TDBTag_FieldNameByIndex.GetTagName: String;
begin
  Result := 'FIELDNAMEBYINDEX';
end;

procedure TDBTag_FieldNameByIndex.OnExecute(var aToken: String; aConnectionItem: tConnectionItem; aTableName: string;aTokenParser: tTokenParser);
Var
  lsToken: String;
  liFieldIndex: Integer;
  lFieldDesc: tFieldDesc;
begin
  lsToken := aTokenParser.ParseNextToken;

  if TNovusStringUtils.IsNumeric(lsToken) then
  begin
    liFieldIndex := StrToint(lsToken);

    lFieldDesc := aConnectionItem.FieldByIndex(aTableName, liFieldIndex);

    if Assigned(lFieldDesc) then
    begin
      if aTokenParser.ParseNextToken = ')' then
        begin
          aToken := lFieldDesc.FieldName;


        end;

    end
    else
      oOutput.LogError('Syntax Error: lack ")"');
  end
  else
    oOutput.LogError('Error: Field cannot be found.');

  if Assigned(lFieldDesc) then
     lFieldDesc.Free;

end;


function TDBTag_FieldNameByIndex.Execute(aProjectItem: tProjectItem;aTagName: String;aTokens: TTokenProcessor): String;
var
  LFieldFunctionParser: tFieldFunctionParser;
begin
  Try
    Try
      LFieldFunctionParser:= tFieldFunctionParser.Create(aProjectItem,aTokens, oOutput, aTagName);


      LFieldFunctionParser.OnExecute := OnExecute;

      Result := LFieldFunctionParser.Execute(aProjectItem);
    Finally
      LFieldFunctionParser.Free;
    End;
  Except
    oOutput.InternalError;
  End;
end;

// TDBTag_TableCount
function TDBTag_TableCount.GetTagName: String;
begin
  Result := 'TABLECOUNT';
end;

procedure TDBTag_TableCount.OnExecute(var aToken: String; aConnectionItem: tConnectionItem; aTableName: string;aTokenParser: tTokenParser);
Var
  FFieldType: tFieldType;
  FFieldDesc: tFieldDesc;
  lsToken: String;
  liFieldIndex: Integer;
  lFieldDesc: tFieldDesc;
begin
  aToken := IntToStr(aConnectionItem.TableCount);
end;


function TDBTag_TableCount.Execute(aProjectItem: tProjectItem;aTagName: string;aTokens: TTokenProcessor): String;
var
  LTableFunctionParser: tTableFunctionParser;
begin
  Try
    Try
      LTableFunctionParser:= tTableFunctionParser.Create(aProjectItem,aTokens, oOutput, aTagName);


      LTableFunctionParser.OnExecute := OnExecute;

      Result := LTableFunctionParser.Execute(aProjectItem);
    Finally
      LTableFunctionParser.Free;
    End;
  Except
    oOutput.InternalError;
  End;
end;

// TDBTag_FieldAsSQL
function TDBTag_FieldAsSQL.GetTagName: String;
begin
  Result := 'FIELDASSQL';
end;

procedure TDBTag_FieldAsSQL.OnExecute(var aToken: String; aConnectionItem: tConnectionItem; aTableName: string;aTokenParser: tTokenParser);
Var
  lsToken: String;
  liTableIndex: Integer;
  FFieldIndex: Integer;
  FFieldType: tFieldType;
  FFieldDesc: tFieldDesc;
begin
   lsToken := aTokenParser.ParseNextToken;

   FFieldDesc := aConnectionItem.FieldByName(aTableName, lsToken);

   if Assigned(FFieldDesc) then
      begin
        FFieldType := aConnectionItem.oDBSchema.GetFieldType(FFieldDesc,
            aConnectionItem.AuxDriver);

          if FFieldType.SQLFormat = '' then
            aToken := FFieldDesc.FieldName + ' ' + FFieldType.SqlType
          else
            aToken := FFieldDesc.FieldName + ' ' +
              Format(FFieldType.SQLFormat, [FFieldDesc.Column_Length]);

        FFieldType.Free;
        FFieldDesc.Free;


      end
        else
          oOutput.LogError('Error: Field cannot be found.');
end;


function TDBTag_FieldAsSQL.Execute(aProjectItem: tProjectItem;aTagName: string;aTokens: TTokenProcessor): String;
var
  LFieldFunctionParser: tFieldFunctionParser;
begin
  Try
    Try
      LFieldFunctionParser:= tFieldFunctionParser.Create(aProjectItem,aTokens, oOutput, aTagName);


      LFieldFunctionParser.OnExecute := OnExecute;

      Result := LFieldFunctionParser.Execute(aProjectItem);
    Finally
      LFieldFunctionParser.Free;
    End;
  Except
    oOutput.InternalError;
  End;
end;



// TDBTag_Tablenamebyindex
function TDBTag_Tablenamebyindex.GetTagName: String;
begin
  Result := 'TABLENAMEBYINDEX';
end;

procedure TDBTag_Tablenamebyindex.OnExecute(var aToken: String; aConnectionItem: tConnectionItem; aTableName: string;aTokenParser: tTokenParser);
Var
  lsToken: String;
  liTableIndex: Integer;
begin
  lsToken := aTokenParser.ParseNextToken;

  if TNovusStringUtils.IsNumeric(lsToken) then
     begin
       liTableIndex := StrToint(lsToken);

       if aConnectionItem.TableCount > 0 then
         aToken := aConnectionItem.JustTableNamebyIndex(liTableIndex)
       else
         oOutput.LogError('Error: Tablename cannot be found.');

     end
       else
         oOutput.LogError('Syntax Error: Index is not a number ');
end;


function TDBTag_Tablenamebyindex.Execute(aProjectItem: tProjectItem;aTagName: string;aTokens: TTokenProcessor): String;
var
  LTableFunctionParser: tTableFunctionParser;
begin
  Try
    Try
      LTableFunctionParser:= tTableFunctionParser.Create(aProjectItem,aTokens, oOutput, aTagName);


      LTableFunctionParser.OnExecute := OnExecute;

      Result := LTableFunctionParser.Execute(aProjectItem);
    Finally
      LTableFunctionParser.Free;
    End;
  Except
    oOutput.InternalError;
  End;
end;

//  TDBTag_FieldTypeByIndex
function TDBTag_FieldTypeByIndex.GetTagName: String;
begin
  Result := 'FIELDTYPEBYINDEX';
end;

procedure TDBTag_FieldTypeByIndex.OnExecute(var aToken: String; aConnectionItem: tConnectionItem; aTableName: string;aTokenParser: tTokenParser);
Var
  FFieldType: tFieldType;
  FFieldDesc: tFieldDesc;
  lsToken: String;
  liFieldIndex: Integer;
  lFieldDesc: tFieldDesc;
begin
  lsToken := aTokenParser.ParseNextToken;

  if TNovusStringUtils.IsNumeric(lsToken) then
  begin
    liFieldIndex := StrToint(lsToken);

    lFieldDesc := aConnectionItem.FieldByIndex(aTableName, liFieldIndex);

    if Assigned(lFieldDesc) then
    begin
      if aTokenParser.ParseNextToken = ')' then
        begin
          Try
            FFieldType := aConnectionItem.oDBSchema.GetFieldType
                                (lFieldDesc, aConnectionItem.AuxDriver);



            if FFieldType.SQLFormat = '' then
              aToken := FFieldType.SqlType
            else
              aToken := Format(FFieldType.SQLFormat, [lFieldDesc.Column_Length]);


           Finally
             FFieldType.Free;
           End;


        end;

    end
    else
      oOutput.LogError('Syntax Error: lack ")"');
  end
  else
    oOutput.LogError('Error: Field cannot be found.');

  if Assigned(lFieldDesc) then
     lFieldDesc.Free;
end;


function TDBTag_FieldTypeByIndex.Execute(aProjectItem: tProjectItem;aTagName: string;aTokens: TTokenProcessor): String;
var
  LFieldFunctionParser: tFieldFunctionParser;
begin
  Try
    Try
      LFieldFunctionParser:= tFieldFunctionParser.Create(aProjectItem, aTokens, oOutput, ATagName);

      LFieldFunctionParser.OnExecute := OnExecute;

      Result := LFieldFunctionParser.Execute(aProjectItem);
    Finally
      LFieldFunctionParser.Free;
    End;
  Except
    oOutput.InternalError;
  End;
end;





exports
  GetPluginObject name func_GetPluginObject;

initialization
  begin
    _Plugin_DBTags := nil;
  end;

finalization
  FreeAndNIL(_Plugin_DBTags);

end.
