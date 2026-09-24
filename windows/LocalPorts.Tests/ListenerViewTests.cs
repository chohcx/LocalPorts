using LocalPorts.Core;
using Xunit;
public class ListenerViewTests {
 [Theory]
 [InlineData("node","Node.js")][InlineData("PYTHON3.EXE","Python")][InlineData("pythonw","Python")]
 [InlineData("java","Java")][InlineData("dotnet",".NET")][InlineData("ruby","Ruby")][InlineData("php","PHP")]
 [InlineData("bun","Bun")][InlineData("deno","Deno")][InlineData("uvicorn","Python")]
 public void DeveloperRuntimesAreExplicit(string name,string runtime) {
  Assert.Equal(runtime,RuntimeHint.FromName(name));
  Assert.True(RuntimeHint.IsDeveloper(name));
 }
 [Fact] public void DefaultHidesSystemEvenAtHighPortsAndSearchIncludesHiddenBindings() {
  var dev=Row(10,100,3000,"::");
  var groups=ListenerView.Group(new[]{dev,dev with { Address="127.0.0.1" },Row(11,100,49152,"0.0.0.0") with { Name="svchost",Runtime="Native / other" }});
  Assert.Single(ListenerView.Filter(groups));
  Assert.Equal(2,ListenerView.Filter(groups,true).Count);
  Assert.Single(ListenerView.Filter(groups,false,"[::]:3000"));
  Assert.Single(ListenerView.Filter(groups,true,"11"));
  Assert.Empty(ListenerView.Filter(groups,false,"49152"));
  Assert.Equal("Unavailable",RuntimeHint.FromName(null));
  Assert.Equal("Unavailable",RuntimeHint.FromName("Unavailable"));
  Assert.Equal("Native / other",RuntimeHint.FromName("my-go-app"));
  Assert.False(RuntimeHint.IsDeveloper("node-helper"));
 }
 [Theory][InlineData("::","http://[::1]:3000/")][InlineData("192.168.1.2","http://192.168.1.2:3000/")]
 public void OpenNeverInventsAnUnboundFamily(string address,string url) => Assert.Equal(url,Assert.Single(ListenerView.Group(new[]{Row(10,100,3000,address)})).Url);
 static Listener Row(int pid, long start, int port, string address) => new(pid,"node","Node.js",address,port,start,null,null,null,null);
 [Fact] public void GroupingPreservesBindingsAndProcessIdentity() {
  var rows=new[]{Row(10,100,3000,"::"),Row(10,100,3000,"0.0.0.0"),Row(11,100,3000,"127.0.0.1"),Row(10,101,3000,"::1"),Row(10,100,3001,"::")};
  var groups=ListenerView.Group(rows);
  Assert.Equal(4,groups.Count);
  var merged=Assert.Single(groups,g=>g.Pid==10 && g.Start==100 && g.Port==3000);
  Assert.Equal(2,merged.Bindings.Count);
  Assert.Equal("http://127.0.0.1:3000/",merged.Url);
  Assert.Equal(merged.Id,Assert.Single(ListenerView.Group(new[]{rows[0]})).Id);
 }
}
