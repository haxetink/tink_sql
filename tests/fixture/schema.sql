CREATE TABLE `test`.`Schema` ( 
  `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY, 
  `text` INT(100) NOT NULL, 
  `number` INT(11) NULL, 
  `boolean` TINYINT(1) NOT NULL, 
  `toremove` VARCHAR(1) NOT NULL
);
ALTER TABLE `test`.`Schema` ADD UNIQUE (`number`);