-- Generated by Ora2Pg, the Oracle database Schema converter, version 24.0
-- Copyright 2000-2023 Gilles DAROLD. All rights reserved.
-- DATASOURCE: dbi:Oracle:host=172.17.0.5;sid=xe;port=1521

SET client_encoding TO 'UTF8';

SET search_path = JUROR,public;
\set ON_ERROR_STOP ON

DROP TRIGGER IF EXISTS PHOENIX_DOB_ZIP ON POOL CASCADE;
CREATE OR REPLACE FUNCTION trigger_fct_phoenix_dob_zip() RETURNS trigger AS $BODY$
declare
  l_check_on        varchar(1);
BEGIN
  BEGIN
  select coalesce(PNC_CHECK_ON,'N')
  into STRICT   l_check_on
  from   JUROR.COURT_LOCATION
  where  COURT_LOCATION.LOC_CODE = NEW.LOC_CODE;
  if (l_check_on = 'Y' or l_check_on = 'y') then
  BEGIN
    if (coalesce(NEW.POLICE_CHECK,'^') != 'E' and coalesce(NEW.POLICE_CHECK, '^') != 'P') then
    BEGIN
        NEW.PHOENIX_DATE := date_trunc('day', statement_timestamp());
    end;
    end if;
  end;
  end if;
exception
  when OTHERS then
      RAISE EXCEPTION '%', 'Trigger: phoenix_dob_zip '||SQLERRM||'('||SQLSTATE||')' USING ERRCODE = '45902';
  END;
  RETURN NEW;
end
$BODY$
 LANGUAGE 'plpgsql' SECURITY DEFINER;
-- REVOKE ALL ON FUNCTION trigger_fct_phoenix_dob_zip() FROM PUBLIC;

CREATE TRIGGER PHOENIX_DOB_ZIP
  before update of DOB, ZIP ON POOL for each row
    
	WHEN ((OLD.DOB is null or OLD.ZIP is null) and NEW.DOB is not null and NEW.ZIP is not null and (OLD.STATUS=2 and NEW.STATUS=2))
	EXECUTE PROCEDURE trigger_fct_phoenix_dob_zip();
