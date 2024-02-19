-- Generated by Ora2Pg, the Oracle database Schema converter, version 24.0
-- Copyright 2000-2023 Gilles DAROLD. All rights reserved.
-- DATASOURCE: dbi:Oracle:host=172.17.0.5;sid=xe;port=1521

SET client_encoding TO 'UTF8';
SET search_path = JUROR,public;




CREATE OR REPLACE PROCEDURE pkg_pwd_rules_password_rules (jurorusername text, jurorpassword text, old_jurorpassword text) AS $body$
DECLARE

   n boolean;
   m integer;
   isdigit boolean;
   islowchar  boolean;
   isupchar  boolean;
   ispunct boolean;
   digitarray varchar(10);
   punctarray varchar(25);
   lowchararray varchar(26);
   upchararray varchar(26);
BEGIN
   digitarray:= '0123456789';
   lowchararray:= 'abcdefghijklmnopqrstuvwxyz';
   upchararray:= 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
   punctarray:='!#$%^&()`*+,-/:;<=>?_?';

   -- Check if the password is same as the username
   IF NLS_LOWER(jurorpassword) = NLS_LOWER(jurorusername) THEN
     RAISE EXCEPTION '%', 'Password same as Login Name' USING ERRCODE = '45001';
   END IF;

   --Check for the minimum length of the password
   IF length(jurorpassword) < 8 THEN
      RAISE EXCEPTION '%', 'Password length less than 8' USING ERRCODE = '45002';
   END IF;

   -- Check if the password is too simple. A dictionary of words may be
   -- maintained and a check may be made so as not to allow the words
   -- that are too simple for the password.
--   IF NLS_LOWER(jurorpassword) IN ('welcome', 'database', 'account',  'user', 'password', 'oracle', 'computer', 'abcd')
--THEN
--      raise_application_error(-20002, 'Password too simple');
--   END IF;
   -- Check if the password contains at least one lower-case letter, one upper-case letter, one digit and one
   -- punctuation mark.
   -- 1. Check for the digit
   isdigit:=FALSE;
   m := length(jurorpassword);
   <<digitcheck>>
   FOR i IN 1..10 LOOP 
      FOR j IN 1..m LOOP
         IF substr(jurorpassword,j,1) = substr(digitarray,i,1) THEN
            isdigit:=TRUE;
            EXIT digitcheck;
         END IF;
      END LOOP;
   END LOOP;
   IF isdigit = FALSE THEN
      RAISE EXCEPTION '%', 'Password should contain at least one digit, one uppercase character, one lowercase character and one special character from ' || punctarray USING ERRCODE = '45003';
   END IF;
   -- 2. Check for the lower-case character
   islowchar:=FALSE;
   <<lowchar>>
   FOR i IN 1..length(lowchararray) LOOP
      FOR j IN 1..m LOOP
         IF substr(jurorpassword,j,1) = substr(lowchararray,i,1) THEN
            islowchar:=TRUE;
             EXIT lowchar;
         END IF;
      END LOOP;
   END LOOP;
   IF islowchar = FALSE THEN
      RAISE EXCEPTION '%', 'Password should contain at least one digit, one uppercase character, one lowercase character and one special character from ' || punctarray USING ERRCODE = '45003';
   END IF;
   -- 3. Check for the upper-case character
   isupchar:=FALSE;
   <<findupper>>
   FOR i IN 1..length(upchararray) LOOP
      FOR j IN 1..m LOOP
         IF substr(jurorpassword,j,1) = substr(upchararray,i,1) THEN
            isupchar:=TRUE;
             EXIT findupper;
         END IF;
      END LOOP;
   END LOOP;
   IF isupchar = FALSE THEN
      RAISE EXCEPTION '%', 'Password should contain at least one digit, one uppercase character, one lowercase character and one special character from ' || punctarray USING ERRCODE = '45003';
   END IF;
   -- 4. Check for the punctuation
   
   ispunct:=FALSE;
   <<findpunct>>
   FOR i IN 1..length(punctarray) LOOP
      FOR j IN 1..m LOOP
         IF substr(jurorpassword,j,1) = substr(punctarray,i,1) THEN
            ispunct:=TRUE;
            EXIT findpunct;
         END IF;
      END LOOP;
   END LOOP;
   IF ispunct = FALSE THEN
      RAISE EXCEPTION '%', 'Password should contain at least one digit, one uppercase character, one lowercase character and one special character from ' || punctarray USING ERRCODE = '45003';
   END IF;

END;

$body$
LANGUAGE PLPGSQL
SECURITY DEFINER
;
-- REVOKE ALL ON PROCEDURE pkg_pwd_rules_password_rules (jurorusername text, jurorpassword text, old_jurorpassword text) FROM PUBLIC;