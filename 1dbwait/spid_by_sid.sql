col machine for a20
col program for a30
col spid for  a10
col USERNAME for a10
select a.inst_id,a.spid,b.sid,b.serial#,b.USERNAME,b.program,b.machine,b.osuser,b.sql_id  from gv$process a,gv$session b where a.addr=b.paddr and a.inst_id=b.inst_id and b.inst_id ='&inst_id' and b.sid='&sid';