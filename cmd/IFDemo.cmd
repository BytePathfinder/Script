@echo off
echo "------------------------------cmd test------------------------------"
set /p flag="please input y/n :"
if "%flag%" == "y" (
    echo "==y"
) else (
    if "%flag%" == "n" (
        echo "==n"
    ) else (
        echo "other"
    )
)

call IFDemo.cmd

