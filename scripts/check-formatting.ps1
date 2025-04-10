<#
Format Terraform and Sentinel source files in the current folder recursively.
#>

param(
	[switch]$Sentinel,
	[switch]$Terraform,
	[switch]$Write
)

$InformationPreference = 'Continue'

if (!($Terraform -or $Sentinel)) {
	throw "Please select -Terraform or -Sentinel"
}

if ($Terraform) {
	if ($Write) {
		$WriteCmd = '-write=true'
	}
	else {
		$WriteCmd = '-write=false'
	}
	tf-13-5 fmt $WriteCmd -diff -recursive
	$TerraformResult = $LASTEXITCODE
	if ($TerraformResult) {
		Write-Warning "Terraform formatting issues"
	}
	else {
		Write-Information "Terraform formatting: OK"
	}
}

if ($Sentinel) {
	if ($Write) {
		$WriteCmd = ''
	}
	else {
		$WriteCmd = '-check=true'
	}

	$files = Get-ChildItem -Include '*.sentinel' -Exclude 'mock*' -Recurse -Force -File
	$files = $files | Where-Object FullName -notmatch '\\sentinel-tmp\\'
	if ($files.Count -eq 0) {
		Write-Warning "No files found.."
	}
	else {
		sentinel fmt $WriteCmd $files.FullName
		$SentinelResult = $LASTEXITCODE
		if ($SentinelResult -gt 0) {
			Write-Warning "Sentinel formatting issues"
		}
		else {
			Write-Information "Sentinel formatting: OK"
		}
	}
}

if ($TerraformResult + $SentinelResult -gt 0) {
	exit 1
}
