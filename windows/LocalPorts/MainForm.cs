using System.Diagnostics;
using LocalPorts.Core;
namespace LocalPorts;
internal sealed class MainForm : Form {
 readonly NotifyIcon tray;
 readonly System.Windows.Forms.Timer timer = new() { Interval=3000 };
 readonly CheckBox showAll = new() { Text="Show all", AutoSize=true, Checked=false, Dock=DockStyle.Right };
 readonly TextBox search = new() { PlaceholderText="Search port, name, runtime, PID or binding", Dock=DockStyle.Fill };
 readonly ListView list = new() { Dock=DockStyle.Fill, View=View.Details, FullRowSelect=true, MultiSelect=false, HideSelection=false };
 readonly TextBox details = new() { Dock=DockStyle.Fill, Multiline=true, ReadOnly=true, ScrollBars=ScrollBars.Vertical, Visible=false };
 readonly Label status = new() { Dock=DockStyle.Fill, AutoSize=true, Text="Scanning TCP listeners…" };
 readonly Button stop = new() { Text="Stop…", AutoSize=true };
 readonly Button folder = new() { Text="Directory", AutoSize=true };
 readonly Button terminal = new() { Text="Terminal", AutoSize=true };
 readonly Dictionary<(int,long),(TimeSpan Cpu,DateTime At)> samples = new();
 readonly Dictionary<(int,long),string> cpuUsage = new();
 List<Listener> rows = new(); bool busy, quitting;
 DateTime? updated;
 internal bool ShowAll { get=>showAll.Checked; set=>showAll.Checked=value; }
 internal int VisibleRowCount => list.Items.Count;
 internal int ColumnCount => list.Columns.Count;
 internal void LoadRows(List<Listener> next) { rows=next;Render(); }
 internal bool TrayVisible => tray.Visible;
 ListenerGroup? SelectedGroup => list.SelectedItems.Count==0 ? null : list.SelectedItems[0].Tag as ListenerGroup;
 Listener? Selected => SelectedGroup?.Primary;
 internal MainForm() {
  Text="LocalPorts"; Size=new Size(800,530); MinimumSize=new Size(630,380); StartPosition=FormStartPosition.CenterScreen; Font=new Font("Segoe UI",10);
  var iconPath=Path.Combine(AppContext.BaseDirectory,"localports.ico");
  Icon=File.Exists(iconPath)?new Icon(iconPath):SystemIcons.Application;
  var menu=new ContextMenuStrip(); menu.Items.Add("Open LocalPorts",null,(_,_)=>RestoreWindow()); menu.Items.Add("Quit",null,(_,_)=>Quit());
  tray=new NotifyIcon { Text="LocalPorts — listening ports", Icon=Icon, ContextMenuStrip=menu, Visible=true };
  tray.DoubleClick+=(_,_)=>RestoreWindow();
  var layout=new TableLayoutPanel { Dock=DockStyle.Fill, Padding=new Padding(14), RowCount=5, ColumnCount=1 };
  layout.RowStyles.Add(new RowStyle(SizeType.Absolute,36)); layout.RowStyles.Add(new RowStyle(SizeType.Percent,100)); layout.RowStyles.Add(new RowStyle(SizeType.AutoSize)); layout.RowStyles.Add(new RowStyle(SizeType.AutoSize)); layout.RowStyles.Add(new RowStyle(SizeType.Absolute,26));
  list.Columns.Add("Port",90);list.Columns.Add("Name",350);list.Columns.Add("Runtime",180);
  var actions=new FlowLayoutPanel { Dock=DockStyle.Fill, AutoSize=true, WrapContents=true };
  void Button(string label,Action action) { var b=new Button { Text=label,AutoSize=true };b.Click+=(_,_)=>Guard(action);actions.Controls.Add(b); }
  Button("Open",()=>WithRow(r=>Launch(EndpointUrl.Create(r.Address,r.Port))));
  Button("Copy URL",()=>WithRow(r=>Clipboard.SetText(EndpointUrl.Create(r.Address,r.Port))));
  Button("Details",()=>{ details.Visible=!details.Visible; details.Height=135; UpdateDetails(); });
  folder.Click+=(_,_)=>Guard(()=>WithRow(r=>Launch(Path.GetDirectoryName(r.Path!)!)));
  terminal.Click+=(_,_)=>Guard(()=>WithRow(r=>Process.Start(new ProcessStartInfo(Path.Combine(Environment.SystemDirectory,"cmd.exe")) { WorkingDirectory=Path.GetDirectoryName(r.Path!)!, UseShellExecute=true })));
  stop.Click+=(_,_)=>Guard(()=>WithRow(r=>ProcessActions.Stop(r,this)));
  actions.Controls.AddRange(new Control[]{folder,terminal,stop}); Button("Refresh",()=>_ = RefreshAsync());
  var filters=new Panel { Dock=DockStyle.Fill }; filters.Controls.Add(search);filters.Controls.Add(showAll);
  layout.Controls.Add(filters,0,0);layout.Controls.Add(list,0,1);layout.Controls.Add(actions,0,2);layout.Controls.Add(details,0,3);layout.Controls.Add(status,0,4); Controls.Add(layout);
  search.TextChanged+=(_,_)=>Render(); showAll.CheckedChanged+=(_,_)=>Render(); list.SelectedIndexChanged+=(_,_)=>UpdateDetails();
  Resize+=(_,_)=>{if(WindowState==FormWindowState.Minimized) Hide();};
  FormClosing+=(_,e)=>{if(!quitting && e.CloseReason==CloseReason.UserClosing){ e.Cancel=true;Hide(); }};
  Shown+=async (_,_)=>await RefreshAsync(); timer.Tick+=async (_,_)=>await RefreshAsync();timer.Start();UpdateDetails();
 }
 internal void RestoreWindow() { Show(); WindowState=FormWindowState.Normal; Activate(); }
 internal void Quit() { quitting=true; Close(); }
 protected override void Dispose(bool disposing) { if(disposing){timer.Stop();timer.Dispose();tray.Visible=false;tray.ContextMenuStrip?.Dispose();tray.Dispose();}base.Dispose(disposing); }
 async Task RefreshAsync() {
  if(busy || IsDisposed) return; busy=true;
  try {
   var next=await Task.Run(Scanner.Scan); if(IsDisposed)return;
   var now=DateTime.UtcNow; cpuUsage.Clear();
   foreach(var r in next.DistinctBy(r=>(r.Pid,r.Start))) {
    var key=(r.Pid,r.Start); cpuUsage[key]="Unavailable";
    if(r.Cpu is not { } cpu || r.Start<=0)continue;
    cpuUsage[key]="Sampling…";
    if(samples.TryGetValue(key,out var old) && now>old.At && cpu>=old.Cpu) cpuUsage[key]=$"{Math.Clamp((cpu-old.Cpu).TotalSeconds/(now-old.At).TotalSeconds/Environment.ProcessorCount*100,0,100):F1}%";
   }
   samples.Clear();foreach(var r in next) if(r.Cpu is { } cpu && r.Start>0)samples[(r.Pid,r.Start)]=(cpu,now);
   updated=DateTime.Now;LoadRows(next);
  } catch(Exception e) {if(!IsDisposed)status.Text="Scan failed: "+e.Message;}finally{busy=false;}
 }
 void Render() {
  var selected=SelectedGroup?.Id; var groups=ListenerView.Group(rows);
  var visible=ListenerView.Filter(groups,showAll.Checked,search.Text);
  list.BeginUpdate();list.Items.Clear();
  foreach(var group in visible) {
   var row=group.Primary;
   var item=new ListViewItem(new[]{row.Port.ToString(),row.Name,row.Runtime}){Tag=group}; list.Items.Add(item);
   if(selected==group.Id)item.Selected=true;
  }
  list.EndUpdate();UpdateDetails();
  status.Text=$"{(showAll.Checked?"All":"Developer")}: {visible.Count}/{groups.Count} rows · {visible.Sum(g=>g.Bindings.Count)}/{rows.Count} TCP bindings"+(updated is { } at?$" · {at:T}":"");
 }
 void UpdateDetails() {
  var r=Selected;folder.Enabled=terminal.Enabled=r?.Path is not null;
  stop.Enabled=r is not null && ProcessSafety.CanStop(r.Pid,r.Start,r.Owner,r.Pid,r.Start,r.Owner,Native.CurrentSid,Environment.ProcessId);
  if(r is null){details.Text="Select a listener to see details.";return;}
  var uptime=r.Start>0 ? (DateTime.UtcNow-DateTime.FromFileTimeUtc(r.Start)).ToString(@"d\d\ hh\h\ mm\m\ ss\s") : "Unavailable";
  details.Text=$"{r.Name} · PID {r.Pid} · {r.Runtime} (name-based hint)\r\nCPU: {(r.Cpu is null?"Unavailable":cpuUsage.GetValueOrDefault((r.Pid,r.Start),"Unavailable"))} (whole-machine share)   RAM: {(r.Memory is { } memory?$"{memory/1048576.0:F1} MiB":"Unavailable")}   Uptime: {uptime}\r\nExecutable: {r.Path??"Unavailable"}\r\nOwner: {(r.Owner==Native.CurrentSid?"Current user":r.Owner??"Unavailable")}\r\nBindings for port {r.Port}: {string.Join(", ",SelectedGroup!.Bindings.Select(x=>x.Binding))}";
 }
 void WithRow(Action<Listener> action){if(Selected is { } row)action(row);}
 static void Launch(string target)=>Process.Start(new ProcessStartInfo(target){UseShellExecute=true});
 void Guard(Action action){try{action();}catch(Exception e){MessageBox.Show(this,e.Message,"LocalPorts",MessageBoxButtons.OK,MessageBoxIcon.Warning);}}
}
