unit APIBase;

interface

uses Classes,  SysUtils, Output;

type
   TAPIBase = class(TPersistent)
   protected
   private
     foOutput: tOutput;
   public
     constructor Create(aOutput: tOutput); virtual;
     destructor Destroy; override;

     property oOutput: tOutput
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
