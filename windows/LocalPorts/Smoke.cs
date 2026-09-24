using System.Diagnostics;
using LocalPorts.Core;
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
   var childGroup=ListenerView.Group(rows).Single(g=>g.Pid==child.Id && g.Port==port);
   if(childGroup.Bindings.Count!=2)throw new Exception("IPv4/IPv6 bindings were not merged");
   if(childGroup.Url!=$"http://127.0.0.1:{port}/")throw new Exception("Wrong browser family");
   using var form = new MainForm();
   form.Show(); Application.DoEvents();
   if(form.ShowAll || form.ColumnCount!=3)throw new Exception("Expected developer-first three-column view");
   var developer=childGroup.Bindings.Select(r=>r with { Name="node",Runtime="Node.js" }).ToList();
   var system=developer[0] with { Pid=4,Name="System",Runtime="Native / other",Port=49152 };
   form.LoadRows(developer.Append(system).ToList());
   if(form.VisibleRowCount!=1)throw new Exception("Developer filter or grouping failed");
   var list=Descendants(form).OfType<ListView>().Single();
   list.Items[0].Selected=true;
   form.LoadRows(new List<Listener>{developer[1],system});
   if(list.SelectedItems.Count!=1)throw new Exception("Selection lost after binding change");
   var unavailable=developer[1] with { Memory=null,Cpu=null };
   var anotherPort=developer[1] with { Port=port==3001?3002:3001 };
   form.LoadRows(new List<Listener>{unavailable,anotherPort,system});
   var detail=Descendants(form).OfType<TextBox>().Single(t=>t.Multiline);
   if(!detail.Text.Contains("RAM: Unavailable") || !detail.Text.Contains("CPU: Unavailable"))throw new Exception("Missing metrics must not become zero");
   if(!detail.Text.Contains(unavailable.Binding) || detail.Text.Contains(anotherPort.Binding))throw new Exception("Details must show only selected port bindings");
   form.LoadRows(new List<Listener>{unavailable,system});
   form.ShowAll=true;
   if(form.VisibleRowCount!=2)throw new Exception("Show all failed");
   var search=Descendants(form).OfType<TextBox>().Single(t=>!t.Multiline);
   search.Text="System";
   if(form.VisibleRowCount!=1)throw new Exception("Search failed");
   search.Text=developer[1].Binding;
   if(form.VisibleRowCount!=1)throw new Exception("Hidden binding search failed");
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
 static IEnumerable<Control> Descendants(Control parent) {
  foreach(Control child in parent.Controls) { yield return child; foreach(var nested in Descendants(child))yield return nested; }
 }
 internal static void Listener() {
  var ipv4 = new TcpListener(IPAddress.Loopback,0); ipv4.Start();
  var port=((IPEndPoint)ipv4.LocalEndpoint).Port;
  var ipv6 = new TcpListener(IPAddress.IPv6Loopback,port); ipv6.Server.DualMode=false; ipv6.Start();
  Console.WriteLine(port); Console.Out.Flush(); Thread.Sleep(60000); ipv4.Stop(); ipv6.Stop();
 }
}
