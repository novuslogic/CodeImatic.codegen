unit FileExistsFunctionParser;


interface

Uses TokenParser, TagParser, TagType, DataProcessor, ProjectItem, TokenProcessor, SysUtils;

Type
   TOnExecute = procedure(var aToken: String; aTokenParser: tTokenParser; aFilename: String) of object;

   TFileExistsFunctionParser = class(tTokenParser)
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

function TFileExistsFunctionParser.Execute: string;
Var
  FFieldDesc: tFieldDesc;
  FsFilename: String;
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
    FsFilename := ParseNextToken;

    if FileExists(FsFilename) then
    begin
      LsToken := '';
      if Assigned(OnExecute) then
        OnExecute(LsToken, self, FsFilename);

      if ParseNextToken = ')' then
         begin
           Result := LsToken;
           Exit;
          end
         else
            oOutput.LogError('Syntax Error: lack ")"');


     end
    else
      oOutput.LogError('Syntax Error: Cannot find filename [' + FsFilename +']');
  end
   else
     oOutput.LogError('Syntax Error: lack "("');
end;

end.
