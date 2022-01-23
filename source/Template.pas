unit Template;

interface

Uses NovusTemplate;

type
   TTemplate = class(tNovusTemplate)
   protected
   private
   public
     class function CreateTemplate(aSwapTagNameBlankValue: boolean = True): tTemplate;
   end;

implementation
           
class function TTemplate.CreateTemplate(aSwapTagNameBlankValue: boolean = True): tTemplate;
begin
  Result :=  TTemplate.Create;
  Result.StartToken := '<';
  Result.EndToken := '>';
  Result.SecondToken := '%';
  Result.SwapTagNameBlankValue := aSwapTagNameBlankValue;
end;

end.
