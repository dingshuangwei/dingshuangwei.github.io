# 从AWR统计SQL性能指标
# huangtingzhong
#modify htz 20190117
#去掉总的值，只显示评估值，新增加AP,CC,IO等指标的显示

set echo off
set lines 300 heading on verify off
col sql_id for a18
col i_mem for 999999 heading 'SHARED|Mem KB'
col sorts for 99999999
col version_count for 999 heading 'VER|NUM'
col executions for 999999 heading 'EXEC|NUM'
col parse_calls for 999999 heading 'PARSE|CALLS'
col avg_disk_reads         for  99999                   heading 'AVG|DISK|READ'
col avg_direct_writes      for  99999                   heading 'AVG|DIRECT|WRITE'
col avg_buffer_gets        for  9999999                heading 'AVG|BUFFER|GET'
col avg_rows_processed     for  999999999              heading 'AVG|ROW_PROC'
col avg_fetches            for  999999999              heading 'AVG|FETCH'
col AVG_ELAPSED_TIME       for  999999999999           heading 'AVG|ELAPSED|TIME'
col cpu_time               for  99999999999            heading 'CPU_TIME'
col AVG_CPU_TIME           for  999999999999           heading 'AVG|CPU_TIME'
col avg_iowait             for  999999999999           heading "AVG|IO_TIME"
col avg_clwait             for  999999999999           heading "AVG|CL_TIME"
col avg_apwait             for  99999999               heading "AVG|AP_TIME"
col avg_ccwait             for  99999999               heading "AVG|CC_TIME"
col avg_plwait             for  99999999               heading "AVG|PL_TIME"
col avg_jawait             for  99999999               heading "AVG|JA_TIME"
col avg_priopswait         for  99999999               heading "AVG|P_R_IOPS"
col avg_pwiopswait         for  99999999               heading "AVG|P_W_IOPS"
col plan_hash_value        for  9999999999             heading "PLAN|HASH_VALUE"

col PARSING_SCHEMA_NAME  for a15 heading 'PARSING|SCHEMA_NAME'

col snap_id for 999999 heading 'SNAP_ID'
col end_time for a5
col instance_number for 99 heading 'I'


PRO
PRO 1. Enter SQL_ID (required)
DEF sqlid = '&1';

VAR sql_id VARCHAR2(13);
EXEC :sql_id := '&&sqlid';

undefine sqlid;
 SELECT TO_CHAR (END_INTERVAL_TIME, 'dd hh24') end_time,
         a.snap_id,
         a.instance_number,
         a.plan_hash_value,
         a.parsing_schema_name,
         (a.executions_delta)                 executions,
         TRUNC (
               (elapsed_time_delta)
             / DECODE ( (executions_delta), 0, 1, (executions_delta)))
             avg_elapsed_time,
         TRUNC (
               (cpu_time_delta)
             / DECODE ( (executions_delta), 0, 1, (executions_delta)))
             avg_cpu_time,
         TRUNC (
               (buffer_gets_delta)
             / DECODE ( (executions_delta), 0, 1, (executions_delta)))
             avg_buffer_gets,
         TRUNC (
               (disk_reads_delta)
             / DECODE ( (executions_delta), 0, 1, (executions_delta)))
             avg_disk_reads,
         TRUNC (
               (direct_writes_delta)
             / DECODE ( (executions_delta), 0, 1, (executions_delta)))
             avg_direct_writes,
         TRUNC (
               (rows_processed_delta)
             / DECODE ( (executions_delta), 0, 1, (executions_delta)))
             avg_rows_processed,
         TRUNC (
               (fetches_delta)
             / DECODE ( (executions_delta), 0, 1, (executions_delta)))
             avg_fetches,
         TRUNC (
               (IOWAIT_DELTA)
             / DECODE ( (executions_delta), 0, 1, (executions_delta)))
             avg_iowait,
         TRUNC (
               (CLWAIT_DELTA)
             / DECODE ( (executions_delta), 0, 1, (executions_delta)))
             avg_clwait,
         TRUNC (
               (APWAIT_DELTA)
             / DECODE ( (executions_delta), 0, 1, (executions_delta)))
             avg_apwait,
         TRUNC (
               (CCWAIT_DELTA)
             / DECODE ( (executions_delta), 0, 1, (executions_delta)))
             avg_ccwait,
         TRUNC (
               (PLSEXEC_TIME_DELTA)
             / DECODE ( (executions_delta), 0, 1, (executions_delta)))
             avg_plwait,
         TRUNC (
               (JAVEXEC_TIME_DELTA)
             / DECODE ( (executions_delta), 0, 1, (executions_delta)))
             avg_jawait,
         TRUNC (
               (PHYSICAL_READ_REQUESTS_DELTA)
             / DECODE ( (executions_delta), 0, 1, (executions_delta)))
             avg_priopswait,
         TRUNC (
               (PHYSICAL_WRITE_REQUESTS_DELTA)
             / DECODE ( (executions_delta), 0, 1, (executions_delta)))
             avg_pwiopswait
    FROM dba_hist_sqlstat a, dba_hist_snapshot b
   WHERE     a.sql_id = :sql_id
         AND a.snap_id = b.snap_id
         AND a.instance_number = b.instance_number
ORDER BY snap_id
/
undefine begin_snap;
undefine sqlid;
undefine end_snap;
undefine sort_type;
undefine topn;