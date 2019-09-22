unit TableFunctionParser;

interface

Uses TokenParser, TagParser, TagType, DataProcessor, ProjectItem, TokenProcessor;

Type
   TOnExecute = procedure(var aToken: String; aConnectionItem: tConnectionItem; aTableName: string; aTokenParser: tTokenParser) of object;

   TTableFunctionParser = class(tTokenParser)
   private
   protected
     foConnectionItem: tConnectionItem;
   public
     OnExecute: TOnExecute;
     function Execute(aProjectItem: TProjectItem): String;

     property oConnectionItem: tConnectionItem
       read foConnectionItem
       write foConnectionItem;
   end;

implementation

function TTableFunctionParser.Execute(aProjectItem: TProjectItem): string;
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

  if fsTagName = oTokens.Strings[TokenIndex] then
     oTokens.TokenIndex := oTokens.TokenIndex + 1;

  If  ParseNextToken = '(' then
  begin
    FConnectionName := ParseNextToken;

    foConnectionItem := aProjectItem.oProject.oProjectConfigLoader.oConnections.FindConnectionName(FConnectionName);

    if Assigned(foConnectionItem) then
    begin
      if foConnectionItem.Connected then
      begin
        if Assigned(OnExecute) then
            OnExecute(LsToken, foConnectionItem , FsTableName, Self);

        if ParseNextToken = ')' then
          begin
            Result := LsToken;
            Exit;
          end
        else
          oOutput.LogError('Syntax Error: lack ")"');
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
    oOutput.LogError('Syntax Error: lack "("');

  end;
end;

end.
