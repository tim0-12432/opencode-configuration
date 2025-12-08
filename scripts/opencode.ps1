<#
.SYNOPSIS
    Wrapper script for opencode chat with smart model resolution and STDIN support.

.DESCRIPTION
    This script provides a convenient interface to opencode chat with features like:
    - Smart model name resolution (exact or unique partial match, case-insensitive)
    - STDIN prompt input when no --prompt flag is provided
    - Default model (gpt-5-mini) when --model is not specified
    - Passthrough of unknown flags to opencode
    - Support for --help/-h flag

.EXAMPLE
    ./opencode.ps1 --prompt "Hello World"
    
.EXAMPLE
    ./opencode.ps1 -p "Quick question" --model claude/sonnet-4.5
    
.EXAMPLE
    echo "Piped input" | ./opencode.ps1
    
.EXAMPLE
    ./opencode.ps1 --model=openai/gpt-5 --prompt "Analyze this code"
    
.EXAMPLE
    Get-Content file.txt | ./opencode.ps1 --model claude/sonnet-4.5
#>

# SOLUTION: Use $args automatic variable for arguments, handle pipeline separately
# ValueFromRemainingArguments doesn't work reliably when combined with ValueFromPipeline
# because PowerShell tries to bind arguments as pipeline values

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

# Main script execution

# Collect piped input if present (must be done before accessing $args)
$pipeBuffer = [System.Collections.Generic.List[string]]::new()

# Always try to collect pipeline input - if there's no input, the loop won't execute
# This approach works correctly whether invoked via -File or -Command
$input | ForEach-Object {
    if ($null -ne $_ -and $_ -ne '') {
        $pipeBuffer.Add($_.ToString())
    }
}

# Now get the arguments - use $args which works correctly with -File invocation
$scriptArgs = $args

# Check for help
if ($scriptArgs -contains '--help' -or $scriptArgs -contains '-h') {
    Write-Host @"
Usage: ./opencode.ps1 [OPTIONS]

Options:
  --prompt, -p TEXT    Prompt text (required if not piping)
  --model MODEL        Model name or partial match (default: gpt-5-mini)
  --help, -h           Show this help message

Examples:
  ./opencode.ps1 --prompt "Hello World"
  ./opencode.ps1 -p "Quick question" --model openai/gpt-5
  echo "Piped input" | ./opencode.ps1
  Get-Content file.txt | ./opencode.ps1 --model claude/sonnet-4.5
  ./opencode.ps1 --model=xai/grok-3 --prompt="Analyze code" --temperature=0.7
"@
    exit 0
}

# Parse $scriptArgs for --prompt, --model, and passthrough args
$modelValue = $null
$promptValue = $null
$passthroughArgs = @()
$i = 0

while ($i -lt $scriptArgs.Count) {
    $arg = $scriptArgs[$i]
    
    if ($arg -match '^--model=(.+)$') {
        $modelValue = $Matches[1]
        $i++
    }
    elseif ($arg -eq '--model') {
        if ($i + 1 -lt $scriptArgs.Count) {
            $modelValue = $scriptArgs[$i + 1]
            $i += 2
        }
        else {
            Write-ErrorMessage "--model requires a value"
            exit $ExitCode.UsageError
        }
    }
    elseif ($arg -match '^--prompt=(.*)$') {
        $promptValue = $Matches[1]
        $i++
    }
    elseif ($arg -eq '--prompt' -or $arg -eq '-p') {
        if ($i + 1 -lt $scriptArgs.Count) {
            $promptValue = $scriptArgs[$i + 1]
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

# Set default model
if ($null -eq $modelValue -or $modelValue -eq '') {
    $modelValue = 'github-copilot/gpt-5-mini'
}

# Check if opencode is available
if (-not (Get-Command opencode -ErrorAction SilentlyContinue)) {
    Write-ErrorMessage "opencode command not found. Please ensure opencode is installed and in PATH."
    exit $ExitCode.OpencodeNotFound
}

# Get and validate model
$availableModels = Get-AvailableModels
$resolvedModel = Resolve-ModelName -InputModel $modelValue -AvailableModels $availableModels

# Acquire prompt: --prompt flag takes precedence over pipeline
if ($null -eq $promptValue) {
    if ($pipeBuffer.Count -gt 0) {
        $promptValue = $pipeBuffer -join "`n"
    }
    else {
        Write-ErrorMessage "No prompt provided. Use --prompt/-p or pipe input via STDIN."
        exit $ExitCode.UsageError
    }
}

# Validate prompt is not empty
if ([string]::IsNullOrWhiteSpace($promptValue)) {
    Write-ErrorMessage "Prompt cannot be empty."
    exit $ExitCode.PromptAcquisitionError
}

# Build opencode command
$opencodeArgs = @('run', '--model', $resolvedModel) + $passthroughArgs

# Execute opencode and stream output
try {
    echo "$promptValue" | & opencode @opencodeArgs
    $exitResult = $LASTEXITCODE
    
    if ($exitResult -ne 0) {
        exit $exitResult
    }
    
    exit $ExitCode.Success
}
catch {
    Write-ErrorMessage "Failed to execute opencode: $($_.Exception.Message)"
    exit $ExitCode.OpencodeExecutionError
}
