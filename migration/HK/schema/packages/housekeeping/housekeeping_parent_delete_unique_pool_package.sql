-- Generated by Ora2Pg, the Oracle database Schema converter, version 24.0
-- Copyright 2000-2023 Gilles DAROLD. All rights reserved.
-- DATASOURCE: dbi:Oracle:host=172.17.0.2;sid=xe;port=1521

SET client_encoding TO 'UTF8';
SET search_path = hk,public;

   
   -----------
   --
   -----------
   


CREATE OR REPLACE PROCEDURE hk.housekeeping_parent_delete_unique_pool () AS $body$
DECLARE


     l_start         timestamp(0);
     l_start_stats   timestamp(0);
     l_start_comments timestamp(0);
     l_start_hist       timestamp(0);
     l_deleted          bigint;
     l_deleted_comments bigint;
     l_deleted_stats    bigint;
     l_deleted_hist     bigint;
     l_end_comments    timestamp(0);
     l_end_stats       timestamp(0);
     l_end_hist       timestamp(0);


   
BEGIN
 
     PERFORM set_config('housekeeping.l_error_stage', 'POOL_COMMENTS', false);

     l_start_comments := clock_timestamp();

     SELECT COUNT(*) INTO STRICT current_setting('housekeeping.l_pool_comments')::logs('PRE') FROM pool_comments;

     DELETE FROM pool_comments  pc
     WHERE  EXISTS (SELECT null
                    FROM    unique_pool up
                    WHERE   pc.owner = up.owner
                    AND     pc.pool_no = up.pool_no
                    AND     return_date + CASE WHEN owner=400 THEN current_setting('housekeeping.l_param_bureau_threshold')::integer  ELSE current_setting('housekeeping.l_param_court_threshold')::integer END  < clock_timestamp()
                    AND NOT EXISTS (SELECT null
                                    FROM   pool p
                                    WHERE  p.pool_no = up.pool_no
                                    AND    p.owner = up.owner
                                    )
                    );
     GET DIAGNOSTICS l_deleted_comments = ROW_COUNT;
     l_end_comments := clock_timestamp();

 
     PERFORM set_config('housekeeping.l_error_stage', 'POOL_STATS', false);
     l_start_stats := clock_timestamp();

     SELECT COUNT(*) INTO STRICT current_setting('housekeeping.l_pool_stats')::logs('PRE') FROM pool_stats;

     DELETE FROM pool_stats  pc
     WHERE  EXISTS (SELECT null
                    FROM    unique_pool up
                    WHERE   pc.owner = up.owner
                    AND     pc.pool_no = up.pool_no
                    AND     return_date +  CASE WHEN owner=400 THEN current_setting('housekeeping.l_param_bureau_threshold')::integer  ELSE current_setting('housekeeping.l_param_court_threshold')::integer END  < clock_timestamp()
                    AND NOT EXISTS (SELECT null
                                    FROM   pool p
                                    WHERE  p.pool_no = up.pool_no
                                    AND    p.owner = up.owner
                                    )
                    );
     GET DIAGNOSTICS l_deleted_stats = ROW_COUNT;
     l_end_stats := clock_timestamp();

 
     PERFORM set_config('housekeeping.l_error_stage', 'POOL_HIST', false);
     l_start_hist := clock_timestamp();

     SELECT COUNT(*) INTO STRICT current_setting('housekeeping.l_pool_hist')::logs('PRE') FROM pool_hist;

     DELETE FROM pool_hist  pc
     WHERE  EXISTS (SELECT null
                    FROM    unique_pool up
                    WHERE   pc.owner = up.owner
                    AND     pc.pool_no = up.pool_no
                    AND     return_date + CASE WHEN owner=400 THEN current_setting('housekeeping.l_param_bureau_threshold')::integer  ELSE current_setting('housekeeping.l_param_court_threshold')::integer END  < clock_timestamp()
                    AND NOT EXISTS (SELECT null
                                    FROM   pool p
                                    WHERE  p.pool_no = up.pool_no
                                    AND    p.owner = up.owner
                                    )
                    );

     GET DIAGNOSTICS l_deleted_hist = ROW_COUNT;
     l_end_hist   := clock_timestamp();
                   
      PERFORM set_config('housekeeping.l_error_stage', 'UNIQUE_POOL', false);
     l_start := clock_timestamp();

     SELECT COUNT(*) INTO STRICT current_setting('housekeeping.l_unique_pool')::logs('PRE')   FROM unique_pool;

     DELETE FROM unique_pool up
     WHERE  return_date + CASE WHEN owner=400 THEN current_setting('housekeeping.l_param_bureau_threshold')::integer  ELSE current_setting('housekeeping.l_param_court_threshold')::integer END  < clock_timestamp()
     AND    NOT EXISTS (SELECT null
                        FROM   pool p
                        WHERE  p.pool_no = up.pool_no
                        AND    p.owner = up.owner
                         );
     GET DIAGNOSTICS l_deleted = ROW_COUNT;
 
      IF p_read_only_mode THEN
        ROLLBACK;
      ELSE
        COMMIT;
      END IF;

     SELECT COUNT(*) INTO STRICT current_setting('housekeeping.l_unique_pool')::logs('POST')   FROM unique_pool;
     SELECT COUNT(*) INTO STRICT current_setting('housekeeping.l_pool_comments')::logs('POST') FROM pool_comments;
     SELECT COUNT(*) INTO STRICT current_setting('housekeeping.l_pool_stats')::logs('POST')    FROM pool_stats;
     SELECT COUNT(*) INTO STRICT current_setting('housekeeping.l_pool_hist')::logs('POST')     FROM pool_hist;

     utl_file.put_line(l_file,'POOL_COMMENTS,'||l_deleted_comments||','||TO_CHAR(l_start_comments,'DD-MM-YYYY hh24:MI:SS')||','||TO_CHAR(l_end_comments,'DD-MM-YYYY hh24:MI:SS')||','||current_setting('housekeeping.l_pool_comments')::logs('PRE')||','||current_setting('housekeeping.l_pool_comments')::logs('POST')||','||current_setting('housekeeping.l_pool_comments')::logs('PRE')-current_setting('housekeeping.l_pool_comments')::logs('POST')::varchar ,TRUE);
     utl_file.put_line(l_file,'POOL_STATS,'||l_deleted_stats||','||TO_CHAR(l_start_stats,'DD-MM-YYYY hh24:MI:SS')||','||TO_CHAR(l_end_stats,'DD-MM-YYYY hh24:MI:SS')||','||current_setting('housekeeping.l_pool_stats')::logs('PRE')||','||current_setting('housekeeping.l_pool_stats')::logs('POST')||','||current_setting('housekeeping.l_pool_stats')::logs('PRE')-current_setting('housekeeping.l_pool_stats')::logs('POST')::varchar ,TRUE);
     utl_file.put_line(l_file,'POOL_HIST,'||l_deleted_hist||','||TO_CHAR(l_start_hist,'DD-MM-YYYY hh24:MI:SS')||','||TO_CHAR(l_end_hist,'DD-MM-YYYY hh24:MI:SS')||','||current_setting('housekeeping.l_pool_hist')::logs('PRE')||','||current_setting('housekeeping.l_pool_hist')::logs('POST')||','||current_setting('housekeeping.l_pool_hist')::logs('PRE')-current_setting('housekeeping.l_pool_hist')::logs('POST')::varchar,TRUE);
     utl_file.put_line(l_file,'UNIQUE_POOL,'||l_deleted||','||TO_CHAR(l_start,'DD-MM-YYYY hh24:MI:SS')||','||TO_CHAR(clock_timestamp(),'DD-MM-YYYY hh24:MI:SS')||','||current_setting('housekeeping.l_unique_pool')::logs('PRE')||','||current_setting('housekeeping.l_unique_pool')::logs('POST')||','||current_setting('housekeeping.l_unique_pool')::logs('PRE')-current_setting('housekeeping.l_unique_pool')::logs('POST')::varchar,TRUE);

   
    EXCEPTION 

     WHEN others THEN
     
       ROLLBACK;

       PERFORM set_config('housekeeping.l_err_msg', SUBSTR(sqlerrm,1,200), false);
       RAISE EXCEPTION 'e_delete_error' USING ERRCODE = '50001';
 
   END;

$body$
LANGUAGE PLPGSQL
;
-- REVOKE ALL ON PROCEDURE hk.housekeeping_parent_delete_unique_pool () FROM PUBLIC;