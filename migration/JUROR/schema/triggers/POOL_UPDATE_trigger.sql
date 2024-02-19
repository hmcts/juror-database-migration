-- Generated by Ora2Pg, the Oracle database Schema converter, version 24.0
-- Copyright 2000-2023 Gilles DAROLD. All rights reserved.
-- DATASOURCE: dbi:Oracle:host=172.17.0.5;sid=xe;port=1521

SET client_encoding TO 'UTF8';

SET search_path = JUROR,public;
\set ON_ERROR_STOP ON

DROP TRIGGER IF EXISTS POOL_UPDATE ON POOL CASCADE;
CREATE OR REPLACE FUNCTION trigger_fct_pool_update() RETURNS trigger AS $BODY$
BEGIN
   If (NEW.READ_ONLY <> '*' and OLD.READ_ONLY <> '*') or NEW.READ_ONLY is null
      or NEW.READ_ONLY = 'N' Then
            NEW.LAST_UPDATE := statement_timestamp();
   End If;
   IF OLD.STATUS is null THEN
      IF NEW.STATUS = 6 and NEW.DISQ_CODE = 'A' and NEW.RESPONDED = 'N' THEN
         NEW.SUMMONS_FILE := 'Disq. on selection';
      END IF;
   END IF;
RETURN NEW;
END
$BODY$
 LANGUAGE 'plpgsql' SECURITY DEFINER;
-- REVOKE ALL ON FUNCTION trigger_fct_pool_update() FROM PUBLIC;

CREATE TRIGGER POOL_UPDATE
       BEFORE INSERT OR UPDATE 
       ON POOL
       FOR EACH ROW
	EXECUTE PROCEDURE trigger_fct_pool_update();
