unit Template;

interface

Uses NovusTemplate;

type
   TTemplate = class(tNovusTemplate)
   protected
   private
   public
     class function CreateTemplate(aIgnoreBlankValue: boolean = false): tTemplate;
   end;

implementation
           
class function TTemplate.CreateTemplate(aIgnoreBlankValue: boolean = false): tTemplate;
begin
  Result :=  TTemplate.Create;
  Result.StartToken := '<';
  Result.EndToken := '>';
  Result.SecondToken := '%';
  Result.IgnoreBlankValue := aIgnoreBlankValue;
end;

end.
