$pathsToRemove = @(
  ".hugo-content",
  "public",
  "public-debug",
  "public-release",
  "public-test",
  "public-test-future",
  "resources",
  ".hugo_build.lock"
)

foreach ($relativePath in $pathsToRemove) {
  $targetPath = Join-Path (Get-Location) $relativePath

  if (-not (Test-Path -LiteralPath $targetPath)) {
    Write-Host "Skip: $relativePath"
    continue
  }

  Remove-Item -LiteralPath $targetPath -Recurse -Force
  Write-Host "Removed: $relativePath"
}
