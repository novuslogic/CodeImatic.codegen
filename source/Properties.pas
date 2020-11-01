unit Properties;

interface

Uses NovusXMLBO, Classes, SysUtils, XMLlist, Project, Output;

Type
  tProperties = class(TXMLlist)
  protected
  private
    foProject: tProject;
    FoOutput: TOutput;
    foProjectItem: tObject;
  public
    constructor Create(aProjectItem: tObject);  reintroduce;

    function IsPropertyExists(APropertyName: String): Boolean;
    function GetProperty(APropertyName: String): String;
    //function GetPluginProperty(APropertyName: string): string;

//    property oProject: tProject
//      read foProject
//      write foProject;

//    property oOutput: TOutput
//      read FoOutput
//      write FoOutput;
  end;

implementation

uses Runtime, Plugin, ProjectParser, variables, ProjectItem;

constructor tProperties.Create(aProjectItem: tObject); //virtual;
begin
  inherited Create;

  foProjectItem := aProjectItem;

  if Assigned(foProjectItem) then
    begin
      FoOutput := (foProjectItem as TProjectItem).oOutput;
      foProject := (foProjectItem as TProjectItem).oPRoject;
    end;
end;


function tProperties.GetProperty(APropertyName: String): String;
var
  lsGetProperty: String;
  fVariable: tVariable;
begin

  lsGetProperty := GetFieldAsString(oXMLDocument.Root, APropertyName);
  Try
    if Assigned(foProject) then
      if foProject.oProjectConfigLoader.Load then
         lsGetProperty := tProjectParser.ParseProject(lsGetProperty,foProject, foOutput);

    fVariable := (foProjectItem as TProjectItem).oVariables.GetVariableByName(APropertyName);
    if assigned(fVariable) then
      lsGetProperty := fVariable.AsString;
  Except
    FoOutput.log(APropertyName + ' Projectconfig error.');

  End;

  Result := lsGetProperty;

end;


(*
function tProperties.GetPluginProperty(APropertyName: string): string;
var
  loPlugin: TPlugin;
  I: Integer;
begin
   for I := 0 to oRuntime.oPlugins.PluginsList.Count -1 do
    begin
      loPlugin := TPlugin(oRuntime.oPlugins.PluginsList.Items[i]);

    end;
end;
*)


function tProperties.IsPropertyExists(APropertyName: String): Boolean;
Var
  I: integer;
begin
  Result := False;

  for i := 0 to NodeNames.Count - 1 do
    begin
      If Uppercase(NodeNames.Strings[i]) = Uppercase(APropertyName) then
        begin
          Result := True;

          Exit;
        end;
    end;
end;

end.
