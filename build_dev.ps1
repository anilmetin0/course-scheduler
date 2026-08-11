Write-Host "Course Scheduler - Development Build"
Write-Host "===================================="

function Load-DotEnv {
  param([string]$Path = ".env")

  if (!(Test-Path $Path)) {
    Write-Warning ".env not found. Proceeding without loading environment variables."
    return
  }

  foreach ($line in Get-Content $Path) {
    $trimmed = $line.Trim()
    if ($trimmed -eq "" -or $trimmed.StartsWith("#")) {
      continue
    }

    if ($trimmed.StartsWith("export ")) {
      $trimmed = $trimmed.Substring(7)
    }

    $parts = $trimmed.Split("=", 2)
    if ($parts.Count -lt 2) {
      continue
    }

    $name = $parts[0].Trim()
    $value = $parts[1].Trim()

    if (($value.StartsWith('"') -and $value.EndsWith('"')) -or ($value.StartsWith("'") -and $value.EndsWith("'"))) {
      $value = $value.Substring(1, $value.Length - 2)
    }

    Set-Item -Path "Env:$name" -Value $value
  }
}

Load-DotEnv

$gitSha = (git rev-parse --short HEAD 2>$null).Trim()
$gitDefine = ""
if ($LASTEXITCODE -eq 0 -and $gitSha) {
  $gitDefine = "--dart-define=GIT_SHA=$gitSha"
}

Write-Host "Building for development with WASM..."
flutter build web --wasm $gitDefine --dart-define-from-file=firebase_config.env
if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}

Write-Host "Development build completed."
Write-Host ""
Write-Host "Test locally:"
Write-Host "cd build/web && python -m http.server 8080"
Write-Host "Then open: http://localhost:8080"
