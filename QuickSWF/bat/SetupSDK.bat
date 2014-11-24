:user_configuration

:: 这里修改成你的flex sdk 目录
set FLEX_SDK=E:\GameDev\flex_sdk_4.6_3.4\flex_sdk_4.6


:validation
if not exist "%FLEX_SDK%\bin" goto flexsdk
goto succeed

:flexsdk
echo.
echo ERROR: incorrect path to Flex SDK in 'bat\SetupSDK.bat'
echo.
echo Looking for: %FLEX_SDK%\bin
echo.
if %PAUSE_ERRORS%==1 pause
exit

:succeed
set PATH=%PATH%;%FLEX_SDK%\bin

