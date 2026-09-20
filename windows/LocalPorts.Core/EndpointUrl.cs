namespace LocalPorts.Core;
public static class EndpointUrl {
 public static string Create(string address, int port) {
  var host = address == "0.0.0.0" ? "127.0.0.1" : address == "::" ? "::1" : address;
  if(host.Contains(':')) host = "[" + host.Replace("%", "%25") + "]";
  return $"{(port == 443 ? "https" : "http")}://{host}:{port}/";
 }
}
