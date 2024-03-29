-- Generated by Ora2Pg, the Oracle database Schema converter, version 24.0
-- Copyright 2000-2023 Gilles DAROLD. All rights reserved.
-- DATASOURCE: dbi:Oracle:host=172.17.0.5;sid=xe;port=1521

SET client_encoding TO 'UTF8';

SET search_path = JUROR,public;
\set ON_ERROR_STOP ON

DROP TRIGGER IF EXISTS TRG_SP_INSERTUPDATE ON SYSTEM_PARAMETER CASCADE;
CREATE OR REPLACE FUNCTION trigger_fct_trg_sp_insertupdate() RETURNS trigger AS $BODY$
BEGIN
  IF TG_OP = 'INSERT' THEN
    NEW.CREATED_BY := current_user;
    NEW.CREATED_DATE := statement_timestamp();
    NEW.UPDATED_BY := current_user;
    NEW.UPDATED_DATE := statement_timestamp();
  ELSIF TG_OP = 'UPDATE' THEN
    NEW.UPDATED_BY := current_user;
    NEW.UPDATED_DATE := statement_timestamp();
  END IF;
RETURN NEW;
END
$BODY$
 LANGUAGE 'plpgsql';
-- REVOKE ALL ON FUNCTION trigger_fct_trg_sp_insertupdate() FROM PUBLIC;

CREATE TRIGGER TRG_SP_INSERTUPDATE
	BEFORE INSERT OR UPDATE 
  ON SYSTEM_PARAMETER
  FOR EACH ROW
	EXECUTE PROCEDURE trigger_fct_trg_sp_insertupdate();

