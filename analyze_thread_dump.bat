@echo off
setlocal enabledelayedexpansion

rem Thread Dump Analyzer for Windows
rem This script analyzes Java thread dumps in log files and identifies potential issues
rem Usage: analyze_thread_dump.bat <logfile>

if "%~1"=="" (
    echo Usage: %0 ^<logfile^>
    exit /b 1
)

set LOGFILE=%~1

if not exist "%LOGFILE%" (
    echo Error: Log file '%LOGFILE%' not found.
    exit /b 1
)

echo =====================================================
echo Thread Dump Analysis for: %LOGFILE%
echo =====================================================

rem Count the number of thread dumps in the file
findstr /C:"Full thread dump" "%LOGFILE%" > thread_dumps_temp.txt
set /a thread_dump_count=0
for /f %%a in (thread_dumps_temp.txt) do set /a thread_dump_count+=1
echo Found %thread_dump_count% thread dump(s) in the log file.
echo.

rem Extract thread states
echo Thread State Summary:
echo ---------------------

rem Find all BLOCKED threads
findstr /C:"java.lang.Thread.State: BLOCKED" "%LOGFILE%" > blocked_threads_temp.txt
set /a blocked_count=0
for /f %%a in (blocked_threads_temp.txt) do set /a blocked_count+=1
echo BLOCKED threads: %blocked_count%

rem Find all WAITING threads
findstr /C:"java.lang.Thread.State: WAITING" "%LOGFILE%" > waiting_threads_temp.txt
set /a waiting_count=0
for /f %%a in (waiting_threads_temp.txt) do set /a waiting_count+=1
echo WAITING threads: %waiting_count%

rem Find all TIMED_WAITING threads
findstr /C:"java.lang.Thread.State: TIMED_WAITING" "%LOGFILE%" > timed_waiting_threads_temp.txt
set /a timed_waiting_count=0
for /f %%a in (timed_waiting_threads_temp.txt) do set /a timed_waiting_count+=1
echo TIMED_WAITING threads: %timed_waiting_count%

rem Find all RUNNABLE threads
findstr /C:"java.lang.Thread.State: RUNNABLE" "%LOGFILE%" > runnable_threads_temp.txt
set /a runnable_count=0
for /f %%a in (runnable_threads_temp.txt) do set /a runnable_count+=1
echo RUNNABLE threads: %runnable_count%
echo.

rem Check for deadlocks
echo Deadlock Analysis:
echo -----------------
findstr /C:"Found" /C:"deadlock" "%LOGFILE%" > deadlocks_temp.txt
if %ERRORLEVEL% EQU 0 (
    echo ALERT: Deadlocks detected in thread dump!
    echo.
    echo Deadlock Details:
    findstr /N /C:"Found" /C:"deadlock" "%LOGFILE%" > deadlock_lines_temp.txt
    for /f "tokens=1 delims=:" %%a in (deadlock_lines_temp.txt) do (
        set /a line_num=%%a
        set /a end_line=!line_num!+15
        set /a current_line=!line_num!
        echo --- Deadlock at line !line_num! ---
        for /f "skip=!line_num! delims=" %%b in (%LOGFILE%) do (
            echo %%b
            set /a current_line+=1
            if !current_line! GTR !end_line! goto :deadlock_done
        )
        :deadlock_done
    )
) else (
    echo No deadlocks detected.
)
echo.

rem Check for Pega-specific issues
echo Pega-Specific Issues:
echo --------------------
findstr /C:"PegaRULES" "%LOGFILE%" > pega_temp.txt
if %ERRORLEVEL% EQU 0 (
    rem Check for Pega Database connection issues
    findstr /C:"ConnectionPool" "%LOGFILE%" > connpool_temp.txt
    findstr /C:"timeout" /C:"Timeout" /C:"wait" /C:"Wait" "%LOGFILE%" > timeout_temp.txt
    if %ERRORLEVEL% EQU 0 (
        echo Potential Database Connection Pool issues detected
    )
    
    rem Check for Pega requestor session issues
    findstr /C:"PRRequestor" /C:"PRThread" /C:"RequestProcessor" "%LOGFILE%" > requestor_temp.txt
    if %ERRORLEVEL% EQU 0 (
        echo Potential Pega Requestor processing issues detected
    )

    rem Check for Pega rule assembly issues
    findstr /C:"RuleAssembly" /C:"Rule-Assembly" "%LOGFILE%" > ruleasm_temp.txt
    if %ERRORLEVEL% EQU 0 (
        echo Potential Rule Assembly contention issues detected
    )

    rem Check for BLOB/CLOB operations
    findstr /C:"BLOB" /C:"CLOB" /C:"LargeObject" "%LOGFILE%" > blob_temp.txt
    if %ERRORLEVEL% EQU 0 (
        echo Potential BLOB/CLOB processing issues detected
    )
) else (
    echo No Pega-specific issues identified or not a Pega application log.
)
echo.

echo =====================================================
echo Analysis complete. For detailed investigation, examine BLOCKED threads.
echo Consider using a more comprehensive tool like JVisualVM, IBM Thread Analyzer,
echo or FastThread.io for deeper analysis.
echo =====================================================

rem Clean up temporary files
del *_temp.txt 2>nul

endlocal