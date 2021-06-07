
set search_path to bookings;

-- 1 В каких городах больше одного аэропорта?

-- Решение.
-- Выбираем из таблицы airports города,
-- группируем и выводим те города, кол-во которых больше 1.

select city as "Город",
	count(city) as "Кол-во аэропортов"
from airports
group by city
having count(city) > 1


-- 2 В каких аэропортах есть рейсы, выполняемые самолетом с максимальной дальностью перелета?

-- Решение.
-- Выбираем из таблицы aircrafts код(ы) самолета(ов), с наибольшим расстоянием.
-- Выбираем из таблицы flights как аэропорты вылета, так и аэропорты прилета.
-- Далее необходимо отсеять повторяющиеся значения, оставив уникальными пары код аэропорта-код самолета.
-- Теперь остается только получить информацию о названии аэропорта и оставить только рейсы в аэропорты (и из аэропортов)
-- с максимальной дальностью.
-- Не забываем сгруппироваить по названию аэропорта, т.к. самоетов с максимальной одинаковой дальностью полета
-- может быть несколько, и хотя бы 2 из них могут совершать рейсы из одного и того же аэропорта
-- (выборка из aircrafts в этом случае даст несколько aircraft_code).


select a3.airport_name
from
(
	select departure_airport as airport_code, aircraft_code
	from flights f
	group by departure_airport, aircraft_code
	union
	select arrival_airport as airport_code, aircraft_code
	from flights f2
	group by arrival_airport, aircraft_code
) airps
join airports a3 on airps.airport_code = a3.airport_code
where aircraft_code in
(
	select aircraft_code
	from aircrafts a 
	where "range" in
	(
		select max("range")
		from aircrafts a2 
	)
)
group by a3.airport_name
order by a3.airport_name


-- 3 Вывести 10 рейсов с максимальным временем задержки вылета

-- Решение.
-- Выбираем рейсы, для которых известно actual_departure,
-- вычисляем задерку, сортируем и выводим топ-10

select *, actual_departure - scheduled_departure as delay
from flights
where actual_departure is not null
order by actual_departure - scheduled_departure desc
limit 10


-- 4 Были ли брони, по которым не были получены посадочные талоны?

-- Выбираем данные из таблицы bookings.
-- Далее сперва необходимо получить информацию о номерах билетов,
-- выданных на соответствующее бронирование.
-- Затем по номерам билетов получить информацию о выданных на них
-- посадочных талонах.
-- Поскольку bookings - это словарь-справочник, содержащий все бронирования,
-- то соединять следует через left join, который заполнит значениями null атрибуты
-- тех билетов, которые не были проданы и в тех посадочных талонах, которые
-- не были получены на эти билеты.

select case 
	when count(b.book_ref) > 0 then 'Да'
	else 'Нет'
	end as "Были брони без посадочных талонов?"
from bookings b
left join tickets t on b.book_ref = t.book_ref
left join boarding_passes bp on t.ticket_no = bp.ticket_no
where bp.boarding_no is null

-- Комментарий.
-- Можно сделать то же самое, но без join с использованием множеств.
-- Т.е. проверить все ли брони есть в списке билетов и все ли билеты
-- есть в списке посадочных талонов.
-- Правда, из-за большого кол-ва данных это решение гораздо медленнее,
-- чем решение с join

select case
	when (
			select count(*)
			from
			(
				select book_ref 
				from bookings b
				except
				select book_ref 
				from tickets t
			) br
		)
		+
		(
			select count(*)
			from
			(
				select ticket_no
				from tickets t 
				except
				select ticket_no 
				from boarding_passes bp
			) tn
		) > 0 then 'Да'
	else 'Нет'
	end as "Были брони без посадочных талонов?"


-- 5 Найдите свободные места для каждого рейса, их % отношение к общему количеству мест в самолете.
-- Добавьте столбец с накопительным итогом - суммарное накопление количества вывезенных пассажиров из каждого аэропорта на каждый день.
-- Т.е. в этом столбце должна отражаться накопительная сумма - сколько человек уже вылетело из данного аэропорта на этом или более ранних рейсах за день.
	
