/* Задача 1
Пусть в таблице users поля created_at и updated_at оказались незаполненными. Заполните их текущими датой и временем.
*/

DROP DATABASE IF EXISTS example;
CREATE DATABASE example DEFAULT CHARACTER SET utf8 COLLATE utf8_bin ;
USE example;

DROP TABLE IF EXISTS users;
CREATE TABLE users (
  id SERIAL,
  name VARCHAR(45) NOT NULL,
  created_at DATETIME,
  updated_at DATETIME,
  PRIMARY KEY (id));
  
INSERT INTO users (name) VALUES 
('Helen'), 
('Isa'), 
('Markus'), 
('Inga'), 
('Soeren');

UPDATE users SET created_at= NOW();
UPDATE users SET updated_at= NOW();

ALTER TABLE users MODIFY created_at DATETIME DEFAULT NOW();
ALTER TABLE users MODIFY updated_at DATETIME DEFAULT NOW();
  

/* Задача 2
Таблица users была неудачно спроектирована. Записи created_at и updated_at были заданы типом VARCHAR и в них долгое время помещались значения в формате "20.10.2017 8:10". Необходимо преобразовать поля к типу DATETIME, сохранив введеные ранее значения.
*/

DROP TABLE IF EXISTS users;
CREATE TABLE users (
  id SERIAL,
  name VARCHAR(45) NOT NULL,
  created_at VARCHAR(45),
  updated_at VARCHAR(45),
  PRIMARY KEY (id));
  
INSERT INTO users (name, created_at, updated_at) VALUES 
('Helen', '20.10.2017 8:10', '20.10.2017 8:10'), 
('Isa', '23.05.2017 9:25', '17.01.2019 10:35'), 
('Markus', '16.05.2017 8:15', '21.04.2019 11:10'), 
('Inga', '13.11.2017 13:20', '20.10.2019 22:10'), 
('Soeren', '05.10.2017 15:45', '18.05.2018 18:15');

UPDATE users SET created_at= CONCAT(
STR_TO_DATE(SUBSTRING(created_at, 1, 10), '%d.%m.%Y'),
SUBSTRING(created_at, 11, 15));

UPDATE users SET updated_at= CONCAT(
STR_TO_DATE(SUBSTRING(updated_at, 1, 10), '%d.%m.%Y'),
SUBSTRING(updated_at, 11, 15));

ALTER TABLE users MODIFY created_at DATETIME DEFAULT NOW(); 
ALTER TABLE users MODIFY updated_at DATETIME DEFAULT NOW(); 


/* Задача 3
В таблице складских запасов storehouses_products в поле value могут встречаться самые разные цифры: 0, если товар закончился и выше нуля, если на складе имеются запасы. Необходимо отсортировать записи таким образом, чтобы они выводились в порядке увеличения значения value. Однако, нулевые запасы должны выводиться в конце, после всех записей.
*/

DROP TABLE IF EXISTS storehouses_products;
CREATE TABLE storehouses_products (
  id SERIAL,
  value INT,
  PRIMARY KEY (id));

INSERT INTO storehouses_products (value) VALUES 
('0'),
('2500'),
('0'),
('50'),
('13'),
('429'),
('0'),
('84'),
('8');

 SELECT * FROM storehouses_products ORDER BY 
 CASE WHEN value=0 THEN 1 ELSE 0 END, value;


/* Задача 4 (по желанию)
Из таблицы users необходимо извлечь пользователей, родившихся в августе и мае. Месяцы заданы в виде списка английских названий ('may', 'august')
*/

ALTER TABLE users ADD COLUMN birthday VARCHAR(55); 
UPDATE users SET birthday = '14 August 1989' WHERE (`id` = '1');
UPDATE users SET birthday = '15 May 1953' WHERE (`id` = '2');
UPDATE users SET birthday = '31 July 1999' WHERE (`id` = '3');
UPDATE users SET birthday = '2 May 1997' WHERE (`id` = '4');
UPDATE users SET birthday = '5 June 1985' WHERE (`id` = '5');

SELECT
id, name,
CASE
	WHEN birthday RLIKE 'August' THEN 'Пользователь родился в августе'
    WHEN birthday RLIKE 'May' THEN 'Пользователь родился в мае'
END AS birthday_months
FROM users
	WHERE birthday RLIKE 'August|May';


/* Задача 5 (по желанию)
 Из таблицы catalogs извлекаются записи при помощи запроса. SELECT * FROM catalogs WHERE id IN (5, 1, 2); Отсортируйте записи в порядке, заданном в списке IN.
*/

DROP TABLE IF EXISTS catalogs;
CREATE TABLE catalogs (
  id SERIAL,
  product_name VARCHAR(45),
  product_price FLOAT(11,2),
  PRIMARY KEY (id));
  
  INSERT INTO catalogs (product_name, product_price) VALUES 
('cushion', '2000'),
('sofa', '43000'),
('armchair', '43990'),
('table', '3299'),
('chair', '1992.2'),
('cupboard', '3156.3'),
('computer_table', '3290');
  
  SELECT * FROM catalogs WHERE id IN (5, 1, 2)
  ORDER BY FIELD(id,
        '5',
        '1',
        '2');