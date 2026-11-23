//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  BoundedWait.cs
//  Waits for a task for a fixed period. A faulted task counts as completed;
//  a timeout returns false.
//

namespace Mad.Client;

internal static class BoundedWait
{
	internal static bool Wait(Task task, TimeSpan timeout)
	{
		try
		{
			return task.Wait(timeout);
		}
		catch
		{
			return true;
		}
	}
}
