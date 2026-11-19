#Requires -Version 7
<#
  TestDatabase/test-databases.ps1 -- Windows entry point for the test servers.

  Wraps the shell orchestrator (TestDatabase/test-databases.sh) so the same
  verbs work from PowerShell.  It finds Git Bash, checks that Docker Desktop is
  available for the verbs that touch containers, and calls the shell
  orchestrator.  `download` and `env` work without the Docker daemon; `env` only
  prints the assignments (it never changes the caller's environment).

      .\TestDatabase\test-databases.ps1 -Action up
      .\TestDatabase\test-databases.ps1 -Action download
      .\TestDatabase\test-databases.ps1 -Action status -Service mysql
      .\TestDatabase\test-databases.ps1 -Action env
#>
[CmdletBinding()]
param(
	[Parameter(Mandatory = $true)]
	[ValidateSet('up', 'download', 'wait', 'verify', 'status', 'logs', 'down', 'reset', 'env')]
	[string]$Action,

	[ValidateSet('all', 'mysql', 'tds', 'postgres')]
	[string]$Service = 'all'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# --- Git Bash -----------------------------------------------------------------
$bash = $null
$candidate = 'C:\Program Files\Git\bin\bash.exe'
if (Test-Path $candidate) {
	$bash = $candidate
} else {
	$cmd = Get-Command bash -ErrorAction SilentlyContinue
	if ($cmd) { $bash = $cmd.Source }
}
if (-not $bash -or -not (Test-Path $bash)) {
	throw 'Git Bash (bash.exe) not found. Install Git for Windows, or put bash on PATH.'
}

# --- Docker Desktop (only the verbs that touch containers) --------------------
if ($Action -notin @('download', 'env')) {
	$dockerCmd = Get-Command docker -ErrorAction SilentlyContinue
	if (-not $dockerCmd) {
		throw 'Docker CLI not found. Install/start Docker Desktop with Linux containers.'
	}
	& docker info *> $null
	if ($LASTEXITCODE -ne 0) {
		throw 'The Docker daemon is not running. Start Docker Desktop (Linux containers).'
	}
}

$repo = Split-Path $PSScriptRoot -Parent

# bash: cd into the repo (converting the Windows path to POSIX) and run the
# shell orchestrator.  `_` is $0; $1..$3 are the repo, action and service.
& $bash -c 'cd "$(cygpath -u "$1")" && exec ./TestDatabase/test-databases.sh "$2" "$3"' _ $repo $Action $Service
exit $LASTEXITCODE
