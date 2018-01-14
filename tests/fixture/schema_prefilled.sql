DROP TABLE IF EXISTS test.Schema;
CREATE TABLE test.Schema (
  `toBoolean` float NOT NULL,
  `toFloat` int(11) NOT NULL,
  `toInt` tinyint(1) UNSIGNED NOT NULL,
  `toLongText` tinyint(1) NOT NULL,
  `toText` text NOT NULL,
  `toDate` text NOT NULL
);

INSERT INTO test.Schema VALUES ('1.123456', '123', '1', '0', 'A', '2018-01-01 00:00:00');