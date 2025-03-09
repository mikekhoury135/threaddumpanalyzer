#!/bin/bash

# Thread Dump Analyzer
# This script analyzes Java thread dumps in log files and identifies potential issues
# Usage: ./analyze_thread_dump.sh <logfile>

if [ $# -lt 1 ]; then
    echo "Usage: $0 <logfile>"
    exit 1
fi

LOGFILE=$1

if [ ! -f "$LOGFILE" ]; then
    echo "Error: Log file '$LOGFILE' not found."
    exit 1
fi

echo "====================================================="
echo "Thread Dump Analysis for: $LOGFILE"
echo "====================================================="

# Count the number of thread dumps in the file
thread_dump_count=$(grep -c "Full thread dump" "$LOGFILE")
echo "Found $thread_dump_count thread dump(s) in the log file."
echo

# Extract thread states
echo "Thread State Summary:"
echo "---------------------"
if grep -q "Full thread dump" "$LOGFILE"; then
    # Find all BLOCKED threads
    blocked_count=$(grep -c "java.lang.Thread.State: BLOCKED" "$LOGFILE")
    echo "BLOCKED threads: $blocked_count"
    
    # Find all WAITING threads
    waiting_count=$(grep -c "java.lang.Thread.State: WAITING" "$LOGFILE")
    echo "WAITING threads: $waiting_count"
    
    # Find all TIMED_WAITING threads
    timed_waiting_count=$(grep -c "java.lang.Thread.State: TIMED_WAITING" "$LOGFILE")
    echo "TIMED_WAITING threads: $timed_waiting_count"
    
    # Find all RUNNABLE threads
    runnable_count=$(grep -c "java.lang.Thread.State: RUNNABLE" "$LOGFILE")
    echo "RUNNABLE threads: $runnable_count"
    
    echo
fi

# Check for deadlocks
echo "Deadlock Analysis:"
echo "-----------------"
if grep -q "Found [0-9]\\+ deadlock" "$LOGFILE" || grep -q "deadlock" "$LOGFILE"; then
    echo "ALERT: Deadlocks detected in thread dump!"
    
    # Extract deadlock information
    echo
    echo "Deadlock Details:"
    grep -A 20 "Found.*deadlock" "$LOGFILE" | head -15
else
    echo "No deadlocks detected."
fi
echo

# Check for high CPU threads (threads that are likely consuming CPU)
echo "High CPU Thread Analysis:"
echo "-----------------------"
echo "Top 5 potential high CPU threads (RUNNABLE state with native methods):"
grep -B 2 -A 10 "java.lang.Thread.State: RUNNABLE.*\(Native Method\)" "$LOGFILE" | 
    grep -E "^\".*\"" | head -5

echo

# Check for common issues in Pega applications
echo "Pega-Specific Issues:"
echo "--------------------"
if grep -q "PegaRULES" "$LOGFILE"; then
    # Check for Pega Database connection issues
    if grep -q "ConnectionPool" "$LOGFILE" && grep -q "timeout\|Timeout\|wait\|Wait" "$LOGFILE"; then
        echo "Potential Database Connection Pool issues detected"
    fi
    
    # Check for Pega requestor session issues
    if grep -q "PRRequestor\|PRThread\|RequestProcessor" "$LOGFILE" && grep -q "BLOCKED\|WAITING" "$LOGFILE"; then
        echo "Potential Pega Requestor processing issues detected"
    fi

    # Check for Pega rule assembly issues
    if grep -q "RuleAssembly\|Rule-Assembly" "$LOGFILE" && grep -q "BLOCKED\|WAITING" "$LOGFILE"; then
        echo "Potential Rule Assembly contention issues detected"
    fi

    # Check for BLOB/CLOB operations
    if grep -q "BLOB\|CLOB\|LargeObject" "$LOGFILE" && grep -q "BLOCKED\|WAITING" "$LOGFILE"; then
        echo "Potential BLOB/CLOB processing issues detected"
    fi
else
    echo "No Pega-specific issues identified or not a Pega application log."
fi
echo

# Identify thread groups with most contention
echo "Thread Contention Analysis:"
echo "-------------------------"
echo "Looking for common lock patterns in BLOCKED threads..."

# Extract BLOCKED thread stacks
grep -B 1 -A 20 "java.lang.Thread.State: BLOCKED" "$LOGFILE" > /tmp/blocked_threads.tmp

# Find common locks
if [ -s /tmp/blocked_threads.tmp ]; then
    grep -o 'locked .*' /tmp/blocked_threads.tmp | sort | uniq -c | sort -nr | head -5
    echo
    echo "Top contended locks:"
    grep -o 'waiting to lock .*' /tmp/blocked_threads.tmp | sort | uniq -c | sort -nr | head -5
else
    echo "No detailed lock contention data found."
fi

# Clean up
rm -f /tmp/blocked_threads.tmp

echo
echo "====================================================="
echo "Analysis complete. For detailed investigation, check threads in BLOCKED state and examine lock patterns."
echo "Consider using a more comprehensive tool like JVisualVM, IBM Thread Analyzer, or FastThread.io for deeper analysis."
echo "====================================================="