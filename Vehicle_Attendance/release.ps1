param (
    [string]$Version = "",
    [string]$Notes = ""
)

if ($Version -and $Notes) {
    npx tsx scripts/release.ts $Version $Notes
} elseif ($Version) {
    npx tsx scripts/release.ts $Version
} else {
    npx tsx scripts/release.ts
}

