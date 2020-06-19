
host=`hostname`
echo "= OS SYSTEM NAME ： $host =="
echo
echo "$host title_check_1_os_error_log"
echo
#errpt
unamesr="`uname -sr`"
case "$unamesr" in
AIX*)
errpt | head -100
;;
SunOS\ 5*)
tail -2000 /var/adm/messages |awk '{if( $0 ~ /errors|warning|fail/) {print $0;next}}'
;;
HP*)
tail -2000 /var/adm/syslog/syslog.log |awk '{if( $0 ~ /errors|warning|fail/) {print $0;next}}'
;;
Linux*)
tail -2000 /var/log/messages |awk '{if( $0 ~ /errors|warning|fail/) {print $0;next}}'
;;
*)
exit
;;
esac

echo "$host title_check_2_SWAP STATUS ($host)"
unamesr="`uname -sr`"
case "$unamesr" in
AIX*)
lsps -s
;;
SunOS\ 5*)
swap -s
swap -l
;;
HP*)
/usr/sbin/swapinfo
;;
Linux*)
/sbin/swapon -s
;;
*)
exit
;;
esac

echo


echo "$host title_check_3_cpu($host)"
vmstat 2 5
echo
echo "$host title_check_4 LOCAL FILESYSTEM ($host)"
echo
#unamesr="`uname -sr`"
case "$unamesr" in
AIX*)
df -g | awk -F"[ ]*|%" '(NR>1){if ($4 > 0)print $0}'
;;
SunOS*)
df -h 
;;
HP*)
bdf | awk -F"[ ]*|%" '(NR>1){if ($5 > 0)print $0}'
;;
Linux*)
df -h | awk -F"[ ]*|%" '(NR>1){if ($5 > 0)print $0}'
;;
*)
exit
;;
esac
echo


echo "$host title_check_5 PROCESS COUNT ps -ef|grep LOCAL=NO|wc -l($host)"
echo  "LOCAL=NO PROCCESS IS COUNT"  `ps -ef|grep LOCAL=NO|wc -l`
echo

echo "$host title_check_6 CRS STATUS ($host)"
echo
#crs_stat -t | awk '{ if( $0 ~ /UNKNOWN|OFFLINE/) {print $0;next}}'
crsctl stat res -t > res.log
head -n 6 res.log
while read line
do
        tmp=`echo $line | grep "^ora"`
        exception=`echo $line | grep -E "OFFLINE|UNKNOWN"`
        if [ "X$tmp" != "X" ];then
                title=`echo $line | grep "^ora" | awk '{print $1}'`
        fi
        
        if [ "X$exception" != "X" ];then
                echo $title : $exception
        fi
        
done < res.log
rm res.log


########env profile############
unamesr="`uname -sr`"
case "$unamesr" in
AIX*)
. ~/.profile
;;
SunOS\ 5*)
. ~/.bash_profile
;;
HP*)
. ~/.profile
;;
Linux*)
. ~/.bash_profile
;;
*)
exit
;;
esac

echo

echo
echo "$host title_check_7 ALERT LOG($host)"
sqlplus -s "/as sysdba" <<EOF
set echo off
set termout off
set trimout off
set feedback off
set heading off
set linesize 500
col name for a30
col value for a100
spool bdump_log_dest.txt
select name,value from v\$parameter where name='background_dump_dest';
spool off
exit;
EOF

#select to_char(sysdate-1,'Dy Mon DD','NLS_DATE_LANGUAGE=AMERICAN') startday from dual
#where trunc(sysdate,'DDD') > trunc(sysdate,'MONTH')
#union
#select to_char(sysdate,'Dy Mon DD','NLS_DATE_LANGUAGE=AMERICAN') startday from dual
#where trunc(sysdate,'DDD') = trunc(sysdate,'MONTH');

a_date=`sqlplus -s "/ as sysdba" <<EOF
set echo off
set termout off
set trimout off
set feedback off
set heading off
set linesize 200
select to_char(sysdate-1,'Dy Mon DD','NLS_DATE_LANGUAGE=AMERICAN') startday from dual
exit;
EOF`
b_date=`echo $a_date`

