unit APIBase;

interface

uses Classes,  SysUtils, CodeImatic.Output;

type
   TAPIBase = class(TPersistent)
   protected
   private
     foOutput: tcimOutput;
   public
     constructor Create(aOutput: tcimOutput); virtual;
     destructor Destroy; override;

     property oOutput: tcimOutput
       read foOutput;
   end;

implementation

constructor TAPIBase.create;
begin
  foOutput:= aOutput;
end;

destructor TAPIBase.destroy;
begin
  Inherited;
end;




end.
