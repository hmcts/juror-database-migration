-- Generated by Ora2Pg, the Oracle database Schema converter, version 24.0
-- Copyright 2000-2023 Gilles DAROLD. All rights reserved.
-- DATASOURCE: dbi:Oracle:host=172.17.0.3;sid=xe;port=1521

SET client_encoding TO 'UTF8';

SET search_path = juror_digital_user,public;
\set ON_ERROR_STOP ON

CREATE OR REPLACE VIEW system_parameter (sp_id, sp_desc, sp_value, created_by, created_date, updated_by, updated_date) AS SELECT
    sp.sp_id,
    sp.sp_desc,
    sp.sp_value,
    sp.created_by,
    sp.created_date,
    sp.updated_by,
    sp.updated_date
  FROM JUROR.SYSTEM_PARAMETER sp;
