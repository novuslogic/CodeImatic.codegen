{$I CodeImatic.codegen.inc}
program CodeImatic.codegen;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  FastMM4,
  System.SysUtils,
  Config,
  output,
  runtime,
  project,
  projectconfig,
  CommandLine,
  NovusCommandLine,
  Language in 'Language.pas',
  Plugins in 'Plugins.pas',
  PluginsMapFactory in 'PluginsMapFactory.pas';

  var
    FComandLineResult :  TNovusCommandLineResult;

begin
    Try
      TCommandLine.RegisterCommands;

      FComandLineResult := tCommandLine.Execute;
      if (FComandLineResult.Errors) and (FComandLineResult.IsCommandEmpty = false) then
      begin
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
        Writeln('Version: ' + oRuntime.GetVersion(0));
        Writeln('');
        Writeln('Usage : codeimatic.codegen [command] [options]');

        ExitCode := FComandLineResult.ExitCode;

       end
     else
        begin
          ExitCode := oConfig.LoadConfig(FComandLineResult);
          if ExitCode = 0 then
            begin
              ExitCode := oruntime.RunEnvironment(FComandLineResult);

              if (FComandLineResult.Errors) then
                begin
                  Writeln(oRuntime.GetVersionCopyright);
                  Writeln('Version: ' + oRuntime.GetVersion(0));
                  Writeln('');
                  Writeln('Error:');
                  Writeln(FComandLineResult.ErrorMessages.Text);
                end;
            end
          else
             begin
               Writeln(oRuntime.GetVersionCopyright);
               Writeln('Version: ' + oRuntime.GetVersion(0));
               Writeln('');
               Writeln('Config Error:');

               Writeln(FComandLineResult.ErrorMessages.Text);
             end;

        end;
    Finally
      FComandLineResult.Free;
    End;

end.
