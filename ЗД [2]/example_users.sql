/* Задача 2
Создайте базу данных example, разместите в ней таблицу users, состоящую из двух столбцов, числового id и строкового name.
*/

DROP DATABASE IF EXISTS example;
CREATE DATABASE example DEFAULT CHARACTER SET utf8 COLLATE utf8_bin ;
USE example;

CREATE TABLE users (
  id INT NOT NULL AUTO_INCREMENT,
  name VARCHAR(45) NOT NULL,
  PRIMARY KEY (id));
  

INSERT INTO users (name) VALUES 	/* +закинула парочку имён */
('Helen'), 
('Isa'), 
('Soeren');

SELECT * FROM users;

SELECT * FROM mysql.help_keyword LIMIT 100;
