set lines 300 pages 300
col samp_time for a20
select trunc(sample_time,'mi'),SESSION_ID,SESSION_SERIAL#,SQL_ID
from v$active_session_history a
where a.sample_time > sysdate-10/144
and SESSION_ID='&sid'
order by trunc(sample_time,'mi');