d_date=`sqlplus -s "/ as sysdba" <<EOF
set echo off
set termout off
set trimout off
set feedback off
set heading off
set linesize 200
select to_char(sysdate,'Dy Mon DD','NLS_DATE_LANGUAGE=AMERICAN') startday from dual
exit;
EOF`
today_a=`echo $d_date`

c_date=`sqlplus -s "/ as sysdba" <<EOF
set echo off
set termout off
set trimout off
set feedback off
set heading off
set linesize 200
select to_char(sysdate,'YYYY','NLS_DATE_LANGUAGE=AMERICAN') from dual;
exit;
EOF`
y_date=`echo $c_date`
m_date="yyyxxxxyyyyxxxyy"

daynum_a=`echo $b_date|sed 's/\(.\{8\}\)0/\1 /' |awk '{print $3}'`
if [ $daynum_a -lt 10 ];then
#echo "daynum_a=$daynum_a is little than 10"
m_date=`echo $b_date | awk '{print substr($0,1,8)}'`" $daynum_a"
#echo "m_date = $m_date"
fi

today_b="yyyxxxxyyyyxxxyy"
daynum_b=`echo $today_a|sed 's/\(.\{8\}\)0/\1 /' |awk '{print $3}'`
if [ $daynum_b -lt 10 ];then
#echo "daynum_b=$daynum_b is little than 10"
today_b=`echo $today_a | awk '{print substr($0,1,8)}'`" $daynum_b"
#echo "today_b = $today_b"
fi

BGDEST=`cat  bdump_log_dest.txt|grep -v "select"|grep "background_dump_dest" |awk '{print $2 }'`

rm bdump_log_dest.txt

#unamesr="`uname -sr`"
case "$unamesr" in
SunOS\ 5*)
AWK=nawk
;;
*)
AWK=awk
;;
esac

#echo "BGDEST = \"$BGDEST\""
alert_flag=`cat $BGDEST/alert_$ORACLE_SID.log|${AWK} '{ if (($0 ~ "'"$m_date"'" || $0 ~ "'"$b_date"'" ) && $0 ~ "'"$y_date"'") \
{print $0;exit}}'`

if [ "X$alert_flag" = "X" ];then

cat $BGDEST/alert_$ORACLE_SID.log.`date +%Y%m`01 |${AWK} '{ if (($0 ~ "'"$m_date"'" || $0 ~ "'"$b_date"'" ) && $0 ~ "'"$y_date"'") \
{sk=1;print $0 ;next;} if (sk==1) {print $0}}'|${AWK} '{ if ($0 ~ /'$y_date'$/) {t_date=$0;next;} \
 if( $0 ~ /ORA-|Errors|Deadlock|CHANGE TRACKING ERROR|checkpoint not complete|Starting ORACLE instance|Shutting down instance|^IPC|fail/) {print t_date"|"$0;next}}'
 
cat $BGDEST/alert_$ORACLE_SID.log|${AWK} '{ if (($0 ~ "'"$today_a"'" || $0 ~ "'"$today_b"'" ) && $0 ~ "'"$y_date"'") \
{sk=1;print $0 ;next;} if (sk==1) {print $0}}'|${AWK} '{ if ($0 ~ /'$y_date'$/) {t_date=$0;next;} \
 if( $0 ~ /ORA-|Errors|Deadlock|CHANGE TRACKING ERROR|checkpoint not complete|Starting ORACLE instance|Shutting down instance|^IPC|fail/) {print t_date"|"$0;next}}'

else

cat $BGDEST/alert_$ORACLE_SID.log|${AWK} '{ if (($0 ~ "'"$m_date"'" || $0 ~ "'"$b_date"'" ) && $0 ~ "'"$y_date"'") \
{sk=1;print $0 ;next;} if (sk==1) {print $0}}'|${AWK} '{ if ($0 ~ /'$y_date'$/) {t_date=$0;next;} \
 if( $0 ~ /ORA-|Errors|Deadlock|CHANGE TRACKING ERROR|checkpoint not complete|Starting ORACLE instance|Shutting down instance|^IPC|fail/) {print t_date"|"$0;next}}'

