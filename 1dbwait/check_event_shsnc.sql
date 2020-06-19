-- +----------------------------------------------------------------------------+
-- |                          dingshuangwei                                     |
-- |                                                                            |
-- |----------------------------------------------------------------------------|
-- |  Copyright (c) 1998-2012 dingshuangwei M. Hunter. All rights reserved.     |
-- |----------------------------------------------------------------------------|
-- | DATABASE : Oracle                                                          |
-- | FILE     :                                                                 |
-- | CLASS    :                                                                 |
-- | PURPOSE  :                                                                 |
-- | NOTE     :2019-07-25                                                       |
-- +----------------------------------------------------------------------------+

SET ECHO        OFF
SET FEEDBACK    OFF
SET HEADING     OFF
SET LINESIZE    180
SET PAGESIZE    50000
SET TERMOUT     ON
SET TIMING      OFF
SET TRIMOUT     ON
SET TRIMSPOOL   ON
SET VERIFY      OFF

CLEAR COLUMNS
CLEAR BREAKS
CLEAR COMPUTES

PROMPT 
PROMPT +------------------------------------------------------------------------+
PROMPT | MAX EVENT                                                              |
PROMPT +------------------------------------------------------------------------+


set linesize 500 
set pages 999
col EVENT for a40
col WAIT_CLASS for a15
select inst_id, event#, event,WAIT_CLASS, count(*)  from gv$session where wait_class# <> 6 group by inst_id, event#, event,WAIT_CLASS order by 1,5 desc;



PROMPT 
PROMPT +------------------------------------------------------------------------+
PROMPT |  EVENT'S SESS  INFOMATION                                              |
PROMPT |  Enter EVENT#                                                          |
PROMPT +------------------------------------------------------------------------+



set line 300 pages 150
col username for a10
col program for a35
col event for a30
col MACHINE for a15
col OSUSER for a10
col status for a8
select inst_id,sid,process,username,OSUSER,program,MACHINE,module,sql_id,event,status,BLOCKING_SESSION,LAST_CALL_ET from gv$session where event#='&event'
order by LAST_CALL_ET;





PROMPT 
PROMPT +------------------------------------------------------------------------+
PROMPT |  SQL_TEXT    INFOMATION                                        |
PROMPT |  Enter sql_id                                                          |
PROMPT +------------------------------------------------------------------------+


set linesize 150
set pagesize 150
select SQL_ID,dbms_lob.substr(SQL_FULLTEXT)from v$sqlarea 
where SQL_ID='&SQL_ID1';



PROMPT 
PROMPT +------------------------------------------------------------------------+
PROMPT |  SQL_PLAN  INFOMATION                                        |
PROMPT |  Enter sql_id                                                          |
PROMPT +------------------------------------------------------------------------+

set line 150
set pagesize 9999
set long 9999
select * from table(dbms_xplan.display_cursor('&SQL_ID11',null,'advanced')); 































