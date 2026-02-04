::[Bat To Exe Converter]
::
::fBE1pAF6MU+EWH3eyGcTACxbXg+HLniGBb0V+eHH//iIulRTUfo6GA==
::YAwzoRdxOk+EWAnk
::fBw5plQjdG8=
::YAwzuBVtJxjWCl3EqQJgSA==
::ZR4luwNxJguZRRnk
::Yhs/ulQjdF+5
::cxAkpRVqdFKZSjk=
::cBs/ulQjdF+5
::ZR41oxFsdFKZSDk=
::eBoioBt6dFKZSDk=
::cRo6pxp7LAbNWATEpCI=
::egkzugNsPRvcWATEpSI=
::dAsiuh18IRvcCxnZtBJQ
::cRYluBh/LU+EWAnk
::YxY4rhs+aU+JeA==
::cxY6rQJ7JhzQF1fEqQJQ
::ZQ05rAF9IBncCkqN+0xwdVs0
::ZQ05rAF9IAHYFVzEqQJQ
::eg0/rx1wNQPfEVWB+kM9LVsJDGQ=
::fBEirQZwNQPfEVWB+kM9LVsJDGQ=
::cRolqwZ3JBvQF1fEqQJQ
::dhA7uBVwLU+EWDk=
::YQ03rBFzNR3SWATElA==
::dhAmsQZ3MwfNWATElA==
::ZQ0/vhVqMQ3MEVWAtB9wSA==
::Zg8zqx1/OA3MEVWAtB9wSA==
::dhA7pRFwIByZRRnk
::Zh4grVQjdCuDJHyn3HU/OhBRXhe+P2OzF7wg/O3o+9aBt0ERGucnfe8=
::YB416Ek+ZG8=
::
::
::978f952a14a936cc963da21a135fa983
@echo off
chcp 65001 >nul
setlocal EnableExtensions EnableDelayedExpansion

:: ===== 基本参数 =====
set PROXY_SERVER=127.0.0.1:30000

cls
echo 请选择代理模式
echo [1] 全局代理
echo [2] 跳过中国大陆
echo.
set /p MODE=请输入选项:

if "%MODE%"=="1" set ROUTING=global
if "%MODE%"=="2" set ROUTING=bypass_cn
if not defined ROUTING (
    echo 无效选项
    timeout /t 2 >nul
    exit /b
)

cls
echo 正在启动代理（模式：%ROUTING% ?
echo.

:: ===== 启用系统代理（先开 ?====
call :enable_proxy

echo ===============================
echo 代理已启动，实时日志如下 ?
echo 关闭此窗口将自动关闭系统代理
echo ===============================
echo.

:: ===== 前台运行代理（关键）=====
proxy.exe -f xxx.xxx.workers.dev:443 ^
          -ip saas.sin.fan ^
          -token xxx ^
          -routing %ROUTING%

:: ===== proxy.exe 退出后才会执行到这 ?=====
echo.
echo 代理程序已退出，正在关闭系统代理...
call :disable_proxy
timeout /t 1 >nul
exit /b

:: ================== 函数 ?==================

:enable_proxy
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" ^
 /v ProxyEnable /t REG_DWORD /d 1 /f >nul

reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" ^
 /v ProxyServer /t REG_SZ /d "%PROXY_SERVER%" /f >nul

reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" ^
 /v ProxyOverride /t REG_SZ ^
 /d "localhost;127.*;10.*;172.16.*;172.17.*;172.18.*;172.19.*;172.20.*;172.21.*;172.22.*;172.23.*;172.24.*;172.25.*;172.26.*;172.27.*;172.28.*;172.29.*;172.30.*;172.31.*;192.168.*;<local>" ^
 /f >nul
exit /b

:disable_proxy
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" ^
 /v ProxyEnable /t REG_DWORD /d 0 /f >nul
exit /b
