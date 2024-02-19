-- Generated by Ora2Pg, the Oracle database Schema converter, version 24.0
-- Copyright 2000-2023 Gilles DAROLD. All rights reserved.
-- DATASOURCE: dbi:Oracle:host=172.17.0.5;sid=xe;port=1521

SET client_encoding TO 'UTF8';

SET search_path = JUROR,public;
\set ON_ERROR_STOP ON

DROP TRIGGER IF EXISTS PRINT_FILES_PART_NO ON PRINT_FILES CASCADE;
CREATE OR REPLACE FUNCTION trigger_fct_print_files_part_no() RETURNS trigger AS $BODY$
BEGIN
   IF NEW.PART_NO = ' ' OR NEW.PART_NO IS NULL THEN
      NEW.PART_NO := CASE
          WHEN NEW.FORM_TYPE = '5221' THEN SUBSTR(NEW.DETAIL_REC,280,9)
          WHEN NEW.FORM_TYPE = '5221C' THEN SUBSTR(NEW.DETAIL_REC,280,9)
          WHEN NEW.FORM_TYPE = '5224' THEN SUBSTR(NEW.DETAIL_REC,632,9)
          WHEN NEW.FORM_TYPE = '5224A' THEN SUBSTR(NEW.DETAIL_REC,675,9)
          WHEN NEW.FORM_TYPE = '5224AC' THEN SUBSTR(NEW.DETAIL_REC,656,9)
          WHEN NEW.FORM_TYPE = '5224C' THEN SUBSTR(NEW.DETAIL_REC,613,9)
          WHEN NEW.FORM_TYPE = '5225' THEN SUBSTR(NEW.DETAIL_REC,632,9)
          WHEN NEW.FORM_TYPE = '5225C' THEN SUBSTR(NEW.DETAIL_REC,613,9)
          WHEN NEW.FORM_TYPE = '5226' THEN SUBSTR(NEW.DETAIL_REC,852,9)
          WHEN NEW.FORM_TYPE = '5226A' THEN SUBSTR(NEW.DETAIL_REC,852,9)
          WHEN NEW.FORM_TYPE = '5226AC' THEN SUBSTR(NEW.DETAIL_REC,833,9)
          WHEN NEW.FORM_TYPE = '5226C' THEN SUBSTR(NEW.DETAIL_REC,833,9)
          WHEN NEW.FORM_TYPE = '5227' THEN SUBSTR(NEW.DETAIL_REC,842,9)
          WHEN NEW.FORM_TYPE = '5227C' THEN SUBSTR(NEW.DETAIL_REC,823,9)
          WHEN NEW.FORM_TYPE = '5228' THEN SUBSTR(NEW.DETAIL_REC,632,9)
          WHEN NEW.FORM_TYPE = '5228C' THEN SUBSTR(NEW.DETAIL_REC,653,9)
          WHEN NEW.FORM_TYPE = '5229' THEN SUBSTR(NEW.DETAIL_REC,632,9)
          WHEN NEW.FORM_TYPE = '5229A' THEN SUBSTR(NEW.DETAIL_REC,672,9)
          WHEN NEW.FORM_TYPE = '5229AC' THEN SUBSTR(NEW.DETAIL_REC,653,9)
          WHEN NEW.FORM_TYPE = '5229C' THEN SUBSTR(NEW.DETAIL_REC,613,9)
          END;
   END IF;
RETURN NEW;
END
$BODY$
 LANGUAGE 'plpgsql' SECURITY DEFINER;
-- REVOKE ALL ON FUNCTION trigger_fct_print_files_part_no() FROM PUBLIC;

CREATE TRIGGER PRINT_FILES_PART_NO
	BEFORE INSERT 
   ON PRINT_FILES 
   FOR EACH ROW
	EXECUTE PROCEDURE trigger_fct_print_files_part_no();
