<#
Creates a fresh GCP OAUTH token and drops it in the current git repo's root.
#>

gcloud auth print-access-token | Out-File -encoding ASCII "$(git rev-parse --show-toplevel)/token.secret" -NoNewline  
