unit FieldFunctionParser;

interface

Uses TokenParser, TagParser, TagType, DataProcessor, ProjectItem, TokenProcessor;

Type
   TOnExecute = procedure(var aToken: String; aConnectionItem: tConnectionItem; aTableName: string; aTokenParser: tTokenParser) of object;

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
  FsTableName: String;
  FFieldIndex: Integer;
  LStr: String;
  FFieldType: tFieldType;
  LsToken: string;
begin
  Result := '';

  If  ParseNextToken = '(' then
  begin
    FConnectionName := ParseNextToken;

    foConnectionItem := oCodeGeneratorItem.oProject.oProjectConfig.oConnections.FindConnectionName(FConnectionName);

    if Assigned(foConnectionItem) then
    begin
      if foConnectionItem.Connected then
      begin
        FsTableName := ParseNextToken;

        If foConnectionItem.TableExists(FsTableName) then
        begin
          if Assigned(OnExecute) then
            OnExecute(result, foConnectionItem , FsTableName, Self);
        end
        else
        begin
          oOutput.LogError('Error: Table cannot be found "' + FsTableName + '"');
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
