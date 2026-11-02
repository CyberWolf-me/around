<#
.SYNOPSIS
  Around — Polsia-Style 24/7 Autonomous Company Loop for Windows PowerShell (`d:\around`)
.DESCRIPTION
  Runs outside the Antigravity IDE chat window in a standard Windows PowerShell terminal
  so the loop never terminates after a single chat turn.
#>
param(
  [int]$MaxCycles = 0,
  [int]$MaxRework = 4,
  [int]$SleepSeconds = 8
)

$ErrorActionPreference = "Continue"
Write-Host "Starting Around Polsia 24/7 Autonomous Company Daemon on Windows..." -ForegroundColor Cyan

$nodeArgs = @("scripts/polsia_daemon.mjs", "--max-rework", "$MaxRework", "--sleep", "$SleepSeconds")
if ($MaxCycles -gt 0) {
  $nodeArgs += @("--max-cycles", "$MaxCycles")
}

& node @nodeArgs
