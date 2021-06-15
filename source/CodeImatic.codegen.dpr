{$I CodeImatic.codegen.inc}
program CodeImatic.codegen;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  FastMM5,
  System.SysUtils,
  Config,
  output,
  runtime,
  project,
  projectconfig,
  CommandLine,
  NovusCommandLine,
  PluginsMapFactory in 'PluginsMapFactory.pas';

var
    FComandLineResult :  TNovusCommandLineResult;

begin
    FComandLineResult := NIL;


    Try
      TCommandLine.RegisterCommands;

      FComandLineResult := tCommandLine.Execute;
      if (FComandLineResult.IsHelpCommand) and (FComandLineResult.Errors = false) then
        begin
          Writeln(oRuntime.GetVersionCopyright);
          Writeln('');

          if Trim(FComandLineResult.Help) = '' then
                 Writeln('Usage : codeimatic.codegen [command] [options]')
           else Writeln(FComandLineResult.Help);

           ExitCode := FComandLineResult.ExitCode;
        end
      else
      if (FComandLineResult.Errors) and (FComandLineResult.IsCommandEmpty = false) then
      begin
        Writeln(oRuntime.GetVersionCopyright);
        Writeln('');
        Writeln('Invalid options:');

        Writeln(FComandLineResult.ErrorMessages.Text);

        Writeln('');
        if Trim(FComandLineResult.Help) = '' then
               Writeln('Usage : codeimatic.codegen [command] [options]')
         else Writeln(FComandLineResult.Help);

         ExitCode := FComandLineResult.ExitCode;

      end
    else
    if FComandLineResult.IsCommandEmpty then
      begin
        Writeln(oRuntime.GetVersionCopyright);
        Writeln('');
        Writeln('Usage : codeimatic.codegen [command] [options]');

        ExitCode := FComandLineResult.ExitCode;

       end
     else
        begin
          ExitCode := oConfig.LoadConfig(FComandLineResult);
          if ExitCode = 0 then
            begin
              ExitCode := oruntime.Execute(FComandLineResult);

              if (FComandLineResult.Errors) then
                begin
                  Writeln(oRuntime.GetVersionCopyright);
                  Writeln('');
                  Writeln('Error:');
                  Writeln(FComandLineResult.ErrorMessages.Text);
                end;
            end
          else
             begin
               Writeln(oRuntime.GetVersionCopyright);
               Writeln('');
               Writeln('Config Error:');

               Writeln(FComandLineResult.ErrorMessages.Text);
             end;

        end;
    Finally
      if Assigned(FComandLineResult) then
        FComandLineResult.Free;
    End;

end.
