-- Generated by Ora2Pg, the Oracle database Schema converter, version 24.0
-- Copyright 2000-2023 Gilles DAROLD. All rights reserved.
-- DATASOURCE: dbi:Oracle:host=172.17.0.5;sid=xe;port=1521

SET client_encoding TO 'UTF8';
SET search_path = JUROR,public;




CREATE OR REPLACE PROCEDURE phoenixinterface_preventDups () AS $body$
BEGIN

PERFORM set_config('phoenixinterface_lc_job_type', 'phoenixinterface_PREVENTDUPS()', false);

   DELETE from phoenix_temp
   WHERE rowid NOT in (
   SELECT MIN(rowid) FROM phoenix_temp
   GROUP by part_no);
COMMIT;
EXCEPTION
      WHEN OTHERS THEN
         CALL phoenixinterface_write_error( 'Error on deleting duplicates from phoenix_temp table');
	 ROLLBACK;
	 RAISE;

END;

$body$
LANGUAGE PLPGSQL
;
-- REVOKE ALL ON PROCEDURE phoenixinterface_preventDups () FROM PUBLIC;