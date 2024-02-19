-- Generated by Ora2Pg, the Oracle database Schema converter, version 24.0
-- Copyright 2000-2023 Gilles DAROLD. All rights reserved.
-- DATASOURCE: dbi:Oracle:host=172.17.0.5;sid=xe;port=1521

SET client_encoding TO 'UTF8';

SET search_path = "JUROR",public;
\set ON_ERROR_STOP ON

CREATE OR REPLACE PACKAGE payment_files_to_clob AS

	PROCEDURE extract;
END payment_files_to_clob;



CREATE OR REPLACE PACKAGE BODY payment_files_to_clob AS
ext_date		DATE := case when to_number(to_char(sysdate,'SSSSS')) < 64800
              			then sysdate - 1
               			else sysdate
              			end;


PROCEDURE write_to_clob(p_creation_date date, p_header varchar2, p_file_name varchar2);

	type t_creation_date	is table of aramis_payments.creation_date%type;
	type t_header    		is table of varchar2(100);
	type t_file_name    	is table of varchar2(100);

	tab_creation_date  	t_creation_date;
	tab_header			t_header;
	tab_file_name  		t_file_name;


/***********************************************************************
* PROCEDURE EXTRACT
***********************************************************************/

PROCEDURE extract IS
BEGIN

-- Check to remove duplicate payment to jurors
-- Update conf_file_ref to prevent payment from being included in the next payment file
Update aramis_payments a1
set con_file_ref = to_char(trunc(sysdate),'DDMONYYYY')||'DuplicateRemoved'
where
-- Restrict to payments yet to be extracted.
-- This also avoids updating a payment that has already had it's corresponding duplicate flagged
decode(con_file_ref,null,'N',null) ='N'
-- Restrict to duplicates identified by audit_report vs part_hist
and trunc(a1.creation_date)||substr(a1.part_invoice,1,9)||ltrim(to_char(a1.expense_total,'99999.00'))
in (select creation_date||part_no||total from (
select p.owner, p.part_no, substr(other_information,10,9) audit_no, substr(p.pool_no,2,length(p.pool_no)-1) total,
sum(a.total_amount),max(trunc(date_part)) creation_date
from audit_report a, part_hist p
where
a.date_aramis_created >= (select min(trunc(creation_date)) from aramis_payments where decode(con_file_ref,null,'N',null) = 'N')
and a.app_stage = 10
and a.owner=p.owner
and a.part_no=p.part_no
and a.audits=substr(p.other_information,10,9)
and p.history_code='AEDF'
and p.pool_no <>'#0'
and p.owner <> '400'
group by p.owner, p.part_no, substr(other_information,10,9),p.pool_no
having nvl(sum(a.total_amount),0) = 0))
-- select rows to update from aramis_payments i.e. exclude the first row of each set of duplicate rows
and unique_id <> (select min(a2.unique_id) from aramis_payments a2
where a2.owner=a1.owner and substr(part_invoice,1,9)=substr(a1.part_invoice,1,9)
and decode(a2.con_file_ref, null,'N',null) = 'N');

SELECT creation_date, to_char(creation_date,'FMDDMONTHYYYY') || lpad(aramis_count.nextval,9,0) || '.dat', 'HEADER' || '|' || lpad(aramis_count.currval,9,0) || '|' || lpad(to_char(total,'9999990.90'),11)
BULK COLLECT
  INTO   tab_creation_date, tab_file_name, tab_header
FROM ( SELECT trunc(CREATION_DATE) creation_date, sum(expense_total) total
  		FROM aramis_payments
		WHERE  trunc(creation_date) <= trunc(ext_date)
		 AND decode(con_file_ref ,NULL,'N',NULL) = 'N'
		GROUP BY trunc(creation_date));

 IF sql%RowCount > 0 THEN
	FOR x in tab_creation_date.first..tab_creation_date.last loop
		begin
			write_to_clob(tab_creation_date(x), tab_header(x), tab_file_name(x));
			UPDATE aramis_payments
    			SET con_file_ref = tab_file_name(x)
    			WHERE trunc(CREATION_DATE) = tab_creation_date(x);
		end;
	END LOOP;
 END IF;

commit;

EXCEPTION
	WHEN OTHERS THEN
	    rollback;
		raise;

END extract;

/***********************************************************************
* PROCEDURE write_to_clob
*
* 26/2/15 Strip out CRLF (end of line) and pipe characters.
*         Replacing with space to preserve fixed width columns
*
***********************************************************************/

