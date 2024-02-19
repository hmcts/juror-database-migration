-- Generated by Ora2Pg, the Oracle database Schema converter, version 24.0
-- Copyright 2000-2023 Gilles DAROLD. All rights reserved.
-- DATASOURCE: dbi:Oracle:host=172.17.0.2;sid=xe;port=1521

SET client_encoding TO 'UTF8';
SET search_path = hk,public;

 
   -----------
   --
   -----------
CREATE OR REPLACE PROCEDURE hk.housekeeping_initate_log () AS $body$
DECLARE


      -- Opens up log file and writes header into
  
      l_filename varchar(50);

    
BEGIN
 
      l_filename := 'HK_run_'||TO_CHAR(clock_timestamp(),'dd-mon-yyyy_hh24:mi');

      l_file := utl_file.fopen('HK_LOG_DIR',l_filename,'w');

      utl_file.put_line(l_file,'HK Run started on '||TO_CHAR(clock_timestamp(),'dd-mon-yyyy hh24:mi:ss'),TRUE);


    EXCEPTION 
      WHEN OTHERS THEN
    
        RAISE e_log_error;

    END;

$body$
LANGUAGE PLPGSQL
SECURITY DEFINER
;
-- REVOKE ALL ON PROCEDURE hk.housekeeping_initate_log () FROM PUBLIC;