fi


sqlplus -s / as sysdba  <<EOF
set head off
set linesize 200
select '$host title_check_8 RMAN_CHECK($host)' from dual;
set head on
col STATUS format a23
col START_TIME format a15
col END_TIME format a15
col hrs format 999.99
select * from (select SESSION_KEY,
       INPUT_TYPE,
       STATUS,
       to_char(START_TIME, 'mm/dd/yy hh24:mi') start_time,
       to_char(END_TIME, 'mm/dd/yy hh24:mi') end_time,
       elapsed_seconds / 3600 hrs
  from V\$RMAN_BACKUP_JOB_DETAILS
 order by session_key desc) where rownum<40;
set head off

select '$host title_check_9 SCN headroom($host)' from dual;
set head on
select
   version,
   to_char(SYSDATE,'YYYY/MM/DD HH24:MI:SS') DATE_TIME,
   ((((
    ((to_number(to_char(sysdate,'YYYY'))-1988)*12*31*24*60*60) +
    ((to_number(to_char(sysdate,'MM'))-1)*31*24*60*60) +
    (((to_number(to_char(sysdate,'DD'))-1))*24*60*60) +
    (to_number(to_char(sysdate,'HH24'))*60*60) +
    (to_number(to_char(sysdate,'MI'))*60) +
    (to_number(to_char(sysdate,'SS')))
    ) * (16*1024)) - dbms_flashback.get_system_change_number)
   / (16*1024*60*60*24)
   ) indicator
   from v\$instance;


