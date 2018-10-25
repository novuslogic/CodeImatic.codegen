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
     function Execute: String;

     property oConnectionItem: tConnectionItem
       read foConnectionItem
       write foConnectionItem;
   end;

implementation

function TTableFunctionParser.Execute: string;
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

  if fsTagName = oCodeGeneratorItem.oTokens.Strings[TokenIndex] then
     foCodeGeneratorItem.TokenIndex := foCodeGeneratorItem.TokenIndex + 1;

  If  ParseNextToken = '(' then
  begin
    FConnectionName := ParseNextToken;

    foConnectionItem := oCodeGeneratorItem.oProject.oProjectConfig.oConnections.FindConnectionName(FConnectionName);

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
          oOutput.LogError('Incorrect syntax: lack ")"');
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
