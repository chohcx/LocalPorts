using System.ComponentModel;
using System.Runtime.InteropServices;
using System.Security.Principal;
using Microsoft.Win32.SafeHandles;
namespace LocalPorts;
internal static class Native {
 [DllImport("iphlpapi.dll", SetLastError=true)] internal static extern uint GetExtendedTcpTable(IntPtr table, ref int size, bool order, int family, int tableClass, uint reserved);
 [DllImport("kernel32.dll", SetLastError=true)] internal static extern SafeProcessHandle OpenProcess(uint access, bool inherit, int pid);
 [DllImport("advapi32.dll", SetLastError=true)] static extern bool OpenProcessToken(SafeProcessHandle process, uint access, out SafeAccessTokenHandle token);
 [DllImport("kernel32.dll", SetLastError=true)] static extern bool GetProcessTimes(SafeProcessHandle process, out long created, out long exited, out long kernel, out long user);
 [DllImport("kernel32.dll", SetLastError=true)] internal static extern bool TerminateProcess(SafeProcessHandle process, uint code);
 internal static string CurrentSid => WindowsIdentity.GetCurrent().User!.Value;
 internal static (long Start, string? Owner) Identity(SafeProcessHandle handle) {
  if(handle.IsInvalid || !GetProcessTimes(handle,out var start,out _,out _,out _)) throw new Win32Exception();
  if(!OpenProcessToken(handle,8,out var token)) throw new Win32Exception();
  using(token) using(var identity = new WindowsIdentity(token.DangerousGetHandle())) return (start,identity.User?.Value);
 }
}