-- Решение.
-- Выбираем из seats и считаем кол-во мест по каждому воздушному судну.
-- Выбираем из boarding_passes и считаем кол-во занятых мест.
-- Далее делаем выборку из flights и через join обединяем с предыдущими подзапросами,
-- рассчитываем нужные метрики.
-- Поскольку посадочные талоны могут быть выданы не на все рейсы, то выполняем
-- left join.

select f.*,
	(ja.total_seats - coalesce(jbp.non_free_seats, 0))::varchar || ' (' ||
	round((ja.total_seats - coalesce(jbp.non_free_seats, 0)) * 100. / ja.total_seats, 2)::varchar || '%)' as free_seats,
	coalesce(jbp.non_free_seats, 0) as dep_pass,
	coalesce(sum(jbp.non_free_seats) over (partition by f.departure_airport, date_trunc('day', f.actual_departure) order by f.actual_departure), 0) as cusum_dep_pass
from flights f
join (
	select s.aircraft_code, count(s.seat_no) as total_seats 
	from seats s
	group by s.aircraft_code
) ja on f.aircraft_code = ja.aircraft_code
left join (
	select flight_id, count(ticket_no) as non_free_seats 
	from boarding_passes bp
	group by flight_id
) jbp on f.flight_id = jbp.flight_id
order by f.departure_airport, f.actual_departure


-- 6 Найдите процентное соотношение перелетов по типам самолетов от общего количества.

-- Решение.
-- Выбираем из таблицы полетов самолеты, группируем их по типам, вычисляем кол-во в каждой группе,
-- через подзапрос находим их общее число и вычисляем соотношение

select aircraft_code, round(count(flight_id) * 100. / (select count(flight_id) from flights f2), 2)::varchar || '%' as flight_proportion
from flights f 
group by aircraft_code


-- 7 Были ли города, в которые можно добраться бизнес - классом дешевле, чем эконом-классом в рамках перелета?

-- Решение.
-- Сперва формируем CTE, в которой выбираем только те рейсы, на которые были проданы билеты как на эконом-класс, так и на бизнес-класс.
-- Из ticket_flights выбираем интересующие нас атрибуты и ставим ранг цены.
-- Затем в другой CTE отбрасываем дубликаты.
-- Таким образом, у нас внутри каждого рейса (где есть бизнес- и эконом-класс) цена на класс обслуживания будет отсортирована
-- по убыванию. А значит, останется только в основном запросе отфильтровать по классу обслуживания для самой дорогой позиции. 

with summary as (
	select flight_id, fare_conditions, amount, dense_rank() over (partition by flight_id order by amount desc)
	from ticket_flights tf
	where flight_id in
	(
		select flight_id
		from ticket_flights tf
		where fare_conditions = 'Business'
		intersect
		select flight_id
		from ticket_flights tf
		where fare_conditions = 'Economy'	
	)	
),
summary_uniq as (
	select flight_id, fare_conditions, amount, dense_rank
	from summary
	group by flight_id, fare_conditions, amount, dense_rank
	order by flight_id, dense_rank
)
select case
	when count(a.city) > 0 then 'Да'
	else 'Нет'
	end as "Были ли города ...?"
from flights f
join airports a on f.arrival_airport = a.airport_code
where flight_id in (
	select flight_id
	from summary_uniq
	where dense_rank = 1 and fare_conditions = 'Economy'
)

