unit ProjectconfigParser;

interface

uses ExpressionParser, system.Classes,  Variables, output, SysUtils, Project,
     TagType, tagTypeParser, TokenProcessor, NovusEnvironment;


type
   tProjectconfigParser = class
   protected
   private
   public
     class function ParseProjectConfig(aItemName: String; aProject: tProject; aOutput: tOutput): String;
   end;


implementation

uses VariablesCmdLine, NovusTemplate, Config, CodeGenerator;

class function tProjectconfigParser.ParseProjectConfig(aItemName: String; aProject: tProject; aOutput: tOutput): String;
var
  lEParser: tExpressionParser;
  lTokens: tTokenProcessor;
  loTemplate: tNovusTemplate;
  I: Integer;
  FTemplateTag: TTemplateTag;
  lsToken1: String;
  lsToken2: String;
  FTagType: TTagType;
  lVariable: TVariable;
begin
  Result := '';

  if aItemName= '' then Exit;

  Try
    lEParser:= tExpressionParser.Create;
    lTokens:= tTokenProcessor.Create;
    loTemplate := tNovusTemplate.Create;

    loTemplate.StartToken := '[';
    loTemplate.EndToken := ']';
    loTemplate.SecondToken := '%';

    loTemplate.TemplateDoc.Text := Trim(aItemName);

    loTemplate.ParseTemplate;

    For I := 0 to loTemplate.TemplateTags.Count -1 do
       begin
         lTokens.Clear;

         FTemplateTag := TTemplateTag(loTemplate.TemplateTags.items[i]);

         lEParser.Expr := FTemplateTag.TagName;
         lEParser.ListTokens(lTokens);

         FTagType := TTagTypeParser.ParseTagType(NIL, NIL,lTokens, aOutput, 0);

         case FtagType of
           ttVariableCmdLine:
              begin
                lVariable := oConfig.oVariablesCmdLine.GetVariableByName(lsToken2);

                if Assigned(lVariable) then
                  FTemplateTag.TagValue := lvariable.Value;

              end
           else
             FTemplateTag.TagValue := aProject.oProjectConfig.Getproperties(FTemplateTag.TagName);
         end;
       end;

    loTemplate.InsertAllTagValues;

    Result := Trim(loTemplate.OutputDoc.Text);
  Finally
    loTemplate.Free;
    lTokens.Free;
    lEParser.Free;
  End;


  Result :=  tNovusEnvironment.ParseGetEnvironmentVar(Result,ETTToken2 );
  Result :=  tNovusEnvironment.ParseGetEnvironmentVar(Result, ETTToken1);
end;


end.
