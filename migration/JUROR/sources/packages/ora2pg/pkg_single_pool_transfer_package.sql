-- Generated by Ora2Pg, the Oracle database Schema converter, version 24.0
-- Copyright 2000-2023 Gilles DAROLD. All rights reserved.
-- DATASOURCE: dbi:Oracle:host=172.17.0.4;sid=xe;port=1521

SET client_encoding TO 'UTF8';

\set ON_ERROR_STOP ON

CREATE OR REPLACE PACKAGE PKG_SINGLE_POOL_TRANSFER AS

   PROCEDURE transfer_pool_details(p_pool_no varchar2);

END PKG_SINGLE_POOL_TRANSFER;



CREATE OR REPLACE PACKAGE BODY PKG_SINGLE_POOL_TRANSFER AS

ld_location_code varchar2(9);
g_job_status  boolean := true;

PROCEDURE write_error_message(p_job varchar2, p_Message varchar2);
PROCEDURE transfer_pool(p_pool_no varchar2);
PROCEDURE transfer_court_unique_pool(p_pool_no varchar2, p_location_code varchar2);

/***********************************************************************************************************/
/************************************************************************
*
*	Procedure:	pool_transfer.transfer_pool_details			 *
*
*	Access:		public													 *
*
*	Arguments:	p_pool_no varchar2(9) the number of the pool to be transferred													 *
*
*	Returns:	none													 *
*
*	Description:	When run at the SUPS Database, this program will  			 *
*			transfer pool, part_hist , phone log and pool request detail
*          data from the SUPS Bureau to SUPS Courts and		  					 *
*			insert or update the data accordingly					 *
*
*
*	Name		Date		Action										 *
*	====		====		======										 *
*	Joy         15/09/05	Created 									 *
*  Jeeva		01/12/05	Changed from writing Error Logs to OS file to  writing to ERROR_LOG table
************************************************************************/

PROCEDURE transfer_pool_details (p_pool_no varchar2) is

   ln_no_pool_recs number := 0;
   ln_no_unip_recs number := 0;
   ln_no_part_recs number := 0;
   ln_no_plog_recs number := 0;
   
   Begin

      dbms_output.ENABLE;     
      ld_location_code := SUBSTR(p_pool_no, 1, 3);
      dbms_output.put_line('Pool: ' || p_pool_no);     

      Begin
         -- Transfer the POOL records.
         transfer_pool(p_pool_no);
                
         -- Transfer the UNIQUE_POOL records.
         Transfer_court_unique_pool(p_pool_no, ld_location_code);

         -- This block for debug info only.
         select count(*) into ln_no_unip_recs from unique_pool;
         select count(*) into ln_no_pool_recs from pool where pool_no in (select pool_no from unique_pool where pool_no like (ld_location_code || '%')); 
         select count(*) into ln_no_plog_recs from phone_log;
         select count(*) into ln_no_part_recs from part_hist;
               
	       commit; -- commit the transaction for each court.
         --rollback;
         dbms_output.put_line('Rollback ' || p_pool_no);     
               
	       EXCEPTION
		      WHEN OTHERS THEN
			    write_error_message('POOL TRANSFER', 'LOC_CODE :'||p_pool_no||' : '||SQLERRM);
			    rollback;
			    g_job_status := false;
      End;

      IF NOT g_job_status THEN
			  raise_application_error(-20001, 'Error in Pool Transfer Procedure. Not all pools are transferred.');
			  raise_application_error(-20001, 'Check ERROR_LOG table for failed Locations.');
			END IF;

      EXCEPTION
		    WHEN OTHERS THEN
			  write_error_message('POOL TRANSFER', SQLERRM);
			  rollback;
			  raise;
        
	End  transfer_pool_details;
  
/************************************************************************
*
*	Procedure:	transfer_pool                   					 *
*
*	Access:		private													 *
*
*	Arguments:	location code											 *
*
*	Returns:	None 			                   					 *
*
*	Description:	This procedure transfers pool details, phone log, and part_hist details	*
*					from SUPS bureau to SUPS court              		 *
*									   		  	  						 *
*	Name		Date		Action										 *
*	====		====		======										 *
*	Joy       15/09/05		Created this procedure						 *
************************************************************************/
PROCEDURE transfer_pool(p_pool_no varchar2) is

ln_debug_no_rows number:=0;

-- Cursor for pool records
Cursor C2_pool_records(p_pool_no varchar2) is 
       SELECT p.rowid row_id, p.* 
       FROM pool p
       WHERE  p.status IN (1,2)
       AND p.owner='400' 
       and (p.read_only='N' or p.read_only is null) 
       and  p.pool_no = p_pool_no;

Begin