-- Комментарий.
-- Судя по данным, билеты эконом-класса на один и тот же рейс могут стоить по-разному.
-- В задании не сказано, должен ли билет бизнес-класса быть дешевле всех билетов из
-- эконом-класса. В данном решении предполагается, что хотя бы одного.
-- Если требуется, чтобы проверялось, что билет бизнес-класса стоит дешевле всех из
-- эконом-класса, достаточно заменить:
--   select flight_id, fare_conditions, amount, dense_rank() over (partition by flight_id order by amount desc)
-- на
--   select flight_id, fare_conditions, amount, dense_rank() over (partition by flight_id order by amount)
-- и
--   where dense_rank = 1 and fare_conditions = 'Economy'
-- на
--   where dense_rank = 1 and fare_conditions = 'Business'


-- 8 Между какими городами нет прямых рейсов?

-- Решение.
-- Строим 2 представления: обычное - для декартового произведения всех городов,
-- и материализованное для таблицы городов на основе таблицы рейсов.
-- Далее остается только из 1-ого вычесть 2-ое.

create view cities as
	with ct as
	(
		select distinct city
		from airports a
	)
	select c.city as city1,
		c2.city as city2
	from ct c
	cross join ct c2
	where c.city != c2.city
	
create materialized view connected_cities as
	select a.city as city1, a2.city as city2
	from flights f 
	join airports a on f.departure_airport = a.airport_code
	join airports a2 on f.arrival_airport = a2.airport_code
	group by a.city, a2.city
	
select *
from cities
except
select *
from connected_cities

-- Комментарий.
-- В задании не сказано нужно ли исключить зеркальные дубликаты типа Москва-Ижевск и Ижевск-Москва.
-- В случае их исключения представления должны быть сформированы так.

create view cities as
	with ct as
	(
		select distinct city
		from airports a
	)
	select c.city as city1,
		c2.city as city2
	from ct c
	cross join ct c2
	where c.city < c2.city
	
create materialized view connected_cities as
	select least(a.city, a2.city) as city1, greatest(a.city, a2.city) as city2
	from flights f 
	join airports a on f.departure_airport = a.airport_code
	join airports a2 on f.arrival_airport = a2.airport_code
	group by least(a.city, a2.city), greatest(a.city, a2.city)


-- 9 Вычислите расстояние между аэропортами, связанными прямыми рейсами, сравните с допустимой максимальной дальностью перелетов  в самолетах, обслуживающих эти рейсы

-- Решение.
-- Из списка рейсов получаем список аэропортов и убираем дубликаты (в т.ч. зеркальные).
-- Производим требуемые вычисления по формуле:
-- d = arccos(sin(latitude_a) * sin(latitude_b) + cos(latitude_a) * cos(latitude_b) * cos(longitude_a - longitude_b)),
-- где latitude_a и latitude_b — широты, longitude_a, longitude_b — долготы данных пунктов,
-- d — расстояние между пунктами измеряется в радианах длиной дуги большого круга земного шара.
-- Расстояние между пунктами, измеряемое в километрах, определяется по формуле:
-- L = d·R, где R = 6371 км — средний радиус земного шара.

select a.airport_name as airport1, a2.airport_name as airport2,
	round(acos(sind(a.latitude) * sind(a2.latitude) + cosd(a.latitude) * cosd(a2.latitude) * cosd(a.longitude - a2.longitude)) * 6371) as distance,
	airs.aircraft_range,
	case
		when round(acos(sind(a.latitude) * sind(a2.latitude) + cosd(a.latitude) * cosd(a2.latitude) * cosd(a.longitude - a2.longitude)) * 6371) < airs.aircraft_range then 'Да'
		else 'Нет'
		end as "Долетил ли самолет?"
from
(
	select least(f.departure_airport, f.arrival_airport) as airport_code1, greatest(f.departure_airport, f.arrival_airport) as airport_code2, a3.range as aircraft_range
	from flights f
	join aircrafts a3 on f.aircraft_code = a3.aircraft_code
	group by least(f.departure_airport, f.arrival_airport), greatest(f.departure_airport, f.arrival_airport), a3."range"
) airs
join airports a on airs.airport_code1 = a.airport_code
join airports a2 on airs.airport_code2 = a2.airport_code
order by a.airport_name, a2.airport_name

