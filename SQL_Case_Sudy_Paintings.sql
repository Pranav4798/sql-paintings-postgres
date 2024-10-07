-- Paintings not displayed in any museums
select count(*) from "work" w 
where museum_id is null

--museum without paintings
select * from museum m 
where not exists (select 1 from work w where w.museum_id = m.museum_id)

--Paintings having sales_price more than regular_price
select count(*) from product_size ps 
where sale_price > regular_price 

--which canvas size costs the most
select cs.size_id, label, ps.sale_price 
from product_size ps join canvas_size cs on cs.size_id = ps.size_id 
order by ps.sale_price desc
limit 1

--Museums with invalid city
select *
from museum m where city ~ '[0-9]'

--Top 10 most famous painting subject
select subject, count(subject)
from subject s 
group by subject 
order by count(subject) desc 
limit 10

--Museums open only on Sundays/Mondays
select m."name" , m.museum_id, m.city from 
museum m join (
select m.museum_id
from museum m join museum_hours mh on m.museum_id = mh.museum_id 
where day in ('Sunday','Monday')
group by m.museum_id 
having count(mh.museum_id) = 2
) as m_list on m.museum_id  = m_list.museum_id

--Museums open 7 days a week
select name, m.museum_id
from museum m join (select museum_id from museum_hours mh group by museum_id having count(museum_id) = 7) as mcount on m.museum_id = mcount.museum_id

--Most popular Museum based on number of paintings
select m.museum_id, m."name", m.city, mcnt
from museum m join ( select museum_id, count(museum_id) as mcnt
from work 
group by museum_id 
order by count(museum_id) desc 
limit 10 ) as mc on m.museum_id = mc.museum_id

--Least popular canvas sizes
select cs.size_id, csi, cs."label" 
from canvas_size cs join ( select ps.size_id, count(cs.size_id) as csi
from product_size ps
join canvas_size cs on ps.size_id = cs.size_id 
group by ps.size_id 
order by csi asc 
limit 20 ) as plim on cs.size_id = plim.size_id

--Most number of painting styles
with cntMus as (
select count(mcnt) as TypesOfPaintings,mcnt.museum_id from ( 
select count(*), "style", m.museum_id 
from museum m join "work" w on w.museum_id = m.museum_id 
group by w."style", m.museum_id ) as mcnt
group by mcnt.museum_id
order by count(museum_id) desc 
)
select m."name" , m.city , m.museum_id, TypesOfPaintings
from museum m join cntMus on m.museum_id = cntMus.museum_id

--Museum with most paintings of one style
with styleTop as (
select count(*), "style" 
from "work" w 
where "style" is not null
group by w."style" 
order by 1 desc
limit 1 )
select m.museum_id, name, mcnt from museum m join ( select museum_id, count(museum_id) as mcnt 
from "work" w join styleTop on w."style" = styleTop."style"
group by museum_id ) as MostStyle on m.museum_id = MostStyle.museum_id
order by mcnt desc
limit 1

--Countries with most number of museums
select m.country, count(country) as cntC
from "work" w 
join museum m on w.museum_id = m.museum_id 
group by country
order by 2 desc


--Artists having paintings in multiple countries
with cte as (
select a.full_name as nameF, count(w.museum_id), w.museum_id, m.country 
from artist a 
join "work" w on w.artist_id = a.artist_id
join museum m on w.museum_id = m.museum_id 
group by a.full_name, w.museum_id, m.country
)
select cte.nameF, count(distinct cte.country) as countries
from cte 
group by nameF
having count(distinct cte.country) > 1
order by 2 desc
limit 10

--Countries with number of museums
select country, count(country)
from museum m 
group by country 
order by count(country) desc

--Country and Cities with most number of museums
with cteCnt as (
	select country, count(country), rank() over (order by count(1) desc) as rnk
	from museum m 
	group by country ), 
	cteCty as (
	select city, count(1), rank() over (order by count(1) desc) as rnk
	from museum m 
	group by city )
select string_agg(distinct country.country,',') as CountryMost,string_agg(distinct city.city,',') as CityMost
from cteCnt country cross join cteCty city
where country.rnk = 1 and city.rnk = 1

--Most expensive painting
with MostCte as (
select sale_price, work_id 
from product_size ps 
order by ps.sale_price desc 
limit 1 ),
LeastCte as (
select sale_price, work_id 
from product_size ps 
order by ps.sale_price asc
limit 1 )
select *
from "work" w
join MostCte using (work_id)

--Most expensive and least expensive painting
with cte as (
select *, rank() over (order by sale_price desc ) as rnk, rank() over (order by sale_price) as asc_rnk
from product_size ps )
select distinct w.name, a.full_name , w.work_id, rnk, asc_rnk, cte.sale_price
from "work" w 
join cte on cte.work_id = w.work_id 
join artist a on a.artist_id = w.artist_id 
where rnk = 1 or asc_rnk = 1

--Country with 5th higest number of paintings
select *  from (
select count(m.museum_id) as NoPaint, m.country
from museum m
join "work" w on m.museum_id = w.museum_id 
group by m.country 
order by 1 desc
limit 5)
order by NoPaint asc
limit 1

--Country with 5th higest number of paintings (using rank)
select * from (
select m.country, count(m.museum_id), rank() over (order by count(country) desc) as rnk
from museum m 
join "work" w on m.museum_id = w.museum_id 
group by m.country)
where rnk = '5'

--3 most and 3 least popular painting styles
select * from (
select w."style", count(style), rank() over (order by count(w.style) desc) as desc_rnk,  rank() over (order by count(w.style) asc) as asc_rnk
from "work" w 
group by w."style" )
where desc_rnk <= 3 or asc_rnk <= 3 

-- Artists with most number of portraits outside USA
with cteP as (
select *
from subject s 
where s.subject = 'Portraits' ),
cteW as (
select * from "work" w 
join cteP on w.work_id = cteP.work_id ),
cteA as (
select * from artist
join cteW on cteW.artist_id = artist.artist_id )
select cteA.full_name, count(full_name) from cteA 
join museum m on cteA.museum_id = m.museum_id 
where m.country != 'USA'
group by full_name 
order by count(full_name) desc
limit 2

--Types of styles with count
select count(*), w."style" 
from "work" w 
group by w."style" 


