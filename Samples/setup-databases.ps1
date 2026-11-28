#Requires -Version 7
<#
  Samples/setup-databases.ps1 -- Windows entry point for the sample databases.

  Wraps Samples/setup-databases.sh so the same actions work from PowerShell.
  It finds Git Bash, checks that Docker Desktop is available for the actions
  that touch containers, and calls the shell script.

      .\Samples\setup-databases.ps1 -Action up
      .\Samples\setup-databases.ps1 -Action status
      .\Samples\setup-databases.ps1 -Action down
      .\Samples\setup-databases.ps1 -Action sql
#>
[CmdletBinding()]
param(
	[Parameter(Mandatory = $true)]
	[ValidateSet('up', 'status', 'down', 'sql')]
	[string]$Action
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

# --- Docker Desktop (only the actions that touch containers) -------------------
if ($Action -ne 'sql') {
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

& $bash -c 'cd "$(cygpath -u "$1")" && exec ./Samples/setup-databases.sh "$2"' _ $repo $Action
exit $LASTEXITCODE
