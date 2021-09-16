@echo off&setlocal enabledelayedexpansion

rem 录入待检测网址
set /p URL="Please input URL :"
if "%URL%" == "" (
    set URL=www.baidu.com
    echo "check out remote host(!URL!) ..."
) else (
    echo "check out remote host(%URL%) ..."
)

rem ping网站
ping %URL% >nul
goto answer%ERRORLEVEL%
    :answer0
        echo URL IS OK
        goto end
    :answer1
        echo URL IS NOT OK
:end

rem 是否下载该网页
set URL = www/baidu/com
set /p flag="is DownLoading %URL% ... y/n :"
if "%flag%" == "y" (
    echo "DownLoading ..."
    curl -o URL.html https://%URL%
) else (
    echo give up DownLoading
)

dir | find /i "URL.html"

type URL.html

start URL.html

echo end
