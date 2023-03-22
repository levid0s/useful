@echo off
IF NOT DEFINED DELAY (
  SET "myDELAY=3"
  echo [WATCH.cmd]: Set %%DELAY%% for a custom delay, defaulting to 3 seconds.
  echo.
) else (
  SET "myDELAY=%DELAY%"
)

for /l %%g in () do @(%* & timeout /t %myDELAY% >NUL & echo. )
