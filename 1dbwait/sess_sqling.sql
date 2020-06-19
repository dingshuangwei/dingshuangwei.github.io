SET ECHO OFF
SET PAGESIZE 2000  LINESIZE 200 VERIFY OFF HEADING ON
COL event FORMAT a18
COL program FORMAT a23
COL os_sess FOR a25 heading 'SESS_SERIAL|OSPID'
col u_s for a22 heading 'USERNMAE|LAST_CALL|SEQ#'
COL client FOR a31
col sql_id for a18
COL row_wait  for a22 heading 'ROW_WAIT|FILE#:OBJ#:BLOCK#:ROW#'
col logon_time for a12
col status for a10  heading 'STATUS|STATE'
col command for a3
col block_s for a15 heading 'BLOCK_SESS|INST:SESS'
col inst_id for 9 heading 'I'
col EXEC_TIME for a5 heading 'RUN|TIME'
col sql_text for a250
col machine for a15

define _VERSION_11  = "--"
define _VERSION_10  = "--"
define _LONG_MODE   = "  "

col version11  noprint new_value _VERSION_11
col version10  noprint new_value _VERSION_10

select /*+ no_parallel */case
         when substr(banner,
                     instr(banner, 'Release ') + 8,
                     instr(substr(banner, instr(banner, 'Release ') + 8), ' ')) >=
              '10.2' and
              substr(banner,
                     instr(banner, 'Release ') + 8,
                     instr(substr(banner, instr(banner, 'Release ') + 8), ' ')) <
              '11.2' then
          '  '
         else
          '--'
       end  version10,
       case
         when substr(banner,
                     instr(banner, 'Release ') + 8,
                     instr(substr(banner, instr(banner, 'Release ') + 8), ' ')) >=
              '11.2' then
          '  '
         else
          '--'
       end  version11
  from v$version
 where banner like 'Oracle Database%';


break on inst_id
SELECT /*+ noparallel */b.inst_id,
       SUBSTR(DECODE(b.STATE,
                     'WAITING',
                     b.EVENT,
                     DECODE(TYPE, 'BACKGROUND', '[BCPU]:', '[CPU]:') ||b.event),
              1,
              18) event,
       SUBSTR(b.program, 1, 22) program,
       b.username || ':' || last_call_et || ':' || b.seq# u_s,
       b.sid || ':' || b.serial# || ':' || c.spid os_sess,
--      substr(b.status || ':' || b.state, 1, 19) status,
&_VERSION_10       substr(decode(b.status,
&_VERSION_10              'ACTIVE',
&_VERSION_10              'A',
&_VERSION_10              'INACTIVE',
&_VERSION_10              'I',
&_VERSION_10              'KILLED',
&_VERSION_10              'K',
&_VERSION_10              'CACHED',
&_VERSION_10              'C',
&_VERSION_10              'SNIPED',
&_VERSION_10              'S') || '.' || decode(b.state,
&_VERSION_10                                    'WAITING',
&_VERSION_10                                    'W' || '.' || b.SECONDS_IN_WAIT || 'S',
&_VERSION_10                                    'WAITED UNKNOWN TIME',
&_VERSION_10                                    'U',
&_VERSION_10                                    'WAITED SHORT TIME',
&_VERSION_10                                    'S',
&_VERSION_10                                    'WAITED KNOWN TIME',
&_VERSION_10                                    'N'),1,10) status,
&_VERSION_11       substr(decode(b.status,
&_VERSION_11              'ACTIVE',
&_VERSION_11              'A',
&_VERSION_11              'INACTIVE',
&_VERSION_11              'I',
&_VERSION_11              'KILLED',
&_VERSION_11              'K',
&_VERSION_11              'CACHED',
&_VERSION_11              'C',
&_VERSION_11              'SNIPED',
&_VERSION_11              'S') || '.' ||
&_VERSION_11       decode(b.state,
&_VERSION_11              'WAITING',
&_VERSION_11              'W' || '.' || trunc(b.wait_time_micro / 1000) || 'MS',
&_VERSION_11              'WAITED UNKNOWN TIME',
&_VERSION_11              'U' || '.' || trunc(b.TIME_SINCE_LAST_WAIT_MICRO / 1000) || 'MS',
&_VERSION_11              'WAITED SHORT TIME',
&_VERSION_11              'S' || '.' || trunc(b.TIME_SINCE_LAST_WAIT_MICRO / 1000) || 'MS',
&_VERSION_11              'WAITED KNOWN TIME',
&_VERSION_11              'N' || '.' || trunc(b.TIME_SINCE_LAST_WAIT_MICRO / 1000) || 'MS'),1,10) status, 
                   substr(machine,1,15) machine,
                   DECODE(b.sql_id, '0', 'P.'||b.prev_sql_id, '', 'P.'||b.prev_sql_id, 'C.'||b.sql_id) || ':' || sql_child_number sql_id,
                   substr(l.sql_text,1,50) sql_text
  FROM gv$session b, gv$process c, gv$session_wait s, sys.audit_actions a,gv$sql l
 WHERE b.paddr = c.addr
   AND s.SID = b.SID
   and b.inst_id = c.inst_id
   and c.inst_id = s.inst_id
   and a.action = b.command
   and b.status = 'ACTIVE'
   and b.username is not null
   and l.sql_id=b.sql_id
   and b.SQL_CHILD_NUMBER=l.CHILD_NUMBER
   and b.inst_id=l.inst_id
 order by inst_id, sql_id 
/