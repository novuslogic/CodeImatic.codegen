
unit Plugin;

interface

uses classes, Output, NovusPlugin;

type
   TPlugin = class(TPersistent)
   private
   protected
     foOutput: tOutput;
   public
     constructor Create(aOutput: tOutput); virtual;

     property oOutput: tOutput
       read foOutput
       write foOutput;


   end;

    IExternalPlugin = interface(INovusPlugin)
     ['{155A396A-9457-4C48-A787-0C9582361B45}']

     function  CreatePlugin(aOutput: tOutput):TPlugin safecall;
   end;


   TPluginClass = class of TPlugin;

implementation

constructor TPlugin.create;
begin
  foOutput:= aOutput;


end;


end.
