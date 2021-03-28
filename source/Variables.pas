unit Variables;

interface

Uses Variants, NovusList, SysUtils, Output, NovusGUID, NovusStringUtils, TagType;

Type
  TVariable = class(TObject)
  protected
     fbIsDestroy: Boolean;
     fsVariableName: String;
     FValue: Variant;
     FoObject: tObject;
  private
    function GetIsVarEmpty: boolean;
    function GetIsLinked: Boolean;
    function GetIsObject: Boolean;
    function GetIsNumeric: Boolean;
    function GetIsString: Boolean;
  public
    constructor Create; virtual;
    destructor Destroy; override;

    property VariableName: String
      read fsVariableName
      write fsVariableName;

    property oObject: Tobject
      read foObject
      write foObject;

    property Value: Variant
      read FValue
      Write FValue;

    function AsString: String;

    property  IsLinked: Boolean
      read GetIsLinked;

    property IsNumeric: Boolean
      read GetIsNumeric;

    property  IsObject: Boolean
      read GetIsObject;

    property IsVarEmpty: Boolean
      read GetIsVarEmpty;

    property IsString: Boolean
      read GetIsString;

    property IsDestroy: boolean
      read fbIsDestroy
      write fbIsDestroy;
  end;

  TVariables = class(TObject)
  protected
    foOutput: tOutput;
    foVariableList: tNovusList;
    function GetCount: Integer;
  private
  public
    constructor Create(aOutput: tOutput); virtual;
    destructor Destroy; override;

    procedure ClearVariables;

    function AddVariableObject(AVariableName: String; aObject: Tobject; aIsDestroy: boolean): String;
    function AddVariable(AVariableName: String;AValue: Variant): tVariable;
    function GetVariableByName(aVariableName: String): TVariable;
    function VariableExists(aVariableName: String): boolean;

    class function IsVariableType(aVariableName: String): tTagType;

    class function CleanVariableName(AVariableName: String): String;

    property oVariableList: tNovusList
      read foVariableList
      write foVariableList;


    property Count: Integer
       read GetCount;
  end;


implementation

// TVariables

constructor TVariables.Create;
begin
  inherited Create;
  foOutput := aOutput;

  foVariableList := tNovusList.Create(TVariable);

  foVariableList.InSensitiveKey := true;
end;

destructor TVariables.Destroy;
begin
  foVariableList.Free;

  inherited;
end;

procedure TVariables.ClearVariables;
begin
  foVariableList.Clear;
end;


function TVariables.AddVariableObject(AVariableName: String; aObject: Tobject; aIsDestroy: boolean): String;
Var
  foVariable: TVariable;
begin
  foVariable := TVariable.Create;

  foVariable.VariableName := '@@' + TNovusGuid.NewGuidNoBracketsString + '.' + AVariableName;

  if AVariableName = '' then
    foVariable.Value := 'TObject'
  else
    foVariable.Value := AVariableName;

  foVariable.oObject := aObject;

  foVariable.IsDestroy := aIsDestroy;

  FoVariableList.Add(foVariable.VariableName, foVariable);

  Result := foVariable.VariableName;
end;


function TVariables.AddVariable(AVariableName: String;AValue: Variant): tVariable;
Var
  foVariable: TVariable;
begin
  foVariable := TVariable.Create;

  foVariable.VariableName := AVarIableName;

  foVariable.Value := AValue;

  FoVariableList.Add(AVariableName, foVariable);

  Result := foVariable;
end;



function TVariables.VariableExists(aVariableName: String): boolean;
begin
  Result := (GetVariableByName(aVariableName) <> NIL);
end;

function TVariables.GetVariableByName(aVariableName: String): TVariable;
Var
  liIndex: Integer;
  FObject: tObject;
begin
  Result := Nil;

  aVariableName := CleanVariableName(aVariableName);

  FObject := FoVariableList.FindItem(aVariableName);
  if Not Assigned(FObject) then Exit;
  Result := (FObject as TVariable);
end;

class function TVariables.IsVariableType(aVariableName: String): tTagType;
begin
  Result := ttUnknown;
  if Pos('$$', aVariableName) = 1 then
      result := ttPropertyVariable
    else if Pos('$', aVariableName) = 1 then
       result := ttVariable
end;


class function TVariables.CleanVariableName(AVariableName: String): String;
begin
  If Copy(AVariableName, 1, 2) = '$$' then
    result := Copy(AVariableName, 3, Length(AVariableName))
  else
  If Copy(AVariableName, 1, 1) = '$' then
    Result := Copy(AVariableName, 2, Length(AVariableName))
  else
    Result := Trim(AVariableName);
end;

function TVariables.GetCount: integer;
begin
  Result := foVariableList.Count;
end;


//  TVariable
constructor TVariable.Create;
begin
  inherited Create;

  //FObject := NIL;
end;

destructor TVariable.Destroy;
begin
//  if Assigned(fObject) then FObject.Free;
  
  inherited;
end;

function TVariable.AsString: String;
begin
  Result := VartoStr(FValue);
end;

function TVariable.GetIsLinked: Boolean;
begin
  Result := False;
  if Copy(AsString, 1, 2) = '@@' then Result := true;
end;

function TVariable.GetIsObject: Boolean;
begin
  Result := False;
  if Copy(fsVariableName, 1, 2) = '@@' then
     Result := true;
end;

function TVariable.GetIsNumeric: Boolean;
begin
  Result := False;
  if Not IsObject then
    Result :=  TNovusStringUtils.IsNumeric(AsString)
end;


function TVariable.GetIsString: Boolean;
begin
  Result := False;
  if Not IsObject then
    Result := (VarType(FValue) = varUString);
end;

function TVariable.GetIsVarEmpty:Boolean;
begin
  Result := False;

  if IsObject then
    begin
      If oObject = NIL then
        begin
          Result := true;
        end;
    end
  else
    if VarIsNull(FValue) then Result := True;
end;





end.
