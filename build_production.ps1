Write-Host "Course Scheduler - Build Script"
Write-Host "==============================="

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

Write-Host "Generating code files (.g.dart)..."
flutter pub run build_runner build --delete-conflicting-outputs
if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}

Write-Host "Building with WASM for production..."
flutter build web --wasm --release $gitDefine --dart-define-from-file=firebase_config.env
if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}

Write-Host "Build completed."
Write-Host "Bundle size:"
$wasmPath = "build/web/main.dart.wasm"
$mjsPath = "build/web/main.dart.mjs"
if (Test-Path $wasmPath) {
  $wasmSize = (Get-Item $wasmPath).Length
  Write-Host "$wasmPath : $([math]::Round($wasmSize / 1MB, 2)) MB"
} else {
  Write-Warning "Missing $wasmPath"
}
if (Test-Path $mjsPath) {
  $mjsSize = (Get-Item $mjsPath).Length
  Write-Host "$mjsPath : $([math]::Round($mjsSize / 1MB, 2)) MB"
} else {
  Write-Warning "Missing $mjsPath"
}

Write-Host ""
Write-Host "Deploy to Firebase:"
Write-Host "firebase deploy --project course-scheduler-25"
Write-Host ""
Write-Host "Test locally:"
Write-Host "firebase serve"
