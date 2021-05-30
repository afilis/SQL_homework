--=============== МОДУЛЬ 4. УГЛУБЛЕНИЕ В SQL =======================================
--= ПОМНИТЕ, ЧТО НЕОБХОДИМО УСТАНОВИТЬ ВЕРНОЕ СОЕДИНЕНИЕ И ВЫБРАТЬ СХЕМУ PUBLIC===========
SET search_path TO public;

--======== ОСНОВНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--База данных: если подключение к облачной базе, то создаете новые таблицы в формате:
--таблица_фамилия, 
--если подключение к контейнеру или локальному серверу, то создаете новую схему и в ней создаете таблицы.


-- Спроектируйте базу данных для следующих сущностей:
-- 1. язык (в смысле английский, французский и тп)
-- 2. народность (в смысле славяне, англосаксы и тп)
-- 3. страны (в смысле Россия, Германия и тп)


--Правила следующие:
-- на одном языке может говорить несколько народностей
-- одна народность может входить в несколько стран
-- каждая страна может состоять из нескольких народностей

 
--Требования к таблицам-справочникам:
-- идентификатор сущности должен присваиваться автоинкрементом
-- наименования сущностей не должны содержать null значения и не должны допускаться дубликаты в названиях сущностей
 
--СОЗДАНИЕ ТАБЛИЦЫ ЯЗЫКИ

set search_path to lecture_4_afremov;

create table languages (
	language_id serial primary key,
	language_name varchar(25)
);

--ВНЕСЕНИЕ ДАННЫХ В ТАБЛИЦУ ЯЗЫКИ

insert into languages ("language_name")
values ('English'), ('French'), ('German'), ('Russian'), ('Chinese');

--СОЗДАНИЕ ТАБЛИЦЫ НАРОДНОСТИ

create table ethnoses (
	ethnos_id serial primary key,
	ethnos_name varchar(25)
);

--ВНЕСЕНИЕ ДАННЫХ В ТАБЛИЦУ НАРОДНОСТИ

insert into ethnoses ("ethnos_name")
values ('Anglo-Saxons'), ('Frenches'), ('Germans'), ('Russians'), ('Chinese');

--СОЗДАНИЕ ТАБЛИЦЫ СТРАНЫ

create table countries (
	country_id serial primary key,
	country_name varchar(25)
);

--ВНЕСЕНИЕ ДАННЫХ В ТАБЛИЦУ СТРАНЫ

insert into countries ("country_name")
values ('UK'), ('France'), ('Belgium'), ('Russia'), ('China');

--СОЗДАНИЕ ПЕРВОЙ ТАБЛИЦЫ СО СВЯЗЯМИ

create table language_ethnos (
	language_ethnos_id serial primary key,
	language_id integer references languages(language_id),
	ethnos_id integer references ethnoses(ethnos_id)
);

--ВНЕСЕНИЕ ДАННЫХ В ТАБЛИЦУ СО СВЯЗЯМИ

insert into language_ethnos ("language_id", "ethnos_id")
values (1, 1), (1, 2), (1, 3),	-- en: as, fr, ger
	(2, 2),              	-- fr: fr
	(3, 3),                 -- ger: ger
	(4, 4),                 -- ru: ru
	(5, 5);                 -- ch: ch

--СОЗДАНИЕ ВТОРОЙ ТАБЛИЦЫ СО СВЯЗЯМИ

create table ethnos_country (
	ethnos_country_id serial primary key,
	ethnos_id integer references ethnoses(ethnos_id),
	country_id integer references countries(country_id)
);

--ВНЕСЕНИЕ ДАННЫХ В ТАБЛИЦУ СО СВЯЗЯМИ

insert into ethnos_country ("ethnos_id", "country_id")
values (1, 1), (1, 3),		-- as: UK, Belgium
	(2, 2), (2, 3),        	-- fr: France, Belgium
	(3, 3),                 -- ger: Belgium
	(4, 4),                 -- ru: Russia
	(5, 5);                 -- ch: UK, China

--======== ДОПОЛНИТЕЛЬНАЯ ЧАСТЬ ==============


--ЗАДАНИЕ №1 
--Создайте новую таблицу film_new со следующими полями:
--·   	film_name - название фильма - тип данных varchar(255) и ограничение not null
--·   	film_year - год выпуска фильма - тип данных integer, условие, что значение должно быть больше 0
--·   	film_rental_rate - стоимость аренды фильма - тип данных numeric(4,2), значение по умолчанию 0.99
--·   	film_duration - длительность фильма в минутах - тип данных integer, ограничение not null и условие, что значение должно быть больше 0
--Если работаете в облачной базе, то перед названием таблицы задайте наименование вашей схемы.

set search_path to lecture_4_afremov;

create table film_new (
  	film_name varchar(255) not null primary key,
   	film_year integer check (film_year > 0),
   	film_rental_rate numeric(4, 2) default 0.99,
   	film_duration integer not null check (film_duration > 0)
);

--ЗАДАНИЕ №2 
--Заполните таблицу film_new данными с помощью SQL-запроса, где колонкам соответствуют массивы данных:
--·       film_name - array['The Shawshank Redemption', 'The Green Mile', 'Back to the Future', 'Forrest Gump', 'Schindlers List']
--·       film_year - array[1994, 1999, 1985, 1994, 1993]
--·       film_rental_rate - array[2.99, 0.99, 1.99, 2.99, 3.99]
--·   	  film_duration - array[142, 189, 116, 142, 195]

insert into film_new ("film_name", "film_year", "film_rental_rate", "film_duration")
select unnest(array['The Shawshank Redemption', 'The Green Mile', 'Back to the Future', 'Forrest Gump', 'Schindlers List']),
	unnest(array[1994, 1999, 1985, 1994, 1993]),
	unnest(array[2.99, 0.99, 1.99, 2.99, 3.99]),
	unnest(array[142, 189, 116, 142, 195])

--ЗАДАНИЕ №3
--Обновите стоимость аренды фильмов в таблице film_new с учетом информации, 
--что стоимость аренды всех фильмов поднялась на 1.41

update film_new set film_rental_rate = film_rental_rate + 1.41 where true

--ЗАДАНИЕ №4
--Фильм с названием "Back to the Future" был снят с аренды, 
--удалите строку с этим фильмом из таблицы film_new

delete from film_new where film_name = 'Back to the Future'

--ЗАДАНИЕ №5
--Добавьте в таблицу film_new запись о любом другом новом фильме

insert into film_new ("film_name", "film_year", "film_duration")
values ('Her', 2013, 126)

--ЗАДАНИЕ №6
--Напишите SQL-запрос, который выведет все колонки из таблицы film_new, 
--а также новую вычисляемую колонку "длительность фильма в часах", округлённую до десятых

select "film_name", "film_year", "film_rental_rate", "film_duration",
	round("film_duration" / 60.0, 1) as "film_duration_hours"
from film_new

--ЗАДАНИЕ №7 
--Удалите таблицу film_new

drop table film_new

