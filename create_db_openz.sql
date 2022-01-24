DO
$do$
BEGIN
	IF NOT EXISTS (
	      SELECT               
	      FROM   pg_catalog.pg_roles
	      WHERE  rolname = 'tad'
	) 
	THEN
	      CREATE ROLE tad LOGIN SUPERUSER PASSWORD 'tad'; 
	END IF;


	IF NOT EXISTS (
	      SELECT               
	      FROM   pg_catalog.pg_database
	      WHERE  datname = 'openz'
	) 
	THEN
	      CREATE DATABASE openz; 
	END IF;
END
$do$;
