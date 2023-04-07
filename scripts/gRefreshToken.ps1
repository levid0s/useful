<#
.VERSION 20230331

.SYNOPSIS
Generates a fresh GCP OAUTH token and drops it in the current git repo's root as `token.secret`

.EXAMPLE
```
gRefreshToken
```
#>

gcloud auth print-access-token | Out-File -Encoding ASCII "$(git rev-parse --show-toplevel)/token.secret" -NoNewline  
