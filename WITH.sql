WITH
    ext
    AS
    
    (
        SELECT
            a.*,
            SUBSTR(endtime,1,7) AS endmonth,
            SUBSTR(endtime,1,4) AS endyear,
            b.projectname,
            b.user_group_name,
            b.company,
            c.payername
        FROM ref_riutil.reservedinstance_status a
            LEFT JOIN (SELECT *
            FROM `ref_pair_of_payer_N_usage.*`) b ON a.reservedaccountid = b.usageaccountid
            LEFT JOIN (SELECT *
            FROM `ref_pair_of_payer_N_usage.*`) c ON a.payeraccountid = c.usageaccountid
        WHERE dt = 202011
            AND c.payername IN ('MEGAZONE', 'awscloud5')
    ),


    attach_hours
    AS
    (
        SELECT a.*, CAST(b.hours AS float64) AS hours
        FROM ext a LEFT JOIN(SELECT *
            FROM reference.month_hour) b ON CAST(a.dt AS STRING) = CONCAT(b.year,b.month)
    ),

    attach_ri_monthly_cost
    AS
    (
        SELECT *, original_reserved_effectiverate * hours AS ri_cost_month
        FROM attach_hours
    ),

    attach_price_odi
    AS
    (
        SELECT a.*, b.price_odi, b.price_odi * hours AS odi_cost_month
        FROM attach_ri_monthly_cost a LEFT JOIN (SELECT DISTINCT reservedinstancesid, price_odi
            FROM ref_riutil.attach_priceodi_n_mendatorycost) b ON a.reservedinstancesid = b.reservedinstancesid AND a.dt = b.dt
    ),

    attach_saving_cost
    AS
    (
        SELECT *, odi_cost_month - ri_cost_month AS saving_cost
        FROM attach_price_odi
    )

  