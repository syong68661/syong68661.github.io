param(
  [string]$ContentRoot = "content"
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

  return ($Value.Trim().ToLowerInvariant())
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
  param([System.IO.FileInfo]$File)

  $text = Get-Content $File.FullName -Raw -Encoding utf8
  $title = Get-FrontMatterValue -Text $text -Key "title"
  $slug = Get-FrontMatterValue -Text $text -Key "slug"

  $relative = Resolve-Path -LiteralPath $File.FullName | ForEach-Object { $_.Path.Substring((Resolve-Path $ContentRoot).Path.Length + 1) }
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

$contentPath = Resolve-Path -LiteralPath $ContentRoot
$markdownFiles = Get-ChildItem $contentPath -Recurse -File -Include *.md

$pageMap = @{}
foreach ($file in $markdownFiles) {
  if ($file.Name -eq "_index.md") {
    continue
  }

  $identity = Get-PageIdentity -File $file
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

foreach ($file in $markdownFiles) {
  if ($file.Name -eq "obsi-hugo-writing-notes.md") {
    continue
  }

  $text = Get-Content $file.FullName -Raw -Encoding utf8
  $original = $text

  $text = [regex]::Replace($text, '!\[\[([^\]|]+)(?:\|([^\]]+))?\]\]', {
      param($match)
      $target = $match.Groups[1].Value.Trim()
      $alt = if ($match.Groups[2].Success) { $match.Groups[2].Value.Trim() } else { [System.IO.Path]::GetFileNameWithoutExtension($target) }
      return "![{0}]({1})" -f $alt, $target
    })

  $text = [regex]::Replace($text, '(?<!\!)\[\[([^\]|]+)(?:\|([^\]]+))?\]\]', {
      param($match)
      $target = $match.Groups[1].Value.Trim()
      $label = if ($match.Groups[2].Success) { $match.Groups[2].Value.Trim() } else { $target }

      $extension = [System.IO.Path]::GetExtension($target).ToLowerInvariant()
      if ($imageExtensions -contains $extension) {
        return "[{0}]({1})" -f $label, $target
      }

      $pageTarget = $target
      $anchor = $null
      if ($target.Contains('#')) {
        $parts = $target.Split('#', 2)
        $pageTarget = $parts[0].Trim()
        $anchor = Convert-ToAnchorId $parts[1]
      }

      $normalized = Normalize-LinkKey $pageTarget
      if ($pageMap.ContainsKey($normalized)) {
        $resolved = $pageMap[$normalized]
        if ($anchor) {
          $resolved = "{0}#{1}" -f $resolved.TrimEnd('/'), $anchor
        }
        return "[{0}]({1})" -f $label, $resolved
      }

      return $label
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

  if ($text -ne $original) {
    Set-Content -LiteralPath $file.FullName -Value $text -Encoding utf8
  }
}
