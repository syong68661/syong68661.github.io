param(
  [string]$ContentRoot = "content",
  [string]$OutputRoot = ".hugo-content"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-FrontMatterValue {
  param(
    [string]$Text,
    [string]$Key
  )

  $pattern = "(?ms)^\+\+\+\s*(.*?)^\+\+\+\s*"
  $match = [regex]::Match($Text, $pattern)
  if (-not $match.Success) {
    return $null
  }

  $body = $match.Groups[1].Value
  $lineMatch = [regex]::Match($body, "(?m)^\s*$Key\s*=\s*[""']?(.+?)[""']?\s*$")
  if ($lineMatch.Success) {
    return $lineMatch.Groups[1].Value.Trim()
  }

  return $null
}

function Normalize-LinkKey {
  param([string]$Value)

  return $Value.Trim().ToLowerInvariant()
}

function Convert-ToAnchorId {
  param([string]$Value)

  $normalized = $Value.Trim().ToLowerInvariant()
  $normalized = $normalized -replace '\s+', '-'
  $normalized = $normalized -replace '[^-\p{L}\p{Nd}]', ''
  return $normalized
}

function Get-SectionPermalinkPrefix {
  param([string]$Section)

  $osSection = [string]::Concat(([char[]](0x64CD, 0x4F5C, 0x7CFB, 0x7EDF)))
  $dsSection = [string]::Concat(([char[]](0x6570, 0x636E, 0x7ED3, 0x6784)))
  $coSection = [string]::Concat(([char[]](0x8BA1, 0x7B97, 0x673A, 0x7EC4, 0x6210, 0x539F, 0x7406)))
  $cnSection = [string]::Concat(([char[]](0x8BA1, 0x7B97, 0x673A, 0x7F51, 0x7EDC)))

  switch ($Section) {
    { $_ -eq $osSection } { return "/os/" }
    { $_ -eq $dsSection } { return "/data-structure/" }
    { $_ -eq $coSection } { return "/computer-organization/" }
    { $_ -eq $cnSection } { return "/network/" }
    default { return "/$Section/" }
  }
}

function Get-PageIdentity {
  param(
    [System.IO.FileInfo]$File,
    [string]$RootPath
  )

  $text = Get-Content $File.FullName -Raw -Encoding utf8
  $title = Get-FrontMatterValue -Text $text -Key "title"
  $slug = Get-FrontMatterValue -Text $text -Key "slug"

  $resolvedRoot = (Resolve-Path -LiteralPath $RootPath).Path
  $resolvedFile = (Resolve-Path -LiteralPath $File.FullName).Path
  $relative = $resolvedFile.Substring($resolvedRoot.Length + 1)
  $parts = $relative -split '[\\/]'
  if ($parts.Length -lt 2) {
    return $null
  }

  $section = $parts[0]
  $bundleName = if ($File.Directory.Name -ne $section) { $File.Directory.Name } else { $File.BaseName }
  $effectiveSlug = if ($slug) { $slug } else { $bundleName -replace '\s+', '-' }
  $permalink = (Get-SectionPermalinkPrefix $section) + $effectiveSlug.Trim('/') + "/"

  return [pscustomobject]@{
    File = $File.FullName
    Title = $title
    BundleName = $bundleName
    Slug = $effectiveSlug
    Permalink = $permalink
  }
}

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

  $alt = [System.IO.Path]::GetFileNameWithoutExtension($Target)
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
    if ($Target -match '\s') {
      return '<img src="{0}" alt="{1}" />' -f (Escape-Html $imageSrc), (Escape-Html $alt)
    }

    return '![{0}]({1})' -f $alt, $markdownTarget
  }

  $attributes = @(
    'src="{0}"' -f (Escape-Html $imageSrc),
    'alt="{0}"' -f (Escape-Html $alt)
  ) + $attributes

  return "<img {0} />`r`n`r`n" -f ($attributes -join ' ')
}