-- For debug only.
  select count(*) 
  into ln_debug_no_rows 
  FROM pool p
       WHERE  p.status IN (1,2)
       AND p.owner='400' 
       and (p.read_only='N' or p.read_only is null) 
       and  p.pool_no = p_pool_no;
           
           
For Pool_records in C2_pool_records(p_pool_no)
Loop
EXIT when C2_pool_records%NOTFOUND;

 INSERT INTO pool (owner,part_no,
						pool_no,
						poll_number,
						title,
						lname,
						fname,
						dob,
						address,
						address2,
						address3,
						address4,
                        address5,
                        address6,
                        zip,
                        h_phone,
                        w_phone,
                        w_ph_local,
                        times_sel,
                        trial_no,
                        juror_no,
                        reg_spc,
                        ret_date,
                        def_date,
                        responded,
                        date_excus,
                        exc_code,
                        acc_exc,
                        date_disq,
                        disq_code,
                        mileage,
                        location,
                        user_edtq,
                        status,
                        notes,
                        no_attendances,
                        is_active,
                        no_def_pos,
                        no_attended,
                        no_fta,
                        no_awol,
                        pool_seq,
                        edit_tag,
                        pool_type,
                        loc_code,
                        next_date,
                        on_call,
                        perm_disqual,
                        pay_county_emp,
                        pay_expenses,
                        spec_need,
                        spec_need_msg,
                        smart_card,
                        amt_spent,
                        completion_flag,
                        completion_date,
                        sort_code,
                        bank_acct_name,
                        bank_acct_no,
                        bldg_soc_roll_no,
                        was_deferred,
                        id_checked,
                        postpone,
                        welsh,
                        paid_cash,
                        travel_time,
                        scan_code,
                        financial_loss,
                        police_check,
                        last_update,
                        read_only,
                        summons_file,
                        reminder_sent,
                        phoenix_date,
                        phoenix_checked)
			VALUES      (ld_location_code,
                         pool_records.part_no,
                         pool_records.pool_no,
                         pool_records.poll_number,
                         pool_records.title,
                         pool_records.lname,
                         pool_records.fname,
                         pool_records.dob,
                         pool_records.address,
                         pool_records.address2,
                         pool_records.address3,
                         pool_records.address4,
                         pool_records.address5,
                         pool_records.address6,
                         pool_records.zip,
                         pool_records.h_phone,
                         pool_records.w_phone,
                         pool_records.w_ph_local,
                         pool_records.times_sel,
                         pool_records.trial_no,
                         pool_records.juror_no,
                         pool_records.reg_spc,
                         pool_records.ret_date,
                         pool_records.def_date,
                         pool_records.responded,
                         pool_records.date_excus,
                         pool_records.exc_code,
                         pool_records.acc_exc,
                         pool_records.date_disq,
                         pool_records.disq_code,
                         pool_records.mileage,
                         pool_records.location,
                         pool_records.user_edtq,
                         pool_records.status,
                         pool_records.notes,
                         pool_records.no_attendances,
                         pool_records.is_active,
                         pool_records.no_def_pos,
                         pool_records.no_attended,
                         pool_records.no_fta,
                         pool_records.no_awol,
                         pool_records.pool_seq,
                         pool_records.edit_tag,
                         pool_records.pool_type,
                         pool_records.loc_code,
                         pool_records.next_date,
                         pool_records.on_call,
                         pool_records.perm_disqual,
                         pool_records.pay_county_emp,
                         pool_records.pay_expenses,
                         pool_records.spec_need,
                         pool_records.spec_need_msg,
                         pool_records.smart_card,
                         pool_records.amt_spent,
                         pool_records.completion_flag,
                         pool_records.completion_date,
                         pool_records.sort_code,
                         pool_records.bank_acct_name,
                         pool_records.bank_acct_no,
                         pool_records.bldg_soc_roll_no,
                         pool_records.was_deferred,
                         pool_records.id_checked,
                         pool_records.postpone,
                         pool_records.welsh,
                         pool_records.paid_cash,
                         pool_records.travel_time,
                         pool_records.scan_code,
                         pool_records.financial_loss,
                         pool_records.police_check,
                         pool_records.last_update,
                         'N',
                         pool_records.summons_file,
                         pool_records.reminder_sent,
                         pool_records.phoenix_date,
                         pool_records.phoenix_checked);

	 -- Update the read_only flag in the bureau side
	 UPDATE pool SET read_only ='Y'
	 WHERE rowid = pool_records.row_id;

   -- Insert into the part_hist details
   INSERT INTO part_hist (Owner,part_no,date_part,history_code,user_id,other_information,pool_no)
   SELECT  ld_location_code, part_no,date_part,history_code,user_id,other_information,pool_no
   FROM	part_hist
   WHERE	owner = '400'
   AND		part_no = pool_records.part_no;

   -- Insert into the  phone_log table
   INSERT INTO phone_log (owner,part_no,start_call,user_id,end_call,phone_code,notes)
	 SELECT ld_location_code, part_no,start_call,user_id,end_call,phone_code,notes
	 FROM	phone_log
	 WHERE	owner = '400'
	 AND	part_no = pool_records.part_no;

 End Loop;

 Exception
		 WHEN OTHERS THEN
			 write_error_message('POOL TRANSFER','Error in TRANSFER_POOL Package. '||SUBSTR(SQLERRM, 1, 100));
			   rollback;
			   raise;

