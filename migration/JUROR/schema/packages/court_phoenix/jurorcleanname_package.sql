-- Generated by Ora2Pg, the Oracle database Schema converter, version 24.0
-- Copyright 2000-2023 Gilles DAROLD. All rights reserved.
-- DATASOURCE: dbi:Oracle:host=172.17.0.5;sid=xe;port=1521

SET client_encoding TO 'UTF8';
SET search_path = JUROR,public;


/************************************************************************
 *	FUNCTION:	court_phoenix_jurorCleanName( name_in VARCHAR2 )
 *	Access  :	private
 *	Args In :	name_in (juror first name)
 *	Returns :	s_name (Varchar2)
 *
 *	Desc    :	This function 'cleans' the firstname to remove and convert unwanted characters or
 *            chars in the supplied firstname.
 *
 *            This function will :
 *            1) Replace all full stops and commas with a space and
 *            2) Remove anything within brackets () or []
 *            3) Convert NUll string to a empty string and
 *            4) Remove leading and trailing spaces...
 *
 *  History
 *
 *	Version Name		  Date		 Desc
 *	======= ========= ======== ====
 *	V1.0    Kal Sohal 20/11/06 Initial version
 *  V2.0    M Turton  21/03/11 Trac3897 Handle characters in () and []
 ************************************************************************/
CREATE OR REPLACE FUNCTION court_phoenix_jurorCleanName ( name_in text ) RETURNS varchar AS $body$
DECLARE


      s_name               varchar(20);
      n_pos1               bigint;
      n_pos2               bigint;


BEGIN
      -- Replace all full stops and commas with a space
      s_name := REPLACE( name_in, '.', ' ');
      s_name := REPLACE( s_name, ',', ' ');

      -- Remove anything within '(' or ')'
      n_pos1 := position('(' in s_name);
      n_pos2 := position(')' in s_name);

      IF (n_pos1 > 0 AND n_pos2 > 0) THEN
         s_name := Substr(s_name, 1, n_pos1 -1) || ' ' || Substr(s_name, n_pos2 + 1);
      END IF;

      -- Remove anything within '[' or ']'
      n_pos1 := position('[' in s_name);
      n_pos2 := position(']' in s_name);

      IF (n_pos1 > 0 AND n_pos2 > 0) THEN
         s_name := Substr(s_name, 1, n_pos1 -1) || ' ' || Substr(s_name, n_pos2 + 1);
      END IF;

   return trim(both s_name);

   EXCEPTION
      WHEN OTHERS THEN
         CALL court_phoenix_write_error( 'jurorCleanName ' );

   END;

$body$
LANGUAGE PLPGSQL
SECURITY DEFINER
;
-- REVOKE ALL ON FUNCTION court_phoenix_jurorCleanName ( name_in text ) FROM PUBLIC;