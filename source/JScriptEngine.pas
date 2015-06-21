unit JScriptEngine;

interface

Uses Classes, NovusTemplate;

Type
   TJScriptEngine = Class(TObject)
   protected
      FTemplate: TNovusTemplate;
   private
   public
     constructor Create(ATemplate: TNovusTemplate); virtual;
     destructor Destroy; override;
   End;


implementation

constructor TJScriptEngine.Create;
begin
  inherited Create;

  FTemplate := ATemplate;
end;

destructor TJScriptEngine.Destroy;
begin
  inherited;
end;


end.
