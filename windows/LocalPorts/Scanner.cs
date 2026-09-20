using System.ComponentModel;
using System.Diagnostics;
using System.Net;
using System.Runtime.InteropServices;
namespace LocalPorts;
internal record Listener(int Pid, string Name, string Runtime, string Address, int Port, long Start, string? Owner, string? Path, long Memory, TimeSpan Cpu) {
 public string Binding => Address.Contains(':') ? $"[{Address}]:{Port}" : $"{Address}:{Port}";
}
internal static class Scanner {
 internal static List<Listener> Scan() {
  var endpoints = Read(2).Concat(Read(23)).ToArray();
  var result = new List<Listener>();
  foreach(var group in endpoints.GroupBy(e=>e.Pid)) {
   string name="Unavailable", runtime="Unknown"; string? owner=null,path=null; long start=0,memory=0; TimeSpan cpu=default;
   try {
    using var p=Process.GetProcessById(group.Key);
    name=p.ProcessName; memory=p.WorkingSet64; cpu=p.TotalProcessorTime;
    runtime = name.ToLowerInvariant() switch { "node" => "Node.js", "python" or "python3" or "pythonw" => "Python", "java" or "javaw" => "Java", "dotnet" => ".NET", "ruby" => "Ruby", "php" => "PHP", _ => "Native / other" };
    using var handle=Native.OpenProcess(0x1000,false,group.Key);
    (start,owner)=Native.Identity(handle);
    try { path=p.MainModule?.FileName; } catch { }
   } catch { /* Protected/exited processes remain visible, with actions disabled. */ }
   foreach(var e in group) result.Add(new Listener(e.Pid,name,runtime,e.Address,e.Port,start,owner,path,memory,cpu));
  }
  return result.OrderBy(r=>r.Port).ThenBy(r=>r.Pid).ToList();
 }
 private static List<(int Pid,string Address,int Port)> Read(int family) {
  int size=0; var status=Native.GetExtendedTcpTable(IntPtr.Zero,ref size,true,family,3,0);
  if(status!=122 && status!=0) throw new Win32Exception((int)status);
  for(int attempt=0;attempt<4;attempt++) {
   var buffer=Marshal.AllocHGlobal(size);
   try {
    status=Native.GetExtendedTcpTable(buffer,ref size,true,family,3,0);
    if(status==122) continue;
    if(status!=0) throw new Win32Exception((int)status);
    int count=Marshal.ReadInt32(buffer); int stride=family==2 ? 24 : 56;
    if(count<0 || (long)count*stride+4>size) throw new InvalidDataException("Invalid TCP table");
    var rows=new List<(int,string,int)>();
    for(int i=0;i<count;i++) {
     var row=IntPtr.Add(buffer,4+i*stride);
     var bytes=new byte[family==2?4:16]; Marshal.Copy(IntPtr.Add(row,family==2?4:0),bytes,0,bytes.Length);
     var address=family==2?new IPAddress(bytes):new IPAddress(bytes,(uint)Marshal.ReadInt32(row,16));
     int portOffset=family==2?8:20;
     int port=(Marshal.ReadByte(row,portOffset)<<8)|Marshal.ReadByte(row,portOffset+1);
     int pid=Marshal.ReadInt32(row,family==2?20:52);
     rows.Add((pid,address.ToString(),port));
    }
    return rows;
   } finally { Marshal.FreeHGlobal(buffer); }
  }
  throw new IOException("TCP table changed repeatedly; try refreshing.");
 }
}