End transfer_pool;
/**************************************************************************************************/
/************************************************************************
*
*	Procedure:	transfer_court_unique_pool                   			 *
*
*	Access:		private													 *
*
*	Arguments:	location code											 *
*
*	Returns:	None 			                   					 *
*
*	Description:	This procedure transfers pool reuests created at bureau for the courts
* 					from SUPS bureau to SUPS court              		 *
*									   		  	  						 *
*
*	Name		Date		Action										 *
*	====		====		======										 *
*	Joy       21/09/05		Created this procedure						 *
************************************************************************/

Procedure transfer_court_unique_pool(p_pool_no varchar2, p_location_code  varchar2) is

ln_up_ins_records number:=0;
ln_up_found number:=0;
ln_debug_no_rows number:=0;
Cursor C5_unique_pool(p_pool_no varchar2) is
          SELECT  pool_no,
		   		  jurisdiction_code,
				  TRUNC(return_date) return_date,
				  next_date,
				  pool_total,
				  no_requested,
				  reg_spc,
				  pool_type,
				  loc_code,
				  new_request,
				  read_only
		   FROM	  unique_pool
		   WHERE owner = '400'
           AND read_only = 'N'
           AND pool_no = p_pool_no;

Begin

  -- For debug only.
  select count(*) 
  into ln_debug_no_rows 
  FROM	  unique_pool
		   WHERE owner = '400'
           AND read_only = 'N'
           AND pool_no = p_pool_no;

	 For unique_pool_recs in c5_unique_pool(p_pool_no)
	 Loop
	 EXIT when c5_unique_pool%NOTFOUND;

	 SELECT count(1)
	 INTO ln_up_found
	 FROM unique_pool
	 WHERE OWNER=p_location_code
	 AND  pool_no= unique_pool_recs.pool_no;

     IF ln_up_found = 0 THEN

 			INSERT INTO unique_pool(owner,
					   		  	   			   pool_no,
											   jurisdiction_code,
											   return_date,
											   next_date,
											   pool_total,
											   no_requested,
											   reg_spc,
											   pool_type,
											   loc_code,
											   new_request,
											   read_only)
					  				    VALUES ( p_location_code,
                        unique_pool_recs.pool_no,
											   unique_pool_recs.jurisdiction_code,
											   unique_pool_recs.return_date,
											   unique_pool_recs.next_date,
											   unique_pool_recs.pool_total,
											   unique_pool_recs.no_requested,
											   unique_pool_recs.reg_spc,
											   unique_pool_recs.pool_type,
											   unique_pool_recs.loc_code,
											   'N',
											   'N'
											   );
						ln_up_ins_records := ln_up_ins_records+ SQL%rowcount;


   Else
                   UPDATE unique_pool
				   SET	  jurisdiction_code  = unique_pool_recs.jurisdiction_code,
				   		  return_date 	   	 = unique_pool_recs.return_date,
						  next_date		   	 = unique_pool_recs.next_date,
						  pool_total	   	 = unique_pool_recs.pool_total,
						  no_requested	   	 = unique_pool_recs.no_requested,
						  reg_spc		   	 = unique_pool_recs.reg_spc,
						  pool_type		   	 = unique_pool_recs.pool_type,
						  loc_code		   	 = unique_pool_recs.loc_code,
						  new_request	   	 = 'N',
						  read_only		   	 = decode('OWNER','400','Y','N')
					WHERE pool_no = unique_pool_recs.pool_no;

   End If;

    	-- update unique_pool read_only flag in Bureau
			UPDATE unique_pool SET read_only ='Y'
			, new_request = 'N'
			WHERE pool_no = unique_pool_recs.pool_no
			AND owner ='400';

End loop;

Exception
	when others then
		write_error_message('POOL TRANSFER','Error in TRANSFER_COURT_UNIQUE_POOL Package. '||SUBSTR(SQLERRM, 1, 100));
		rollback;
		raise;
END transfer_court_unique_pool;

  PROCEDURE write_error_message(p_job varchar2, p_Message varchar2) is
   pragma autonomous_transaction;
  BEGIN
   INSERT INTO ERROR_LOG (job, error_info) values (p_job, p_Message );
	commit;
  END write_error_message;

END PKG_SINGLE_POOL_TRANSFER;
