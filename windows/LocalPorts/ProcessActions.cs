using System.ComponentModel;
using System.Diagnostics;
using LocalPorts.Core;
namespace LocalPorts;
internal static class ProcessActions {
 internal static void Stop(Listener row, IWin32Window owner) {
  if(MessageBox.Show(owner,$"Request {row.Name} (PID {row.Pid}) to close? All of its listening ports are affected.","Close process",MessageBoxButtons.YesNo,MessageBoxIcon.Warning,MessageBoxDefaultButton.Button2)!=DialogResult.Yes) return;
  // Hold the process object handle across confirmation and action. Never kill by PID.
  using var handle=Native.OpenProcess(0x1001,false,row.Pid);
  var identity=Native.Identity(handle);
  if(!ProcessSafety.CanStop(row.Pid,row.Start,row.Owner,row.Pid,identity.Start,identity.Owner,Native.CurrentSid,Environment.ProcessId)) throw new InvalidOperationException("Process identity or ownership changed. Refresh and try again.");
  using var process=Process.GetProcessById(row.Pid);
  // The retained native handle prevents PID reuse while CloseMainWindow resolves the PID.
  bool requested=process.CloseMainWindow();
  if(requested) { MessageBox.Show(owner,"A close request was sent. Click OK to check whether it has exited. If still running, you can cancel the next dialog to give it more time."); }
  if(process.HasExited) return;
  if(MessageBox.Show(owner,(requested?"The process has not exited yet. You can cancel and give it time.\n\n":"This process has no closeable main window.\n\n")+$"Force terminate {row.Name} (PID {row.Pid})? Unsaved work may be lost.","Force termination",MessageBoxButtons.YesNo,MessageBoxIcon.Warning,MessageBoxDefaultButton.Button2)!=DialogResult.Yes) return;
  identity=Native.Identity(handle);
  if(!ProcessSafety.CanStop(row.Pid,row.Start,row.Owner,row.Pid,identity.Start,identity.Owner,Native.CurrentSid,Environment.ProcessId)) throw new InvalidOperationException("Process identity changed.");
  if(!Native.TerminateProcess(handle,1)) throw new Win32Exception();
 }
}
