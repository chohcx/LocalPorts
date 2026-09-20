using LocalPorts.Core;
using Xunit;
public class SafetyTests {
 [Fact] public void ReusedPidIsRejected() => Assert.False(ProcessSafety.CanStop(10, 100, "me", 10, 101, "me", "me", 99));
 [Fact] public void OtherOwnerIsRejected() => Assert.False(ProcessSafety.CanStop(10, 100, "other", 10, 100, "other", "me", 99));
 [Fact] public void OwnUnchangedProcessIsAllowed() => Assert.True(ProcessSafety.CanStop(10, 100, "me", 10, 100, "me", "me", 99));
 [Fact] public void SelfIsRejected() => Assert.False(ProcessSafety.CanStop(10, 100, "me", 10, 100, "me", "me", 10));
 [Fact] public void UnknownOwnerIsRejected() => Assert.False(ProcessSafety.CanStop(10, 100, null, 10, 100, null, "me", 99));
}
