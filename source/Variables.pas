unit Variables;

interface

Uses Variants, NovusList, SysUtils;

Type
  TVariable = class(TObject)
  protected
     fsVariableName: String;
     FValue: Variant;
  private
  public
    property VariableName: String
      read fsVariableName
      write fsVariableName;

    property Value: Variant
      read FValue
      Write FValue;

    function AsString: String;
  end;

  TVariables = class(TObject)
  protected
    fVariableList: tNovusList;
  private
  public
    constructor Create; virtual;
    destructor Destroy; override;

    procedure AddVariable(AVariableName: String;AValue: Variant);
    function VariableExistsIndex(AVariableName: String): Integer;
    function GetVariableByIndex(AIndex: Integer): TVariable;
  end;


implementation

// TVariables

constructor TVariables.Create;
begin
  inherited Create;

  fVariableList := tNovusList.Create(TVariable);
end;

destructor TVariables.Destroy;
begin
  fVariableList.Free;

  inherited;
end;


procedure TVariables.AddVariable(AVariableName: String;AValue: Variant);
Var
  FVariable: TVariable;
begin
  FVariable := TVariable.Create;

  FVariable.VariableName := AVarIableName;

  FVariable.Value := AValue;

  FVariableList.Add(FVariable);
end;


function TVariables.VariableExistsIndex(AVariableName: String): Integer;
Var
  I: Integer;
  FVariable: TVariable;
begin
  Result := -1;

  for I := 0 to fVariableList.Count - 1 do
    begin
      FVariable := TVariable(fVariableList.Items[i]);

      if Uppercase(FVariable.VariableName) = Uppercase(AVariableName) then
        begin
          Result := i;

          break;
        end;
    end;
end;

function TVariables.GetVariableByIndex(AIndex: Integer): TVariable;
begin
  Try
    Result := TVariable(fVariableList.Items[AIndex]);
  Except
    Result := NIL;
  End;
end;

//  TVariable
function TVariable.AsString: String;
begin
  Result := VartoStr(FValue);
end;


end.
