using System.Net;
using System.Net.Sockets;
namespace LocalPorts.Core;
public record Listener(int Pid, string Name, string Runtime, string Address, int Port, long Start, string? Owner, string? Path, long? Memory, TimeSpan? Cpu) {
 public string Binding => Address.Contains(':') ? $"[{Address}]:{Port}" : $"{Address}:{Port}";
}
public sealed record ListenerGroup(IReadOnlyList<Listener> Bindings) {
 public Listener Primary => Bindings[0];
 public int Pid => Primary.Pid;
 public long Start => Primary.Start;
 public int Port => Primary.Port;
 public (int Pid,long Start,int Port) Id => (Pid,Start,Port);
 public string Url => EndpointUrl.Create(Primary.Address,Port);
}
public static class ListenerView {
 public static List<ListenerGroup> Filter(IEnumerable<ListenerGroup> groups,bool showAll=false,string search="") => groups
  .Where(g=>(showAll || RuntimeHint.IsDeveloper(g.Primary.Name)) && g.Bindings.Any(r=>$"{r.Port} {r.Name} {r.Runtime} {r.Pid} {r.Binding}".Contains(search,StringComparison.OrdinalIgnoreCase))).ToList();
 public static List<ListenerGroup> Group(IEnumerable<Listener> rows) => rows.GroupBy(r=>(r.Pid,r.Start,r.Port))
  .Select(g=>new ListenerGroup(g.OrderBy(r=>AddressRank(r.Address)).ThenBy(r=>r.Address,StringComparer.Ordinal).ToArray()))
  .OrderBy(g=>g.Port).ThenBy(g=>g.Pid).ThenBy(g=>g.Start).ToList();
 static int AddressRank(string address) {
  if(!IPAddress.TryParse(address,out var ip))return 10;
  var local=IPAddress.IsLoopback(ip) || ip.Equals(IPAddress.Any) || ip.Equals(IPAddress.IPv6Any);
  return (local?0:4)+(ip.AddressFamily==AddressFamily.InterNetwork?0:2)+(IPAddress.IsLoopback(ip)?0:1);
 }
}
