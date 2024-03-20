CREATE OR REPLACE PROCEDURE juror_mod.housekeeping_process(p_max_timeout INTEGER DEFAULT 600, p_owner_restrict BOOLEAN DEFAULT false)
LANGUAGE plpgsql
AS
/***********************************************************************************************************************
*  Author  : Andrew Fraser
*  Created : 12 Feb 2024
*  Purpose : Housekeeping for Juror parent and child records, including pool related data
* 
* 	step 1	- Identify all aged jurors from the juror history - taken the last updated rows as the date to compare with.
* 			  If the parameter p_owner_restrict is set to true then the logic will check for only courts where they are 
* 			  flagged as restricted.
* 	step 2	- Loop through a juror record at a time
* 	step 3	- Perform deletes on child reocrds first and then the parent record
* 	step 4	- log event
* 
* 	N.B. p_max_timeout is used as a time limit check, if the max time is reached then exit the process - this stops the 
* 		 process overrunning and impacting BAU.
* 
*   Change History:
*
*   Ver  Date     Author     Description
*   ---  ----     ------     -----------
*
***********************************************************************************************************************/

$$
DECLARE
   	temprow RECORD;
  	v_print_msg TEXT;
    v_start_time TIMESTAMP := CURRENT_TIMESTAMP;
   	v_start_time_int INTEGER;
    v_rows_deleted INTEGER := 0;
    v_rows_in_error INTEGER := 0;
   	v_row_limit INTEGER;
    v_audit_threshold INTEGER;
    v_text_var1 TEXT;
   	v_text_var2 TEXT;
   	v_text_var3 TEXT;

BEGIN
	-- store start time (as an integer) in order to compare to timeout expiry date whilst looping through deletes
	v_start_time_int := EXTRACT(EPOCH FROM v_start_time)/60;

	v_row_limit :=  (
						SELECT hp.value::INTEGER
						FROM juror_mod.hk_params hp 
						WHERE hp."key" = 3	-- Maximum Pool deletions allowed/check for juror
					);
	
    FOR temprow IN 
       /*
		* create a loop and, for each juror number, delete the assocated rows
		*/
		SELECT  jh.juror_number,
				jp."owner" -- store the owner for identifying the trial retention threshold
		FROM 
			(
				SELECT  jh.juror_number,
						max(jh.date_created) as date_created
				FROM juror_mod.juror_history jh
				GROUP BY jh.juror_number 
			) jh
		JOIN
			(
					SELECT 	jp.juror_number,
							jp.owner
					FROM juror_mod.juror_pool jp -- link to identify the owner associated 
					JOIN hk.hk_owner_restrict hor
				 	ON jp.owner::INTEGER = hor.id
					WHERE (p_owner_restrict = false OR hor.value = 'YES')
			) jp
		ON jh.juror_number = jp.juror_number
		WHERE jh.date_created < CURRENT_DATE - (SELECT hp.value::INTEGER FROM juror_mod.hk_params hp WHERE (hp.key = 1 and jp.owner != '400') OR (hp.key = 2 AND jp.owner = '400'))
		LIMIT v_row_limit
	
        LOOP
	        
	        CALL juror_mod.housekeeping_juror_deletion(temprow.juror_number,temprow.owner,v_start_time_int,p_max_timeout,v_print_msg);

	       	raise notice 'v_print_msg%',v_print_msg;
	       
	        -- log if the deletion was successful or not based on the return value of the call
	        IF (v_print_msg IS NULL) THEN
	   			CALL juror_mod.hk_insert_audit(temprow.juror_number, v_start_time, 'Deleted');
				v_rows_deleted := v_rows_deleted + 1;
			ELSIF POSITION('TIMED' IN v_print_msg) THEN
				EXIT;
			ELSE
		        CALL juror_mod.hk_insert_audit(temprow.juror_number, v_start_time, v_print_msg);
				v_rows_in_error := v_rows_in_error + 1;
		    END IF;
	
		    COMMIT;  -- COMMIT THE DELETES FOR THIS JUROR
	END LOOP;

	raise notice 'Start :%',v_start_time;
	raise notice 'rows_deleted :%',v_rows_deleted;
	raise notice 'rows_in_error :%',v_rows_in_error;

	-- write to log that the run has completed
	CALL juror_mod.hk_insert_log(v_start_time,v_rows_deleted,v_rows_in_error);

	-- identify the default threshold for the audit & log tables
	v_audit_threshold := (
							SELECT hp.value::INTEGER
							FROM juror_mod.hk_params hp 
							WHERE hp."key" = 4 -- audit threshold 
						 );
	
	-- remove any aged audit data (default is 10 years if not specified)
	IF EXISTS(SELECT 1 FROM juror_mod.hk_audit ha WHERE ha.deletion_date < CURRENT_DATE - COALESCE(v_audit_threshold,3652)) THEN
		CALL juror_mod.hk_delete_audit(v_audit_threshold);
	END IF;
	-- remove any aged log data (default is 10 years if not specified)
	IF EXISTS(SELECT 1 FROM juror_mod.hk_run_log hrl WHERE hrl.end_time < CURRENT_DATE - COALESCE(v_audit_threshold,3652)) THEN
		CALL juror_mod.hk_delete_log(v_audit_threshold);
	END IF;
END;
$$
