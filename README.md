# Thread Dump Analyzer for Pega Applications

A lightweight tool for analyzing thread dumps in large log files, particularly targeting Pega 8.6+ applications.

## Features

- Identifies thread dumps in log files
- Counts threads by state (BLOCKED, WAITING, TIMED_WAITING, RUNNABLE)
- Detects deadlocks
- Highlights potential high CPU consumption threads
- Discovers Pega-specific issues:
  - Database connection pool issues
  - Requestor processing problems
  - Rule assembly contention
  - BLOB/CLOB operation bottlenecks
- Identifies locks with most contention

## Usage

### Windows

```
analyze_thread_dump.bat <path_to_logfile>
```

### Linux/macOS

```
./analyze_thread_dump.sh <path_to_logfile>
```

Make sure the shell script is executable:
```
chmod +x analyze_thread_dump.sh
```

## Example

```
analyze_thread_dump.bat C:\logs\pega-server-2023-10-15.log
```

## When to Use

Use this tool when:
- Your Pega application experiences slowness or hangs
- You need to quickly identify the root cause of thread contention
- You have large log files with multiple thread dumps that are difficult to review manually

## Interpreting Results

The analysis focuses on these key areas:

1. **Thread States Summary** - Large numbers of BLOCKED threads typically indicate contention issues.

2. **Deadlock Detection** - Explicitly identifies deadlocks in the thread dump.

3. **High CPU Thread Analysis** - Threads in RUNNABLE state with native methods may be consuming high CPU.

4. **Pega-Specific Issues** - Common Pega platform issues that can cause performance problems.

5. **Thread Contention Analysis** - Identifies which locks are most contended, helping pinpoint bottlenecks.

## Limitations

This is a basic analyzer that uses pattern matching. For more complex analysis:
- Use JVisualVM for live JVM monitoring
- Use IBM Thread Analyzer or FastThread.io for more comprehensive analysis
- Consider commercial APM tools like AppDynamics or Dynatrace