package tink.sql;

/**
 * Convert each member in a Model object into a readonly property
 */
@:genericBuild(tink.sql.Results.build())
class Results<T> {}