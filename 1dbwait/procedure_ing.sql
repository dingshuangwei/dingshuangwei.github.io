--edit dingshuangwei

set echo off
store set sqlplusset replace
set pages 1000
set lines 270;
col sess   for a20 heading 'sess:serial|os process';
col status for a10;
col username for a15;
col client for a25;
col osuser for a10;
col program for a30;
col command for a20;
set verify off
col sql_id for a20 heading 'SQL_ID|SQL_CHILD_NUMBER'
col block_s for a15 heading 'BLOCK_SESS|INST:SESS'
col u_s_l for a45 heading 'USERNAME.STATUS|LAST_elapsed_time.SEQ#'
col inst_id for 9 heading 'I'
col object_name for a20
col name for a15
col owner for a10
col text for a100
set lines 500

PROMPT
PROMPT +------------------------------------------------------------------------+
PROMPT | display  runing procedure  in library                            |
PROMPT +------------------------------------------------------------------------+ 
PROMPT


select owner,name from v$db_object_cache where type like '%PROCE%' and locks>0 and pins>0;

PROMPT
PROMPT +------------------------------------------------------------------------+
PROMPT | display   procedure text                       |
PROMPT +------------------------------------------------------------------------+ 
PROMPT


select NAME,text from dba_source where name in (select name from v$db_object_cache where type like '%PROCE%'
and locks>0 and pins>0) 



PROMPT
PROMPT +------------------------------------------------------------------------+
PROMPT | display session  is runing procedure                            |
PROMPT +------------------------------------------------------------------------+ 
PROMPT
/* Formatted on 2013/4/17 15:47:13 (QP5 v5.227.12220.39754) */
SELECT DISTINCT
       a.inst_id,
       a.sid || ':' || a.serial# || ':' || c.spid AS sess,
       a.username,
       a.status||'.'||
       a.LAST_CALL_ET||'.'|| 
       a.seq# u_s_l,
       d.kglnaobj object_name,
       SUBSTR (a.program, 1, 25) program,
       SUBSTR (a.osuser || '@' || a.machine || '@' || a.process, 1, 24)
          AS client,
          a.BLOCKING_SESSION_STATUS
       || ':'
       || a.BLOCKING_INSTANCE
       || ':'
       || a.BLOCKING_SESSION
          block_s,
       TO_CHAR (a.logon_time, 'mm-dd hh24:mi') AS logon_time
  FROM gv$session a,
       gv$process c,
       sys.x$kglpn b,
       sys.x$kglob d
 WHERE     a.paddr = c.addr(+)
       AND a.username IS NOT NULL
       AND a.inst_id = c.inst_id
       AND b.kglpnuse = a.saddr
       AND a.inst_id = b.inst_id
       AND UPPER (d.kglnaobj) LIKE UPPER ('%&obj_name%')
       AND b.kglpnhdl = d.kglhdadr
/
@sqlplusset
