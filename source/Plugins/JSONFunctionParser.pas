unit JSONFunctionParser;


interface

Uses TokenParser, TagParser, TagType, DataProcessor, ProjectItem, TokenProcessor, SysUtils;

Type
   TOnExecute = procedure(var aToken: String; aTokenParser: tTokenParser; aJSONFilename: String) of object;

   TJSONFunctionParser = class(tTokenParser)
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

function TJSONFunctionParser.Execute: string;
Var
  FFieldDesc: tFieldDesc;
  FsJSONFilename: String;
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
    FsJSONFilename := ParseNextToken;

    if FileExists(FsJSONFilename) then
    begin
      LsToken := '';
      if Assigned(OnExecute) then
        OnExecute(LsToken, self, FsJSONFilename);

      if ParseNextToken = ')' then
         begin
           Result := LsToken;
           Exit;
          end
         else
            oOutput.LogError('Incorrect syntax: lack ")"');


    end
  end
   else
    oOutput.Log('Incorrect syntax: lack "("');
end;

end.
