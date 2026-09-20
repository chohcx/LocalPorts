using System.Diagnostics;
using System.Net;
using System.Net.Sockets;
namespace LocalPorts;
internal static class Smoke {
 internal static int Run() {
  using var child = Process.Start(new ProcessStartInfo(Environment.ProcessPath!, "--listener-child") { UseShellExecute = false, RedirectStandardOutput = true });
  if(child is null) throw new Exception("Could not start listener child");
  try {
   var line = child.StandardOutput.ReadLineAsync().WaitAsync(TimeSpan.FromSeconds(15)).GetAwaiter().GetResult();
   var port = int.Parse(line!);
   var rows = Scanner.Scan();
   if (!rows.Any(r => r.Pid == child.Id && r.Port == port && r.Owner == Native.CurrentSid)) throw new Exception("Child listener/ownership not discovered");
   using var form = new MainForm();
   form.Show(); Application.DoEvents();
   form.Close(); Application.DoEvents();
   if (form.IsDisposed || form.Visible || !form.TrayVisible) throw new Exception("Close must retain tray");
   form.RestoreWindow(); Application.DoEvents();
   if (!form.Visible) throw new Exception("Restore failed");
   form.WindowState = FormWindowState.Minimized; Application.DoEvents();
   if(form.Visible || !form.TrayVisible) throw new Exception("Minimize must retain tray");
   form.Quit(); Application.DoEvents();
   if(!form.IsDisposed) throw new Exception("Quit did not dispose");
   return 0;
  } finally { if (!child.HasExited) { child.Kill(); child.WaitForExit(); } }
 }
 internal static void Listener() { var listener = new TcpListener(IPAddress.Loopback,0); listener.Start(); Console.WriteLine(((IPEndPoint)listener.LocalEndpoint).Port); Console.Out.Flush(); Thread.Sleep(60000); listener.Stop(); }
}
