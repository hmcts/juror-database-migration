-- Generated by Ora2Pg, the Oracle database Schema converter, version 24.0
-- Copyright 2000-2023 Gilles DAROLD. All rights reserved.
-- DATASOURCE: dbi:Oracle:host=172.17.0.5;sid=xe;port=1521

SET client_encoding TO 'UTF8';
SET search_path = JUROR,public;




CREATE OR REPLACE PROCEDURE reset_set_summoned_dates ( p_pool_no text, p_date timestamp(0) ) AS $body$
DECLARE


   -- Amend start date of pool
   -- Will only update if the pool only has jurors with status = 1 i.e. summoned
    l_count bigint;


BEGIN
    
    select count(1) into STRICT l_count
    from pool
    where pool_no = p_pool_no
    and status <> 1
    and summons_file is null; -- don't count disqualified on selection
    IF l_count = 0 THEN
      BEGIN

  	  -- what about the year and month in pool_no?
 
      update unique_pool
      set return_date = date_trunc('day', p_date), next_date = date_trunc('day', p_date)
      where pool_no = p_pool_no;

      update pool
      set ret_date = date_trunc('day', p_date), next_date = CASE WHEN next_date = NULL THEN null  ELSE date_trunc('day', p_date) END 
      where pool_no = p_pool_no;

      commit;

      END;
   END IF;

   EXCEPTION
     when others then
     rollback;
	   raise;

   END;

$body$
LANGUAGE PLPGSQL
;
-- REVOKE ALL ON PROCEDURE reset_set_summoned_dates ( p_pool_no text, p_date timestamp(0) ) FROM PUBLIC;