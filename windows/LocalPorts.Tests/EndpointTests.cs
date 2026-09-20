using LocalPorts.Core;
using Xunit;
public class EndpointTests {
 [Theory][InlineData("0.0.0.0",8080,"http://127.0.0.1:8080/")][InlineData("::",80,"http://[::1]:80/")][InlineData("::1",443,"https://[::1]:443/")]
 public void BrowserTargetHandlesWildcardAndV6(string address,int port,string expected) => Assert.Equal(expected, EndpointUrl.Create(address,port));
}
