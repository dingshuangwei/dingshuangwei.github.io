set pages 9999;
set linesize 200;
set echo off
col event for a40;
col program format a27
col username for a9
col client for a25
col sess for a12
PROMPT
PROMPT +------------------------------------------------------------------------+
PROMPT | display uncommit transactions session                                  |
PROMPT +------------------------------------------------------------------------+ 
PROMPT

select to_char(sysdate,'mmdd hh24:mi:ss') as curtime,a.sid||','||a.serial# as sess,a.program,a.username,
to_char(a.logon_time,'mmdd hh24:mi:ss') as logon_time,
a.machine||'@'||a.osuser||'@'||a.process as client,decode(a.sql_id,'',a.prev_sql_id,a.sql_id) as sql_id,b.event||':'||b.p1||':'||b.p2 as event
from v$session a,v$session_wait b,v$transaction c
where c.ses_addr=a.saddr and a.sid=b.sid;

