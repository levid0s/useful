$dirs = Get-ChildItem -Directory
$gitUserName = 'lev'

try {
    foreach ($dir in $dirs) {
        Write-Debug "Checking: $dir"
    
        if (!(Test-Path "$dir/.git")) { 
            Write-Debug "Not a git repo: $dir"
            continue
        }
        
        Push-Location $dir
        
        [string[]]$remotes = git remote
        if ($remotes.count -eq 0) {
            Write-Debug "No remotes: $dir"
            Pop-Location
            continue
        }

        $remote = $remotes[0]

        $mainBranch = git symbolic-ref refs/remotes/$remote/HEAD
        $mainBranch = $mainBranch -replace "refs/remotes/$remote/", ''
    
        $branches = git for-each-ref --format '%(refname:short)' refs/heads
        Write-Debug "Branches: $branches"
    
        $branches | ForEach-Object {
            if ($_ -ne $mainBranch) {
                $lastCommitAuthor = git log $_ --pretty="format:%an" -n 1
                if ($lastCommitAuthor -eq $gitUserName) {
                    $isMerged = git merge-base --is-ancestor $_ "$remote/$mainBranch"
                    if (-Not $isMerged) { Write-Host ">>> $_ in $pwd" }
                }
            }
        }
    
        Pop-Location
    }
}
finally {
    Pop-Location
}
