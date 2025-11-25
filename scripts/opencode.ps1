<#
.SYNOPSIS
    Wrapper script for opencode chat with smart model resolution and STDIN support.

.DESCRIPTION
    This script provides a convenient interface to opencode chat with features like:
    - Smart model name resolution (exact or unique partial match, case-insensitive)
    - STDIN prompt input when no --prompt flag is provided
    - Default model (gpt-5-mini) when --model is not specified
    - Passthrough of unknown flags to opencode

.PARAMETER model
    The model name or unique partial match. Default: github-copilot/gpt-5-mini

.PARAMETER prompt
    The prompt text. If not provided, reads from STDIN.

.EXAMPLE
    opencode.ps1 --model github-copilot/gpt-4 --prompt "Hello world"
    
.EXAMPLE
    opencode.ps1 --model=claude/sonnet-4.5 --prompt "Analyze this code"
    
.EXAMPLE
    echo "What is the meaning of life?" | opencode.ps1
    
.EXAMPLE
    opencode.ps1 -p "Quick question" --model openai/gpt-5
    
.EXAMPLE
    Get-Content input.txt | opencode.ps1 --model claude/sonnet-4.5 --flag1 --flag2
#>

[CmdletBinding()]
param(
    [Parameter(ValueFromRemainingArguments=$true)]
    [string[]]$Arguments
)

# Exit codes
$ExitCode = @{
    Success = 0
    UsageError = 2
    OpencodeNotFound = 3
    ModelsFetchFailed = 4
    ModelResolutionFailed = 5
    OpencodeExecutionError = 6
    PromptAcquisitionError = 7
}

function Write-ErrorMessage {
    param([string]$Message)
    [Console]::Error.WriteLine("Error: $Message")
}

function Get-AvailableModels {
    try {
        $modelsOutput = & opencode models 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-ErrorMessage "Failed to fetch models from opencode (exit code: $LASTEXITCODE)"
            exit $ExitCode.ModelsFetchFailed
        }
        
        $models = @()
        foreach ($line in $modelsOutput) {
            $line = $line.ToString().Trim()
            if ($line -and $line -notmatch '^\s*$') {
                $models += $line
            }
        }
        
        if ($models.Count -eq 0) {
            Write-ErrorMessage "No models returned by 'opencode models'"
            exit $ExitCode.ModelsFetchFailed
        }
        
        return $models
    }
    catch {
        Write-ErrorMessage "Exception fetching models: $($_.Exception.Message)"
        exit $ExitCode.ModelsFetchFailed
    }
}

function Resolve-ModelName {
    param(
        [string]$InputModel,
        [string[]]$AvailableModels
    )
    
    # Try exact match (case-insensitive)
    foreach ($model in $AvailableModels) {
        if ($model -eq $InputModel) {
            return $model
        }
    }
    
    # Try case-insensitive exact match
    $exactMatches = @($AvailableModels | Where-Object { $_ -ieq $InputModel })
    if ($exactMatches.Count -ge 1) {
        return $exactMatches[0]
    }
    
    # Try unique partial match (case-insensitive)
    $partialMatches = @($AvailableModels | Where-Object { $_ -ilike "*$InputModel*" })
    
    if ($partialMatches.Count -eq 0) {
        Write-ErrorMessage "Model '$InputModel' not found. Available models:"
        foreach ($model in $AvailableModels) {
            [Console]::Error.WriteLine("  - $model")
        }
        exit $ExitCode.ModelResolutionFailed
    }
    elseif ($partialMatches.Count -gt 1) {
        Write-ErrorMessage "Model '$InputModel' is ambiguous. Matching models:"
        foreach ($model in $partialMatches) {
            [Console]::Error.WriteLine("  - $model")
        }
        exit $ExitCode.ModelResolutionFailed
    }
    
    return $partialMatches[0]
}

# Check if opencode is available
if (-not (Get-Command opencode -ErrorAction SilentlyContinue)) {
    Write-ErrorMessage "opencode command not found. Please ensure opencode is installed and in PATH."
    exit $ExitCode.OpencodeNotFound
}

# Parse arguments
$modelValue = $null
$promptValue = $null
$passthroughArgs = @()
$i = 0

while ($i -lt $Arguments.Count) {
    $arg = $Arguments[$i]
    
    if ($arg -match '^--model=(.+)$') {
        # --model=value format (take last occurrence)
        $modelValue = $Matches[1]
        $i++
    }
    elseif ($arg -eq '--model') {
        # --model value format (take last occurrence)
        if ($i + 1 -lt $Arguments.Count) {
            $modelValue = $Arguments[$i + 1]
            $i += 2
        }
        else {
            Write-ErrorMessage "--model requires a value"
            exit $ExitCode.UsageError
        }
    }
    elseif ($arg -match '^--prompt=(.*)$') {
        # --prompt=value format (takes precedence)
        $promptValue = $Matches[1]
        $i++
    }
    elseif ($arg -eq '--prompt' -or $arg -eq '-p') {
        # --prompt value or -p value format (takes precedence)
        if ($i + 1 -lt $Arguments.Count) {
            $promptValue = $Arguments[$i + 1]
            $i += 2
        }
        else {
            Write-ErrorMessage "$arg requires a value"
            exit $ExitCode.UsageError
        }
    }
    else {
        # Unknown flag - passthrough
        $passthroughArgs += $arg
        $i++
    }
}

# Set default model if not provided
if ($null -eq $modelValue -or $modelValue -eq '') {
    $modelValue = 'github-copilot/gpt-5-mini'
}

# Get and validate model
$availableModels = Get-AvailableModels
$resolvedModel = Resolve-ModelName -InputModel $modelValue -AvailableModels $availableModels

# Get prompt: from flag or STDIN
if ($null -eq $promptValue) {
    # Read from STDIN
    if ([Console]::IsInputRedirected) {
        try {
            $stdinLines = @()
            $reader = [Console]::In
            while ($null -ne ($line = $reader.ReadLine())) {
                $stdinLines += $line
            }
            $promptValue = $stdinLines -join "`n"
            
            if ([string]::IsNullOrWhiteSpace($promptValue)) {
                Write-ErrorMessage "No prompt provided via --prompt/-p and STDIN is empty"
                exit $ExitCode.PromptAcquisitionError
            }
        }
        catch {
            Write-ErrorMessage "Failed to read from STDIN: $($_.Exception.Message)"
            exit $ExitCode.PromptAcquisitionError
        }
    }
    else {
        Write-ErrorMessage "No prompt provided. Use --prompt/-p or pipe input via STDIN."
        exit $ExitCode.UsageError
    }
}

# Build opencode command
$opencodeArgs = @('run', $promptValue, '--model', $resolvedModel) + $passthroughArgs

# Execute opencode and stream output
try {
    & opencode @opencodeArgs
    $exitResult = $LASTEXITCODE
    
    if ($exitResult -ne 0) {
        # Propagate the underlying opencode exit code when possible
        exit $exitResult
    }
    
    exit $ExitCode.Success
}
catch {
    Write-ErrorMessage "Failed to execute opencode: $($_.Exception.Message)"
    exit $ExitCode.OpencodeExecutionError
}