PROCEDURE write_to_clob(p_creation_date date, p_header varchar2, p_file_name varchar2) IS
CURSOR c_extract is SELECT LOC_CODE,
			  UNIQUE_ID,
  			CREATION_DATE,
  			EXPENSE_TOTAL,
			  PART_INVOICE,
  			BANK_SORT_CODE,
  			replace(replace(replace(BANK_AC_NAME,'|',' '),chr(10),' '),chr(13),' ') BANK_AC_NAME,
  			replace(replace(replace(BANK_AC_NUMBER,'|',' '),chr(10),' '),chr(13),' ') BANK_AC_NUMBER,
  			replace(replace(replace(BUILD_SOC_NUMBER,'|',' '),chr(10),' '),chr(13),' ') BUILD_SOC_NUMBER,
  			replace(replace(replace(ADDRESS_LINE1,'|',' '),chr(10),' '),chr(13),' ') ADDRESS_LINE1,
  			replace(replace(replace(ADDRESS_LINE2,'|',' '),chr(10),' '),chr(13),' ') ADDRESS_LINE2,
  			replace(replace(replace(ADDRESS_LINE3,'|',' '),chr(10),' '),chr(13),' ') ADDRESS_LINE3,
  			replace(replace(replace(ADDRESS_LINE4,'|',' '),chr(10),' '),chr(13),' ') ADDRESS_LINE4,
  			replace(replace(replace(ADDRESS_LINE5,'|',' '),chr(10),' '),chr(13),' ') ADDRESS_LINE5,
  			replace(replace(replace(POSTCODE,'|',' '),chr(10),' '),chr(13),' ') POSTCODE,
  			ARAMIS_AUTH_CODE,
  			replace(replace(replace(NAME,'|',' '),chr(10),' '),chr(13),' ') NAME,
  			LOC_COST_CENTRE,
  			TRAVEL_TOTAL,
  			SUB_TOTAL,
			  FLOSS_TOTAL,
  			SUB_DATE
			FROM aramis_payments
			WHERE trunc(CREATION_DATE) = p_creation_date;

out_rec			VARCHAR2(450);
out_rec2		VARCHAR2(450);
out_rec3		VARCHAR2(450);

c_lob clob;

BEGIN

	-- Write header line into CLOB
      insert into content_store(request_id, document_id, file_type, data) values (content_store_seq.nextval,
	  		 	  										 	   		   p_File_Name,
																	   'PAYMENT' ,
																	   empty_clob() ) returning data into c_lob;
	  dbms_lob.write( c_lob,length(p_header||chr(10)), 1,p_header||chr(10));

	FOR i in c_extract LOOP
	  out_rec := i.loc_code || i.unique_id || '|' || to_char(i.creation_date,'DD-Mon-YYYY') || '|' || lpad(to_char(i.expense_total,'9999990.90'),11) || '|' || rpad(i.loc_code || i.part_invoice,50) || '|' || to_char(i.creation_date,'DD-Mon-YYYY') || '|' || i.bank_sort_code || '|' || rpad(i.bank_ac_name,18) || '|' || rpad(i.bank_ac_number,8) || '|' || rpad(i.build_soc_number,18);
    	  out_rec2 := '|' || rpad(i.address_line1,35) || '|' || rpad(i.address_line2,35) || '|' || rpad(i.address_line3,35) || '|' || rpad(i.address_line4,35);

	  IF i.travel_total IS NOT NULL THEN
	    out_rec3 := '|' || rpad(i.address_line5,35) || '|' || rpad(i.postcode,20) || '|' || i.aramis_auth_code || '|' || rpad(i.name,50) || '|' || i.loc_cost_centre || '|' || '2' || '|' || lpad(to_char(i.travel_total,'9999990.90'),11) || '|' || to_char(i.sub_date,'DD-Mon-YYYY');
		dbms_lob.writeappend( c_lob, length((out_rec||out_rec2||out_rec3)||chr(10)), (out_rec||out_rec2||out_rec3)||chr(10) );
      END IF;
      IF i.sub_total IS NOT NULL THEN
	    out_rec3 := '|' || rpad(i.address_line5,35) || '|' || rpad(i.postcode,20) || '|' || i.aramis_auth_code || '|' || rpad(i.name,50) || '|' || i.loc_cost_centre || '|' || '1' || '|' ||lpad(to_char(i.sub_total,'9999990.90'),11) || '|' || to_char(i.sub_date,'DD-Mon-YYYY');
    	dbms_lob.writeappend( c_lob, length((out_rec||out_rec2||out_rec3)||chr(10)), (out_rec||out_rec2||out_rec3)||chr(10) );
	  END IF;
      IF i.floss_total IS NOT NULL THEN
	    out_rec3 := '|' || rpad(i.address_line5,35) || '|' || rpad(i.postcode,20) || '|' || i.aramis_auth_code || '|' || rpad(i.name,50) || '|' || i.loc_cost_centre || '|' || '0' || '|' ||lpad(to_char(i.floss_total,'9999990.90'),11) || '|' || to_char(i.sub_date,'DD-Mon-YYYY');
    	dbms_lob.writeappend( c_lob, length((out_rec||out_rec2||out_rec3)||chr(10)), (out_rec||out_rec2||out_rec3)||chr(10) );
	  END IF;

	END LOOP;

	dbms_lob.writeappend( c_lob, length('****'||chr(10)), '****'||chr(10) );


END write_to_clob;

END payment_files_to_clob;