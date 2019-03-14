unit Variables;

interface

Uses Variants, NovusList, SysUtils, Output, NovusGUIDEx, NovusStringUtils;

Type
  TVariable = class(TObject)
  protected
     fsVariableName: String;
     FValue: Variant;
     FObject: tObject;
  private
    function GetIsVarEmpty: boolean;
    function GetIsLinked: Boolean;
    function GetIsObject: Boolean;
    function GetIsNumeric: Boolean;
  public
    constructor Create; virtual;
    destructor Destroy; override;

    property VariableName: String
      read fsVariableName
      write fsVariableName;

    property oObject: Tobject
      read fObject
      write fObject;

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

    function AddVariableObject(aObject: Tobject; aObjectTypeName: String = ''): String;
    procedure AddVariable(AVariableName: String;AValue: Variant);
    //function VariableExistsIndex(AVariableName: String): Integer;
   // function GetVariableByIndex(AIndex: Integer): TVariable;
    function GetVariableByName(aVariableName: String): TVariable;
    function VariableExists(aVariableName: String): boolean;

    class function CleanVariableName(AVariableName: String): String;
    class function IsVariable(AVariableName: String): Boolean;

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
end;

destructor TVariables.Destroy;
begin
  foVariableList.Free;

  inherited;
end;


function TVariables.AddVariableObject(aObject: Tobject; aObjectTypeName: string): String;
Var
  foVariable: TVariable;
begin
  foVariable := TVariable.Create;

  foVariable.VariableName := '@@' + TGuidExUtils.NewGuidNoBracketsString + '.' + aObjectTypeName;

  if aObjectTypeName = '' then
    foVariable.Value := 'TObject'
  else
    foVariable.Value := aObjectTypeName;

  foVariable.oObject := aObject;

  FoVariableList.Add(foVariable.VariableName, foVariable);

  Result := foVariable.VariableName;
end;


procedure TVariables.AddVariable(AVariableName: String;AValue: Variant);
Var
  foVariable: TVariable;
begin
  foVariable := TVariable.Create;

  foVariable.VariableName := AVarIableName;

  foVariable.Value := AValue;

  FoVariableList.Add(AVariableName, foVariable);
end;


(*
function TVariables.VariableExistsIndex(AVariableName: String): Integer;
Var
  I: Integer;
  foVariable: TVariable;
begin
  Result := -1;

  for I := 0 to foVariableList.Count - 1 do
    begin
      foVariable := TVariable(foVariableList.Items[i]);

      if Uppercase(foVariable.VariableName) = Uppercase(AVariableName) then
        begin
          Result := i;

          break;
        end;
    end;
end;
*)

(*
function TVariables.GetVariableByIndex(AIndex: Integer): TVariable;
begin
  Try
    Result := TVariable(foVariableList.Items[AIndex]);
  Except
    Result := NIL;
  End;
end;
*)


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

class function TVariables.IsVariable(AVariableName: String): Boolean;
begin
  Result := Copy(AVariableName, 1, 1) = '$';
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

  FObject := NIL;
end;

destructor TVariable.Destroy;
begin
  if Assigned(fObject) then FObject.Free;
  
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
    Result :=  TNovusStringUtils.IsNumberStr(AsString)
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