function Convert-ObsidianSyntax {
  param(
    [string]$Text,
    [hashtable]$PageMap,
    [string[]]$ImageExtensions
  )

  $text = [regex]::Replace($Text, '!\[\[([^\]|]+)(?:\|([^\]]+))?\]\]', {
      param($match)
      $target = $match.Groups[1].Value.Trim()
      $option = if ($match.Groups[2].Success) { $match.Groups[2].Value.Trim() } else { "" }
      return Convert-ObsidianImage -Target $target -Option $option
    })

  $text = [regex]::Replace($text, '(?<!\!)\[\[([^\]|]+)(?:\|([^\]]+))?\]\]', {
      param($match)
      $target = $match.Groups[1].Value.Trim()
      $label = if ($match.Groups[2].Success) { $match.Groups[2].Value.Trim() } else { $target }

      $extension = [System.IO.Path]::GetExtension($target).ToLowerInvariant()
      if ($ImageExtensions -contains $extension) {
        return '[{0}]({1})' -f $label, $target
      }

      $pageTarget = $target
      $anchor = $null
      if ($target.Contains('#')) {
        $parts = $target.Split('#', 2)
        $pageTarget = $parts[0].Trim()
        $anchor = Convert-ToAnchorId $parts[1]
      }

      $normalized = Normalize-LinkKey $pageTarget
      if ($PageMap.ContainsKey($normalized)) {
        $resolved = $PageMap[$normalized]
        if ($anchor) {
          $resolved = '{0}#{1}' -f $resolved.TrimEnd('/'), $anchor
        }
        return '[{0}]({1})' -f $label, $resolved
      }

      return $label
    })

  $text = [regex]::Replace($text, '==(.+?)==', {
      param($match)
      return '<mark>{0}</mark>' -f $match.Groups[1].Value
    })

  $text = [regex]::Replace($text, '(?ms)^> \[!(\w+)\]\s*(.*?)\r?\n((?:>.*(?:\r?\n|$))*)', {
      param($match)
      $kind = $match.Groups[1].Value.ToLowerInvariant()
      $title = $match.Groups[2].Value.Trim()
      $body = $match.Groups[3].Value -replace '(?m)^>\s?', ''

      if ([string]::IsNullOrWhiteSpace($title)) {
        $title = (Get-Culture).TextInfo.ToTitleCase($kind)
      }

      return @"
<div class="callout callout-$kind">
  <div class="callout-title">$title</div>
  <div class="callout-body">
$body  </div>
</div>
"@
    })

  return $text
}

$contentPath = (Resolve-Path -LiteralPath $ContentRoot).Path
$outputPath = [System.IO.Path]::GetFullPath((Join-Path (Get-Location) $OutputRoot))

if ($outputPath -eq $contentPath) {
  throw "OutputRoot cannot be the same as ContentRoot."
}

if (Test-Path -LiteralPath $outputPath) {
  try {
    Remove-Item -LiteralPath $outputPath -Recurse -Force -ErrorAction Stop
  }
  catch {
    Write-Warning "Could not fully clean $outputPath. Existing files will be overwritten in place."
  }
}

if (-not (Test-Path -LiteralPath $outputPath)) {
  New-Item -ItemType Directory -Path $outputPath | Out-Null
}

$generatedContentRoot = Join-Path $outputPath (Split-Path $contentPath -Leaf)
if (-not (Test-Path -LiteralPath $generatedContentRoot)) {
  New-Item -ItemType Directory -Path $generatedContentRoot | Out-Null
}

Get-ChildItem $contentPath -Recurse -File | ForEach-Object {
  $sourceFile = $_.FullName
  $relativePath = $sourceFile.Substring($contentPath.Length + 1)
  $destinationFile = Join-Path $generatedContentRoot $relativePath
  $destinationDir = Split-Path -Parent $destinationFile

  if (-not (Test-Path -LiteralPath $destinationDir)) {
    New-Item -ItemType Directory -Path $destinationDir -Force | Out-Null
  }

  Copy-Item -LiteralPath $sourceFile -Destination $destinationFile -Force
}
$sourceMarkdownFiles = Get-ChildItem $contentPath -Recurse -File -Include *.md
$generatedMarkdownFiles = Get-ChildItem $generatedContentRoot -Recurse -File -Include *.md

$pageMap = @{}
foreach ($file in $sourceMarkdownFiles) {
  if ($file.Name -eq "_index.md") {
    continue
  }

  $identity = Get-PageIdentity -File $file -RootPath $contentPath
  if ($null -eq $identity) {
    continue
  }

  foreach ($key in @($identity.Title, $identity.BundleName, $identity.Slug)) {
    if ([string]::IsNullOrWhiteSpace($key)) {
      continue
    }

    $normalized = Normalize-LinkKey $key
    if (-not $pageMap.ContainsKey($normalized)) {
      $pageMap[$normalized] = $identity.Permalink
    }
  }
}

$imageExtensions = @(".png", ".jpg", ".jpeg", ".gif", ".webp", ".svg", ".bmp")

foreach ($file in $generatedMarkdownFiles) {
  $text = Get-Content $file.FullName -Raw -Encoding utf8
  $converted = Convert-ObsidianSyntax -Text $text -PageMap $pageMap -ImageExtensions $imageExtensions

  if ($converted -ne $text) {
    Set-Content -LiteralPath $file.FullName -Value $converted -Encoding utf8
  }
}

Write-Output $generatedContentRoot
