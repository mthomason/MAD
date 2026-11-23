//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  BoundedWaitTests.cs
//  The bounded wait used by shutdown: a pending task times out, a completed
//  or faulted task counts as finished.
//

namespace Mad.Client.Tests;

public sealed class BoundedWaitTests
{
	[Fact]
	public void Wait_ReturnsFalse_WhenTheTaskDoesNotComplete()
	{
		var pending = new TaskCompletionSource();
		Assert.False(BoundedWait.Wait(pending.Task, TimeSpan.FromMilliseconds(100)));
	}

	[Fact]
	public void Wait_ReturnsTrue_WhenTheTaskCompletes()
	{
		var done = new TaskCompletionSource();
		done.SetResult();
		Assert.True(BoundedWait.Wait(done.Task, TimeSpan.FromSeconds(1)));
	}

	[Fact]
	public void Wait_ReturnsTrue_WhenTheTaskFaults()
	{
		var faulted = new TaskCompletionSource();
		faulted.SetException(new InvalidOperationException("closed"));
		Assert.True(BoundedWait.Wait(faulted.Task, TimeSpan.FromSeconds(1)));
	}
}
