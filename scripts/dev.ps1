$convertScript = Join-Path $PSScriptRoot "convert-obsidian.ps1"
$contentRoot = Join-Path (Split-Path $PSScriptRoot -Parent) "content"
$debounceWindowMs = 500

function Invoke-ObsidianConvert {
  & $convertScript
}

$generatedContent = Invoke-ObsidianConvert

$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $contentRoot
$watcher.IncludeSubdirectories = $true
$watcher.EnableRaisingEvents = $true
$watcher.NotifyFilter = [System.IO.NotifyFilters]'FileName, DirectoryName, LastWrite, CreationTime'

$watchState = [hashtable]::Synchronized(@{
  LastRun = [datetime]::MinValue
})

$eventAction = {
  $now = Get-Date
  $state = $event.MessageData.State
  $elapsed = ($now - $state.LastRun).TotalMilliseconds

  if ($elapsed -lt $event.MessageData.DebounceWindowMs) {
    return
  }

  $state.LastRun = $now
  try {
    & $event.MessageData.ConvertScript | Out-Null
    Write-Host "Updated generated content for $($event.SourceEventArgs.ChangeType): $($event.SourceEventArgs.FullPath)"
  }
  catch {
    Write-Warning "Failed to sync generated content: $($_.Exception.Message)"
  }
}

$eventData = @{
  ConvertScript = $convertScript
  DebounceWindowMs = $debounceWindowMs
  State = $watchState
}

$subscriptions = @(
  Register-ObjectEvent -InputObject $watcher -EventName Changed -Action $eventAction -MessageData $eventData
  Register-ObjectEvent -InputObject $watcher -EventName Created -Action $eventAction -MessageData $eventData
  Register-ObjectEvent -InputObject $watcher -EventName Deleted -Action $eventAction -MessageData $eventData
  Register-ObjectEvent -InputObject $watcher -EventName Renamed -Action $eventAction -MessageData $eventData
)

try {
  hugo server -D -F -c $generatedContent --renderToMemory --disableFastRender
}
finally {
  foreach ($subscription in $subscriptions) {
    Unregister-Event -SubscriptionId $subscription.Id -ErrorAction SilentlyContinue
    Remove-Job -Id $subscription.Id -Force -ErrorAction SilentlyContinue
  }

  $watcher.Dispose()
}
