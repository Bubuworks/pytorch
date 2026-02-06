setlocal enabledelayedexpansion
set "DRIVER_DOWNLOAD_LINK=https://s3.amazonaws.com/ossci-windows/452.39-data-center-tesla-desktop-win10-64bit-international.exe"
for %%F in ("%DRIVER_DOWNLOAD_LINK%") do set "DRIVER_FILE=%%~nxF"
curl --retry 3 --retry-all-errors -L "%DRIVER_DOWNLOAD_LINK%" --output "%DRIVER_FILE%" || (
    echo Error: failed to download driver.
    exit /b 1
)
start /wait "" "%DRIVER_FILE%" -s -noreboot || (
    echo Error: driver installation failed.
    exit /b 1
)
del /f /q "%DRIVER_FILE%" || echo Warning: failed to delete installer.
endlocal
