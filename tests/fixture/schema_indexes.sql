DROP TABLE IF EXISTS test.Schema;
CREATE TABLE test.Schema (
  `id` int(12) UNSIGNED NOT NULL,
  `a` tinyint(1) NOT NULL,
  `b` tinyint(1) NOT NULL,
  `c` tinyint(1) NOT NULL,
  `d` tinyint(1) NOT NULL,
  `e` tinyint(1) NOT NULL,
  `f` tinyint(1) NOT NULL,
  `g` tinyint(1) NOT NULL,
  `h` tinyint(1) NOT NULL,
  `indexed` tinyint(1) NOT NULL,
  `toAdd` tinyint(1) NOT NULL,
  `toBoolean` tinyint(1) NOT NULL,
  `toFloat` float NOT NULL,
  `toInt` int(11) UNSIGNED NOT NULL,
  `toLongText` text NOT NULL,
  `toText` varchar(1) NOT NULL,
  `toDate` datetime NOT NULL,
  `unique` tinyint(1) NOT NULL
);

ALTER TABLE test.Schema
  ADD KEY `ab` (`a`), -- Add b
  ADD UNIQUE KEY `ef` (`f`), -- Add e
  ADD UNIQUE KEY `h` (`h`), -- Remove
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique` (`b`), -- Named after another field
  ADD UNIQUE KEY `indexed` (`indexed`); -- Unique to index

ALTER TABLE test.Schema
  MODIFY `id` int(12) UNSIGNED NOT NULL AUTO_INCREMENT;