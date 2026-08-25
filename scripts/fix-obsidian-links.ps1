param(
  [string]$ContentRoot = "content"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Escape-Html {
  param([string]$Value)

  if ($null -eq $Value) {
    return ""
  }

  return $Value.Replace("&", "&amp;").Replace('"', "&quot;").Replace("<", "&lt;").Replace(">", "&gt;")
}

function Get-ImageSrc {
  param([string]$Target)

  return ($Target -replace ' ', '%20')
}

function Convert-ObsidianImage {
  param(
    [string]$Target,
    [string]$Option
  )

  $defaultAlt = [System.IO.Path]::GetFileNameWithoutExtension($Target)
  $alt = ""
  $markdownTarget = if ($Target -match '\s') { "<$Target>" } else { $Target }
  $imageSrc = Get-ImageSrc $Target
  $attributes = @()

  if (-not [string]::IsNullOrWhiteSpace($Option)) {
    $trimmed = $Option.Trim()

    if ($trimmed -match '^(?<width>\d+)$') {
      $attributes += 'width="{0}"' -f $matches.width
    }
    elseif ($trimmed -match '^(?<width>\d+)px$') {
      $attributes += 'width="{0}"' -f $matches.width
    }
    elseif ($trimmed -match '^(?<width>\d+)\s*[xX]\s*(?<height>\d+)$') {
      $attributes += 'width="{0}"' -f $matches.width
      $attributes += 'height="{0}"' -f $matches.height
    }
    else {
      $alt = $trimmed
    }
  }

  if ($attributes.Count -eq 0) {
    return '![{0}]({1})' -f $alt, $markdownTarget
  }

  $attributes = @(
    'src="{0}"' -f (Escape-Html $imageSrc),
    'alt="{0}"' -f (Escape-Html $(if ($alt) { $alt } else { $defaultAlt }))
  ) + $attributes

  return "<img {0} />" -f ($attributes -join ' ')
}

$contentPath = (Resolve-Path -LiteralPath $ContentRoot).Path
$markdownFiles = Get-ChildItem $contentPath -Recurse -File -Include *.md
$changedCount = 0

foreach ($file in $markdownFiles) {
  $text = Get-Content $file.FullName -Raw -Encoding utf8
  $converted = [regex]::Replace($text, '!\[\[([^\]|]+)(?:\|([^\]]+))?\]\]', {
      param($match)
      $target = $match.Groups[1].Value.Trim()
      $option = if ($match.Groups[2].Success) { $match.Groups[2].Value.Trim() } else { "" }
      return Convert-ObsidianImage -Target $target -Option $option
    })

  if ($converted -ne $text) {
    Set-Content -LiteralPath $file.FullName -Value $converted -Encoding utf8
    $changedCount++
    Write-Host "Updated: $($file.FullName)"
  }
}

Write-Host "Done. Updated $changedCount file(s)."
