/* Задача 1
Подсчитайте средний возраст пользователей в таблице users
*/

DROP DATABASE IF EXISTS example;
CREATE DATABASE example DEFAULT CHARACTER SET utf8 COLLATE utf8_bin ;
USE example;

DROP TABLE IF EXISTS users;
CREATE TABLE users (
  id SERIAL,
  name VARCHAR(45) NOT NULL,
  birthday DATE,
  created_at DATETIME DEFAULT NOW(),
  updated_at DATETIME DEFAULT NOW(),
  PRIMARY KEY (id));
  
INSERT INTO users (name, birthday) VALUES 
('Helen', '1990-02-04'), 
('Isa', '1982-11-21'), 
('Markus', '1997-05-03'), 
('Inga', '1973-09-10'), 
('Soeren', '1983-02-01');

SELECT 
	 ROUND(AVG (YEAR(CURDATE()) - YEAR(birthday))) AS average_age
     FROM users;

/* Задача 2
Подсчитайте количество дней рождения, которые приходятся на каждый из дней недели. Следует учесть, что необходимы дни недели текущего года, а не года рождения.
*/

SELECT 
DAYNAME(DATE_ADD( birthday, INTERVAL (YEAR(CURDATE()) - YEAR(birthday))YEAR )) as day, -- дата др + возраст пользователя (сейчас год - год рождения)) = некое число в 2019, вычисляем название дня этого числа. 
COUNT(DISTINCT birthday) AS weekday_this_year FROM users
GROUP BY day;


/* Задача 3 (по желанию)
Подсчитайте произведение чисел в столбце таблицы
*/

DROP TABLE IF EXISTS user_data;
CREATE TABLE user_data (
  id SERIAL,
  value INT,
PRIMARY KEY (id));

INSERT INTO user_data (value) VALUES 
('1'),
('2'),
('3'),
('4'),
('5');

SELECT ROUND(exp(sum(ln(value)))) as result from user_data; -- немного округлить нужно, иначе это 119,(9)

  