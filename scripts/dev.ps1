$generatedContent = & "$PSScriptRoot\convert-obsidian.ps1"
hugo server -D -c $generatedContent
