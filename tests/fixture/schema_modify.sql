DROP TABLE IF EXISTS test.Schema;
CREATE TABLE test.Schema (
  `id` int(12) UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `toBoolean` float NOT NULL,
  `toFloat` int(11) UNSIGNED NOT NULL,
  `toInt` tinyint(1) UNSIGNED NOT NULL,
  `toLongText` tinyint(1) NOT NULL,
  `toText` text NOT NULL,
  `toDate` tinyint(1) NOT NULL
);