set lines 200
set verify off
set echo off
set feedback off
set serveroutput on
set pages 9999

accept sid1 prompt 'ENTER YOU sid: ' 
variable i_sid1 number;
exec :i_sid1 := &sid1;



accept hash_value1 prompt 'ENTER YOU sql_hash_value: ' 
variable i_hash_value1 varchar2(30);
exec :i_hash_value1 :=upper('&hash_value1');



PROMPT
PROMPT
PROMPT  EVENT INFORMATION
PROMPT 

col EVENT for a30
col P1TEXT for a20
col P2TEXT for a20
col P3TEXT for a20
col MODULE for a30
select EVENT,P1TEXT,P1,P2TEXT,P2,P3TEXT,P3 from v$session where sid = :i_sid1 and SQL_HASH_VALUE = :i_hash_value1 ;


PROMPT
PROMPT
PROMPT 1 SQL_ID INFORMATION
PROMPT


select MODULE,SQL_ID,PREV_SQL_ID from v$session where sid = :i_sid1 and SQL_HASH_VALUE = :i_hash_value1 ;

PROMPT
PROMPT 
PROMPT 2 BLOCKING INFORMATION         
PROMPT 


select BLOCKING_SESSION_STATUS,BLOCKING_INSTANCE,BLOCKING_SESSION from v$session where  sid = :i_sid1 and SQL_HASH_VALUE = :i_hash_value1 ;




PROMPT
PROMPT
PROMPT 3 SQLTEXT INFORMATION    
PROMPT 



set pagesize 9999
set long 9999
set line 200
select SQL_FULLTEXT
from v$sql where HASH_VALUE= :i_hash_value1;













