namespace LocalPorts.Core;
public static class ProcessSafety {
 public static bool CanStop(int expectedPid, long expectedStart, string? expectedOwner, int actualPid, long actualStart, string? actualOwner, string currentOwner, int selfPid) =>
 expectedPid > 4 && expectedPid != selfPid && expectedPid == actualPid && expectedStart > 0 && expectedStart == actualStart && !string.IsNullOrEmpty(expectedOwner) && expectedOwner == currentOwner && actualOwner == currentOwner;
}
