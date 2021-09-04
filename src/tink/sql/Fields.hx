package tink.sql;

/**
 * Convert each member in a Model object into a tink.sql.Field instance
 */
@:genericBuild(tink.sql.Fields.build())
class Fields<T> {}