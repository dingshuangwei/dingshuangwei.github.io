set echo off
store set sqlplusset replace
set echo off
set verify off
set serveroutput on
set feedback off
set lines 200
set pages 1000
col user_name for a15

SELECT a.user_name,
       a.sid,
       a.hash_value,
       b.VALUE open_cursor,
       a.sql_id,
       a.sql_text
  FROM v$OPEN_CURSOR a, v$sesstat b, V$STATNAME c
 WHERE     a.sid = NVL ('&sid', a.sid)
       AND a.sid = b.sid
       AND B.STATISTIC# = C.STATISTIC#
       AND c.name IN ('opened cursors current')
/
clear    breaks  
undefine sid
@sqlplusset

