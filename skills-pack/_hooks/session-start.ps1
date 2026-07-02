# Cursor user hook: inject using-superpowers at session start
# Reads from ~/.cursor/skills/superpowers/using-superpowers/SKILL.md
# Does not install the full Superpowers plugin (TDD / writing-plans stay local).

$ErrorActionPreference = 'Stop'

function Write-Empty {
    [Console]::Out.WriteLine('{}')
    exit 0
}

$skillPath = Join-Path $env:USERPROFILE '.cursor\skills\superpowers\using-superpowers\SKILL.md'
if (-not (Test-Path $skillPath)) {
    Write-Empty
}

try {
    $content = Get-Content -LiteralPath $skillPath -Raw -Encoding UTF8
}
catch {
    Write-Empty
}

if ([string]::IsNullOrWhiteSpace($content)) {
    Write-Empty
}

$sessionContext = @"
<EXTREMELY_IMPORTANT>
You have superpowers (custom install: skills in ~/.cursor/skills/, not the full plugin).

**Below is the full content of your using-superpowers skill. For all other skills, use Cursor skill invocation (@skill-name or Agent Decides) — do not read SKILL.md files manually with file tools.**

$content

**Cursor note:** Local custom skills test-driven-development and writing-plans override Superpowers upstream versions. Always use those when TDD or implementation planning applies.
</EXTREMELY_IMPORTANT>
"@

$payload = @{ additional_context = $sessionContext }
[Console]::Out.WriteLine(($payload | ConvertTo-Json -Compress -Depth 3))
exit 0
