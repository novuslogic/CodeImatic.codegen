unit TokenProcessor;

interface

Uses SysUtils, Classes, TagType, CodeImatic.Output, NovusTokenProcessor;

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
     foOutput: tcimOutput;
   protected
   public
     constructor Create(aOutput: tcimOutput); overload;
     function GetFirstTokenProcessorItem: tTokenProcessorItem;
     property oOutput: tcimOutput
       read foOutput
       write foOutput;
   end;

implementation

// Token Processor
constructor tTokenProcessor.Create(aOutput: tcimOutput);
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
