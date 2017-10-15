unit TokenProcessor;

interface

Uses SysUtils, Classes;

type
   tTokenProcessor = class(TStringList)
   private
     fiTokenIndex: Integer;
   protected
   public
     constructor Create; overload;
     function GetNextToken(aIgnoreNextToken: Boolean = false): string;
     function IsNextTokenEquals: boolean;

     property TokenIndex: Integer
         read fiTokenIndex
         write fiTokenIndex;
   end;

implementation

// Token Processor
constructor tTokenProcessor.Create;
begin
  fiTokenIndex:= 0;
end;

function tTokenProcessor.GetNextToken(aIgnoreNextToken: Boolean): String;
begin
  Result := '';

  if fiTokenIndex > Count then  Exit;

  if Count > 0 then
    Result := Trim(Strings[fiTokenIndex]);

  if Not aIgnoreNextToken then
    begin
      Inc(fiTokenIndex);
    end;


end;

function tTokenProcessor.IsNextTokenEquals: boolean;
begin
 Result := GetNextToken = '=';
end;

end.
