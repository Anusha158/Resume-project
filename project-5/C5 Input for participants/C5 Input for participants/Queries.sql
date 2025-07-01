---1)top 10 district
use Test
with dom as(
select * from [dbo].[domestic_visitors_2016]
union all
select * from [dbo].[domestic_visitors_2017]
union all
select * from [dbo].[domestic_visitors_2018]
union all
select * from [dbo].[domestic_visitors_2019]
)

select top 10 district,sum(visitors)as Total_visitors

from dom
group by district
order by Total_visitors desc


--2)cagr for domestic and foreign
--cagr=(current_2019/previous_2016)\/n -1
with dom as(
select * from [dbo].[domestic_visitors_2016]
union all
select * from [dbo].[domestic_visitors_2017]
union all
select * from [dbo].[domestic_visitors_2018]
union all
select * from [dbo].[domestic_visitors_2019]
)
, get_16_19_data as(

select 
	'2016' as start_year
	,'2019' as end_year
	,district
	,sum(case when year='2016' then visitors end) as start_value
	,sum(case when year='2019' then visitors end) as end_value
from  dom
where year in('2016','2019')
group by district
)
select 
	top 3 district,
    '2016'as start_year,
    '2019' as end_year,
     round(Isnull(POWER(CAST(end_value AS FLOAT) / NULLIF(start_value, 0), 1.0 /3.0) - 1,0),2) AS CAGR

from 
	get_16_19_data
order by CAGR desc

--bottom 3 district based on CAGR for domestic tourist
with dom as(
select * from [dbo].[domestic_visitors_2016]
union all
select * from [dbo].[domestic_visitors_2017]
union all
select * from [dbo].[domestic_visitors_2018]
union all
select * from [dbo].[domestic_visitors_2019]
)
, get_16_19_data as(

select 
	'2016' as start_year
	,'2019' as end_year
	,district
	,sum(case when year='2016' then visitors end) as start_value
	,sum(case when year='2019' then visitors end) as end_value
from  dom
where year in('2016','2019')
group by district
)
select 
	top 3 district,
    '2016'as start_year,
    '2019' as end_year,
     Isnull(POWER(CAST(end_value AS FLOAT) / NULLIF(start_value, 0), 1.0 /3.0) - 1,0) AS CAGR

from 
	get_16_19_data
order by CAGR asc

--3)Peak high and low season for hyderabad
with dom as(
select * from [dbo].[domestic_visitors_2016]
union all
select * from [dbo].[domestic_visitors_2017]
union all
select * from [dbo].[domestic_visitors_2018]
union all
select * from [dbo].[domestic_visitors_2019]
)

,peak_low_mon as(
select year,month,district
,	rank()over(partition by year order by visitors asc)as low_months
,	rank()over(partition by year order by visitors desc)as peak_months
from
	dom 
where 
	district='Hyderabad'
	
)
select
  year,month,district,'low_season' as month_desc
from 
	peak_low_mon
where 
	low_months=1 
union all
select
  year,month,district,'peak_season' as month_desc
from 
	peak_low_mon
where 
	peak_months=1 

---5)district with  domestic to foreign ratio
with dom as(
select * from [dbo].[domestic_visitors_2016]
union all
select * from [dbo].[domestic_visitors_2017]
union all
select * from [dbo].[domestic_visitors_2018]
union all
select * from [dbo].[domestic_visitors_2019]
)
,dom_vis as	(
select
	district,sum(visitors)as Total_dom_vistors
from dom
group by district
),
frg as(
select * from [dbo].[foreign_visitors_2016]
union all
select * from [dbo].[foreign_visitors_2017]
union all
select * from [dbo].[foreign_visitors_2018]
union all
select * from [dbo].[foreign_visitors_2019]
),frg_cal as(
select 
	district
	,sum(visitors)as Total_frg_vistors
from 
	frg
group by 
	district
	)
select  f.district, CASE 
        WHEN NULLIF(cast(f.Total_frg_vistors as float), 0) IS NULL THEN NULL
        ELSE isnull(cast(d.Total_dom_vistors as float)/ NULLIF(cast(f.Total_frg_vistors as float), 0),0)
    END AS ratio
	from dom_vis d
	join frg_cal f
	on d.district=f.district
	order by ratio 


	select * from pop;
with cte1 as(
select * from domestic_visitors_2019
union all
select * from foreign_visitors_2019
), cte2 as(
select district,sum(visitors) as Total_vis_2019
from cte1
group by district
),res_pop as
(
select column2,sum(column5)as Tot_res_population
from pop
group by column2)

select  c.district,isnull(round((cast(Total_vis_2019 as float)/Tot_res_population),2),0) as tourist_footfall_ratio
from cte2 c join res_pop p
on c.district=p.column2
order by tourist_footfall_ratio desc