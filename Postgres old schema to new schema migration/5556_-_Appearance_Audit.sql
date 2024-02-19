/*
 * Task: 5556 - Develop migration script(s) to migrate the AUDIT_REPORT table to the new appearance_audit table
 *
 *				report_type
 *				-----------
 *				1 = Pay Attendance (i.e. initial expenses due)
 *				2 = Edit Payment (i.e. new amounts after the edit - includes edits before any payments approved as well as edits after a payment has been approved)
 *				3 = Aramis Payment (i.e. amounts approved for BACS/Cheque payment)
 *				4 = Cash Payment (i.e. amounts approved for Cash payment)
 *				5 = Aramis Repayment (i.e. amounts approved for BACS/Cheque payment after edits to a  previously made payment)
 *
 */

ALTER TABLE juror_mod.appearance_audit
	DROP CONSTRAINT IF EXISTS fk_revision_number;
ALTER TABLE juror_mod.appearance_audit
	DROP CONSTRAINT IF EXISTS fk_f_audit;

TRUNCATE TABLE juror_mod.appearance_audit;  -- DO NOT RESET THE REVISION SEEDING AS OTHER TABLES USE REV_INFO!

/*
 * migrate audit_report
 */
WITH rows
AS
(
	INSERT INTO juror_mod.appearance_audit(revision,rev_type,attendance_date,juror_number,loc_code,time_in,time_out,trial_number,non_attendance,no_show,mileage_due,mileage_paid,misc_description,pay_cash,last_updated_by,created_by,public_transport_total_due,public_transport_total_paid,hired_vehicle_total_due,hired_vehicle_total_paid,motorcycle_total_due,motorcycle_total_paid,car_total_due,car_total_paid,pedal_cycle_total_due,pedal_cycle_total_paid,childcare_total_due,childcare_total_paid,parking_total_due,parking_total_paid,misc_total_due,misc_total_paid,smart_card_due,smart_card_paid,travel_time,payment_approved_date,expense_submitted_date,f_audit,sat_on_jury,pool_number,appearance_stage,loss_of_earnings_due,loss_of_earnings_paid,subsistence_due,subsistence_paid,attendance_type,is_draft_expense)
	SELECT DISTINCT
		 	NEXTVAL('public.rev_info_seq') as revision,
			CASE 
				WHEN afr.report_type = '1'
					THEN 0 -- first insert
					ELSE 1 -- update
			END as rev_type,
			ar.att_date as attendance_date,
			ar.part_no as juror_number,
			a.loc_code,  -- this is nullable in the source table so use parent row from appearance
			ar.timein as time_in,
			ar.timeout as time_out,
			CASE 
				WHEN EXISTS(SELECT 1 FROM juror.trial t WHERE t.trail_no = a.pool_trial_no)
					THEN a.pool_trial_no
					ELSE NULL
			END AS trial_number,
			CASE UPPER(ar.non_attendance)
				WHEN 'Y'
					THEN true
					ELSE false
			END AS non_attendance,
			false AS no_show,
			CASE 
				WHEN afr.report_type IN ('1','2')
					THEN ar.mileage
					ELSE NULL
			END AS mileage_due,
			CASE
				WHEN afr.report_type IN ('3','4','5')
					THEN ar.mileage
					ELSE NULL
			END AS mileage_paid,
			ar.misc_description,
			CASE UPPER(ar.pay_cash)
				WHEN 'Y'
					THEN true
					ELSE false
			END AS pay_cash,
			ar.user_id as last_updated_by,
			ar.user_id as created_by,
			CASE 
				WHEN afr.report_type IN ('1','2')
					THEN ar.public_trans
					ELSE NULL
			END AS public_transport_total_due,
			CASE
				WHEN afr.report_type IN ('3','4','5')
					THEN ar.public_trans
					ELSE NULL
			END AS public_transport_total_paid,
			CASE
				WHEN afr.report_type IN ('1','2')
					THEN ar.hired_vehicle_total
					ELSE NULL
			END AS hired_vehicle_total_due,
			CASE
				WHEN afr.report_type IN ('3','4','5')
					THEN ar.hired_vehicle_total
					ELSE NULL
			END AS hired_vehicle_total_paid,
			CASE
				WHEN afr.report_type IN ('1','2')
					THEN ar.mcycles_total
					ELSE NULL
			END AS motorcycle_total_due,
			CASE
				WHEN afr.report_type IN ('3','4','5')
					THEN ar.mcycles_total
					ELSE NULL
			END AS motorcycle_total_paid,
			CASE
				WHEN afr.report_type IN ('1','2')
					THEN ar.mcars_total
					ELSE NULL
			END AS car_total_due,
			CASE
				WHEN afr.report_type IN ('3','4','5')
					THEN ar.mcars_total
					ELSE NULL
			END AS car_total_paid,
			CASE
				WHEN afr.report_type IN ('1','2')
					THEN ar.pcycles_total
					ELSE NULL
			END AS pedal_cycle_total_due,
			CASE
				WHEN afr.report_type IN ('3','4','5')
					THEN ar.pcycles_total
					ELSE NULL
			END AS pedal_cycle_total_paid,
			CASE
				WHEN afr.report_type IN ('1','2')
					THEN ar.child_care
					ELSE NULL
			END AS childcare_total_due,
			CASE
				WHEN afr.report_type IN ('3','4','5')
					THEN ar.child_care
					ELSE NULL
			END AS childcare_total_paid,
			CASE
				WHEN afr.report_type IN ('1','2')
					THEN ar.public_parking_total
					ELSE NULL
			END AS parking_total_due,
			CASE
				WHEN afr.report_type IN ('3','4','5')
					THEN ar.public_parking_total
					ELSE NULL
			END AS parking_total_paid,
			CASE
				WHEN afr.report_type IN ('1','2')
					THEN ar.misc_amount
					ELSE NULL
			END AS misc_total_due,
			CASE
				WHEN afr.report_type IN ('3','4','5')
					THEN ar.misc_amount
					ELSE NULL
			END AS misc_total_paid,
			CASE
				WHEN afr.report_type IN ('1','2')
					THEN ar.amt_spent
					ELSE NULL
			END AS smart_card_due,
			CASE
				WHEN afr.report_type IN ('3','4','5')
					THEN ar.amt_spent
					ELSE NULL
			END AS smart_card_paid,
			ar.travel_time,
			ar.date_aramis_created as payment_approved_date,
			ar.exp_subs_date as expense_submitted_date,
			RIGHT(afr.faudit,LENGTH(afr.faudit)-1)::BIGINT AS f_audit, -- Remove the leading F character to leave just the digits
			CASE 
				WHEN ar.court_emp = 'J'
					THEN true
					ELSE false
			END AS sat_on_jury,
			CASE 
				WHEN LENGTH(ar.pool_trial) = 9 AND EXISTS(SELECT 1 FROM juror.unique_pool up WHERE up.pool_no = ar.pool_trial)
					THEN ar.pool_trial
					ELSE NULL
			END AS pool_number,
			CASE ar.app_stage
				WHEN 1
					THEN 'CHECKED_IN' 
				WHEN 2
					THEN 'CHECKED_OUT' 
				WHEN 4
					THEN 'APPEARANCE_CONFIRMED' 
				WHEN 8
					THEN 'APPEARANCE_CONFIRMED' 
				WHEN 9
					THEN 'EXPENSE_ENTERED' 
				WHEN 10
					THEN 'EXPENSE_AUTHORISED' 
				WHEN 11
					THEN 'EXPENSE_EDITED'
					ELSE NULL
			END AS appearance_stage,
			CASE
				WHEN afr.report_type IN ('1','2')
					THEN COALESCE(ar.los_lfour_total,ar.los_mfour_total,ar.loss_mten_total,ar.loss_oten_h_total)
					ELSE NULL
			END AS loss_of_earnings_due,
			CASE
				WHEN afr.report_type IN ('3','4','5')
					THEN COALESCE(ar.los_lfour_total,ar.los_mfour_total,ar.loss_mten_total,ar.loss_oten_h_total)
					ELSE NULL
			END AS loss_of_earnings_paid,
			CASE
				WHEN afr.report_type IN ('1','2')
					THEN COALESCE(ar.subs_lfive_total,ar.subs_mfive_total,ar.loss_oten_total,ar.loss_overnight_total)
					ELSE NULL
			END AS subsistence_due,
			CASE
				WHEN afr.report_type IN ('3','4','5')
					THEN COALESCE(ar.subs_lfive_total,ar.subs_mfive_total,ar.loss_oten_total,ar.loss_overnight_total)
					ELSE NULL
			END AS subsistence_paid,
			CASE 
				WHEN COALESCE(ar.los_mfour_total, ar.subs_mfive_total, ar.loss_overnight_total, 0) > 0
					THEN 'FULL_DAY'
				WHEN COALESCE(ar.los_lfour_total, ar.subs_lfive_total, 0) > 0
					THEN 'HALF_DAY'
				WHEN COALESCE(ar.loss_mten_total, 0) > 0
					THEN 'FULL_DAY_LONG_TRIAL'
				WHEN COALESCE(ar.loss_oten_h_total, 0) > 0
					THEN 'HALF_DAY_LONG_TRIAL'
				WHEN UPPER(ar.non_attendance) = 'Y'
					THEN 'NON_ATTENDANCE'
					ELSE NULL
			END AS attendance_type,
			false as is_draft_expense
	FROM juror.audit_f_report afr
	JOIN juror.audit_report ar
	ON afr.part_no = ar.part_no
	AND afr.owner = ar.owner
	AND afr.line_no = ar.line_no
	AND afr.faudit = ar.audits
	JOIN juror_mod.appearance a -- link to the new table to identify the loc_code *** CHECK THIS LOGIC ***
	ON ar.part_no = a.juror_number
	AND ar.att_date = a.attendance_date

	RETURNING 1
)
SELECT COUNT(*) FROM rows;

