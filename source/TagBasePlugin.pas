unit TagBasePlugin;

interface

Uses CodeImatic.Output, ProjectItem, Variables, TokenProcessor;

type
  TTagBasePlugin = class
  private
    foOutput: tcimOutput;
    foProjectItem: tProjectItem;
    foVariables: TVariables;
  protected
    function GetTagName: String; virtual;
  public
    constructor Create(aOutput: tcimOutput);
    function Execute(aProjectItem: tProjectItem; aTagName: string;
      aTokens: tTokenProcessor): String; virtual;

    property TagName: String read GetTagName;

    property oOutput: tcimOutput read foOutput;

    property oVariables: TVariables read foVariables write foVariables;
  end;

implementation

constructor TTagBasePlugin.Create(aOutput: tcimOutput);
begin
  foOutput := aOutput;
end;

function TTagBasePlugin.GetTagName: String;
begin
  Result := '';
end;

function TTagBasePlugin.Execute(aProjectItem: tProjectItem; aTagName: String;
  aTokens: tTokenProcessor): String;
begin
  Result := '';
end;


end.
