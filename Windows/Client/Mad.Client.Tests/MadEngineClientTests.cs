//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  MadEngineClientTests.cs
//  The Phase 4 acceptance tests: the success path over CLI/Fixtures/London.portable.mad,
//  malformed requests, engine failures and clean process shutdown.  Each test starts its
//  own `mad serve` child; `Dispose`/`Shutdown` ends it so no test leaves an orphan.
//
//  The engine must be built first (Windows/Engine/build.ps1).  Override the discovered
//  paths with MAD_EXE and GNUSTEP_BIN if the build lives elsewhere.
//

using System.Diagnostics;
using System.Text.Json;

namespace Mad.Client.Tests;

public sealed class MadEngineClientTests
{
	private static string RepoRoot()
	{
		var directory = new DirectoryInfo(AppContext.BaseDirectory);
		while (directory != null)
		{
			if (File.Exists(Path.Combine(directory.FullName, "CLI", "Fixtures", "London.portable.mad")))
			{
				return directory.FullName;
			}
			directory = directory.Parent;
		}
		throw new DirectoryNotFoundException("could not locate the repo root (CLI/Fixtures/London.portable.mad)");
	}

	private static string MadExe =>
		Environment.GetEnvironmentVariable("MAD_EXE")
		?? Path.Combine(RepoRoot(), "Windows", "Engine", "build", "mad.exe");

	private static string GnustepBin =>
		Environment.GetEnvironmentVariable("GNUSTEP_BIN")
		?? @"C:\GNUstep\x64\Release\bin";

	private static string London => Path.Combine(RepoRoot(), "CLI", "Fixtures", "London.portable.mad");

	private static MadEngineClient StartClient() => new(MadExe, GnustepBin);

	private static Dictionary<string, object?> Dict(params object[] keyValues)
	{
		var dictionary = new Dictionary<string, object?>();
		for (int i = 0; i + 1 < keyValues.Length; i += 2)
		{
			dictionary[(string)keyValues[i]] = keyValues[i + 1];
		}
		return dictionary;
	}

	private static void AssertProcessGone(int pid)
	{
		for (int i = 0; i < 50; i++)
		{
			try
			{
				Process.GetProcessById(pid);
			}
			catch (ArgumentException)
			{
				return; // the process no longer exists
			}
			Thread.Sleep(100);
		}
		Assert.Fail($"process {pid} is still running after shutdown");
	}

	[Fact]
	public void LondonFixture_OpenDescribeRefreshExport_Completes()
	{
		using var client = StartClient();
		client.Start();

		int handle = client.Open(London);
		Assert.True(handle >= 0);

		var describe = client.CallOk("describe", Dict("handle", handle));
		Assert.Equal("Sqlite 3", describe.GetProperty("driver").GetString());
		Assert.Equal(21, describe.GetProperty("columns").GetArrayLength());
		Assert.Equal(11, describe.GetProperty("tables").GetArrayLength());

		var firstColumn = describe.GetProperty("columns")[0];
		Assert.Equal("\"Album0\".\"AlbumId\"", firstColumn.GetProperty("key").GetString());
		Assert.Equal("AlbumId", firstColumn.GetProperty("name").GetString());
		Assert.Equal("Integer", firstColumn.GetProperty("type").GetString());

		var query = client.CallOk("query", Dict("handle", handle));
		Assert.Contains("FROM", query.GetProperty("sql").GetString());

		var refresh = client.CallOk("refresh", Dict("handle", handle));
		Assert.Equal(76, refresh.GetProperty("rowCount").GetInt32());

		var json = client.CallOk("export", Dict("handle", handle, "format", "json"));
		using var report = JsonDocument.Parse(json.GetProperty("data").GetString()!);
		Assert.Equal("mad.report/1", report.RootElement.GetProperty("format").GetString());
		Assert.Equal(76, report.RootElement.GetProperty("rows").GetArrayLength());

		var csv = client.CallOk("export", Dict("handle", handle, "format", "csv"));
		string csvText = csv.GetProperty("data").GetString()!;
		var lines = csvText.Split("\r\n", StringSplitOptions.None);
		Assert.Equal(78, lines.Length); // header + 76 rows + the trailing empty element
		Assert.Contains("AlbumId", lines[0]);

		client.Shutdown();
		Assert.Equal(0, client.ExitCode);
	}

	[Fact]
	public void Write_ProducesACopy()
	{
		using var client = StartClient();
		client.Start();

		int handle = client.Open(London);
		string outPath = Path.Combine(Path.GetTempPath(), $"mad-serve-copy-{Guid.NewGuid():N}.mad");
		try
		{
			var write = client.CallOk("write", Dict("handle", handle, "out", outPath, "reproducible", true));
			Assert.Equal(outPath, write.GetProperty("path").GetString());
			Assert.True(write.GetProperty("bytes").GetInt64() > 0);
			Assert.True(File.Exists(outPath));
		}
		finally
		{
			if (File.Exists(outPath)) File.Delete(outPath);
		}
	}

	[Fact]
	public void MalformedRequest_IsAStructuredError_AndTheSessionSurvives()
	{
		using var client = StartClient();
		client.Start();

		var error = client.SendRaw("this is not JSON");
		Assert.False(error.Ok);
		Assert.Equal(1, error.Error!.Code);
		Assert.False(string.IsNullOrEmpty(error.Error.Message));

		int handle = client.Open(London); // the session is still alive
		Assert.True(handle >= 0);
	}

	[Fact]
	public void UnknownMethod_IsAStructuredError()
	{
		using var client = StartClient();
		client.Start();

		var error = client.Call("frobnicate");
		Assert.False(error.Ok);
		Assert.Equal(1, error.Error!.Code);
		Assert.Contains("frobnicate", error.Error.Message);
	}

	[Fact]
	public void OpenMissingDocument_IsABadDocumentError()
	{
		using var client = StartClient();
		client.Start();

		var error = client.Call("open", Dict("path", Path.Combine(RepoRoot(), "no-such.mad")));
		Assert.False(error.Ok);
		Assert.Equal(2, error.Error!.Code);
	}

	[Fact]
	public void ExportUnavailableFormat_IsAnExportError()
	{
		using var client = StartClient();
		client.Start();

		int handle = client.Open(London);
		var error = client.Call("export", Dict("handle", handle, "format", "pdf"));
		Assert.False(error.Ok);
		Assert.Equal(5, error.Error!.Code); // pdf is not available off Apple
	}

	[Fact]
	public void Shutdown_ExitsCleanly_WithNoOrphanProcess()
	{
		int pid;
		var client = StartClient();
		client.Start();
		pid = client.Pid;
		Assert.True(pid > 0);

		client.Shutdown();
		Assert.Equal(0, client.ExitCode);
		client.Dispose();

		AssertProcessGone(pid);
	}
}
