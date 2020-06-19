set echo off
set lines 2000 pages 20000 verify off heading on 
col owner for a20
col name for a50 heading 'TABLE_NAME:PART_NAME:SUB_NAME'
col partition_name for a20
col subpartition_name for a20
col last_analyzed for a14
col interval_time for a26
col rowcnt for 99999999999
col blkcnt for 999999999
col avgrln for 9999999
col samplesize for 999999
col cachedblk for 9999999
col cachehit for 9999999
col logicalread for 999999999
undefine owner;
undefine table_name;
select *
  from (select u.name owner,
               o.name,
               to_char(h.savtime, 'yyyymmdd hh24:mi') last_analyzed,
               h.savtime - h.analyzetime interval_time,
               h.rowcnt,
               h.blkcnt,
               h.avgrln,
               h.samplesize,
               h.cachedblk,
               h.cachehit,
               h.logicalread
          from sys.user$ u, sys.obj$ o, sys.wri$_optstat_tab_history h
         where h.obj# = o.obj#
           and u.name = upper('&&owner')
           and o.type# = 2
           and o.owner# = u.user#
           and o.name = upper('&&table_name')
           and h.savtime <= systimestamp -- exclude pending statistics
        union all
        -- partitions
        select u.name,
               o.name||'.'||
               o.subname name,
               to_char(h.savtime, 'yyyymmdd hh24:mi') last_analyzed,
               h.savtime - h.analyzetime,
               h.rowcnt,
               h.blkcnt,
               h.avgrln,
               h.samplesize,
               h.cachedblk,
               h.cachehit,
               h.logicalread
          from sys.user$ u, sys.obj$ o, sys.wri$_optstat_tab_history h
         where h.obj# = o.obj#
           and u.name = upper('&&owner')
           and o.type# = 19
           and o.owner# = u.user#
           and o.name = upper('&&table_name')
           and h.savtime <= systimestamp -- exclude pending statistics
        union all
        -- sub partitions
        select u.name,
               osp.name||'.'||
               ocp.subname||'.'||
               osp.subname name,
               to_char(h.savtime, 'yyyymmdd hh24:mi') last_analyzed,
               h.savtime - h.analyzetime,
               h.rowcnt,
               h.blkcnt,
               h.avgrln,
               h.samplesize,
               h.cachedblk,
               h.cachehit,
               h.logicalread
          from sys.user$                    u,
               sys.obj$                     osp,
               obj$                         ocp,
               sys.tabsubpart$              tsp,
               sys.wri$_optstat_tab_history h
         where h.obj# = osp.obj#
           and osp.type# = 34
           and u.name = upper('&&owner')
           and osp.obj# = tsp.obj#
           and tsp.pobj# = ocp.obj#
           and osp.owner# = u.user#
           and ocp.name = upper('&&table_name')
           and h.savtime <= systimestamp)
 order by last_analyzed
;
undefine owner;
undefine table_name;