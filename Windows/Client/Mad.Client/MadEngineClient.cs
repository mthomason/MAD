//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  MadEngineClient.cs
//  The .NET side of the Phase 4 process contract (docs/developers/build/windows.md §Phase 4):
//  it spawns `mad serve`, speaks the newline-delimited JSON protocol, and exposes the
//  seven methods (open, describe, query, refresh, export, write, shutdown) as typed calls.
//
//  Standard output is the protocol; the engine's diagnostics stay on its standard
//  error, which this client leaves alone.  The child process is given the GNUstep
//  bin directory on PATH so `mad.exe` can find the shipped DLLs it links.
//

using System.Diagnostics;
using System.Text;
using System.Text.Json;

namespace Mad.Client;

/// <summary>The engine's answer to `engine-info`.  Every identity field is nullable:
/// an engine built without the generated identity file reports nulls, never a guess.</summary>
public sealed record EngineInfo(
	int ProtocolVersion,
	string? EngineVersion,
	string? EngineRevision,
	string? SourceCommit,
	string? SourceCommitShort,
	bool? SourceDirty,
	IReadOnlyList<string> Capabilities);

/// <summary>The `error` member of a failed response.</summary>
public sealed class MadEngineError
{
	public int Code { get; set; }
	public string Message { get; set; } = "";
}

/// <summary>One parsed response line from `mad serve`.</summary>
public sealed class MadEngineResponse
{
	public JsonElement Id { get; set; }
	public bool Ok { get; set; }
	public JsonElement Result { get; set; }
	public MadEngineError? Error { get; set; }

	public static MadEngineResponse Parse(string line)
	{
		using var document = JsonDocument.Parse(line);
		var root = document.RootElement;
		var response = new MadEngineResponse();
		if (root.TryGetProperty("id", out var id)) response.Id = id.Clone();
		if (root.TryGetProperty("ok", out var ok)) response.Ok = ok.GetBoolean();
		if (root.TryGetProperty("result", out var result)) response.Result = result.Clone();
		if (root.TryGetProperty("error", out var error))
		{
			response.Error = new MadEngineError
			{
				Code = error.GetProperty("code").GetInt32(),
				Message = error.GetProperty("message").GetString() ?? "",
			};
		}
		return response;
	}

	/// <summary>Throws a <see cref="MadEngineException"/> when the response is not `ok`.</summary>
	public void EnsureOk()
	{
		if (!Ok)
		{
			throw new MadEngineException(Error?.Code ?? -1, Error?.Message ?? "the engine reported an error");
		}
	}
}

/// <summary>A non-`ok` response, carrying the engine's error code (the CLI exit code).</summary>
public sealed class MadEngineException : Exception
{
	public int Code { get; }

	public MadEngineException(int code, string message) : base(message)
	{
		Code = code;
	}
}

/// <summary>A `mad serve` child process and the request/response line protocol.</summary>
public sealed class MadEngineClient : IDisposable
{
	private static readonly TimeSpan DefaultShutdownTimeout = TimeSpan.FromSeconds(5);

	private readonly string _madExePath;
	private readonly string? _gnustepBinPath;
	private readonly ProcessStartInfo? _testStartInfo;
	private Process? _process;
	private StreamWriter? _stdin;
	private StreamReader? _stdout;
	private readonly StringBuilder _stderr = new();
	private int _nextId = 1;
	private bool _disposed;

	public MadEngineClient(string madExePath, string? gnustepBinPath = null)
	{
		_madExePath = madExePath;
		_gnustepBinPath = gnustepBinPath;
	}

	/// <summary>Starts a supplied command instead of `mad serve`; tests only.</summary>
	internal MadEngineClient(ProcessStartInfo startInfo)
	{
		_madExePath = startInfo.FileName;
		_testStartInfo = startInfo;
	}

	public bool IsRunning => _process is { HasExited: false };

	/// <summary>The engine's standard error, drained continuously so the child never
	/// blocks on a full pipe.  Protocol output stays on standard output.</summary>
	public string Stderr => _stderr.ToString();

	/// <summary>The child's process id once started, or -1.</summary>
	public int Pid => _process?.Id ?? -1;

	/// <summary>The child's exit code once it has exited, or -1 while it runs.</summary>
	public int ExitCode => _process is { HasExited: true } ? _process.ExitCode : -1;

	public void Start()
	{
		if (_process != null)
		{
			throw new InvalidOperationException("the engine process is already started");
		}

		var startInfo = _testStartInfo ?? new ProcessStartInfo
		{
			FileName = _madExePath,
			Arguments = "serve",
			RedirectStandardInput = true,
			RedirectStandardOutput = true,
			RedirectStandardError = true,
			UseShellExecute = false,
			CreateNoWindow = true,
		};

		if (_testStartInfo == null && !string.IsNullOrEmpty(_gnustepBinPath))
		{
			var separator = Path.PathSeparator;
			var inherited = Environment.GetEnvironmentVariable("PATH") ?? "";
			startInfo.Environment["PATH"] = _gnustepBinPath + separator + inherited;
		}

		_process = new Process { StartInfo = startInfo };
		if (!_process.Start())
		{
			throw new InvalidOperationException("could not start the engine process");
		}

		_stdin = _process.StandardInput;
		_stdin.NewLine = "\n";
		_stdout = _process.StandardOutput;

		// Drain the engine's standard error on a background thread.  Without this the
		// child can block writing diagnostics once the pipe buffer fills, while this
		// client blocks reading standard output -- a deadlock.  The bytes are kept so
		// a failing test can surface what the engine reported.
		_process.ErrorDataReceived += (_, eventArgs) =>
		{
			if (eventArgs.Data != null) _stderr.AppendLine(eventArgs.Data);
		};
		_process.BeginErrorReadLine();
	}

