-- Generated by Ora2Pg, the Oracle database Schema converter, version 24.0
-- Copyright 2000-2023 Gilles DAROLD. All rights reserved.
-- DATASOURCE: dbi:Oracle:host=172.17.0.2;sid=xe;port=1521

SET client_encoding TO 'UTF8';
SET search_path = hk,public;

   
   -----------
   --
   -----------
   


CREATE OR REPLACE PROCEDURE hk.housekeeping_nocommit_parent_delete_unique_pool () AS $body$
DECLARE


     ora2pg_rowcount int;
l_pool_comments integer;
     l_pool_stats    integer;
     l_pool_hist     integer;
     l_start         timestamp(0);


   
BEGIN
 
     PERFORM set_config('housekeeping_nocommit.l_error_stage', 'POOL_COMMENTS', false);
     l_start := clock_timestamp();

     DELETE FROM pool_comments  pc
     WHERE  EXISTS (SELECT null
                    FROM    unique_pool up
                    WHERE   pc.owner = up.owner
                    AND     pc.pool_no = up.pool_no
                    AND     return_date + CASE WHEN owner=400 THEN current_setting('housekeeping_nocommit.l_param_bureau_threshold')::integer  ELSE current_setting('housekeeping_nocommit.l_param_court_threshold')::integer END  < clock_timestamp()
                    AND NOT EXISTS (SELECT null
                                    FROM   pool p
                                    WHERE  p.pool_no = up.pool_no
                                    AND    p.owner = up.owner
                                    )
                    );
                    
     GET DIAGNOSTICS ora2pg_rowcount = ROW_COUNT;

                    
     utl_file.put_line(l_file,'POOL_COMMENTS,'|| ora2pg_rowcount||','||TO_CHAR(l_start,'DD-MM-YYYY hh24:MI:SS')||','||TO_CHAR(clock_timestamp(),'DD-MM-YYYY hh24:MI:SS') ,TRUE);

     PERFORM set_config('housekeeping_nocommit.l_error_stage', 'POOL_STATS', false);
     l_start := clock_timestamp();


     DELETE FROM pool_stats  pc
     WHERE  EXISTS (SELECT null
                    FROM    unique_pool up
                    WHERE   pc.owner = up.owner
                    AND     pc.pool_no = up.pool_no
                    AND     return_date +  CASE WHEN owner=400 THEN current_setting('housekeeping_nocommit.l_param_bureau_threshold')::integer  ELSE current_setting('housekeeping_nocommit.l_param_court_threshold')::integer END  < clock_timestamp()
                    AND NOT EXISTS (SELECT null
                                    FROM   pool p
                                    WHERE  p.pool_no = up.pool_no
                                    AND    p.owner = up.owner
                                    )
                    );

     GET DIAGNOSTICS ora2pg_rowcount = ROW_COUNT;


     utl_file.put_line(l_file,'POOL_STATS,'|| ora2pg_rowcount||','||TO_CHAR(l_start,'DD-MM-YYYY hh24:MI:SS')||','||TO_CHAR(clock_timestamp(),'DD-MM-YYYY hh24:MI:SS') ,TRUE);

     PERFORM set_config('housekeeping_nocommit.l_error_stage', 'POOL_HIST', false);
     l_start := clock_timestamp();


     DELETE FROM pool_hist  pc
     WHERE  EXISTS (SELECT null
                    FROM    unique_pool up
                    WHERE   pc.owner = up.owner
                    AND     pc.pool_no = up.pool_no
                    AND     return_date + CASE WHEN owner=400 THEN current_setting('housekeeping_nocommit.l_param_bureau_threshold')::integer  ELSE current_setting('housekeeping_nocommit.l_param_court_threshold')::integer END  < clock_timestamp()
                    AND NOT EXISTS (SELECT null
                                    FROM   pool p
                                    WHERE  p.pool_no = up.pool_no
                                    AND    p.owner = up.owner
                                    )
                    );

    GET DIAGNOSTICS ora2pg_rowcount = ROW_COUNT;


    utl_file.put_line(l_file,'POOL_HIST,'|| ora2pg_rowcount||','||TO_CHAR(l_start,'DD-MM-YYYY hh24:MI:SS')||','||TO_CHAR(clock_timestamp(),'DD-MM-YYYY hh24:MI:SS' ),TRUE);
    PERFORM set_config('housekeeping_nocommit.l_error_stage', 'UNIQUE_POOL', false);
    l_start := clock_timestamp();

     DELETE FROM unique_pool up
     WHERE  return_date + CASE WHEN owner=400 THEN current_setting('housekeeping_nocommit.l_param_bureau_threshold')::integer  ELSE current_setting('housekeeping_nocommit.l_param_court_threshold')::integer END  < clock_timestamp()
     AND    NOT EXISTS (SELECT null
                        FROM   pool p
                        WHERE  p.pool_no = up.pool_no
                        AND    p.owner = up.owner
                        );

     GET DIAGNOSTICS ora2pg_rowcount = ROW_COUNT;


     utl_file.put_line(l_file,'UNIQUE_POOL,'|| ora2pg_rowcount||','||TO_CHAR(l_start,'DD-MM-YYYY hh24:MI:SS')||','||TO_CHAR(clock_timestamp(),'DD-MM-YYYY hh24:MI:SS' ),TRUE);

      IF p_read_only_mode THEN
        ROLLBACK;
      ELSE
        NULL;
        -- COMMIT;  **testing
      END IF;


    EXCEPTION 

     WHEN others THEN
     
       ROLLBACK;

       PERFORM set_config('housekeeping_nocommit.l_err_msg', SUBSTR(sqlerrm,1,200), false);
       RAISE EXCEPTION 'e_delete_error' USING ERRCODE = '50001';
 
   END;

$body$
LANGUAGE PLPGSQL
;
-- REVOKE ALL ON PROCEDURE hk.housekeeping_nocommit_parent_delete_unique_pool () FROM PUBLIC;