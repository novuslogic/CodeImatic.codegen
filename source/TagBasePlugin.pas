unit TagBasePlugin;

interface

Uses Output, ProjectItem, Variables, TokenProcessor;

type
  TTagBasePlugin = class
  private
    foOutput: tOutput;
    foProjectItem: tProjectItem;
    foVariables: TVariables;
  protected
    function GetTagName: String; virtual;
  public
    constructor Create(aOutput: tOutput);
    function Execute(aProjectItem: tProjectItem; aTagName: string;
      aTokens: tTokenProcessor): String; virtual;

    property TagName: String read GetTagName;

    property oOutput: tOutput read foOutput;

    property oVariables: TVariables read foVariables write foVariables;
  end;

implementation

constructor TTagBasePlugin.Create(aOutput: tOutput);
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
