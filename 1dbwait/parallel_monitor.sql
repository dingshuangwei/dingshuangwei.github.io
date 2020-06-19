col username for a12
col "QC SID" for A6
col "SID" for A6
col "QC/Slave" for A8
col "Req. DOP" for 9999
col "Actual DOP" for 9999
col "Slaveset" for A8
col "Slave INST" for A9
col "QC INST" for A6
set pages 300 lines 300
col wait_event format a30
SELECT DECODE(PX.QCINST_ID,
              NULL,
              USERNAME,
              ' - ' ||
              LOWER(SUBSTR(PP.SERVER_NAME, LENGTH(PP.SERVER_NAME) - 4, 4))) "Username",
       DECODE(PX.QCINST_ID, NULL, 'QC', '(Slave)') "QC/Slave",
       TO_CHAR(PX.SERVER_SET) "SlaveSet",
       TO_CHAR(S.SID) "SID",
       TO_CHAR(PX.INST_ID) "Slave INST",
       DECODE(SW.STATE, 'WAITING', 'WAIT', 'NOT WAIT') AS STATE,
       CASE SW.STATE
         WHEN 'WAITING' THEN
          SUBSTR(SW.EVENT, 1, 30)
         ELSE
          NULL
       END AS WAIT_EVENT,
       DECODE(PX.QCINST_ID, NULL, TO_CHAR(S.SID), PX.QCSID) "QC SID",
       TO_CHAR(PX.QCINST_ID) "QC INST",
       PX.REQ_DEGREE "Req. DOP",
       PX.DEGREE "Actual DOP"
  FROM GV$PX_SESSION PX, GV$SESSION S, GV$PX_PROCESS PP, GV$SESSION_WAIT SW
 WHERE PX.SID = S.SID(+)
   AND PX.SERIAL# = S.SERIAL#(+)
   AND PX.INST_ID = S.INST_ID(+)
   AND PX.SID = PP.SID(+)
   AND PX.SERIAL# = PP.SERIAL#(+)
   AND SW.SID = S.SID
   AND SW.INST_ID = S.INST_ID
 ORDER BY DECODE(PX.QCINST_ID, NULL, PX.INST_ID, PX.QCINST_ID),
          PX.QCSID,
          DECODE(PX.SERVER_GROUP, NULL, 0, PX.SERVER_GROUP),
          PX.SERVER_SET,
          PX.INST_ID;
          
          
          

from : Oracle数据库并行使用规范