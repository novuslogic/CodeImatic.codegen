unit TokenProcessor;

interface

Uses SysUtils, Classes, TagType, Output;

type
  tTokenProcessorItem = class(Tobject)
  protected
  private
    fTagType: TTagType;
    fsToken: string;
  public
    property Token: string
      read fsToken write fsToken;

    property TagType: tTagType
       read fTagType write fTagType;
  end;

   tTokenProcessor = class(TStringList)
   private
     fiTokenIndex: Integer;
     foOutput: tOutput;
   protected
   public
     constructor Create; overload;
     constructor Create(aOutput: tOutput); overload;

     function ToString: String; override;

     function GetFirstToken: string;
     function GetFirstTokenProcessorItem: tTokenProcessorItem;
     function GetNextToken(aIgnoreNextToken: Boolean = false): string; overload;
     function GetNextToken(aTokenIndex: Integer): string; overload;
     function IsNextTokenEquals: boolean;
     function IsNextTokenOpenBracket: boolean;

     function EOF: Boolean;

     property TokenIndex: Integer
         read fiTokenIndex
         write fiTokenIndex;

     property oOutput: tOutput
       read foOutput
       write foOutput;
   end;

implementation

// Token Processor
constructor tTokenProcessor.Create;
begin
  fiTokenIndex:= 0;
end;

constructor tTokenProcessor.Create(aOutput: tOutput);
begin
  fiTokenIndex:= 0;

  foOutput := aOutput;
end;

function tTokenProcessor.EOF: Boolean;
begin
  Result := (fiTokenIndex >= Count);
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


function tTokenProcessor.GetFirstToken: string;
begin
  fiTokenIndex:=0;
  if Count =0 then Exit;
  Result := Trim(Strings[fiTokenIndex]);
  Inc(fiTokenIndex);
end;




function tTokenProcessor.GetFirstTokenProcessorItem: tTokenProcessorItem;
begin
  fiTokenIndex:=0;
  if Count =0 then Exit;
  Result := tTokenProcessorItem(Objects[fiTokenIndex]);
  Inc(fiTokenIndex);
end;

function tTokenProcessor.GetNextToken(aTokenIndex: Integer): string;
begin
  Result := '';

  fiTokenINdex := aTokenIndex;

  if aTokenIndex > Count then  Exit;

  if Count > 0 then
    Result := Trim(Strings[aTokenIndex]);
end;


function tTokenProcessor.IsNextTokenEquals: boolean;
begin
  Result := GetNextToken = '=';
end;

function tTokenProcessor.IsNextTokenOpenBracket: Boolean;
begin
  Result := GetNextToken = '(';
end;

function tTokenProcessor.ToString: String;
Var
  I: Integer;
begin
  Result := '';

  for I := 0 to Self.Count -1 do
     Result := Result +Trim(Strings[i]);
end;

end.
