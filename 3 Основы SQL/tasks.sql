--=============== МОДУЛЬ 3. ОСНОВЫ SQL =======================================
--= ПОМНИТЕ, ЧТО НЕОБХОДИМО УСТАНОВИТЬ ВЕРНОЕ СОЕДИНЕНИЕ И ВЫБРАТЬ СХЕМУ PUBLIC===========
SET search_path TO public;

--======== ОСНОВНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Выведите для каждого покупателя его адрес проживания, 
--город и страну проживания.


select concat(c.last_name, ' ', c.first_name) as "Фамилия и имя",
	a.address as "Адрес",
	c2.city as "Город",
	c3.country as "Страна"
from customer c
join address a using(address_id)
join city c2 using(city_id)
join country c3 using(country_id)


--ЗАДАНИЕ №2
--С помощью SQL-запроса посчитайте для каждого магазина количество его покупателей.


select c.store_id as "ID магазина",
	count(c.customer_id) as "Количество покупателей"
from customer c
group by c.store_id


--Доработайте запрос и выведите только те магазины, 
--у которых количество покупателей больше 300-от.
--Для решения используйте фильтрацию по сгруппированным строкам 
--с использованием функции агрегации.


select c.store_id as "ID магазина",
	count(c.customer_id) as "Количество покупателей"
from customer c
group by c.store_id
having count(c.customer_id) >= 300


-- Доработайте запрос, добавив в него информацию о городе магазина, 
--а также фамилию и имя продавца, который работает в этом магазине.


select c.store_id as "ID магазина",
	count(c.customer_id) as "Количество покупателей",
	c2.city as "Город магазина",
	concat(s2.last_name, ' ', s2.first_name) as "Фамилия и имя продавца"
from customer c
join store s on c.store_id = s.store_id
join address a on s.address_id = a.address_id
join city c2 on a.city_id = c2.city_id
join staff s2 on c.store_id = s2.store_id
group by c.store_id, c2.city, s2.last_name, s2.first_name
having count(c.customer_id) >= 300


--ЗАДАНИЕ №3
--Выведите ТОП-5 покупателей, 
--которые взяли в аренду за всё время наибольшее количество фильмов


select concat(c.last_name, ' ', c.first_name) as "Фамилия и имя покупателя",
	count(i.film_id) as "Количество фильмов"
from rental r
join customer c using(customer_id)
join inventory i using(inventory_id)
group by c.last_name, c.first_name
order by count(i.film_id) desc
limit 5


--ЗАДАНИЕ №4
--Посчитайте для каждого покупателя 4 аналитических показателя:
--  1. количество фильмов, которые он взял в аренду
--  2. общую стоимость платежей за аренду всех фильмов (значение округлите до целого числа)
--  3. минимальное значение платежа за аренду фильма
--  4. максимальное значение платежа за аренду фильма


select concat(c.last_name, ' ', c.first_name) as "Фамилия и имя покупателя",
	count(i.film_id) as "Количество фильмов",
	round(sum(p.amount)) as "Общая стоимость платежей",
	min(p.amount) as "Минимальная стоимость платежа",
	max(p.amount) as "Максимальная стоимость платежа"
from payment p
join rental r using(rental_id, customer_id)
join inventory i using (inventory_id)
join customer c using (customer_id)
group by concat(c.last_name, ' ', c.first_name)


--ЗАДАНИЕ №5
--Используя данные из таблицы городов составьте одним запросом всевозможные пары городов таким образом,
 --чтобы в результате не было пар с одинаковыми названиями городов. 
 --Для решения необходимо использовать декартово произведение.


select c.city, c2.city
from city c
cross join city c2
where c.city != c2.city


--ЗАДАНИЕ №6
--Используя данные из таблицы rental о дате выдачи фильма в аренду (поле rental_date)
--и дате возврата фильма (поле return_date), 
--вычислите для каждого покупателя среднее количество дней, за которые покупатель возвращает фильмы.
 

select customer_id,
	round(avg(date_part('day', return_date - rental_date)::numeric), 2)
from rental
group by customer_id


--======== ДОПОЛНИТЕЛЬНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Посчитайте для каждого фильма сколько раз его брали в аренду и значение общей стоимости аренды фильма за всё время.


select f.title as "Название",
	f.rating as "Рейтинг",
	c."name" as "Жанр",
	f.release_year as "Год выпуска",
	l."name" as "Язык",
	count(p.amount) as "Количество аренд",
	sum(p.amount) as "Общая стоимость аренды"
from film f
left join inventory i on f.film_id = i.film_id
left join rental r on i.inventory_id = r.inventory_id 
left join payment p on r.rental_id = p.rental_id
join film_category fc on f.film_id = fc.film_id
join category c on fc.category_id = c.category_id
join "language" l on f.language_id = l.language_id
group by f.film_id, c."name", l."name"


--ЗАДАНИЕ №2
--Доработайте запрос из предыдущего задания и выведите с помощью запроса фильмы, которые ни разу не брали в аренду.


select f.title as "Название",
	f.rating as "Рейтинг",
	c."name" as "Жанр",
	f.release_year as "Год выпуска",
	l."name" as "Язык",
	0 as "Количество аренд",
	0 as "Общая стоимость аренды"
from film f
left join inventory i on f.film_id = i.film_id
left join rental r on i.inventory_id = r.inventory_id 
left join payment p on r.rental_id = p.rental_id
join film_category fc on f.film_id = fc.film_id
join category c on fc.category_id = c.category_id
join "language" l on f.language_id = l.language_id
group by f.film_id, c."name", l."name"
having count(p.amount) = 0


--ЗАДАНИЕ №3
--Посчитайте количество продаж, выполненных каждым продавцом. Добавьте вычисляемую колонку "Премия".
--Если количество продаж превышает 7300, то значение в колонке будет "Да", иначе должно быть значение "Нет".


select staff_id as "ID сотрудника",
	count(payment_id) as "Количество продаж",
	case when count(payment_id) > 7300 then 'Да'
	else 'Нет' end as "Премия"
from payment
group by staff_id

