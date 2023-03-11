unit TokenProcessor;

interface

Uses SysUtils, Classes, TagType, Output, NovusTokenProcessor;

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

   tTokenProcessor = class(TNovusTokenProcessor)
   private
     foOutput: tOutput;
   protected
   public
     constructor Create(aOutput: tOutput); overload;
     function GetFirstTokenProcessorItem: tTokenProcessorItem;
     property oOutput: tOutput
       read foOutput
       write foOutput;
   end;

implementation

// Token Processor
constructor tTokenProcessor.Create(aOutput: tOutput);
begin
  TokenIndex:= 0;

  foOutput := aOutput;
end;

function tTokenProcessor.GetFirstTokenProcessorItem: tTokenProcessorItem;
begin
  TokenIndex:=0;

  if Count =0 then Exit;

  Result := tTokenProcessorItem(Objects[TokenIndex]);

  NextToken;
end;

end.