	/// <summary>Sends one request and reads its response.</summary>
	public MadEngineResponse Call(string method, IReadOnlyDictionary<string, object?>? parameters = null)
	{
		EnsureRunning();

		int id = _nextId++;
		var request = new Dictionary<string, object?>
		{
			["id"] = id,
			["method"] = method,
			["params"] = parameters ?? new Dictionary<string, object?>(),
		};

		_stdin!.WriteLine(JsonSerializer.Serialize(request));
		_stdin.Flush();

		string? line = _stdout!.ReadLine();
		if (line == null)
		{
			throw new MadEngineException(-1, "the engine closed its standard output before answering");
		}
		return MadEngineResponse.Parse(line);
	}

	/// <summary>Sends a request and returns its `result` member, throwing on `ok: false`.</summary>
	public JsonElement CallOk(string method, IReadOnlyDictionary<string, object?>? parameters = null)
	{
		var response = Call(method, parameters);
		response.EnsureOk();
		return response.Result;
	}

	/// <summary>Sends one raw protocol line and reads its response.  This is how a test
	/// exercises malformed input, which the formatted `Call` cannot produce.</summary>
	public MadEngineResponse SendRaw(string line)
	{
		EnsureRunning();
		_stdin!.WriteLine(line);
		_stdin.Flush();
		string? reply = _stdout!.ReadLine();
		if (reply == null)
		{
			throw new MadEngineException(-1, "the engine closed its standard output before answering");
		}
		return MadEngineResponse.Parse(reply);
	}

	/// <summary>`engine-info` -- the running engine's identity.  An engine older than
	/// this client answers "unknown method", which raises <see cref="MadEngineException"/>;
	/// callers treat that as an unknown identity, never as a failed open.</summary>
	public EngineInfo EngineInfo()
	{
		var result = CallOk("engine-info");
		int protocolVersion = result.TryGetProperty("protocolVersion", out var protocol)
			&& protocol.ValueKind == JsonValueKind.Number ? protocol.GetInt32() : 0;

		string? String(string name) =>
			result.TryGetProperty(name, out var value) && value.ValueKind == JsonValueKind.String
				? value.GetString() : null;

		bool? dirty = null;
		if (result.TryGetProperty("sourceDirty", out var dirtyValue))
		{
			if (dirtyValue.ValueKind == JsonValueKind.True) dirty = true;
			else if (dirtyValue.ValueKind == JsonValueKind.False) dirty = false;
		}

		var capabilities = new List<string>();
		if (result.TryGetProperty("capabilities", out var collection)
			&& collection.ValueKind == JsonValueKind.Array)
		{
			foreach (var capability in collection.EnumerateArray())
			{
				if (capability.ValueKind == JsonValueKind.String
					&& capability.GetString() is { } name)
				{
					capabilities.Add(name);
				}
			}
		}

		return new EngineInfo(protocolVersion, String("engineVersion"),
			String("engineRevision"), String("sourceCommit"),
			String("sourceCommitShort"), dirty, capabilities);
	}

	/// <summary>`open` -- opens a document and returns its handle.</summary>
	public int Open(string path, string? host = null, int? port = null, string? database = null)
	{
		var parameters = new Dictionary<string, object?> { ["path"] = path };
		if (host != null) parameters["host"] = host;
		if (port is int portValue) parameters["port"] = portValue;
		if (database != null) parameters["database"] = database;
		return CallOk("open", parameters).GetProperty("handle").GetInt32();
	}

	/// <summary>`shutdown` -- asks the engine to stop, then waits for the process to exit.</summary>
	public void Shutdown() => Shutdown(DefaultShutdownTimeout);

	internal void Shutdown(TimeSpan timeout)
	{
		if (_process == null || _process.HasExited)
		{
			return;
		}

		try
		{
			Task response = Task.Run(() => CallOk("shutdown"));
			if (!BoundedWait.Wait(response, timeout))
			{
				try { _process.Kill(entireProcessTree: true); } catch { /* best effort */ }
			}
		}
		catch
		{
			/* best effort */
		}

		if (!_process.WaitForExit(5000))
		{
			try { _process.Kill(entireProcessTree: true); } catch { /* best effort */ }
		}
	}

	public void Dispose()
	{
		if (_disposed)
		{
			return;
		}
		_disposed = true;

		try { Shutdown(); } catch { /* best effort */ }

		if (_process is { HasExited: false })
		{
			try { _process.Kill(entireProcessTree: true); } catch { /* best effort */ }
		}
		_process?.Dispose();
	}

	private void EnsureRunning()
	{
		if (_process == null || _process.HasExited)
		{
			throw new MadEngineException(-1, "the engine process is not running");
		}
	}
}
