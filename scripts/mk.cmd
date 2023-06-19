:: Minikube alias for Windows

@echo off

:: These are no longer needed, I'll just use k alias for all kubectl commands.
:: set DIRECT_COMMANDS=:addons:cache:completion:config:dashboard:delete:docker-env:image:ip:kubectl:mount:node:options:pause:podman-env:profile:service:ssh:ssh-host:ssh-key:start:status:stop:tunnel:unpause:update-check:update-context:version:
:: echo:%DIRECT_COMMANDS%|findstr /c::%1% >NUL 2>&1

:: if %ERRORLEVEL%==0 (
::   minikube %*
:: ) else (
::   minikube kubectl -- %*
:: )

minikube %*
