if (!$PesterPreference) {
  Write-Host "`n>> Please set `$PesterPreference first: `n`n  Import-Module Pester`n  `$PesterPreference = [PesterConfiguration]::Default`n  `$PesterPreference.Output.Verbosity = 'Detailed'`n`n"
  Throw
}