/* 
 * verify results
 */
select count(*) from juror.audit_f_report;
select max(revision) FROM juror_mod.appearance_audit;
select last_value from rev_info_seq;
select * from juror_mod.appearance_audit a order by revision desc limit 10;

/*
 * FTA LETTERS - for each no show record insert a basic entry into appearance
 */
WITH rows
AS
(
	INSERT INTO juror_mod.appearance_audit(revision,rev_type,attendance_date,juror_number,loc_code,no_show,pool_number,created_by)
	SELECT DISTINCT
		 	NEXTVAL('public.rev_info_seq') as revision,
			0 as rev_type,	-- -- first insert
			fl.date_fta as attendance_date,
			fl.part_no as juror_number,
			LEFT(jp.pool_number,3) as loc_code,  -- this is nullable in the source table so use parent row from appearance
			true AS no_show,
			jp.pool_number,
			'SYSTEM' as created_by
	FROM juror.fta_lett fl 
	JOIN juror_mod.juror_pool jp 
	ON fl.part_no = jp.juror_number
	AND fl.owner = jp.owner
	WHERE fl.date_fta IS NOT NULL
	AND jp.is_active = true
	AND NOT EXISTS(SELECT 1 FROM juror_mod.appearance_audit aa WHERE aa.juror_number = fl.part_no AND aa.attendance_date = fl.date_fta and aa.loc_code = LEFT(jp.pool_number,3))
			
	RETURNING 1
)
SELECT COUNT(*) FROM rows;

ALTER TABLE juror_mod.appearance_audit
	ADD CONSTRAINT fk_revision_number FOREIGN KEY (revision) REFERENCES juror_mod.rev_info(revision_number) NOT VALID;
ALTER TABLE juror_mod.appearance_audit 
	ADD CONSTRAINT fk_f_audit FOREIGN KEY (f_audit) REFERENCES juror_mod.financial_audit_details(id) NOT VALID;

/* 
 * verify results
 */
select count(*) from juror.fta_lett fl WHERE fl.date_fta IS NOT null;
select max(revision) FROM juror_mod.appearance_audit;
select last_value from rev_info_seq;
select * from juror_mod.appearance_audit a order by revision desc limit 10;