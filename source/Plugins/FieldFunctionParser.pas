unit FieldFunctionParser;

interface

Uses TokenParser, TagParser, TagType, DataProcessor, ProjectItem;

Type
   TOnExecute = procedure(var aToken: String) of object;

   TFieldFunctionParser = class(tTokenParser)
   private
   protected
     foConnectionItem: tConnectionItem;
   public
     OnExecute: TOnExecute;
     function Execute: String;

     property oConnectionItem: tConnectionItem
       read foConnectionItem
       write foConnectionItem;
   end;

implementation

function TFieldFunctionParser.Execute: string;
Var

  FFieldDesc: tFieldDesc;

  FConnectionName: String;
  FTableName: String;
  FFieldIndex: Integer;
  LStr: String;
  FFieldType: tFieldType;
  LsToken: string;
begin
  Result := '';

  If GetNextToken = '(' then
  begin
    FConnectionName := GetNextToken;

    foConnectionItem := oCodeGeneratorItem.oProject.oProjectConfig.oConnections.FindConnectionName(FConnectionName);

    if Assigned(foConnectionItem) then
    begin
      if foConnectionItem.Connected then
      begin
        FTableName := GetNextToken;

        If foConnectionItem.TableExists(FTableName) then
        begin
          if Assigned(OnExecute) then
            OnExecute(result);
        end
        else
        begin
          oOutput.LogError('Error: Table cannot be found "' + FTableName + '"');
        end;

      end
      else
      begin
        oOutput.LogError('Error: Connectioname "' + FConnectionName +
          '" connected.');
      end;
    end
    else
    begin
      oOutput.LogError('Error: Connectioname cannot be found "' +
        FConnectionName + '"');
    end;
  end
  else
  begin
    oOutput.Log('Incorrect syntax: lack "("');

  end;
end;

end.
