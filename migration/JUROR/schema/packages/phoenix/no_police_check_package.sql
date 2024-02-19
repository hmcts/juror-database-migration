-- Generated by Ora2Pg, the Oracle database Schema converter, version 24.0
-- Copyright 2000-2023 Gilles DAROLD. All rights reserved.
-- DATASOURCE: dbi:Oracle:host=172.17.0.5;sid=xe;port=1521

SET client_encoding TO 'UTF8';
SET search_path = JUROR,public;


/************************************************************************
 *									*
 *	Procedure:	phoenix_no_police_check()    			*
 *									*
 *	Access:		public						*
 *									*
 *	Arguments:	none						*
 *									*
 *	Returns:	none						*
 *									*
 *	Description:	This program will extract all POOL records      *
 *			that are ready for a police check but are       *
 *			missing either the dob or zip and will		*
 *			update PART_HIST to record this.		*
 *									*
 *	Name		Date		Action				*
 *	====		====		======				*
 *	C Davies	280601		Created				*
 *									*
 ************************************************************************/
CREATE OR REPLACE PROCEDURE phoenix_no_police_check () AS $body$
DECLARE
  l_check_on        varchar(1);
  lc_Job_Type text := 'phoenix_NO_POLICE_CHECK()';

  no_police_check CURSOR FOR
  SELECT part_no,
         pool_no,
         phoenix_date,
         phoenix_checked,
         lname,
         fname,
         zip,
	 dob,
	 loc_code,
	 police_check
  from   pool
  where (dob is null
  or     zip is null)
  and    status = 2
  and    police_check is null
  and    phoenix_date is not null
  and    phoenix_checked is null
  and    is_active = 'Y'
  and    owner = '400';

  

BEGIN

  
  for each_participant in no_police_check loop
	update pool
	set   police_check = 'I'
	where pool_no  = each_participant.pool_no
	and   part_no = each_participant.part_no
	and   is_active = 'Y'
        and   owner = '400';

	insert into part_hist(owner,
			part_no,
        		date_part,
			history_code,
			user_id,
			other_information,
			pool_no)
	values ('400',
			each_participant.part_no,
			clock_timestamp(),
			'POLI',
			'SYSTEM',
			'Insufficient Information',
			each_participant.pool_no);
  end loop;

EXCEPTION
   when others then
	 CALL phoenix_write_error(sqlerrm);
     rollback;
	 raise;

END;

$body$
LANGUAGE PLPGSQL
;
-- REVOKE ALL ON PROCEDURE phoenix_no_police_check () FROM PUBLIC;