unit ProjectClasses;

interface

Uses NovusBO,  JvSimpleXml, Project, SysUtils, ProjectItem;

Type
  TProjectClasses = class
  protected
  private
  public
    class function LoadProjectItem(aProject: Tproject;aItemName: String; aProjectItem: TProjectItem): Boolean;
  end;


implementation

Uses novusSimpleXML;

class function TProjectClasses.LoadProjectItem(aProject: Tproject;aItemName: String; aProjectItem: TProjectItem): Boolean;
Var
  fJvSimpleXmlElem: TJvSimpleXmlElem;
  Index: Integer;
  FNode: TJvSimpleXmlElem;
begin
  Result := False;

  Try
    fJvSimpleXmlElem  := TnovusSimpleXML.FindNodeByValue(aProject.oXMLDocument.Root, 'projectitem', 'name', aItemName);

    If Assigned(fJvSimpleXmlElem) then
      begin
        aProjectItem.XmlElem := fJvSimpleXmlElem;

        Index := 0;
        if assigned(TNovusSimpleXML.FindNode(fJvSimpleXmlElem, 'template', Index)) then
          begin
            Index := 0;
            aProjectItem.TemplateFile := TNovusSimpleXML.FindNode(fJvSimpleXmlElem, 'template', Index).Value;
          end;

        Index := 0;
        if assigned(TNovusSimpleXML.FindNode(fJvSimpleXmlElem, 'source', Index)) then
          begin
            Index := 0;
            aProjectItem.TemplateFile := TNovusSimpleXML.FindNode(fJvSimpleXmlElem, 'source', Index).Value;
          end;

        Index := 0;
        if Assigned(TNovusSimpleXML.FindNode(fJvSimpleXmlElem, 'properties', Index)) then
          begin
            Index := 0;
            aProjectItem.propertiesFile := TNovusSimpleXML.FindNode(fJvSimpleXmlElem, 'properties', Index).Value;
          end;

          Index := 0;
        if Assigned(TNovusSimpleXML.FindNode(fJvSimpleXmlElem, 'postprocessor', Index)) then
          begin
            Index := 0;
            aProjectItem.postprocessor := Uppercase(TNovusSimpleXML.FindNode(fJvSimpleXmlElem, 'postprocessor', Index).Value);
          end;

        Index := 0;
        if Assigned(TNovusSimpleXML.FindNode(fJvSimpleXmlElem, 'overrideoutput', Index)) then
          begin
            Index := 0;
            if Uppercase(TNovusSimpleXML.FindNode(fJvSimpleXmlElem, 'overrideoutput', Index).Value) = 'TRUE' then
              aProjectItem.overrideoutput := True
            else
               aProjectItem.overrideoutput := false;
          end
        else aProjectItem.overrideoutput := false;

        Index := 0;
        if assigned(TNovusSimpleXML.FindNode(fJvSimpleXmlElem, 'output', Index)) then
          begin
            Index := 0;
            aProjectItem.OutputFile := TNovusSimpleXML.FindNode(fJvSimpleXmlElem, 'output', Index).Value;
          end;
      end;
  Finally
    Result := True;
  end;
end;


end.
