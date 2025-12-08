<#
.SYNOPSIS
    Summarizes a GitLab merge request by fetching its diff and using AI.

.DESCRIPTION
    Fetches a GitLab merge request diff, combines it with a prompt template,
    and pipes the result to opencode.ps1 for AI summarization.

.PARAMETER repo
    GitLab repository id
.PARAMETER mr
    Merge request number

.EXAMPLE
    summarize-gitlab-mr.ps1 --repo 34 --mr 12345
    
.EXAMPLE
    summarize-gitlab-mr.ps1 --repo 56 --mr 42 --model claude/sonnet-4.5
#>

[CmdletBinding()]
param(
    [Parameter(ValueFromRemainingArguments=$true)]
    [string[]]$Arguments
)

# Exit codes
$ExitCode = @{
    Success = 0
    UsageError = 1
    PromptFileMissing = 2
    NetworkError = 3
    OpencodeNotFound = 4
    OpencodeExecutionError = 5
}

# Settings
$GitlabApiBaseUrl = "https://gitlab.com/api/v4"

function Write-Log {
    param([string]$Message, [string]$Level = 'INFO')
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    [Console]::Error.WriteLine("[$timestamp] [$Level] $Message")
}

function Write-ErrorMessage {
    param([string]$Message)
    Write-Log -Message $Message -Level 'ERROR'
}

function Invoke-WithRetry {
    param(
        [scriptblock]$Action,
        [int]$MaxAttempts = 3,
        [int]$BaseDelayMs = 1000
    )
    
    $attempt = 0
    while ($attempt -lt $MaxAttempts) {
        $attempt++
        try {
            Write-Log "Attempt $attempt of $MaxAttempts" -Level 'DEBUG'
            return & $Action
        }
        catch {
            if ($attempt -ge $MaxAttempts) {
                throw
            }
            $delayMs = $BaseDelayMs * [Math]::Pow(2, $attempt - 1)
            Write-Log "Attempt $attempt failed: $($_.Exception.Message). Retrying in $delayMs ms..." -Level 'WARN'
            Start-Sleep -Milliseconds $delayMs
        }
    }
}

# Parse arguments
$repoId = $null
$mrValue = $null
$passthroughArgs = @()
$i = 0

while ($i -lt $Arguments.Count) {
    $arg = $Arguments[$i]
    
    if ($arg -match '^--repo=(.+)$') {
        $repoId = $Matches[1]
        $i++
    }
    elseif ($arg -eq '--repo') {
        if ($i + 1 -lt $Arguments.Count) {
            $repoId = $Arguments[$i + 1]
            $i += 2
        }
        else {
            Write-ErrorMessage "--repo requires a value"
            exit $ExitCode.UsageError
        }
    }
    elseif ($arg -match '^--mr=(.+)$') {
        $mrValue = $Matches[1]
        $i++
    }
    elseif ($arg -eq '--mr') {
        if ($i + 1 -lt $Arguments.Count) {
            $mrValue = $Arguments[$i + 1]
            $i += 2
        }
        else {
            Write-ErrorMessage "--mr requires a value"
            exit $ExitCode.UsageError
        }
    }
    else {
        # Unknown flag - passthrough to opencode.ps1
        $passthroughArgs += $arg
        $i++
    }
}

# Validate required parameters
if ([string]::IsNullOrWhiteSpace($repoId)) {
    Write-ErrorMessage "Missing required parameter: --repo"
    Write-ErrorMessage "Usage: summarize-gitlab-mr.ps1 --repo REPO_ID --mr NUMBER [--model MODEL] [other opencode flags]"
    exit $ExitCode.UsageError
}

if ([string]::IsNullOrWhiteSpace($mrValue)) {
    Write-ErrorMessage "Missing required parameter: --mr"
    Write-ErrorMessage "Usage: summarize-gitlab-mr.ps1 --repo REPO_ID --mr NUMBER [--model MODEL] [other opencode flags]"
    exit $ExitCode.UsageError
}

# Validate MR number is numeric
if ($mrValue -notmatch '^\d+$') {
    Write-ErrorMessage "Invalid MR number: $mrValue (must be a positive integer)"
    exit $ExitCode.UsageError
}

Write-Log "Summarizing MR !$mrValue from repository $repoId"
# Locate the prompt file
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$promptFile = Join-Path $scriptDir 'mr-summary.prompt'

if (-not (Test-Path $promptFile)) {
    Write-ErrorMessage "Prompt file not found: $promptFile"
    exit $ExitCode.PromptFileMissing
}

Write-Log "Reading prompt template from: $promptFile"
try {
    $promptTemplate = Get-Content -Path $promptFile -Raw -ErrorAction Stop
}
catch {
    Write-ErrorMessage "Failed to read prompt file: $($_.Exception.Message)"
    exit $ExitCode.PromptFileMissing
}

# Fetch MR diff from GitLab
$diffUrl = "$GitlabApiBaseUrl/projects/$repoId/merge_requests/$mrValue/raw_diffs"
Write-Log "Fetching diff from: $diffUrl"

$headers = @{}
$gitlabToken = $env:GITLAB_TOKEN
if (-not [string]::IsNullOrWhiteSpace($gitlabToken)) {
    Write-Log "Using GITLAB_TOKEN for authentication"
    $headers['PRIVATE-TOKEN'] = $gitlabToken
}

try {
    $diffContent = Invoke-WithRetry -Action {
        $response = Invoke-WebRequest -Uri $diffUrl -Headers $headers -UseBasicParsing -ErrorAction Stop
        if ($response.StatusCode -ne 200) {
            throw "HTTP $($response.StatusCode): $($response.StatusDescription)"
        }
        return $response.Content
    }
    
    if ([string]::IsNullOrWhiteSpace($diffContent)) {
        Write-ErrorMessage "Fetched diff is empty"
        exit $ExitCode.NetworkError
    }
    
    Write-Log "Successfully fetched diff ($(([Text.Encoding]::UTF8.GetByteCount($diffContent) / 1KB).ToString('F2')) KB)"
}
catch {
    Write-ErrorMessage "Failed to fetch MR diff: $($_.Exception.Message)"
    exit $ExitCode.NetworkError
}

# Build final prompt
$finalPrompt = $promptTemplate.TrimEnd() + "`n`n<GIT_DIFF>`n" + $diffContent.TrimEnd() + "`n</GIT_DIFF>"

# Locate opencode.ps1
$opencodePath = Join-Path $scriptDir 'opencode.ps1'
if (-not (Test-Path $opencodePath)) {
    Write-ErrorMessage "opencode.ps1 not found at: $opencodePath"
    exit $ExitCode.OpencodeNotFound
}

Write-Log "Invoking opencode.ps1 for summarization"

# Pipe final prompt to opencode.ps1 with passthrough args
try {
    $opencodeArgs = $passthroughArgs
    echo "$finalPrompt" | & $opencodePath @opencodeArgs
    $exitResult = $LASTEXITCODE
    
    if ($exitResult -ne 0) {
        Write-ErrorMessage "opencode.ps1 exited with code: $exitResult"
        exit $ExitCode.OpencodeExecutionError
    }
    
    Write-Log "Summarization completed successfully" -Level 'INFO'
    exit $ExitCode.Success
}
catch {
    Write-ErrorMessage "Failed to execute opencode.ps1: $($_.Exception.Message)"
    exit $ExitCode.OpencodeExecutionError
}