select trunc(first_time, 'DD') date_ ,
round((max(first_change#)-min(first_change#))/nullif(max(first_time)-min(first_time), 0)/86400) rate
   , round(min(((((
      ((to_number(to_char(first_time,'yyyy'))-1988)*12*31*24*60*60) +
      ((to_number(to_char(first_time,'mm'))-1)*31*24*60*60) +
      (((to_number(to_char(first_time,'dd'))-1))*24*60*60) +
      (to_number(to_char(first_time,'hh24'))*60*60) +
      (to_number(to_char(first_time,'mi'))*60) +
      (to_number(to_char(first_time,'ss')))
      ) * (16*1024)) - first_change#)
      / (16*1024*60*60*24))),2) scn_headroom
from v\$archived_log
where next_time > first_time
  and next_time>sysdate-3
group by trunc(first_time, 'DD')
order by trunc(first_time, 'DD');
set head off

select '$host title_check_10 DATAFILE STATUS ($host)' from dual;
set head on
col name format a20
select name,status from v\$datafile where status in ('OFFLINE','RECOVER','RECOVER','SYSOFF');
set head off

select '$host title_check_11-1 PARTITION INDEX INVALID ($host)' from dual;
set head on
select index_owner,count(*) from dba_ind_partitions a where a.status='UNUSABLE' group by index_owner order by 2 desc ;
set head off

select '$host title_check_11-2 INDEX INVALID ($host)' from dual;
set head on
select owner,count(*) from dba_indexes a where a.status='UNUSABLE' group by owner order by 2 desc;
set head off

select '$host title_check_12 DBLINK NEW CREATE ($host)' from dual;
set head on
select owner,db_link,username,host,created from dba_db_links where created > sysdate-4;
set head off

select '$host title_check_13 DB_FILES COUNT ($host)' from dual;
set head on
col value for a10
select a.VALUE,(select count(1) from dba_data_files) db_files  from v\$parameter a   where a.NAME='db_files';
set head off

select '$host title_check_14 ASM STATUS ($host)' from dual;
set head on
col name for a40
select group_number,name,state,total_mb/1024 total_gb,free_mb/1024 free_gb from v\$asm_diskgroup;
set head off

select '$host title_check_15 TABLESPACE_USAGE_LIST($host)' from dual;
set head on
set line 200
set pages 2000
set time on
set timing off
set head on
col tablespace_name for a25
select b.tablespace_name,
       round(sum(b.bytes) / 1024 / 1024 / 1024, 0) sum_GB,
       round(sum(nvl(a.bytes, 0)) / 1024 / 1024 / 1024, 0) free_GB,
       round((sum(b.bytes) - sum(nvl(a.bytes, 0))) / sum(b.bytes), 4) * 100 use_precent,
       count(*)
  from (select tablespace_name, file_id, sum(bytes) bytes
          from dba_free_space
         group by tablespace_name, file_id) a,
       dba_data_files b
 where a.file_id(+) = b.file_id
   and a.tablespace_name(+) = b.tablespace_name
 group by b.tablespace_name
having round((sum(b.bytes) - sum(nvl(a.bytes, 0))) / sum(b.bytes), 4) * 100 >= 0
 order by 4 desc;
set head off

select '$host title_check_16 UNDO_USAGE_LIST($host)' from dual;
set head on
SET LINESIZE 500
set feedback off
col tablespace_name for a10
set linesize 258 pagesize 999
col TOTAL_SIZE format a15
col TOTAL_UESD_PCT format a15
col USE_PCT format a11
col USED_SIZE format a15
select -- a.owner,
 a.tablespace_name,
 round(b.total_mb) || ' MB' TOTAL_SIZE,
 round(c.use_mb / b.total_mb * 100) || ' %' TOTAL_UESD_PCT,
 a.status,
 round(a.use_mb) || ' MB' USED_SIZE,
 round(a.use_mb / b.total_mb * 100) || ' %' USE_PCT
  from (select owner,
               tablespace_name,
               status,
               sum(bytes) / 1024 / 1024 use_mb
          from dba_undo_extents
         group by owner, tablespace_name, status) a,
       (select tablespace_name, sum(bytes) / 1024 / 1024 total_mb
          from dba_data_files
         where tablespace_name like '%UNDO%'
         group by tablespace_name) b,
       (select tablespace_name, sum(bytes) / 1024 / 1024 use_mb
          from dba_undo_extents
         group by tablespace_name) c
 where a.tablespace_name = b.tablespace_name
   and a.tablespace_name = c.tablespace_name
 order by 1, 4;
set head off


select '$host title_check_16 TEMP_USAGE_LIST($host)' from dual;
set head on
set lines 400 pages 400
col name for a15
SELECT d.tablespace_name "Name",                                                                                     
TO_CHAR(NVL(a.bytes / 1024 / 1024, 0), '99,999,990.900') "Size (M)",                                                 
TO_CHAR(NVL(t.hwm, 0) / 1024 / 1024, '99999999.999') "HWM (M)",                                                      
TO_CHAR(NVL(t.hwm / a.bytes * 100, 0), '990.00') "HWM %",                                                            
TO_CHAR(NVL(t.bytes / 1024 / 1024, 0), '99999999.999') "Using (M)",                                                  
TO_CHAR(NVL(t.bytes / a.bytes * 100, 0), '990.00') "Using %"                                                         
FROM sys.dba_tablespaces d,                                                                                          
(select tablespace_name, sum(bytes) bytes                                                                            
from dba_temp_files                                                                                                  
group by tablespace_name) a,                                                                                         
(select tablespace_name, sum(bytes_cached) hwm, sum(bytes_used) bytes                                                
from v\$temp_extent_pool                                                                                              
group by tablespace_name) t                                                                                          
WHERE d.tablespace_name = a.tablespace_name(+)                                                                       
AND d.tablespace_name = t.tablespace_name(+)                                                                         
AND d.extent_management like 'LOCAL'                                                                                 
AND d.contents like 'TEMPORARY';                                         
set head off





select '$host title_check_17 session_number ($host)' from dual;
set head on
select count(1) from v\$session;
set head off

select '$host title_check_18  wait event($host)' from dual;
set head on
col inst_id format 9
col count(*) format 9999
col event form a38
col wait_class form a14
select inst_id,event,count(*),wait_class from gv\$session where wait_class<>'Idle' group by inst_id,event,wait_class order by inst_id,3 desc;
set head off
exit

EOF

echo
echo "----------end daily check($host)------------="







