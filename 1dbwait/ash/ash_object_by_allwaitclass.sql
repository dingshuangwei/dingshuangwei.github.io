-- File Name : ash_object_by_allwaitclass.sql
-- Purpose :根据WAITCLASS值，按EVENT,SQL_ID,CURRENT_OBJ排序，显示TOP 2的信息
-- 支持 10g,11g,12c
-- Date : 2019/10/22
-- dingshuangwei
-- 2018.01.11 初始版本，主要用于ash_total.sql结果运行后，使用ash_object_by_allwaitclass.sql来定位更详细的信息

set echo off
set lines 200 pages 1000 heading on verify off
col time           for a17
col event          for a40
col erow           for 999999999   heading 'EVENT|ROWS'
col erowpercent    for 9999        heading 'EVENT%'
col sql_id         for a18
col sqlrow         for 99999999    heading 'EVENT|SQLID|ROWS'
col sqlrowpercent  for 99999       heading 'SQLID%'
col sqlobjrow      for 99999999    heading 'EVENT|SQLID|OBJECT|ROWS'
col sqlobjrowpercent     for 9999  heading 'OBJECT%'
ACCEPT begin_hours prompt 'Enter Search Hours Ago (i.e. 2(default)) : '  default '2'
ACCEPT interval_hours prompt 'Enter How Interval Hours  (i.e. 2(default)) : ' default '2'
ACCEPT display_time prompt 'Enter How Display Interval Minute  (i.e. 10(default)) : ' default '10'
variable begin_hours number;
variable interval_hours number;
variable time number;
begin
   :begin_hours:=&begin_hours;
   :interval_hours:=&interval_hours;
   :time:=&display_time;
   end;
   /
break on time on event on erow on erowpercent on sql_id on sqlrow on sqlrowpercent on object_id on sqlobjrow

/* Formatted on 2018/1/11 0:01:47 (QP5 v5.300) */
  SELECT time,
         event,
         erow,
--         erowpercent,
         sql_id,
         sqlrow,
--         sqlrowpercent,
         object_id,
         sqlobjrow
--       ,sqlobjrowpercent --,  erowtop,sqlrowtop, sqlobjrowtop
    FROM (SELECT time,
                 event,
                 erow,
                 erowpercent,
                 sql_id,
                 sqlrow,
                 sqlrowpercent,
                 current_obj# object_id,
                 sqlobjrow,
                 sqlobjrowpercent,
                 dense_rank ()
                     OVER (PARTITION BY time ORDER BY erow desc)
                     erowtop,
                 dense_rank ()
                 OVER (PARTITION BY time, event ORDER BY sqlrow  desc)
                     sqlrowtop,
                 dense_rank ()
                     OVER (PARTITION BY time,
                                        event,
                                        sql_id
                           ORDER BY sqlobjrow desc)
                     sqlobjrowtop
            FROM (SELECT DISTINCT
                         time,
                         sql_id,
                         event,
                         SUM (cnt) OVER (PARTITION BY time, event) erow,
                           ROUND (
                                 SUM (cnt) OVER (PARTITION BY time, event)
                               / DECODE (SUM (cnt) OVER (PARTITION BY time),
                                         '0', '1',
                                         NULL, 1,
                                         SUM (cnt) OVER (PARTITION BY time)),
                               2)
                         * 100
                             erowpercent,
                         CURRENT_OBJ#,
                         SUM (cnt) OVER (PARTITION BY time, event, sql_id)
                             sqlrow,
                           ROUND (
                                 SUM (cnt)
                                     OVER (PARTITION BY time, event, sql_id)
                               / DECODE (
                                     SUM (cnt) OVER (PARTITION BY time, event),
                                     '0', '1',
                                     NULL, 1,
                                     SUM (cnt) OVER (PARTITION BY time, event)),
                               2)
                         * 100
                             sqlrowpercent,
                         SUM (cnt)
                             OVER (PARTITION BY time,
                                                event,
                                                sql_id,
                                                current_obj#)
                             sqlobjrow,
                           ROUND (
                                 SUM (cnt)
                                     OVER (PARTITION BY time,
                                                        event,
                                                        sql_id,
                                                        current_obj#)
                               / DECODE (
                                     SUM (cnt)
                                     OVER (PARTITION BY time, event, sql_id),
                                     '0', '1',
                                     NULL, 1,
                                     SUM (cnt)
                                     OVER (PARTITION BY time, event, sql_id)),
                               2)
                         * 100
                             sqlobjrowpercent
                    FROM (SELECT    TO_CHAR (DATE_HH, 'yyyymmdd hh24')
                                 || ' '
                                 || 10 * (DATE_MI)
                                 || '-'
                                 || 10 * (DATE_MI + 1)
                                     time,
                                 sql_id,
                                 event,
                                 current_obj#,
                                 wait_class,
                                 cnt
                            FROM (SELECT TRUNC (SAMPLE_TIME, 'HH') DATE_HH,
                                         TRUNC (
                                             TO_CHAR (SAMPLE_TIME, 'MI') / 10)
                                             DATE_MI,
                                         sql_id,
                                         event,
                                         CURRENT_OBJ#,
                                         WAIT_CLASS,
                                         1                       cnt
                                    FROM GV$ACTIVE_SESSION_HISTORY
                                   WHERE     SAMPLE_TIME >=
                                                 SYSDATE - :begin_hours / 24
                                         AND SAMPLE_TIME <=
                                                   SYSDATE
                                                 -   (  :begin_hours
                                                      - :interval_hours)
                                                   / 24
                                  UNION ALL
                                  SELECT TRUNC (SAMPLE_TIME, 'HH') DATE_HH,
                                         TRUNC (
                                             TO_CHAR (SAMPLE_TIME, 'MI') / 10)
                                             DATE_MI,
                                         sql_id,
                                         event,
                                         CURRENT_OBJ#,
                                         WAIT_CLASS,
                                         10                      cnt
                                    FROM DBA_HIST_ACTIVE_SESS_HISTORY
                                   WHERE     SAMPLE_TIME >=
                                                 SYSDATE - :begin_hours / 24
                                         AND SAMPLE_TIME <=
                                                   SYSDATE
                                                 -   (  :begin_hours
                                                      - :interval_hours)
                                                   / 24))) b)
   WHERE erowtop < 3 AND sqlrowtop < 3 AND sqlobjrowtop < 3
ORDER BY time,
         erow,
         sqlrow,
         sqlobjrow
/