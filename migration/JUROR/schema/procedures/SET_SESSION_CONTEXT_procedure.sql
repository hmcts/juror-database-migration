-- Generated by Ora2Pg, the Oracle database Schema converter, version 24.0
-- Copyright 2000-2023 Gilles DAROLD. All rights reserved.
-- DATASOURCE: dbi:Oracle:host=172.17.0.5;sid=xe;port=1521

SET client_encoding TO 'UTF8';

SET search_path = JUROR,public;
\set ON_ERROR_STOP ON





CREATE OR REPLACE PROCEDURE JUROR.SET_SESSION_CONTEXT (p_LocCode text, p_clear_context text default 'N') AS $body$
DECLARE



 l_context_id varchar(3);
/******************************************************************************
   NAME:       SET_SESSION_CONTEXT
   PURPOSE:    To set context for the oracle session.

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        17/08/2005      Jeeva Konar   1. Created this procedure.
   1.1        15/09/2005	Jeeva Konar		2. Consolidated JUROR_SET_CONTEXT procedure into this procedure.
   1.2	  	  04/10/2005	Jeeva Konar		3. Changed the datatype of variable to varchar2
   1.3	  	  14/10/2005	Jeeva Konar		4. Introduced setting of client identifier to that of context value
   			  					  			   This is done to help support staff to identify what was context was set for the session.
											   This value can be found in V$SESSION under  column CLIENT_IDENTIFIER.
   1.4        18/11/2005    Jeeva Konar		5. Introduced code to unsetting context


   PARAMETERS:
   INPUT:
   OUTPUT:
   RETURNED VALUE:
   CALLED BY:
   CALLS:
   EXAMPLE USE:     SET_SESSION_CONTEXT;
   ASSUMPTIONS:
   LIMITATIONS:
   ALGORITHM:
   NOTES:

******************************************************************************/
BEGIN

 IF p_clear_context = 'Y' THEN
   SET LOCAL JUROR_APP.OWNER = '';
 ELSE
   SELECT context_id
   INTO STRICT	  l_context_id
   FROM	  context_data
   WHERE  loc_code = p_LocCode;
   
  -- using set_config as it only lasts until the end of the transactin (whether committed or not) (https://www.postgresql.org/docs/current/sql-set.html)
  SELECT set_config('JUROR_APP.OWNER', l_context_id, true); 
 END IF;

EXCEPTION
     WHEN no_data_found THEN
       RAISE EXCEPTION '%', 'Invalid Location Code. Session Context not set'  USING ERRCODE = '45001';
     when others then
     	   raise;

END;
$body$
LANGUAGE PLPGSQL
SECURITY DEFINER
;
-- REVOKE ALL ON PROCEDURE JUROR.SET_SESSION_CONTEXT (p_LocCode text, p_clear_context text default 'N') FROM PUBLIC;
