unit XMLDocumentationClasses;

interface

Uses Output;

type
  TXMLDocumentation = class
  protected
  private
    foOutput: TOutput;
  public
    constructor Create(aOutput: TOutput);
    destructor Destroy; override;
  end;

implementation

constructor TXMLDocumentation.Create(aOutput: TOutput);
begin
  foOutput := aOutput;
end;

destructor TXMLDocumentation.Destroy;
begin
end;

end.
