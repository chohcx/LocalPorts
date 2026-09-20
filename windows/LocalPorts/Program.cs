namespace LocalPorts;
internal static class Program {
 [STAThread] static int Main(string[] args) {
  if(args.Contains("--listener-child")) { Smoke.Listener(); return 0; }
  ApplicationConfiguration.Initialize();
  if(args.Contains("--smoke-test")) { try { return Smoke.Run(); } catch(Exception e) { File.WriteAllText("smoke-error.txt",e.ToString()); return 1; } }
  Application.Run(new MainForm()); return 0;
 }
}
