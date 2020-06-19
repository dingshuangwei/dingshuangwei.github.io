--大事务回滚
查询回滚需要的时间
select undoblockstotal "Total",
       undoblocksdone "Done",
       undoblockstotal - undoblocksdone "ToDo",
       decode(cputime,
              0,
              'unknown',
              to_char(sysdate + (((undoblockstotal - undoblocksdone) /
                      (undoblocksdone / cputime)) / 86400),
                      'yyyy-mm-dd hh24:mi:ss')) "Estimated time to complete",to_char(sysdate, 'yyyy-mm-dd hh24:mi:ss')
  from v$fast_start_transactions;

--
回滚过程中，回滚的进度可以通过视图V$FAST_START_TRANSACTIONS来确定

SQL> select usn, state, undoblocksdone, undoblockstotal, CPUTIME, pid,xid, rcvservers from v$fast_start_transactions;

       USN STATE            UNDOBLOCKSDONE UNDOBLOCKSTOTAL    CPUTIME        PID XID              RCVSERVERS
---------- ---------------- -------------- --------------- ---------- ---------- ---------------- ----------
       454 RECOVERED                110143          110143        210            01C600210027E0D9          1
       468 RECOVERED                   430             430         17            01D40000001F3A36        128
       
USN：事务对应的undo段
STATE：事务的状态，可选的值为（BE RECOVERED, RECOVERED, or RECOVERING）       
UNDOBLOCKSDONE：事物中已经完成的undo块
UNDOBLOCKSTOTAL：总的需要recovery的undo数据块
CPUTIME：已经回滚的时间，单位是秒
RCVSERVERS：回滚的并行进程数


通过如下查询立刻找到了数据库中是否存在的一死事务：--回滚超慢
select distinct KTUXECFL,count(*) from x$ktuxe group by KTUXECFL;


检查
show parameter parallel_rollback
提高并行回滚进程的数量，设置为HIGH时回滚进程=4*cpu数。在sql命令行模式下执行动态修改 
ALTER SYSTEM SET FAST_START_PARALLEL_ROLLBACK = HIGH; 

oracle加快回滚速度
回滚的速度快慢通过参数fast_start_parallel_rollback来实现，此参数可以动态调整
参数fast_start_parallel_rollback决定了回滚启动的并行次数，在繁忙的系统或者IO性能较差的系统，如果出现大量回滚操作，会显著影响系统系统，可以通过调整此参数来降低影响。
FAST_START_PARALLEL_ROLLBACK specifies the degree of parallelism used when recovering terminated transactions. Terminated transactions are transactions that are active before a system failure. If a system fails when there are uncommitted parallel DML or DDL transactions, then you can speed up transaction recovery during startup by using this parameter.  
Values:  
    FALSE ：  Parallel rollback is disabled  
    LOW   ：  Limits the maximum degree of parallelism to 2 * CPU_COUNT  
    HIGH  ：  Limits the maximum degree of parallelism to 4 * CPU_COUNT   
If you change the value of this parameter, then transaction recovery will be stopped and restarted with the new implied degree of parallelism.  

待回滚结束，为了减少undo的影响，fast_start_parallel_rollback恢复为false，
alter system set fast_start_parallel_rollback= FALSE; 
	