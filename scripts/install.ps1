<#
.SYNOPSIS
  Install Semantic Model Dashboard Skills into an AI agent's skills folder (Windows PowerShell 5.1+ / PowerShell 7+).

.EXAMPLE
  .\scripts\install.ps1 -Agent claude
  .\scripts\install.ps1 -Agent codex -Scope project -Target C:\work\my-bi-project
  .\scripts\install.ps1 -Dest D:\skills -Skills finance-pnl-dashboard,bi-dashboard-design,powerbi-dashboard-builder

.NOTES
  Default destinations (user scope / project scope):
    claude       %USERPROFILE%\.claude\skills          <Target>\.claude\skills
    codex        %USERPROFILE%\.agents\skills          <Target>\.agents\skills
    antigravity  %USERPROFILE%\.gemini\config\skills   <Target>\.agents\skills
    kiro         %USERPROFILE%\.kiro\skills            <Target>\.kiro\skills
    agents       %USERPROFILE%\.agents\skills          <Target>\.agents\skills
  -Link creates directory junctions instead of copies, so `git pull` updates installed skills.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
  [ValidateSet('claude', 'codex', 'antigravity', 'kiro', 'agents')]
  [string]$Agent,
  [ValidateSet('user', 'project')]
  [string]$Scope = 'user',
  [string]$Target = (Get-Location).Path,
  [string]$Dest,
  [switch]$Link,
  [string[]]$Skills,
  [switch]$Force
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent $PSScriptRoot
$Src = Join-Path $RepoRoot 'skills'
$HomeDir = [Environment]::GetFolderPath('UserProfile')

if (-not $Dest) {
  if (-not $Agent) { throw 'Specify -Agent or -Dest. Run Get-Help .\scripts\install.ps1 for usage.' }
  $map = @{
    'claude:user'         = Join-Path $HomeDir '.claude\skills'
    'claude:project'      = Join-Path $Target '.claude\skills'
    'codex:user'          = Join-Path $HomeDir '.agents\skills'
    'codex:project'       = Join-Path $Target '.agents\skills'
    'antigravity:user'    = Join-Path $HomeDir '.gemini\config\skills'
    'antigravity:project' = Join-Path $Target '.agents\skills'
    'kiro:user'           = Join-Path $HomeDir '.kiro\skills'
    'kiro:project'        = Join-Path $Target '.kiro\skills'
    'agents:user'         = Join-Path $HomeDir '.agents\skills'
    'agents:project'      = Join-Path $Target '.agents\skills'
  }
  $Dest = $map["${Agent}:${Scope}"]
}

if (-not $Skills -or $Skills.Count -eq 0) {
  $Skills = Get-ChildItem -Path $Src -Directory |
    Where-Object { Test-Path (Join-Path $_.FullName 'SKILL.md') } |
    ForEach-Object { $_.Name }
}

Write-Host "Installing $($Skills.Count) skill(s) into: $Dest"
Write-Host ("Mode: " + ($(if ($Link) { 'junction (linked)' } else { 'copy' })))

if (-not (Test-Path $Dest)) {
  if ($PSCmdlet.ShouldProcess($Dest, 'Create folder')) { New-Item -ItemType Directory -Path $Dest -Force | Out-Null }
}

$installed = 0; $skipped = 0
foreach ($name in $Skills) {
  $name = $name.Trim()
  $s = Join-Path $Src $name
  $d = Join-Path $Dest $name
  if (-not (Test-Path (Join-Path $s 'SKILL.md'))) { throw "$name not found in $Src" }
  if (Test-Path $d) {
    if ($Force) {
      if ($PSCmdlet.ShouldProcess($d, 'Replace')) {
        $item = Get-Item $d -Force
        if ($item.LinkType) { $item.Delete() } else { Remove-Item $d -Recurse -Force }
      }
    } else {
      Write-Host "  - ${name}: already exists (use -Force to replace)"; $skipped++; continue
    }
  }
  if ($PSCmdlet.ShouldProcess($d, 'Install skill')) {
    if ($Link) { New-Item -ItemType Junction -Path $d -Target $s | Out-Null }
    else { Copy-Item -Path $s -Destination $d -Recurse }
  }
  Write-Host "  + $name"
  $installed++
}

Write-Host ""
Write-Host "Done: $installed installed, $skipped skipped."
Write-Host "Restart or reload your agent so it discovers the new skills."
