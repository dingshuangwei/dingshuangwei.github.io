--������ع�
��ѯ�ع���Ҫ��ʱ��
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
�ع������У��ع��Ľ��ȿ���ͨ����ͼV$FAST_START_TRANSACTIONS��ȷ��

SQL> select usn, state, undoblocksdone, undoblockstotal, CPUTIME, pid,xid, rcvservers from v$fast_start_transactions;

       USN STATE            UNDOBLOCKSDONE UNDOBLOCKSTOTAL    CPUTIME        PID XID              RCVSERVERS
---------- ---------------- -------------- --------------- ---------- ---------- ---------------- ----------
       454 RECOVERED                110143          110143        210            01C600210027E0D9          1
       468 RECOVERED                   430             430         17            01D40000001F3A36        128
       
USN�������Ӧ��undo��
STATE�������״̬����ѡ��ֵΪ��BE RECOVERED, RECOVERED, or RECOVERING��       
UNDOBLOCKSDONE���������Ѿ���ɵ�undo��
UNDOBLOCKSTOTAL���ܵ���Ҫrecovery��undo���ݿ�
CPUTIME���Ѿ��ع���ʱ�䣬��λ����
RCVSERVERS���ع��Ĳ��н�����


ͨ�����²�ѯ�����ҵ������ݿ����Ƿ���ڵ�һ������--�ع�����
select distinct KTUXECFL,count(*) from x$ktuxe group by KTUXECFL;


���
show parameter parallel_rollback
��߲��лع����̵�����������ΪHIGHʱ�ع�����=4*cpu������sql������ģʽ��ִ�ж�̬�޸� 
ALTER SYSTEM SET FAST_START_PARALLEL_ROLLBACK = HIGH; 

oracle�ӿ�ع��ٶ�
�ع����ٶȿ���ͨ������fast_start_parallel_rollback��ʵ�֣��˲������Զ�̬����
����fast_start_parallel_rollback�����˻ع������Ĳ��д������ڷ�æ��ϵͳ����IO���ܽϲ��ϵͳ��������ִ����ع�������������Ӱ��ϵͳϵͳ������ͨ�������˲���������Ӱ�졣
FAST_START_PARALLEL_ROLLBACK specifies the degree of parallelism used when recovering terminated transactions. Terminated transactions are transactions that are active before a system failure. If a system fails when there are uncommitted parallel DML or DDL transactions, then you can speed up transaction recovery during startup by using this parameter.  
Values:  
    FALSE ��  Parallel rollback is disabled  
    LOW   ��  Limits the maximum degree of parallelism to 2 * CPU_COUNT  
    HIGH  ��  Limits the maximum degree of parallelism to 4 * CPU_COUNT   
If you change the value of this parameter, then transaction recovery will be stopped and restarted with the new implied degree of parallelism.  

���ع�������Ϊ�˼���undo��Ӱ�죬fast_start_parallel_rollback�ָ�Ϊfalse��
alter system set fast_start_parallel_rollback= FALSE; 
	