namespace LocalPorts.Core;
public static class RuntimeHint {
 public static string FromName(string? name) {
  if(string.IsNullOrWhiteSpace(name) || name.Equals("Unavailable",StringComparison.OrdinalIgnoreCase))return "Unavailable";
  var normalized=name.ToLowerInvariant();
  if(normalized.EndsWith(".exe",StringComparison.Ordinal))normalized=normalized[..^4];
  return normalized switch {
   "node" => "Node.js", "python" or "python3" or "pythonw" or "uvicorn" or "gunicorn" => "Python",
   "java" or "javaw" => "Java", "dotnet" => ".NET", "ruby" => "Ruby", "php" => "PHP",
   "bun" => "Bun", "deno" => "Deno", _ => "Native / other"
  };
 }
 public static bool IsDeveloper(string? name) => FromName(name) is not ("Native / other" or "Unavailable");
}
