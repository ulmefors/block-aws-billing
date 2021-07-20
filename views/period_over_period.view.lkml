include: "aws_billing.view.lkml"

view: +aws_billing {
  ###################### Period over Period Reporting Metrics ######################

  parameter: period {
    label: "Timeframe"
    view_label: "Period over Period"
    type: unquoted
    allowed_value: {
      label: "Week to Date"
      value: "Week"
    }
    allowed_value: {
      label: "Month to Date"
      value: "Month"
    }
    allowed_value: {
      label: "Quarter to Date"
      value: "Quarter"
    }
    allowed_value: {
      label: "Year to Date"
      value: "Year"
    }
    default_value: "Period"
  }

  # To get start date we need to get either first day of the year, month or quarter
  dimension: first_date_in_period {
    view_label: "Period over Period"
    type: date
    hidden: no
    sql: DATE_TRUNC(CURRENT_DATE(), {% parameter period %});;
    convert_tz: no
    datatype: date
  }

  #Now get the total number of days in the period
  dimension: days_in_period {
    view_label: "Period over Period"
    type: number
    hidden: no
    sql: DATE_DIFF(CURRENT_DATE(),${first_date_in_period}, DAY) ;;
    # convert_tz: no
  }

  #Now get the first date in the prior period
  dimension: first_date_in_prior_period {
    view_label: "Period over Period"
    type: date
    hidden: no
    sql: DATE_TRUNC(DATE_ADD(CURRENT_DATE(), INTERVAL -1 {% parameter period %}),{% parameter period %});;
    convert_tz: no
    datatype: date
  }

  #Now get the last date in the prior period
  dimension: last_date_in_prior_period {
    view_label: "Period over Period"
    type: date
    hidden: no
    sql: DATE_ADD(${first_date_in_prior_period}, INTERVAL ${days_in_period} DAY) ;;
    convert_tz: no
    datatype: date
  }

  # Now figure out which period each date belongs in
  dimension: period_selected {
    view_label: "Period over Period"
    type: string
    sql:
        CASE
          WHEN ${aws_billing.usage_start_date} >=  ${first_date_in_period}
          THEN 'This {% parameter period %} to Date'
          WHEN ${aws_billing.usage_start_date} >= ${first_date_in_prior_period}
          AND ${aws_billing.usage_start_date} <= ${last_date_in_prior_period}
          THEN 'Prior {% parameter period %} to Date'
          ELSE NULL
          END ;;
  }


  dimension: days_from_period_start {
    view_label: "Period over Period"
    type: number
    sql: CASE WHEN ${period_selected} = 'This {% parameter period %} to Date'
          THEN DATE_DIFF(${aws_billing.usage_start_date}, ${first_date_in_period}, DAY)
          WHEN ${period_selected} = 'Prior {% parameter period %} to Date'
          THEN DATE_DIFF(${aws_billing.usage_start_date}, ${first_date_in_prior_period}, DAY)
          ELSE NULL END;;
  }


}
