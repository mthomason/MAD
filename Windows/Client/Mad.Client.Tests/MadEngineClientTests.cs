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

	private static string ChinookSqlite => Path.Combine(RepoRoot(), "MADDesigner", "Resources", "Assets", "Samples.xcassets", "Data", "chinook.dataset", "chinook.sqlite3");

	private static string CopyChinookToTemp()
	{
		string temp = Path.Combine(Path.GetTempPath(), $"mad-chinook-{Guid.NewGuid():N}.sqlite3");
		File.Copy(ChinookSqlite, temp);
		return temp;
	}

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
	public void ExportUnknownFormat_IsAnExportError()
	{
		using var client = StartClient();
		client.Start();

		int handle = client.Open(London);
		var error = client.Call("export", Dict("handle", handle, "format", "docx"));
		Assert.False(error.Ok);
		Assert.Equal(1, error.Error!.Code); // usage: --format is not a format this build has
	}

	[Fact]
	public void ExportPdf_WritesAPdfFile()
	{
		using var client = StartClient();
		client.Start();

		int handle = client.Open(London);
		string outPath = Path.Combine(Path.GetTempPath(), $"mad-serve-pdf-{Guid.NewGuid():N}.pdf");
		try
		{
			var result = client.CallOk("export", Dict("handle", handle, "format", "pdf", "path", outPath));
			Assert.Equal("pdf", result.GetProperty("format").GetString());
			Assert.True(result.GetProperty("bytes").GetInt64() > 0);
			Assert.True(File.Exists(outPath));

			byte[] header = new byte[5];
			using (var stream = File.OpenRead(outPath)) stream.ReadExactly(header);
			Assert.Equal("%PDF-", System.Text.Encoding.ASCII.GetString(header));
		}
		finally
		{
			if (File.Exists(outPath)) File.Delete(outPath);
		}
	}

	[Fact]
	public void TestConnection_Sqlite_ReportsElevenTables()
	{
		using var client = StartClient();
		client.Start();

		string sqlite = CopyChinookToTemp();
		try
		{
			var result = client.CallOk("test-connection", Dict("driver", "sqlite3", "file", sqlite));
			Assert.Equal(11, result.GetProperty("tableCount").GetInt32());
		}
		finally
		{
			File.Delete(sqlite);
		}
	}

	[Fact]
	public void TestConnection_MissingSqliteFile_IsDatabaseUnreachable()
	{
		using var client = StartClient();
		client.Start();

		string missing = Path.Combine(Path.GetTempPath(), $"mad-missing-{Guid.NewGuid():N}.sqlite3");
		var error = client.Call("test-connection", Dict("driver", "sqlite3", "file", missing));
		Assert.False(error.Ok);
		Assert.Equal(3, error.Error!.Code);
		Assert.False(File.Exists(missing));
	}

	[Fact]
	public void TestConnection_ServerMissingHost_IsUsageError()
	{
		using var client = StartClient();
		client.Start();

		var error = client.Call("test-connection", Dict("driver", "mysql", "database", "employees"));
		Assert.False(error.Ok);
		Assert.Equal(1, error.Error!.Code);
	}

	[Fact]
	public void TestConnection_UnknownDriver_IsUsageError()
	{
		using var client = StartClient();
		client.Start();

		var error = client.Call("test-connection", Dict("driver", "oracle"));
		Assert.False(error.Ok);
		Assert.Equal(1, error.Error!.Code);
	}

	[Fact]
	public void Create_FromSqlite_DescribesSchema()
	{
		var client = StartClient();
		client.Start();

		string sqlite = CopyChinookToTemp();
		string mad = Path.Combine(Path.GetTempPath(), $"mad-created-{Guid.NewGuid():N}.mad");
		try
		{
			var create = client.CallOk("create", Dict("path", mad, "driver", "sqlite3", "file", sqlite));
			int handle = create.GetProperty("handle").GetInt32();
			Assert.True(handle >= 0);
			Assert.Equal("Sqlite 3", create.GetProperty("driver").GetString());

			var describe = client.CallOk("describe", Dict("handle", handle));
			Assert.Equal(11, describe.GetProperty("tables").GetArrayLength());
		}
		finally
		{
			client.Dispose(); // release the engine's handle on the source SQLite before cleanup
			if (File.Exists(sqlite)) File.Delete(sqlite);
			if (File.Exists(mad)) File.Delete(mad);
		}
	}

	[Fact]
	public void Create_IntoNewDirectory_Succeeds()
	{
		var client = StartClient();
		client.Start();

		string sqlite = CopyChinookToTemp();
		string dir = Path.Combine(Path.GetTempPath(), $"mad-newdir-{Guid.NewGuid():N}");
		string mad = Path.Combine(dir, "report.mad");
		try
		{
			var create = client.CallOk("create", Dict("path", mad, "driver", "sqlite3", "file", sqlite));
			Assert.True(create.GetProperty("handle").GetInt32() >= 0);
			Assert.True(File.Exists(mad));
		}
		finally
		{
			client.Dispose();
			if (File.Exists(sqlite)) File.Delete(sqlite);
			if (Directory.Exists(dir)) Directory.Delete(dir, recursive: true);
		}
	}

	[Fact]
	public void Create_MissingSqliteFile_IsDatabaseUnreachable_NoMadFile()
	{
		var client = StartClient();
		client.Start();

		string missing = Path.Combine(Path.GetTempPath(), $"mad-missing-{Guid.NewGuid():N}.sqlite3");
		string mad = Path.Combine(Path.GetTempPath(), $"mad-created-{Guid.NewGuid():N}.mad");
		try
		{
			var error = client.Call("create", Dict("path", mad, "driver", "sqlite3", "file", missing));
			Assert.False(error.Ok);
			Assert.Equal(3, error.Error!.Code);
			Assert.False(File.Exists(mad));
			Assert.False(File.Exists(missing));
		}
		finally
		{
			client.Dispose();
			if (File.Exists(mad)) File.Delete(mad);
			if (File.Exists(missing)) File.Delete(missing);
		}
	}

	[Fact]
	public void Connection_ReadsBackSqliteFile()
	{
		var client = StartClient();
		client.Start();

		string sqlite = CopyChinookToTemp();
		string mad = Path.Combine(Path.GetTempPath(), $"mad-created-{Guid.NewGuid():N}.mad");
		try
		{
			var create = client.CallOk("create", Dict("path", mad, "driver", "sqlite3", "file", sqlite));
			int handle = create.GetProperty("handle").GetInt32();

			var conn = client.CallOk("connection", Dict("handle", handle));
			Assert.Equal("sqlite3", conn.GetProperty("driver").GetString());
			Assert.Equal(sqlite, conn.GetProperty("file").GetString());
		}
		finally
		{
			client.Dispose();
			if (File.Exists(sqlite)) File.Delete(sqlite);
			if (File.Exists(mad)) File.Delete(mad);
		}
	}

	[Fact]
	public void Connection_UnknownHandle_IsUsageError()
	{
		using var client = StartClient();
		client.Start();

		var error = client.Call("connection", Dict("handle", 99999));
		Assert.False(error.Ok);
		Assert.Equal(1, error.Error!.Code);
	}

	[Fact]
	public void ApplyConnection_UnreachableServer_IsDatabaseUnreachable()
	{
		var client = StartClient();
		client.Start();

		string sqlite = CopyChinookToTemp();
		string mad = Path.Combine(Path.GetTempPath(), $"mad-created-{Guid.NewGuid():N}.mad");
		try
		{
			var create = client.CallOk("create", Dict("path", mad, "driver", "sqlite3", "file", sqlite));
			int handle = create.GetProperty("handle").GetInt32();

			var error = client.Call("apply-connection", Dict("handle", handle, "driver", "mysql",
				"host", "127.0.0.1", "port", 1, "database", "test", "credentials", "root:root"));
			Assert.False(error.Ok);
			Assert.Equal(3, error.Error!.Code);
		}
		finally
		{
			client.Dispose();
			if (File.Exists(sqlite)) File.Delete(sqlite);
			if (File.Exists(mad)) File.Delete(mad);
		}
	}

	[Fact]
	public void ApplyConnection_ThenWrite_PersistsTheNewConnection()
	{
		var client = StartClient();
		client.Start();

		string sqliteA = CopyChinookToTemp();
		string sqliteB = CopyChinookToTemp();
		string mad = Path.Combine(Path.GetTempPath(), $"mad-created-{Guid.NewGuid():N}.mad");
		string copy = Path.Combine(Path.GetTempPath(), $"mad-copy-{Guid.NewGuid():N}.mad");
		try
		{
			var create = client.CallOk("create", Dict("path", mad, "driver", "sqlite3", "file", sqliteA));
			int handle = create.GetProperty("handle").GetInt32();

			// Reconnect the live document to a different (equally valid) SQLite file.
			client.CallOk("apply-connection", Dict("handle", handle, "driver", "sqlite3", "file", sqliteB));

			// `write` must serialize the live document, so the copy carries the new
			// connection (file B), not the original source (file A).
			client.CallOk("write", Dict("handle", handle, "out", copy, "reproducible", true));
			int copyHandle = client.Open(copy);
			var conn = client.CallOk("connection", Dict("handle", copyHandle));
			Assert.Equal(Path.GetFullPath(sqliteB), Path.GetFullPath(conn.GetProperty("file").GetString() ?? ""));
		}
		finally
		{
			client.Dispose();
			if (File.Exists(sqliteA)) File.Delete(sqliteA);
			if (File.Exists(sqliteB)) File.Delete(sqliteB);
			if (File.Exists(mad)) File.Delete(mad);
			if (File.Exists(copy)) File.Delete(copy);
		}
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
