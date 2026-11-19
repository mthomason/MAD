//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  Program.cs
//  The executable acceptance test for the Phase 4 process contract: it opens
//  CLI/Fixtures/London.portable.mad through `mad serve`, lists the schema and rows,
//  exports CSV, and shuts the engine down cleanly.  Exits 0 when the flow completes.
//
//    dotnet run --project Mad.Client -- --mad <mad.exe> --document <doc.mad>
//
//  Every path is optional; the defaults resolve the repo's build output and fixture.
//

using System.Text.Json;
using Mad.Client;

static string? Argument(string[] args, string name)
{
	for (int i = 0; i < args.Length - 1; i++)
	{
		if (args[i] == name) return args[i + 1];
	}
	return null;
}

static string FindRepoRoot()
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

int Run(string[] args)
{
	string repoRoot = FindRepoRoot();
	string madExe = Argument(args, "--mad") ?? Path.Combine(repoRoot, "Windows", "Engine", "build", "mad.exe");
	string document = Argument(args, "--document") ?? Path.Combine(repoRoot, "CLI", "Fixtures", "London.portable.mad");
	string gnustepBin = Argument(args, "--gnustep-bin") ?? Environment.GetEnvironmentVariable("GNUSTEP_BIN") ?? @"C:\GNUstep\x64\Release\bin";
	string csvOut = Argument(args, "--csv-out") ?? Path.Combine(Path.GetTempPath(), "london-export.csv");

	if (!File.Exists(madExe)) throw new FileNotFoundException("mad.exe not found; build it first with Windows/Engine/build.ps1", madExe);
	if (!File.Exists(document)) throw new FileNotFoundException("fixture not found", document);

	using var client = new MadEngineClient(madExe, gnustepBin);
	client.Start();

	int handle = client.Open(document);
	Console.WriteLine($"open: handle={handle}");

	var describe = client.CallOk("describe", new Dictionary<string, object?> { ["handle"] = handle });
	string driver = describe.GetProperty("driver").GetString() ?? "";
	var columns = describe.GetProperty("columns");
	var tables = describe.GetProperty("tables");
	Console.WriteLine($"describe: driver={driver} columns={columns.GetArrayLength()} tables={tables.GetArrayLength()}");
	foreach (var column in columns.EnumerateArray())
	{
		Console.WriteLine($"  column {column.GetProperty("key").GetString()} -> {column.GetProperty("name").GetString()} ({column.GetProperty("type").GetString()})");
	}

	var refresh = client.CallOk("refresh", new Dictionary<string, object?> { ["handle"] = handle });
	int rowCount = refresh.GetProperty("rowCount").GetInt32();
	Console.WriteLine($"refresh: rowCount={rowCount} elapsed={refresh.GetProperty("elapsed").GetDouble():F3}s");

	var json = client.CallOk("export", new Dictionary<string, object?> { ["handle"] = handle, ["format"] = "json" });
	using var report = JsonDocument.Parse(json.GetProperty("data").GetString()!);
	int jsonRows = report.RootElement.GetProperty("rows").GetArrayLength();
	Console.WriteLine($"export json: rows={jsonRows}");

	var csv = client.CallOk("export", new Dictionary<string, object?> { ["handle"] = handle, ["format"] = "csv" });
	string csvText = csv.GetProperty("data").GetString() ?? "";
	File.WriteAllText(csvOut, csvText);
	int csvLines = csvText.Split('\n').Count(line => line.TrimEnd('\r').Length > 0);
	Console.WriteLine($"export csv: wrote {csvOut} ({csvLines} lines)");

	client.Shutdown();
	Console.WriteLine($"shutdown: engine exited {client.ExitCode}");
	return client.ExitCode == 0 ? 0 : 1;
}

try
{
	return Run(args);
}
catch (Exception exception)
{
	Console.Error.WriteLine($"acceptance flow failed: {exception.Message}");
	return 1;
}
