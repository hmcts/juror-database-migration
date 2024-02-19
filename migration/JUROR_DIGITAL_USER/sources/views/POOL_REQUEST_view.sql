-- Generated by Ora2Pg, the Oracle database Schema converter, version 24.0
-- Copyright 2000-2023 Gilles DAROLD. All rights reserved.
-- DATASOURCE: dbi:Oracle:host=172.17.0.3;sid=xe;port=1521

SET client_encoding TO 'UTF8';

SET search_path = juror_digital_user,public;
\set ON_ERROR_STOP ON

CREATE OR REPLACE VIEW pool_request (owner, pool_no, attend_time, last_update, loc_code, new_request, next_date, return_date, pool_type, no_requested, pool_total, deferrals_used, reg_spc, read_only, additional_summons) AS SELECT
	u.OWNER,
	u.POOL_NO,
	u.ATTEND_TIME,
	u.LAST_UPDATE,
	u.LOC_CODE,
	u.NEW_REQUEST,
	u.NEXT_DATE,
	u.RETURN_DATE,
	u.POOL_TYPE,
	u.NO_REQUESTED,
	u.POOL_TOTAL,
	u.DEFERRALS_USED,
	u.REG_SPC,
	u.READ_ONLY,
	u.ADDITIONAL_SUMMONS
FROM
	JUROR.UNIQUE_POOL u;
