--
-- PostgreSQL database dump
--

\restrict jz6ynGDl1qoqflsR4URhcw6jUFZfIN2quecsfvw73aFybv1Y47haJH5J6CZ0RQk

-- Dumped from database version 17.6
-- Dumped by pg_dump version 17.6 (Homebrew)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: auth; Type: SCHEMA; Schema: -; Owner: supabase_admin
--

CREATE SCHEMA auth;


ALTER SCHEMA auth OWNER TO supabase_admin;

--
-- Name: pg_cron; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_cron WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION pg_cron; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pg_cron IS 'Job scheduler for PostgreSQL';


--
-- Name: extensions; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA extensions;


ALTER SCHEMA extensions OWNER TO postgres;

--
-- Name: graphql; Type: SCHEMA; Schema: -; Owner: supabase_admin
--

CREATE SCHEMA graphql;


ALTER SCHEMA graphql OWNER TO supabase_admin;

--
-- Name: graphql_public; Type: SCHEMA; Schema: -; Owner: supabase_admin
--

CREATE SCHEMA graphql_public;


ALTER SCHEMA graphql_public OWNER TO supabase_admin;

--
-- Name: pgbouncer; Type: SCHEMA; Schema: -; Owner: pgbouncer
--

CREATE SCHEMA pgbouncer;


ALTER SCHEMA pgbouncer OWNER TO pgbouncer;

--
-- Name: realtime; Type: SCHEMA; Schema: -; Owner: supabase_admin
--

CREATE SCHEMA realtime;


ALTER SCHEMA realtime OWNER TO supabase_admin;

--
-- Name: storage; Type: SCHEMA; Schema: -; Owner: supabase_admin
--

CREATE SCHEMA storage;


ALTER SCHEMA storage OWNER TO supabase_admin;

--
-- Name: vault; Type: SCHEMA; Schema: -; Owner: supabase_admin
--

CREATE SCHEMA vault;


ALTER SCHEMA vault OWNER TO supabase_admin;

--
-- Name: pg_graphql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_graphql WITH SCHEMA graphql;


--
-- Name: EXTENSION pg_graphql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pg_graphql IS 'pg_graphql: GraphQL support';


--
-- Name: pg_stat_statements; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_stat_statements WITH SCHEMA extensions;


--
-- Name: EXTENSION pg_stat_statements; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pg_stat_statements IS 'track planning and execution statistics of all SQL statements executed';


--
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: supabase_vault; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS supabase_vault WITH SCHEMA vault;


--
-- Name: EXTENSION supabase_vault; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION supabase_vault IS 'Supabase Vault Extension';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA extensions;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: aal_level; Type: TYPE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TYPE auth.aal_level AS ENUM (
    'aal1',
    'aal2',
    'aal3'
);


ALTER TYPE auth.aal_level OWNER TO supabase_auth_admin;

--
-- Name: code_challenge_method; Type: TYPE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TYPE auth.code_challenge_method AS ENUM (
    's256',
    'plain'
);


ALTER TYPE auth.code_challenge_method OWNER TO supabase_auth_admin;

--
-- Name: factor_status; Type: TYPE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TYPE auth.factor_status AS ENUM (
    'unverified',
    'verified'
);


ALTER TYPE auth.factor_status OWNER TO supabase_auth_admin;

--
-- Name: factor_type; Type: TYPE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TYPE auth.factor_type AS ENUM (
    'totp',
    'webauthn',
    'phone'
);


ALTER TYPE auth.factor_type OWNER TO supabase_auth_admin;

--
-- Name: oauth_authorization_status; Type: TYPE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TYPE auth.oauth_authorization_status AS ENUM (
    'pending',
    'approved',
    'denied',
    'expired'
);


ALTER TYPE auth.oauth_authorization_status OWNER TO supabase_auth_admin;

--
-- Name: oauth_client_type; Type: TYPE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TYPE auth.oauth_client_type AS ENUM (
    'public',
    'confidential'
);


ALTER TYPE auth.oauth_client_type OWNER TO supabase_auth_admin;

--
-- Name: oauth_registration_type; Type: TYPE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TYPE auth.oauth_registration_type AS ENUM (
    'dynamic',
    'manual'
);


ALTER TYPE auth.oauth_registration_type OWNER TO supabase_auth_admin;

--
-- Name: oauth_response_type; Type: TYPE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TYPE auth.oauth_response_type AS ENUM (
    'code'
);


ALTER TYPE auth.oauth_response_type OWNER TO supabase_auth_admin;

--
-- Name: one_time_token_type; Type: TYPE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TYPE auth.one_time_token_type AS ENUM (
    'confirmation_token',
    'reauthentication_token',
    'recovery_token',
    'email_change_token_new',
    'email_change_token_current',
    'phone_change_token'
);


ALTER TYPE auth.one_time_token_type OWNER TO supabase_auth_admin;

--
-- Name: action; Type: TYPE; Schema: realtime; Owner: supabase_admin
--

CREATE TYPE realtime.action AS ENUM (
    'INSERT',
    'UPDATE',
    'DELETE',
    'TRUNCATE',
    'ERROR'
);


ALTER TYPE realtime.action OWNER TO supabase_admin;

--
-- Name: equality_op; Type: TYPE; Schema: realtime; Owner: supabase_admin
--

CREATE TYPE realtime.equality_op AS ENUM (
    'eq',
    'neq',
    'lt',
    'lte',
    'gt',
    'gte',
    'in'
);


ALTER TYPE realtime.equality_op OWNER TO supabase_admin;

--
-- Name: user_defined_filter; Type: TYPE; Schema: realtime; Owner: supabase_admin
--

CREATE TYPE realtime.user_defined_filter AS (
	column_name text,
	op realtime.equality_op,
	value text
);


ALTER TYPE realtime.user_defined_filter OWNER TO supabase_admin;

--
-- Name: wal_column; Type: TYPE; Schema: realtime; Owner: supabase_admin
--

CREATE TYPE realtime.wal_column AS (
	name text,
	type_name text,
	type_oid oid,
	value jsonb,
	is_pkey boolean,
	is_selectable boolean
);


ALTER TYPE realtime.wal_column OWNER TO supabase_admin;

--
-- Name: wal_rls; Type: TYPE; Schema: realtime; Owner: supabase_admin
--

CREATE TYPE realtime.wal_rls AS (
	wal jsonb,
	is_rls_enabled boolean,
	subscription_ids uuid[],
	errors text[]
);


ALTER TYPE realtime.wal_rls OWNER TO supabase_admin;

--
-- Name: buckettype; Type: TYPE; Schema: storage; Owner: supabase_storage_admin
--

CREATE TYPE storage.buckettype AS ENUM (
    'STANDARD',
    'ANALYTICS'
);


ALTER TYPE storage.buckettype OWNER TO supabase_storage_admin;

--
-- Name: email(); Type: FUNCTION; Schema: auth; Owner: supabase_auth_admin
--

CREATE FUNCTION auth.email() RETURNS text
    LANGUAGE sql STABLE
    AS $$
  select 
  coalesce(
    nullif(current_setting('request.jwt.claim.email', true), ''),
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'email')
  )::text
$$;


ALTER FUNCTION auth.email() OWNER TO supabase_auth_admin;

--
-- Name: FUNCTION email(); Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON FUNCTION auth.email() IS 'Deprecated. Use auth.jwt() -> ''email'' instead.';


--
-- Name: jwt(); Type: FUNCTION; Schema: auth; Owner: supabase_auth_admin
--

CREATE FUNCTION auth.jwt() RETURNS jsonb
    LANGUAGE sql STABLE
    AS $$
  select 
    coalesce(
        nullif(current_setting('request.jwt.claim', true), ''),
        nullif(current_setting('request.jwt.claims', true), '')
    )::jsonb
$$;


ALTER FUNCTION auth.jwt() OWNER TO supabase_auth_admin;

--
-- Name: role(); Type: FUNCTION; Schema: auth; Owner: supabase_auth_admin
--

CREATE FUNCTION auth.role() RETURNS text
    LANGUAGE sql STABLE
    AS $$
  select 
  coalesce(
    nullif(current_setting('request.jwt.claim.role', true), ''),
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'role')
  )::text
$$;


ALTER FUNCTION auth.role() OWNER TO supabase_auth_admin;

--
-- Name: FUNCTION role(); Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON FUNCTION auth.role() IS 'Deprecated. Use auth.jwt() -> ''role'' instead.';


--
-- Name: uid(); Type: FUNCTION; Schema: auth; Owner: supabase_auth_admin
--

CREATE FUNCTION auth.uid() RETURNS uuid
    LANGUAGE sql STABLE
    AS $$
  select 
  coalesce(
    nullif(current_setting('request.jwt.claim.sub', true), ''),
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'sub')
  )::uuid
$$;


ALTER FUNCTION auth.uid() OWNER TO supabase_auth_admin;

--
-- Name: FUNCTION uid(); Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON FUNCTION auth.uid() IS 'Deprecated. Use auth.jwt() -> ''sub'' instead.';


--
-- Name: grant_pg_cron_access(); Type: FUNCTION; Schema: extensions; Owner: supabase_admin
--

CREATE FUNCTION extensions.grant_pg_cron_access() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF EXISTS (
    SELECT
    FROM pg_event_trigger_ddl_commands() AS ev
    JOIN pg_extension AS ext
    ON ev.objid = ext.oid
    WHERE ext.extname = 'pg_cron'
  )
  THEN
    grant usage on schema cron to postgres with grant option;

    alter default privileges in schema cron grant all on tables to postgres with grant option;
    alter default privileges in schema cron grant all on functions to postgres with grant option;
    alter default privileges in schema cron grant all on sequences to postgres with grant option;

    alter default privileges for user supabase_admin in schema cron grant all
        on sequences to postgres with grant option;
    alter default privileges for user supabase_admin in schema cron grant all
        on tables to postgres with grant option;
    alter default privileges for user supabase_admin in schema cron grant all
        on functions to postgres with grant option;

    grant all privileges on all tables in schema cron to postgres with grant option;
    revoke all on table cron.job from postgres;
    grant select on table cron.job to postgres with grant option;
  END IF;
END;
$$;


ALTER FUNCTION extensions.grant_pg_cron_access() OWNER TO supabase_admin;

--
-- Name: FUNCTION grant_pg_cron_access(); Type: COMMENT; Schema: extensions; Owner: supabase_admin
--

COMMENT ON FUNCTION extensions.grant_pg_cron_access() IS 'Grants access to pg_cron';


--
-- Name: grant_pg_graphql_access(); Type: FUNCTION; Schema: extensions; Owner: supabase_admin
--

CREATE FUNCTION extensions.grant_pg_graphql_access() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $_$
DECLARE
    func_is_graphql_resolve bool;
BEGIN
    func_is_graphql_resolve = (
        SELECT n.proname = 'resolve'
        FROM pg_event_trigger_ddl_commands() AS ev
        LEFT JOIN pg_catalog.pg_proc AS n
        ON ev.objid = n.oid
    );

    IF func_is_graphql_resolve
    THEN
        -- Update public wrapper to pass all arguments through to the pg_graphql resolve func
        DROP FUNCTION IF EXISTS graphql_public.graphql;
        create or replace function graphql_public.graphql(
            "operationName" text default null,
            query text default null,
            variables jsonb default null,
            extensions jsonb default null
        )
            returns jsonb
            language sql
        as $$
            select graphql.resolve(
                query := query,
                variables := coalesce(variables, '{}'),
                "operationName" := "operationName",
                extensions := extensions
            );
        $$;

        -- This hook executes when `graphql.resolve` is created. That is not necessarily the last
        -- function in the extension so we need to grant permissions on existing entities AND
        -- update default permissions to any others that are created after `graphql.resolve`
        grant usage on schema graphql to postgres, anon, authenticated, service_role;
        grant select on all tables in schema graphql to postgres, anon, authenticated, service_role;
        grant execute on all functions in schema graphql to postgres, anon, authenticated, service_role;
        grant all on all sequences in schema graphql to postgres, anon, authenticated, service_role;
        alter default privileges in schema graphql grant all on tables to postgres, anon, authenticated, service_role;
        alter default privileges in schema graphql grant all on functions to postgres, anon, authenticated, service_role;
        alter default privileges in schema graphql grant all on sequences to postgres, anon, authenticated, service_role;

        -- Allow postgres role to allow granting usage on graphql and graphql_public schemas to custom roles
        grant usage on schema graphql_public to postgres with grant option;
        grant usage on schema graphql to postgres with grant option;
    END IF;

END;
$_$;


ALTER FUNCTION extensions.grant_pg_graphql_access() OWNER TO supabase_admin;

--
-- Name: FUNCTION grant_pg_graphql_access(); Type: COMMENT; Schema: extensions; Owner: supabase_admin
--

COMMENT ON FUNCTION extensions.grant_pg_graphql_access() IS 'Grants access to pg_graphql';


--
-- Name: grant_pg_net_access(); Type: FUNCTION; Schema: extensions; Owner: supabase_admin
--

CREATE FUNCTION extensions.grant_pg_net_access() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM pg_event_trigger_ddl_commands() AS ev
    JOIN pg_extension AS ext
    ON ev.objid = ext.oid
    WHERE ext.extname = 'pg_net'
  )
  THEN
    IF NOT EXISTS (
      SELECT 1
      FROM pg_roles
      WHERE rolname = 'supabase_functions_admin'
    )
    THEN
      CREATE USER supabase_functions_admin NOINHERIT CREATEROLE LOGIN NOREPLICATION;
    END IF;

    GRANT USAGE ON SCHEMA net TO supabase_functions_admin, postgres, anon, authenticated, service_role;

    IF EXISTS (
      SELECT FROM pg_extension
      WHERE extname = 'pg_net'
      -- all versions in use on existing projects as of 2025-02-20
      -- version 0.12.0 onwards don't need these applied
      AND extversion IN ('0.2', '0.6', '0.7', '0.7.1', '0.8', '0.10.0', '0.11.0')
    ) THEN
      ALTER function net.http_get(url text, params jsonb, headers jsonb, timeout_milliseconds integer) SECURITY DEFINER;
      ALTER function net.http_post(url text, body jsonb, params jsonb, headers jsonb, timeout_milliseconds integer) SECURITY DEFINER;

      ALTER function net.http_get(url text, params jsonb, headers jsonb, timeout_milliseconds integer) SET search_path = net;
      ALTER function net.http_post(url text, body jsonb, params jsonb, headers jsonb, timeout_milliseconds integer) SET search_path = net;

      REVOKE ALL ON FUNCTION net.http_get(url text, params jsonb, headers jsonb, timeout_milliseconds integer) FROM PUBLIC;
      REVOKE ALL ON FUNCTION net.http_post(url text, body jsonb, params jsonb, headers jsonb, timeout_milliseconds integer) FROM PUBLIC;

      GRANT EXECUTE ON FUNCTION net.http_get(url text, params jsonb, headers jsonb, timeout_milliseconds integer) TO supabase_functions_admin, postgres, anon, authenticated, service_role;
      GRANT EXECUTE ON FUNCTION net.http_post(url text, body jsonb, params jsonb, headers jsonb, timeout_milliseconds integer) TO supabase_functions_admin, postgres, anon, authenticated, service_role;
    END IF;
  END IF;
END;
$$;


ALTER FUNCTION extensions.grant_pg_net_access() OWNER TO supabase_admin;

--
-- Name: FUNCTION grant_pg_net_access(); Type: COMMENT; Schema: extensions; Owner: supabase_admin
--

COMMENT ON FUNCTION extensions.grant_pg_net_access() IS 'Grants access to pg_net';


--
-- Name: pgrst_ddl_watch(); Type: FUNCTION; Schema: extensions; Owner: supabase_admin
--

CREATE FUNCTION extensions.pgrst_ddl_watch() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  cmd record;
BEGIN
  FOR cmd IN SELECT * FROM pg_event_trigger_ddl_commands()
  LOOP
    IF cmd.command_tag IN (
      'CREATE SCHEMA', 'ALTER SCHEMA'
    , 'CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO', 'ALTER TABLE'
    , 'CREATE FOREIGN TABLE', 'ALTER FOREIGN TABLE'
    , 'CREATE VIEW', 'ALTER VIEW'
    , 'CREATE MATERIALIZED VIEW', 'ALTER MATERIALIZED VIEW'
    , 'CREATE FUNCTION', 'ALTER FUNCTION'
    , 'CREATE TRIGGER'
    , 'CREATE TYPE', 'ALTER TYPE'
    , 'CREATE RULE'
    , 'COMMENT'
    )
    -- don't notify in case of CREATE TEMP table or other objects created on pg_temp
    AND cmd.schema_name is distinct from 'pg_temp'
    THEN
      NOTIFY pgrst, 'reload schema';
    END IF;
  END LOOP;
END; $$;


ALTER FUNCTION extensions.pgrst_ddl_watch() OWNER TO supabase_admin;

--
-- Name: pgrst_drop_watch(); Type: FUNCTION; Schema: extensions; Owner: supabase_admin
--

CREATE FUNCTION extensions.pgrst_drop_watch() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  obj record;
BEGIN
  FOR obj IN SELECT * FROM pg_event_trigger_dropped_objects()
  LOOP
    IF obj.object_type IN (
      'schema'
    , 'table'
    , 'foreign table'
    , 'view'
    , 'materialized view'
    , 'function'
    , 'trigger'
    , 'type'
    , 'rule'
    )
    AND obj.is_temporary IS false -- no pg_temp objects
    THEN
      NOTIFY pgrst, 'reload schema';
    END IF;
  END LOOP;
END; $$;


ALTER FUNCTION extensions.pgrst_drop_watch() OWNER TO supabase_admin;

--
-- Name: set_graphql_placeholder(); Type: FUNCTION; Schema: extensions; Owner: supabase_admin
--

CREATE FUNCTION extensions.set_graphql_placeholder() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $_$
    DECLARE
    graphql_is_dropped bool;
    BEGIN
    graphql_is_dropped = (
        SELECT ev.schema_name = 'graphql_public'
        FROM pg_event_trigger_dropped_objects() AS ev
        WHERE ev.schema_name = 'graphql_public'
    );

    IF graphql_is_dropped
    THEN
        create or replace function graphql_public.graphql(
            "operationName" text default null,
            query text default null,
            variables jsonb default null,
            extensions jsonb default null
        )
            returns jsonb
            language plpgsql
        as $$
            DECLARE
                server_version float;
            BEGIN
                server_version = (SELECT (SPLIT_PART((select version()), ' ', 2))::float);

                IF server_version >= 14 THEN
                    RETURN jsonb_build_object(
                        'errors', jsonb_build_array(
                            jsonb_build_object(
                                'message', 'pg_graphql extension is not enabled.'
                            )
                        )
                    );
                ELSE
                    RETURN jsonb_build_object(
                        'errors', jsonb_build_array(
                            jsonb_build_object(
                                'message', 'pg_graphql is only available on projects running Postgres 14 onwards.'
                            )
                        )
                    );
                END IF;
            END;
        $$;
    END IF;

    END;
$_$;


ALTER FUNCTION extensions.set_graphql_placeholder() OWNER TO supabase_admin;

--
-- Name: FUNCTION set_graphql_placeholder(); Type: COMMENT; Schema: extensions; Owner: supabase_admin
--

COMMENT ON FUNCTION extensions.set_graphql_placeholder() IS 'Reintroduces placeholder function for graphql_public.graphql';


--
-- Name: get_auth(text); Type: FUNCTION; Schema: pgbouncer; Owner: supabase_admin
--

CREATE FUNCTION pgbouncer.get_auth(p_usename text) RETURNS TABLE(username text, password text)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $_$
begin
    raise debug 'PgBouncer auth request: %', p_usename;

    return query
    select 
        rolname::text, 
        case when rolvaliduntil < now() 
            then null 
            else rolpassword::text 
        end 
    from pg_authid 
    where rolname=$1 and rolcanlogin;
end;
$_$;


ALTER FUNCTION pgbouncer.get_auth(p_usename text) OWNER TO supabase_admin;

--
-- Name: add_cooldown_on_cancel(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.add_cooldown_on_cancel() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  -- Handle cancelled status specifically
  IF NEW.status = 'cancelled'
     AND (OLD.status IS NULL OR OLD.status <> 'cancelled') THEN

    -- Use INSERT ... ON CONFLICT to be idempotent
    INSERT INTO public.match_cooldowns (user_a_fid, user_b_fid, declined_at, cooldown_until)
    VALUES (
      NEW.user_a_fid,
      NEW.user_b_fid,
      NOW(),
      NOW() + INTERVAL '7 days'
    )
    ON CONFLICT (user_a_fid, user_b_fid)
    DO UPDATE SET
      declined_at = NOW(),
      cooldown_until = NOW() + INTERVAL '7 days';

  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION public.add_cooldown_on_cancel() OWNER TO postgres;

--
-- Name: add_cooldown_on_status_change(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.add_cooldown_on_status_change() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  a BIGINT;
  b BIGINT;
BEGIN
  -- Çifti normalize et (küçük -> büyük)
  a := LEAST(NEW.user_a_fid, NEW.user_b_fid);
  b := GREATEST(NEW.user_a_fid, NEW.user_b_fid);

  -- Sadece status değiştiyse ve yeni status 'declined' veya 'cancelled' ise çalış
  IF TG_OP = 'UPDATE'
     AND (OLD.status IS DISTINCT FROM NEW.status)
     AND NEW.status IN ('declined','cancelled')
  THEN
    INSERT INTO match_cooldowns (user_a_fid, user_b_fid, declined_at, cooldown_until)
    VALUES (a, b, NOW(), NOW() + INTERVAL '7 days')
    ON CONFLICT (user_a_fid, user_b_fid)
    DO UPDATE
      SET declined_at   = EXCLUDED.declined_at,
          cooldown_until = EXCLUDED.cooldown_until;
  END IF;

  RETURN NEW;
END
$$;


ALTER FUNCTION public.add_cooldown_on_status_change() OWNER TO postgres;

--
-- Name: add_match_cooldown(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.add_match_cooldown() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_min_fid BIGINT;
    v_max_fid BIGINT;
BEGIN
    IF NEW.status = 'declined' AND (OLD.status IS NULL OR OLD.status IS DISTINCT FROM 'declined') THEN
        v_min_fid := LEAST(NEW.user_a_fid, NEW.user_b_fid);
        v_max_fid := GREATEST(NEW.user_a_fid, NEW.user_b_fid);

        INSERT INTO public.match_cooldowns (
            user_a_fid,
            user_b_fid,
            declined_at,
            cooldown_until
        ) VALUES (
            v_min_fid,
            v_max_fid,
            NOW(),
            NOW() + INTERVAL '7 days'
        )
        ON CONFLICT ((LEAST(user_a_fid, user_b_fid)), (GREATEST(user_a_fid, user_b_fid)))
        DO UPDATE SET
            declined_at = NOW(),
            cooldown_until = GREATEST(
                match_cooldowns.cooldown_until,
                NOW() + INTERVAL '7 days'
            );
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.add_match_cooldown() OWNER TO postgres;

--
-- Name: add_match_cooldown(bigint, bigint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.add_match_cooldown(a_fid bigint, b_fid bigint) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO match_cooldowns (user_a_fid, user_b_fid, declined_at, cooldown_until)
  VALUES (LEAST(a_fid, b_fid), GREATEST(a_fid, b_fid), NOW(), NOW() + interval '7 days')
  ON CONFLICT (user_a_fid, user_b_fid)
  DO UPDATE SET
    declined_at = NOW(),
    cooldown_until = NOW() + interval '7 days';
END;
$$;


ALTER FUNCTION public.add_match_cooldown(a_fid bigint, b_fid bigint) OWNER TO postgres;

--
-- Name: auto_close_expired_rooms(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.auto_close_expired_rooms() RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_expired_count INTEGER;
  v_closed_count INTEGER := 0;
  v_room RECORD;
BEGIN
  -- Get count of expired rooms
  SELECT COUNT(*) INTO v_expired_count
  FROM matches
  WHERE meeting_state IN ('scheduled', 'in_progress')
    AND meeting_expires_at IS NOT NULL
    AND meeting_expires_at < NOW()
    AND meeting_link IS NOT NULL;

  IF v_expired_count = 0 THEN
    RETURN jsonb_build_object(
      'expired_count', 0,
      'closed_count', 0,
      'message', 'No expired rooms to close'
    );
  END IF;

  -- Close each expired room
  FOR v_room IN
    SELECT id FROM matches
    WHERE meeting_state IN ('scheduled', 'in_progress')
      AND meeting_expires_at IS NOT NULL
      AND meeting_expires_at < NOW()
      AND meeting_link IS NOT NULL
  LOOP
    PERFORM close_meeting_room(v_room.id, 'auto_expired');
    v_closed_count := v_closed_count + 1;
  END LOOP;

  RETURN jsonb_build_object(
    'expired_count', v_expired_count,
    'closed_count', v_closed_count,
    'message', format('Auto-closed %s expired room(s)', v_closed_count)
  );
END;
$$;


ALTER FUNCTION public.auto_close_expired_rooms() OWNER TO postgres;

--
-- Name: award_achievement(bigint, text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.award_achievement(p_user_fid bigint, p_code text, p_points integer) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_already_awarded BOOLEAN;
  v_new_total INT;
  v_new_level INT;
  v_new_progress INT;
BEGIN
  -- Check if achievement already awarded
  SELECT EXISTS(
    SELECT 1 FROM user_achievements
    WHERE user_fid = p_user_fid AND code = p_code
  ) INTO v_already_awarded;

  IF v_already_awarded THEN
    -- Already awarded, return current state
    SELECT points_total, level, level_progress
    INTO v_new_total, v_new_level, v_new_progress
    FROM user_levels
    WHERE user_fid = p_user_fid;

    RETURN jsonb_build_object(
      'awarded', false,
      'already_exists', true,
      'points_total', COALESCE(v_new_total, 0),
      'level', COALESCE(v_new_level, 0),
      'level_progress', COALESCE(v_new_progress, 0)
    );
  END IF;

  -- Insert achievement
  INSERT INTO user_achievements (user_fid, code, points)
  VALUES (p_user_fid, p_code, p_points);

  -- Initialize user_levels if not exists
  INSERT INTO user_levels (user_fid, points_total)
  VALUES (p_user_fid, 0)
  ON CONFLICT (user_fid) DO NOTHING;

  -- Update points_total
  UPDATE user_levels
  SET points_total = LEAST(points_total + p_points, 2000)
  WHERE user_fid = p_user_fid;

  -- Get updated values
  SELECT points_total, level, level_progress
  INTO v_new_total, v_new_level, v_new_progress
  FROM user_levels
  WHERE user_fid = p_user_fid;

  RETURN jsonb_build_object(
    'awarded', true,
    'already_exists', false,
    'code', p_code,
    'points', p_points,
    'points_total', v_new_total,
    'level', v_new_level,
    'level_progress', v_new_progress
  );
END;
$$;


ALTER FUNCTION public.award_achievement(p_user_fid bigint, p_code text, p_points integer) OWNER TO postgres;

--
-- Name: calculate_trait_similarity(jsonb, jsonb); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.calculate_trait_similarity(traits_a jsonb, traits_b jsonb) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
DECLARE
    common_count INT;
    total_unique_count INT;
    similarity NUMERIC;
BEGIN
    WITH common AS (
        SELECT COUNT(*) AS cnt
        FROM (
            SELECT jsonb_array_elements_text(traits_a) INTERSECT
            SELECT jsonb_array_elements_text(traits_b)
        ) t
    ),
    total_unique AS (
        SELECT COUNT(*) AS cnt
        FROM (
            SELECT jsonb_array_elements_text(traits_a) UNION
            SELECT jsonb_array_elements_text(traits_b)
        ) t
    )
    SELECT c.cnt, u.cnt
    INTO common_count, total_unique_count
    FROM common c, total_unique u;

    IF total_unique_count = 0 THEN
        RETURN 0;
    END IF;

    similarity := common_count::NUMERIC / total_unique_count::NUMERIC;
    RETURN ROUND(similarity, 3);
END;
$$;


ALTER FUNCTION public.calculate_trait_similarity(traits_a jsonb, traits_b jsonb) OWNER TO postgres;

--
-- Name: check_match_cooldown(bigint, bigint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_match_cooldown(fid_a bigint, fid_b bigint) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
    cooldown_exists BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1
        FROM public.match_cooldowns mc
        WHERE ((mc.user_a_fid = fid_a AND mc.user_b_fid = fid_b)
            OR (mc.user_a_fid = fid_b AND mc.user_b_fid = fid_a))
          AND mc.cooldown_until > NOW()
    )
    INTO cooldown_exists;

    RETURN cooldown_exists;
END;
$$;


ALTER FUNCTION public.check_match_cooldown(fid_a bigint, fid_b bigint) OWNER TO postgres;

--
-- Name: check_match_request_achievements(bigint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_match_request_achievements(p_user_fid bigint) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_unique_count INT;
  v_results JSONB := '[]'::jsonb;
  v_result JSONB;
BEGIN
  -- Count unique recipients this user has sent matches to
  SELECT COUNT(DISTINCT
    CASE
      WHEN created_by_fid = p_user_fid THEN
        CASE
          WHEN user_a_fid = p_user_fid THEN user_b_fid
          ELSE user_a_fid
        END
      ELSE NULL
    END
  )
  INTO v_unique_count
  FROM matches
  WHERE created_by_fid = p_user_fid;

  -- Check thresholds and award
  IF v_unique_count >= 30 THEN
    v_result := award_achievement(p_user_fid, 'sent_30', 100);
    v_results := v_results || jsonb_build_array(v_result);
  END IF;

  IF v_unique_count >= 20 THEN
    v_result := award_achievement(p_user_fid, 'sent_20', 100);
    v_results := v_results || jsonb_build_array(v_result);
  END IF;

  IF v_unique_count >= 10 THEN
    v_result := award_achievement(p_user_fid, 'sent_10', 100);
    v_results := v_results || jsonb_build_array(v_result);
  END IF;

  IF v_unique_count >= 5 THEN
    v_result := award_achievement(p_user_fid, 'sent_5', 100);
    v_results := v_results || jsonb_build_array(v_result);
  END IF;

  RETURN jsonb_build_object(
    'unique_count', v_unique_count,
    'awards', v_results
  );
END;
$$;


ALTER FUNCTION public.check_match_request_achievements(p_user_fid bigint) OWNER TO postgres;

--
-- Name: check_meeting_achievements(bigint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_meeting_achievements(p_user_fid bigint) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_meeting_count INT;
  v_results JSONB := '[]'::jsonb;
  v_result JSONB;
BEGIN
  -- Count completed meetings for this user
  SELECT COUNT(*)
  INTO v_meeting_count
  FROM matches
  WHERE (user_a_fid = p_user_fid OR user_b_fid = p_user_fid)
    AND status = 'completed';

  -- Check thresholds and award
  IF v_meeting_count >= 40 THEN
    v_result := award_achievement(p_user_fid, 'joined_40', 400);
    v_results := v_results || jsonb_build_array(v_result);
  END IF;

  IF v_meeting_count >= 10 THEN
    v_result := award_achievement(p_user_fid, 'joined_10', 400);
    v_results := v_results || jsonb_build_array(v_result);
  END IF;

  IF v_meeting_count >= 5 THEN
    v_result := award_achievement(p_user_fid, 'joined_5', 400);
    v_results := v_results || jsonb_build_array(v_result);
  END IF;

  IF v_meeting_count >= 1 THEN
    v_result := award_achievement(p_user_fid, 'joined_1', 400);
    v_results := v_results || jsonb_build_array(v_result);
  END IF;

  RETURN jsonb_build_object(
    'meeting_count', v_meeting_count,
    'awards', v_results
  );
END;
$$;


ALTER FUNCTION public.check_meeting_achievements(p_user_fid bigint) OWNER TO postgres;

--
-- Name: check_profile_achievements(bigint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_profile_achievements(p_user_fid bigint) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_bio TEXT;
  v_traits JSONB;
  v_bio_result JSONB;
  v_traits_result JSONB;
BEGIN
  -- Get user profile data
  SELECT bio, traits
  INTO v_bio, v_traits
  FROM users
  WHERE fid = p_user_fid;

  -- Initialize result
  v_bio_result := jsonb_build_object('awarded', false);
  v_traits_result := jsonb_build_object('awarded', false);

  -- Check bio achievement
  IF v_bio IS NOT NULL AND LENGTH(TRIM(v_bio)) > 0 THEN
    v_bio_result := award_achievement(p_user_fid, 'bio_done', 50);
  END IF;

  -- Check traits achievement (need at least 5)
  IF v_traits IS NOT NULL AND jsonb_array_length(v_traits) >= 5 THEN
    v_traits_result := award_achievement(p_user_fid, 'traits_done', 50);
  END IF;

  RETURN jsonb_build_object(
    'bio', v_bio_result,
    'traits', v_traits_result
  );
END;
$$;


ALTER FUNCTION public.check_profile_achievements(p_user_fid bigint) OWNER TO postgres;

--
-- Name: check_suggestion_cooldown(bigint, bigint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_suggestion_cooldown(p_user_a_fid bigint, p_user_b_fid bigint) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    v_min_fid BIGINT;
    v_max_fid BIGINT;
    v_cooldown_count INTEGER;
BEGIN
    v_min_fid := LEAST(p_user_a_fid, p_user_b_fid);
    v_max_fid := GREATEST(p_user_a_fid, p_user_b_fid);

    SELECT COUNT(*)
    INTO v_cooldown_count
    FROM match_suggestion_cooldowns
    WHERE LEAST(user_a_fid, user_b_fid) = v_min_fid
      AND GREATEST(user_a_fid, user_b_fid) = v_max_fid
      AND cooldown_until > now();

    RETURN v_cooldown_count = 0;
END;
$$;


ALTER FUNCTION public.check_suggestion_cooldown(p_user_a_fid bigint, p_user_b_fid bigint) OWNER TO postgres;

--
-- Name: cleanup_expired_cooldowns(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.cleanup_expired_cooldowns() RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    deleted_count INT;
BEGIN
    DELETE FROM public.match_cooldowns
    WHERE cooldown_until < NOW();

    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$;


ALTER FUNCTION public.cleanup_expired_cooldowns() OWNER TO postgres;

--
-- Name: close_expired_chat_rooms(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.close_expired_chat_rooms() RETURNS integer
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    closed_count INTEGER;
BEGIN
    WITH updated_rooms AS (
        UPDATE chat_rooms
        SET is_closed = true,
            closed_at = now()
        WHERE is_closed = false
          AND first_join_at IS NOT NULL
          AND now() > (first_join_at + (ttl_seconds || ' seconds')::interval)
        RETURNING id, match_id
    ),
    updated_matches AS (
        UPDATE matches
        SET status = 'completed',
            completed_at = now()
        WHERE id IN (SELECT match_id FROM updated_rooms)
          AND status != 'completed'
        RETURNING id
    )
    SELECT COUNT(*) INTO closed_count FROM updated_rooms;

    RETURN closed_count;
END;
$$;


ALTER FUNCTION public.close_expired_chat_rooms() OWNER TO postgres;

--
-- Name: close_meeting_room(uuid, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.close_meeting_room(p_match_id uuid, p_reason text DEFAULT 'manual'::text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_match RECORD;
  v_both_completed BOOLEAN;
BEGIN
  -- Get match details
  SELECT * INTO v_match
  FROM matches
  WHERE id = p_match_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('error', 'Match not found');
  END IF;

  -- Check if already closed
  IF v_match.meeting_state = 'closed' THEN
    RETURN jsonb_build_object(
      'already_closed', true,
      'closed_at', v_match.meeting_closed_at
    );
  END IF;

  -- Update meeting state to closed
  UPDATE matches
  SET
    meeting_closed_at = NOW(),
    meeting_state = 'closed'
  WHERE id = p_match_id;

  -- Check if both users marked as completed
  v_both_completed := v_match.a_completed AND v_match.b_completed;

  -- If both completed, update match status to completed
  IF v_both_completed AND v_match.status != 'completed' THEN
    UPDATE matches
    SET status = 'completed'
    WHERE id = p_match_id;
  END IF;

  RETURN jsonb_build_object(
    'closed', true,
    'closed_at', NOW(),
    'reason', p_reason,
    'match_status_updated', v_both_completed
  );
END;
$$;


ALTER FUNCTION public.close_meeting_room(p_match_id uuid, p_reason text) OWNER TO postgres;

--
-- Name: count_pending_matches(bigint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.count_pending_matches(user_fid bigint) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    match_count INT;
BEGIN
    SELECT COUNT(*)::INT
    INTO match_count
    FROM public.matches m
    WHERE (m.user_a_fid = user_fid OR m.user_b_fid = user_fid)
      AND m.status IN ('proposed','accepted_by_a','accepted_by_b')
      AND m.created_at > NOW() - INTERVAL '24 hours';

    RETURN match_count;
END;
$$;


ALTER FUNCTION public.count_pending_matches(user_fid bigint) OWNER TO postgres;

--
-- Name: create_initial_match_message(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.create_initial_match_message() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO public.messages (match_id, sender_fid, content, is_system_message)
    VALUES (
        NEW.id,
        NEW.created_by_fid,
        CONCAT('Match created! ',
               (SELECT username FROM public.users WHERE fid = NEW.created_by_fid),
               ' has introduced you both.',
               CASE WHEN NEW.message IS NOT NULL AND NEW.message != ''
                    THEN CONCAT(' Message: ', NEW.message)
                    ELSE ''
               END),
        TRUE
    );
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.create_initial_match_message() OWNER TO postgres;

--
-- Name: create_suggestion_cooldown(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.create_suggestion_cooldown() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
    IF NEW.status = 'declined' AND OLD.status != 'declined' THEN
        INSERT INTO match_suggestion_cooldowns (
            user_a_fid,
            user_b_fid,
            cooldown_until,
            declined_suggestion_id
        ) VALUES (
            LEAST(NEW.user_a_fid, NEW.user_b_fid),
            GREATEST(NEW.user_a_fid, NEW.user_b_fid),
            now() + INTERVAL '7 days',
            NEW.id
        );
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.create_suggestion_cooldown() OWNER TO postgres;

--
-- Name: gen_unique_user_code(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.gen_unique_user_code() RETURNS character
    LANGUAGE plpgsql
    AS $$
DECLARE
  candidate CHAR(10);
  attempts INT := 0;
  max_attempts INT := 100;
BEGIN
  LOOP
    -- Generate random 10-digit number with leading zeros
    candidate := LPAD(FLOOR(RANDOM() * 10000000000)::BIGINT::TEXT, 10, '0');

    -- Exit loop if this code doesn't exist yet
    EXIT WHEN NOT EXISTS (
      SELECT 1 FROM users WHERE user_code = candidate
    );

    -- Safety: prevent infinite loop
    attempts := attempts + 1;
    IF attempts >= max_attempts THEN
      RAISE EXCEPTION 'Failed to generate unique user_code after % attempts', max_attempts;
    END IF;
  END LOOP;

  RETURN candidate;
END;
$$;


ALTER FUNCTION public.gen_unique_user_code() OWNER TO postgres;

--
-- Name: get_expired_meeting_rooms(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_expired_meeting_rooms() RETURNS TABLE(match_id uuid, meeting_link text, meeting_started_at timestamp with time zone, meeting_expires_at timestamp with time zone, minutes_overdue integer)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
  SELECT
    m.id as match_id,
    m.meeting_link,
    m.meeting_started_at,
    m.meeting_expires_at,
    EXTRACT(EPOCH FROM (NOW() - m.meeting_expires_at))::INTEGER / 60 as minutes_overdue
  FROM matches m
  WHERE m.meeting_state IN ('scheduled', 'in_progress')
    AND m.meeting_expires_at IS NOT NULL
    AND m.meeting_expires_at < NOW()
    AND m.meeting_link IS NOT NULL
  ORDER BY m.meeting_expires_at ASC;
END;
$$;


ALTER FUNCTION public.get_expired_meeting_rooms() OWNER TO postgres;

--
-- Name: get_match_cooldown_expiry(bigint, bigint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_match_cooldown_expiry(fid_a bigint, fid_b bigint) RETURNS timestamp with time zone
    LANGUAGE plpgsql
    AS $$
DECLARE
    expiry_time timestamptz;
BEGIN
    SELECT mc.cooldown_until
    INTO expiry_time
    FROM public.match_cooldowns mc
    WHERE ((mc.user_a_fid = fid_a AND mc.user_b_fid = fid_b)
        OR (mc.user_a_fid = fid_b AND mc.user_b_fid = fid_a))
      AND mc.cooldown_until > NOW()
    ORDER BY mc.cooldown_until DESC
    LIMIT 1;

    RETURN expiry_time;
END;
$$;


ALTER FUNCTION public.get_match_cooldown_expiry(fid_a bigint, fid_b bigint) OWNER TO postgres;

--
-- Name: FUNCTION get_match_cooldown_expiry(fid_a bigint, fid_b bigint); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.get_match_cooldown_expiry(fid_a bigint, fid_b bigint) IS 'Returns the cooldown_until timestamp for a user pair if they are currently in cooldown, NULL otherwise';


--
-- Name: get_matchable_users(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_matchable_users() RETURNS TABLE(fid bigint, username text, display_name text, avatar_url text, bio text, traits jsonb)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        u.fid,
        u.username,
        u.display_name,
        u.avatar_url,
        u.bio,
        COALESCE(u.traits, '[]'::jsonb) AS traits
    FROM public.users u
    WHERE u.bio IS NOT NULL
      AND u.bio <> ''
      AND jsonb_array_length(COALESCE(u.traits, '[]'::jsonb)) >= 5
    ORDER BY u.updated_at DESC NULLS LAST;
END;
$$;


ALTER FUNCTION public.get_matchable_users() OWNER TO postgres;

--
-- Name: get_user_achievements(bigint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_user_achievements(p_user_fid bigint) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_result JSONB;
BEGIN
  SELECT COALESCE(jsonb_agg(
    jsonb_build_object(
      'code', code,
      'points', points,
      'awarded_at', awarded_at
    )
    ORDER BY awarded_at ASC
  ), '[]'::jsonb)
  INTO v_result
  FROM user_achievements
  WHERE user_fid = p_user_fid;

  RETURN v_result;
END;
$$;


ALTER FUNCTION public.get_user_achievements(p_user_fid bigint) OWNER TO postgres;

--
-- Name: get_user_level(bigint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_user_level(p_user_fid bigint) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_result JSONB;
BEGIN
  -- Initialize if not exists
  INSERT INTO user_levels (user_fid, points_total)
  VALUES (p_user_fid, 0)
  ON CONFLICT (user_fid) DO NOTHING;

  -- Get level info
  SELECT jsonb_build_object(
    'user_fid', user_fid,
    'points_total', points_total,
    'level', level,
    'level_progress', level_progress,
    'updated_at', updated_at
  )
  INTO v_result
  FROM user_levels
  WHERE user_fid = p_user_fid;

  RETURN v_result;
END;
$$;


ALTER FUNCTION public.get_user_level(p_user_fid bigint) OWNER TO postgres;

--
-- Name: handle_decline_or_cancel(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.handle_decline_or_cancel() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF NEW.status IN ('declined','cancelled')
     AND (OLD.status IS NULL OR OLD.status NOT IN ('declined','cancelled')) THEN

    INSERT INTO public.match_cooldowns (user_a_fid, user_b_fid, declined_at, cooldown_until)
    VALUES (NEW.user_a_fid, NEW.user_b_fid, NOW(), NOW() + INTERVAL '7 days')
    ON CONFLICT (LEAST(user_a_fid,user_b_fid), GREATEST(user_a_fid,user_b_fid))
    DO UPDATE SET
      declined_at   = EXCLUDED.declined_at,
      cooldown_until= EXCLUDED.cooldown_until;
  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION public.handle_decline_or_cancel() OWNER TO postgres;

--
-- Name: handle_match_decline(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.handle_match_decline() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  -- Insert cooldown when match transitions TO 'declined' or 'cancelled'
  -- AND it wasn't already declined/cancelled
  IF NEW.status IN ('declined', 'cancelled')
     AND (OLD.status IS NULL OR OLD.status NOT IN ('declined', 'cancelled')) THEN

    -- Use INSERT ... ON CONFLICT to handle race conditions
    INSERT INTO public.match_cooldowns (user_a_fid, user_b_fid, declined_at, cooldown_until)
    VALUES (
      NEW.user_a_fid,
      NEW.user_b_fid,
      NOW(),
      NOW() + INTERVAL '7 days'
    )
    ON CONFLICT (user_a_fid, user_b_fid)
    DO UPDATE SET
      declined_at = NOW(),
      cooldown_until = NOW() + INTERVAL '7 days';

  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION public.handle_match_decline() OWNER TO postgres;

--
-- Name: is_room_expired(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_room_expired(room_id uuid) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    room_record RECORD;
BEGIN
    SELECT first_join_at, ttl_seconds, is_closed
    INTO room_record
    FROM chat_rooms
    WHERE id = room_id;

    IF NOT FOUND OR room_record.is_closed THEN
        RETURN true;
    END IF;

    IF room_record.first_join_at IS NULL THEN
        RETURN false;
    END IF;

    RETURN now() > (room_record.first_join_at + (room_record.ttl_seconds || ' seconds')::interval);
END;
$$;


ALTER FUNCTION public.is_room_expired(room_id uuid) OWNER TO postgres;

--
-- Name: reload_pgrst_schema(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.reload_pgrst_schema() RETURNS void
    LANGUAGE sql
    AS $$
  NOTIFY pgrst, 'reload schema';
$$;


ALTER FUNCTION public.reload_pgrst_schema() OWNER TO postgres;

--
-- Name: FUNCTION reload_pgrst_schema(); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.reload_pgrst_schema() IS 'Reloads PostgREST schema cache. Call this after DDL changes (ALTER TABLE, etc.) to ensure the API layer sees the latest schema.';


--
-- Name: set_user_code_before_insert(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.set_user_code_before_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  -- Only set if user_code is null
  IF NEW.user_code IS NULL THEN
    NEW.user_code := gen_unique_user_code();
    RAISE NOTICE 'Generated user_code: % for fid: %', NEW.user_code, NEW.fid;
  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.set_user_code_before_insert() OWNER TO postgres;

--
-- Name: start_meeting_timer(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.start_meeting_timer(p_match_id uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_match RECORD;
BEGIN
  -- Get match details
  SELECT * INTO v_match
  FROM matches
  WHERE id = p_match_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('error', 'Match not found');
  END IF;

  -- Only start timer if not already started
  IF v_match.meeting_started_at IS NOT NULL THEN
    RETURN jsonb_build_object(
      'already_started', true,
      'started_at', v_match.meeting_started_at,
      'expires_at', v_match.meeting_expires_at
    );
  END IF;

  -- Set meeting as started, calculate expiry (2 hours)
  UPDATE matches
  SET
    meeting_started_at = NOW(),
    meeting_expires_at = NOW() + INTERVAL '2 hours',
    meeting_state = 'in_progress'
  WHERE id = p_match_id;

  RETURN jsonb_build_object(
    'started', true,
    'started_at', NOW(),
    'expires_at', NOW() + INTERVAL '2 hours'
  );
END;
$$;


ALTER FUNCTION public.start_meeting_timer(p_match_id uuid) OWNER TO postgres;

--
-- Name: trg_match_declined_cooldown(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.trg_match_declined_cooldown() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF (TG_OP = 'UPDATE')
     AND NEW.status = 'declined'
     AND (OLD.status IS DISTINCT FROM NEW.status) THEN
    PERFORM upsert_match_cooldown(NEW.user_a_fid, NEW.user_b_fid, INTERVAL '7 days');
  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.trg_match_declined_cooldown() OWNER TO postgres;

--
-- Name: trg_set_cooldown_on_decline(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.trg_set_cooldown_on_decline() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  -- Sadece 'declined' durumuna geçişte çalış
  IF (TG_OP = 'UPDATE'
      AND NEW.status = 'declined'
      AND (OLD.status IS DISTINCT FROM NEW.status)) THEN
    PERFORM public.upsert_cooldown(NEW.user_a_fid, NEW.user_b_fid, interval '7 days');
  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.trg_set_cooldown_on_decline() OWNER TO postgres;

--
-- Name: update_attestations_updated_at(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_attestations_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_attestations_updated_at() OWNER TO postgres;

--
-- Name: update_match_completion(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_match_completion() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  -- If both users marked as completed, update status
  IF NEW.a_completed = TRUE AND NEW.b_completed = TRUE AND NEW.status = 'accepted' THEN
    NEW.status = 'completed';
    NEW.completed_at = NOW();

    RAISE NOTICE '[Trigger] Match % marked as completed by both users', NEW.id;
  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_match_completion() OWNER TO postgres;

--
-- Name: FUNCTION update_match_completion(); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.update_match_completion() IS 'Automatically sets status to completed when both users mark meeting as complete';


--
-- Name: update_match_status(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_match_status() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.a_accepted IS TRUE AND COALESCE(OLD.a_accepted, FALSE) IS FALSE THEN
        IF COALESCE(NEW.b_accepted, FALSE) IS TRUE THEN
            NEW.status := 'accepted';
        ELSE
            NEW.status := 'accepted_by_a';
        END IF;
    END IF;

    IF NEW.b_accepted IS TRUE AND COALESCE(OLD.b_accepted, FALSE) IS FALSE THEN
        IF COALESCE(NEW.a_accepted, FALSE) IS TRUE THEN
            NEW.status := 'accepted';
        ELSE
            NEW.status := 'accepted_by_b';
        END IF;
    END IF;

    IF COALESCE(NEW.a_accepted, FALSE) IS TRUE
       AND COALESCE(NEW.b_accepted, FALSE) IS TRUE THEN
        NEW.status := 'accepted';
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_match_status() OWNER TO postgres;

--
-- Name: update_suggestion_status(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_suggestion_status() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.a_accepted AND NEW.b_accepted THEN
        NEW.status := 'accepted';
    ELSIF NEW.a_accepted AND NOT NEW.b_accepted THEN
        NEW.status := 'accepted_by_a';
    ELSIF NOT NEW.a_accepted AND NEW.b_accepted THEN
        NEW.status := 'accepted_by_b';
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_suggestion_status() OWNER TO postgres;

--
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_updated_at_column() OWNER TO postgres;

--
-- Name: update_user_levels_timestamp(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_user_levels_timestamp() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_user_levels_timestamp() OWNER TO postgres;

--
-- Name: upsert_cooldown(integer, integer, interval); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.upsert_cooldown(a integer, b integer, ttl interval) RETURNS void
    LANGUAGE sql
    AS $$
  WITH pair AS (
    SELECT LEAST(a, b) AS a1, GREATEST(a, b) AS b1
  )
  INSERT INTO match_cooldowns (user_a_fid, user_b_fid, cooldown_until, declined_at)
  SELECT a1, b1, now() + ttl, now()
  FROM pair
  ON CONFLICT ON CONSTRAINT match_cooldowns_pair_unique
  DO UPDATE SET
    cooldown_until = GREATEST(match_cooldowns.cooldown_until, EXCLUDED.cooldown_until),
    declined_at = now();
$$;


ALTER FUNCTION public.upsert_cooldown(a integer, b integer, ttl interval) OWNER TO postgres;

--
-- Name: upsert_cooldown(bigint, bigint, interval); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.upsert_cooldown(a_fid bigint, b_fid bigint, ttl interval) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
  la bigint := LEAST(a_fid, b_fid);
  gb bigint := GREATEST(a_fid, b_fid);
BEGIN
  INSERT INTO public.match_cooldowns (user_a_fid, user_b_fid, declined_at, cooldown_until)
  VALUES (la, gb, now(), now() + ttl)
  ON CONFLICT ON CONSTRAINT match_cooldowns_pair_unique
  DO UPDATE SET
    declined_at   = now(),
    cooldown_until = GREATEST(public.match_cooldowns.cooldown_until, EXCLUDED.cooldown_until);
END;
$$;


ALTER FUNCTION public.upsert_cooldown(a_fid bigint, b_fid bigint, ttl interval) OWNER TO postgres;

--
-- Name: upsert_match_cooldown(bigint, bigint, interval); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.upsert_match_cooldown(a_fid bigint, b_fid bigint, ttl interval) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
  norm_a bigint := LEAST(a_fid, b_fid);
  norm_b bigint := GREATEST(a_fid, b_fid);
BEGIN
  INSERT INTO match_cooldowns (user_a_fid, user_b_fid, declined_at, cooldown_until)
  VALUES (norm_a, norm_b, NOW(), NOW() + ttl)
  ON CONFLICT (user_a_fid, user_b_fid) DO UPDATE
  SET declined_at    = EXCLUDED.declined_at,
      cooldown_until = GREATEST(match_cooldowns.cooldown_until, EXCLUDED.cooldown_until),
      updated_at     = NOW();
END;
$$;


ALTER FUNCTION public.upsert_match_cooldown(a_fid bigint, b_fid bigint, ttl interval) OWNER TO postgres;

--
-- Name: verify_trigger_fix(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.verify_trigger_fix() RETURNS TABLE(trigger_name text, trigger_timing text, trigger_event text, function_name text)
    LANGUAGE sql
    AS $$
  SELECT
    tgname::TEXT,
    CASE
      WHEN tgtype::INTEGER & 2 = 2 THEN 'BEFORE'
      WHEN tgtype::INTEGER & 1 = 1 THEN 'AFTER'
      ELSE 'UNKNOWN'
    END::TEXT,
    CASE
      WHEN tgtype::INTEGER & 16 = 16 THEN 'UPDATE'
      WHEN tgtype::INTEGER & 8 = 8 THEN 'INSERT'
      WHEN tgtype::INTEGER & 4 = 4 THEN 'DELETE'
      ELSE 'OTHER'
    END::TEXT,
    tgfoid::regprocedure::TEXT
  FROM pg_trigger
  WHERE tgrelid = 'public.matches'::regclass
    AND tgname NOT LIKE 'RI_%'  -- Exclude foreign key triggers
  ORDER BY
    CASE
      WHEN tgtype::INTEGER & 2 = 2 THEN 1  -- BEFORE triggers first
      ELSE 2  -- AFTER triggers second
    END,
    tgname;
$$;


ALTER FUNCTION public.verify_trigger_fix() OWNER TO postgres;

--
-- Name: FUNCTION verify_trigger_fix(); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.verify_trigger_fix() IS 'Helper function to verify trigger order and configuration after applying the fix';


--
-- Name: apply_rls(jsonb, integer); Type: FUNCTION; Schema: realtime; Owner: supabase_admin
--

CREATE FUNCTION realtime.apply_rls(wal jsonb, max_record_bytes integer DEFAULT (1024 * 1024)) RETURNS SETOF realtime.wal_rls
    LANGUAGE plpgsql
    AS $$
declare
-- Regclass of the table e.g. public.notes
entity_ regclass = (quote_ident(wal ->> 'schema') || '.' || quote_ident(wal ->> 'table'))::regclass;

-- I, U, D, T: insert, update ...
action realtime.action = (
    case wal ->> 'action'
        when 'I' then 'INSERT'
        when 'U' then 'UPDATE'
        when 'D' then 'DELETE'
        else 'ERROR'
    end
);

-- Is row level security enabled for the table
is_rls_enabled bool = relrowsecurity from pg_class where oid = entity_;

subscriptions realtime.subscription[] = array_agg(subs)
    from
        realtime.subscription subs
    where
        subs.entity = entity_;

-- Subscription vars
roles regrole[] = array_agg(distinct us.claims_role::text)
    from
        unnest(subscriptions) us;

working_role regrole;
claimed_role regrole;
claims jsonb;

subscription_id uuid;
subscription_has_access bool;
visible_to_subscription_ids uuid[] = '{}';

-- structured info for wal's columns
columns realtime.wal_column[];
-- previous identity values for update/delete
old_columns realtime.wal_column[];

error_record_exceeds_max_size boolean = octet_length(wal::text) > max_record_bytes;

-- Primary jsonb output for record
output jsonb;

begin
perform set_config('role', null, true);

columns =
    array_agg(
        (
            x->>'name',
            x->>'type',
            x->>'typeoid',
            realtime.cast(
                (x->'value') #>> '{}',
                coalesce(
                    (x->>'typeoid')::regtype, -- null when wal2json version <= 2.4
                    (x->>'type')::regtype
                )
            ),
            (pks ->> 'name') is not null,
            true
        )::realtime.wal_column
    )
    from
        jsonb_array_elements(wal -> 'columns') x
        left join jsonb_array_elements(wal -> 'pk') pks
            on (x ->> 'name') = (pks ->> 'name');

old_columns =
    array_agg(
        (
            x->>'name',
            x->>'type',
            x->>'typeoid',
            realtime.cast(
                (x->'value') #>> '{}',
                coalesce(
                    (x->>'typeoid')::regtype, -- null when wal2json version <= 2.4
                    (x->>'type')::regtype
                )
            ),
            (pks ->> 'name') is not null,
            true
        )::realtime.wal_column
    )
    from
        jsonb_array_elements(wal -> 'identity') x
        left join jsonb_array_elements(wal -> 'pk') pks
            on (x ->> 'name') = (pks ->> 'name');

for working_role in select * from unnest(roles) loop

    -- Update `is_selectable` for columns and old_columns
    columns =
        array_agg(
            (
                c.name,
                c.type_name,
                c.type_oid,
                c.value,
                c.is_pkey,
                pg_catalog.has_column_privilege(working_role, entity_, c.name, 'SELECT')
            )::realtime.wal_column
        )
        from
            unnest(columns) c;

    old_columns =
            array_agg(
                (
                    c.name,
                    c.type_name,
                    c.type_oid,
                    c.value,
                    c.is_pkey,
                    pg_catalog.has_column_privilege(working_role, entity_, c.name, 'SELECT')
                )::realtime.wal_column
            )
            from
                unnest(old_columns) c;

    if action <> 'DELETE' and count(1) = 0 from unnest(columns) c where c.is_pkey then
        return next (
            jsonb_build_object(
                'schema', wal ->> 'schema',
                'table', wal ->> 'table',
                'type', action
            ),
            is_rls_enabled,
            -- subscriptions is already filtered by entity
            (select array_agg(s.subscription_id) from unnest(subscriptions) as s where claims_role = working_role),
            array['Error 400: Bad Request, no primary key']
        )::realtime.wal_rls;

    -- The claims role does not have SELECT permission to the primary key of entity
    elsif action <> 'DELETE' and sum(c.is_selectable::int) <> count(1) from unnest(columns) c where c.is_pkey then
        return next (
            jsonb_build_object(
                'schema', wal ->> 'schema',
                'table', wal ->> 'table',
                'type', action
            ),
            is_rls_enabled,
            (select array_agg(s.subscription_id) from unnest(subscriptions) as s where claims_role = working_role),
            array['Error 401: Unauthorized']
        )::realtime.wal_rls;

    else
        output = jsonb_build_object(
            'schema', wal ->> 'schema',
            'table', wal ->> 'table',
            'type', action,
            'commit_timestamp', to_char(
                ((wal ->> 'timestamp')::timestamptz at time zone 'utc'),
                'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'
            ),
            'columns', (
                select
                    jsonb_agg(
                        jsonb_build_object(
                            'name', pa.attname,
                            'type', pt.typname
                        )
                        order by pa.attnum asc
                    )
                from
                    pg_attribute pa
                    join pg_type pt
                        on pa.atttypid = pt.oid
                where
                    attrelid = entity_
                    and attnum > 0
                    and pg_catalog.has_column_privilege(working_role, entity_, pa.attname, 'SELECT')
            )
        )
        -- Add "record" key for insert and update
        || case
            when action in ('INSERT', 'UPDATE') then
                jsonb_build_object(
                    'record',
                    (
                        select
                            jsonb_object_agg(
                                -- if unchanged toast, get column name and value from old record
                                coalesce((c).name, (oc).name),
                                case
                                    when (c).name is null then (oc).value
                                    else (c).value
                                end
                            )
                        from
                            unnest(columns) c
                            full outer join unnest(old_columns) oc
                                on (c).name = (oc).name
                        where
                            coalesce((c).is_selectable, (oc).is_selectable)
                            and ( not error_record_exceeds_max_size or (octet_length((c).value::text) <= 64))
                    )
                )
            else '{}'::jsonb
        end
        -- Add "old_record" key for update and delete
        || case
            when action = 'UPDATE' then
                jsonb_build_object(
                        'old_record',
                        (
                            select jsonb_object_agg((c).name, (c).value)
                            from unnest(old_columns) c
                            where
                                (c).is_selectable
                                and ( not error_record_exceeds_max_size or (octet_length((c).value::text) <= 64))
                        )
                    )
            when action = 'DELETE' then
                jsonb_build_object(
                    'old_record',
                    (
                        select jsonb_object_agg((c).name, (c).value)
                        from unnest(old_columns) c
                        where
                            (c).is_selectable
                            and ( not error_record_exceeds_max_size or (octet_length((c).value::text) <= 64))
                            and ( not is_rls_enabled or (c).is_pkey ) -- if RLS enabled, we can't secure deletes so filter to pkey
                    )
                )
            else '{}'::jsonb
        end;

        -- Create the prepared statement
        if is_rls_enabled and action <> 'DELETE' then
            if (select 1 from pg_prepared_statements where name = 'walrus_rls_stmt' limit 1) > 0 then
                deallocate walrus_rls_stmt;
            end if;
            execute realtime.build_prepared_statement_sql('walrus_rls_stmt', entity_, columns);
        end if;

        visible_to_subscription_ids = '{}';

        for subscription_id, claims in (
                select
                    subs.subscription_id,
                    subs.claims
                from
                    unnest(subscriptions) subs
                where
                    subs.entity = entity_
                    and subs.claims_role = working_role
                    and (
                        realtime.is_visible_through_filters(columns, subs.filters)
                        or (
                          action = 'DELETE'
                          and realtime.is_visible_through_filters(old_columns, subs.filters)
                        )
                    )
        ) loop

            if not is_rls_enabled or action = 'DELETE' then
                visible_to_subscription_ids = visible_to_subscription_ids || subscription_id;
            else
                -- Check if RLS allows the role to see the record
                perform
                    -- Trim leading and trailing quotes from working_role because set_config
                    -- doesn't recognize the role as valid if they are included
                    set_config('role', trim(both '"' from working_role::text), true),
                    set_config('request.jwt.claims', claims::text, true);

                execute 'execute walrus_rls_stmt' into subscription_has_access;

                if subscription_has_access then
                    visible_to_subscription_ids = visible_to_subscription_ids || subscription_id;
                end if;
            end if;
        end loop;

        perform set_config('role', null, true);

        return next (
            output,
            is_rls_enabled,
            visible_to_subscription_ids,
            case
                when error_record_exceeds_max_size then array['Error 413: Payload Too Large']
                else '{}'
            end
        )::realtime.wal_rls;

    end if;
end loop;

perform set_config('role', null, true);
end;
$$;


ALTER FUNCTION realtime.apply_rls(wal jsonb, max_record_bytes integer) OWNER TO supabase_admin;

--
-- Name: broadcast_changes(text, text, text, text, text, record, record, text); Type: FUNCTION; Schema: realtime; Owner: supabase_admin
--

CREATE FUNCTION realtime.broadcast_changes(topic_name text, event_name text, operation text, table_name text, table_schema text, new record, old record, level text DEFAULT 'ROW'::text) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    -- Declare a variable to hold the JSONB representation of the row
    row_data jsonb := '{}'::jsonb;
BEGIN
    IF level = 'STATEMENT' THEN
        RAISE EXCEPTION 'function can only be triggered for each row, not for each statement';
    END IF;
    -- Check the operation type and handle accordingly
    IF operation = 'INSERT' OR operation = 'UPDATE' OR operation = 'DELETE' THEN
        row_data := jsonb_build_object('old_record', OLD, 'record', NEW, 'operation', operation, 'table', table_name, 'schema', table_schema);
        PERFORM realtime.send (row_data, event_name, topic_name);
    ELSE
        RAISE EXCEPTION 'Unexpected operation type: %', operation;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Failed to process the row: %', SQLERRM;
END;

$$;


ALTER FUNCTION realtime.broadcast_changes(topic_name text, event_name text, operation text, table_name text, table_schema text, new record, old record, level text) OWNER TO supabase_admin;

--
-- Name: build_prepared_statement_sql(text, regclass, realtime.wal_column[]); Type: FUNCTION; Schema: realtime; Owner: supabase_admin
--

CREATE FUNCTION realtime.build_prepared_statement_sql(prepared_statement_name text, entity regclass, columns realtime.wal_column[]) RETURNS text
    LANGUAGE sql
    AS $$
      /*
      Builds a sql string that, if executed, creates a prepared statement to
      tests retrive a row from *entity* by its primary key columns.
      Example
          select realtime.build_prepared_statement_sql('public.notes', '{"id"}'::text[], '{"bigint"}'::text[])
      */
          select
      'prepare ' || prepared_statement_name || ' as
          select
              exists(
                  select
                      1
                  from
                      ' || entity || '
                  where
                      ' || string_agg(quote_ident(pkc.name) || '=' || quote_nullable(pkc.value #>> '{}') , ' and ') || '
              )'
          from
              unnest(columns) pkc
          where
              pkc.is_pkey
          group by
              entity
      $$;


ALTER FUNCTION realtime.build_prepared_statement_sql(prepared_statement_name text, entity regclass, columns realtime.wal_column[]) OWNER TO supabase_admin;

--
-- Name: cast(text, regtype); Type: FUNCTION; Schema: realtime; Owner: supabase_admin
--

CREATE FUNCTION realtime."cast"(val text, type_ regtype) RETURNS jsonb
    LANGUAGE plpgsql IMMUTABLE
    AS $$
    declare
      res jsonb;
    begin
      execute format('select to_jsonb(%L::'|| type_::text || ')', val)  into res;
      return res;
    end
    $$;


ALTER FUNCTION realtime."cast"(val text, type_ regtype) OWNER TO supabase_admin;

--
-- Name: check_equality_op(realtime.equality_op, regtype, text, text); Type: FUNCTION; Schema: realtime; Owner: supabase_admin
--

CREATE FUNCTION realtime.check_equality_op(op realtime.equality_op, type_ regtype, val_1 text, val_2 text) RETURNS boolean
    LANGUAGE plpgsql IMMUTABLE
    AS $$
      /*
      Casts *val_1* and *val_2* as type *type_* and check the *op* condition for truthiness
      */
      declare
          op_symbol text = (
              case
                  when op = 'eq' then '='
                  when op = 'neq' then '!='
                  when op = 'lt' then '<'
                  when op = 'lte' then '<='
                  when op = 'gt' then '>'
                  when op = 'gte' then '>='
                  when op = 'in' then '= any'
                  else 'UNKNOWN OP'
              end
          );
          res boolean;
      begin
          execute format(
              'select %L::'|| type_::text || ' ' || op_symbol
              || ' ( %L::'
              || (
                  case
                      when op = 'in' then type_::text || '[]'
                      else type_::text end
              )
              || ')', val_1, val_2) into res;
          return res;
      end;
      $$;


ALTER FUNCTION realtime.check_equality_op(op realtime.equality_op, type_ regtype, val_1 text, val_2 text) OWNER TO supabase_admin;

--
-- Name: is_visible_through_filters(realtime.wal_column[], realtime.user_defined_filter[]); Type: FUNCTION; Schema: realtime; Owner: supabase_admin
--

CREATE FUNCTION realtime.is_visible_through_filters(columns realtime.wal_column[], filters realtime.user_defined_filter[]) RETURNS boolean
    LANGUAGE sql IMMUTABLE
    AS $_$
    /*
    Should the record be visible (true) or filtered out (false) after *filters* are applied
    */
        select
            -- Default to allowed when no filters present
            $2 is null -- no filters. this should not happen because subscriptions has a default
            or array_length($2, 1) is null -- array length of an empty array is null
            or bool_and(
                coalesce(
                    realtime.check_equality_op(
                        op:=f.op,
                        type_:=coalesce(
                            col.type_oid::regtype, -- null when wal2json version <= 2.4
                            col.type_name::regtype
                        ),
                        -- cast jsonb to text
                        val_1:=col.value #>> '{}',
                        val_2:=f.value
                    ),
                    false -- if null, filter does not match
                )
            )
        from
            unnest(filters) f
            join unnest(columns) col
                on f.column_name = col.name;
    $_$;


ALTER FUNCTION realtime.is_visible_through_filters(columns realtime.wal_column[], filters realtime.user_defined_filter[]) OWNER TO supabase_admin;

--
-- Name: list_changes(name, name, integer, integer); Type: FUNCTION; Schema: realtime; Owner: supabase_admin
--

CREATE FUNCTION realtime.list_changes(publication name, slot_name name, max_changes integer, max_record_bytes integer) RETURNS SETOF realtime.wal_rls
    LANGUAGE sql
    SET log_min_messages TO 'fatal'
    AS $$
      with pub as (
        select
          concat_ws(
            ',',
            case when bool_or(pubinsert) then 'insert' else null end,
            case when bool_or(pubupdate) then 'update' else null end,
            case when bool_or(pubdelete) then 'delete' else null end
          ) as w2j_actions,
          coalesce(
            string_agg(
              realtime.quote_wal2json(format('%I.%I', schemaname, tablename)::regclass),
              ','
            ) filter (where ppt.tablename is not null and ppt.tablename not like '% %'),
            ''
          ) w2j_add_tables
        from
          pg_publication pp
          left join pg_publication_tables ppt
            on pp.pubname = ppt.pubname
        where
          pp.pubname = publication
        group by
          pp.pubname
        limit 1
      ),
      w2j as (
        select
          x.*, pub.w2j_add_tables
        from
          pub,
          pg_logical_slot_get_changes(
            slot_name, null, max_changes,
            'include-pk', 'true',
            'include-transaction', 'false',
            'include-timestamp', 'true',
            'include-type-oids', 'true',
            'format-version', '2',
            'actions', pub.w2j_actions,
            'add-tables', pub.w2j_add_tables
          ) x
      )
      select
        xyz.wal,
        xyz.is_rls_enabled,
        xyz.subscription_ids,
        xyz.errors
      from
        w2j,
        realtime.apply_rls(
          wal := w2j.data::jsonb,
          max_record_bytes := max_record_bytes
        ) xyz(wal, is_rls_enabled, subscription_ids, errors)
      where
        w2j.w2j_add_tables <> ''
        and xyz.subscription_ids[1] is not null
    $$;


ALTER FUNCTION realtime.list_changes(publication name, slot_name name, max_changes integer, max_record_bytes integer) OWNER TO supabase_admin;

--
-- Name: quote_wal2json(regclass); Type: FUNCTION; Schema: realtime; Owner: supabase_admin
--

CREATE FUNCTION realtime.quote_wal2json(entity regclass) RETURNS text
    LANGUAGE sql IMMUTABLE STRICT
    AS $$
      select
        (
          select string_agg('' || ch,'')
          from unnest(string_to_array(nsp.nspname::text, null)) with ordinality x(ch, idx)
          where
            not (x.idx = 1 and x.ch = '"')
            and not (
              x.idx = array_length(string_to_array(nsp.nspname::text, null), 1)
              and x.ch = '"'
            )
        )
        || '.'
        || (
          select string_agg('' || ch,'')
          from unnest(string_to_array(pc.relname::text, null)) with ordinality x(ch, idx)
          where
            not (x.idx = 1 and x.ch = '"')
            and not (
              x.idx = array_length(string_to_array(nsp.nspname::text, null), 1)
              and x.ch = '"'
            )
          )
      from
        pg_class pc
        join pg_namespace nsp
          on pc.relnamespace = nsp.oid
      where
        pc.oid = entity
    $$;


ALTER FUNCTION realtime.quote_wal2json(entity regclass) OWNER TO supabase_admin;

--
-- Name: send(jsonb, text, text, boolean); Type: FUNCTION; Schema: realtime; Owner: supabase_admin
--

CREATE FUNCTION realtime.send(payload jsonb, event text, topic text, private boolean DEFAULT true) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
  BEGIN
    -- Set the topic configuration
    EXECUTE format('SET LOCAL realtime.topic TO %L', topic);

    -- Attempt to insert the message
    INSERT INTO realtime.messages (payload, event, topic, private, extension)
    VALUES (payload, event, topic, private, 'broadcast');
  EXCEPTION
    WHEN OTHERS THEN
      -- Capture and notify the error
      RAISE WARNING 'ErrorSendingBroadcastMessage: %', SQLERRM;
  END;
END;
$$;


ALTER FUNCTION realtime.send(payload jsonb, event text, topic text, private boolean) OWNER TO supabase_admin;

--
-- Name: subscription_check_filters(); Type: FUNCTION; Schema: realtime; Owner: supabase_admin
--

CREATE FUNCTION realtime.subscription_check_filters() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    /*
    Validates that the user defined filters for a subscription:
    - refer to valid columns that the claimed role may access
    - values are coercable to the correct column type
    */
    declare
        col_names text[] = coalesce(
                array_agg(c.column_name order by c.ordinal_position),
                '{}'::text[]
            )
            from
                information_schema.columns c
            where
                format('%I.%I', c.table_schema, c.table_name)::regclass = new.entity
                and pg_catalog.has_column_privilege(
                    (new.claims ->> 'role'),
                    format('%I.%I', c.table_schema, c.table_name)::regclass,
                    c.column_name,
                    'SELECT'
                );
        filter realtime.user_defined_filter;
        col_type regtype;

        in_val jsonb;
    begin
        for filter in select * from unnest(new.filters) loop
            -- Filtered column is valid
            if not filter.column_name = any(col_names) then
                raise exception 'invalid column for filter %', filter.column_name;
            end if;

            -- Type is sanitized and safe for string interpolation
            col_type = (
                select atttypid::regtype
                from pg_catalog.pg_attribute
                where attrelid = new.entity
                      and attname = filter.column_name
            );
            if col_type is null then
                raise exception 'failed to lookup type for column %', filter.column_name;
            end if;

            -- Set maximum number of entries for in filter
            if filter.op = 'in'::realtime.equality_op then
                in_val = realtime.cast(filter.value, (col_type::text || '[]')::regtype);
                if coalesce(jsonb_array_length(in_val), 0) > 100 then
                    raise exception 'too many values for `in` filter. Maximum 100';
                end if;
            else
                -- raises an exception if value is not coercable to type
                perform realtime.cast(filter.value, col_type);
            end if;

        end loop;

        -- Apply consistent order to filters so the unique constraint on
        -- (subscription_id, entity, filters) can't be tricked by a different filter order
        new.filters = coalesce(
            array_agg(f order by f.column_name, f.op, f.value),
            '{}'
        ) from unnest(new.filters) f;

        return new;
    end;
    $$;


ALTER FUNCTION realtime.subscription_check_filters() OWNER TO supabase_admin;

--
-- Name: to_regrole(text); Type: FUNCTION; Schema: realtime; Owner: supabase_admin
--

CREATE FUNCTION realtime.to_regrole(role_name text) RETURNS regrole
    LANGUAGE sql IMMUTABLE
    AS $$ select role_name::regrole $$;


ALTER FUNCTION realtime.to_regrole(role_name text) OWNER TO supabase_admin;

--
-- Name: topic(); Type: FUNCTION; Schema: realtime; Owner: supabase_realtime_admin
--

CREATE FUNCTION realtime.topic() RETURNS text
    LANGUAGE sql STABLE
    AS $$
select nullif(current_setting('realtime.topic', true), '')::text;
$$;


ALTER FUNCTION realtime.topic() OWNER TO supabase_realtime_admin;

--
-- Name: add_prefixes(text, text); Type: FUNCTION; Schema: storage; Owner: supabase_storage_admin
--

CREATE FUNCTION storage.add_prefixes(_bucket_id text, _name text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    prefixes text[];
BEGIN
    prefixes := "storage"."get_prefixes"("_name");

    IF array_length(prefixes, 1) > 0 THEN
        INSERT INTO storage.prefixes (name, bucket_id)
        SELECT UNNEST(prefixes) as name, "_bucket_id" ON CONFLICT DO NOTHING;
    END IF;
END;
$$;


ALTER FUNCTION storage.add_prefixes(_bucket_id text, _name text) OWNER TO supabase_storage_admin;

--
-- Name: can_insert_object(text, text, uuid, jsonb); Type: FUNCTION; Schema: storage; Owner: supabase_storage_admin
--

CREATE FUNCTION storage.can_insert_object(bucketid text, name text, owner uuid, metadata jsonb) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO "storage"."objects" ("bucket_id", "name", "owner", "metadata") VALUES (bucketid, name, owner, metadata);
  -- hack to rollback the successful insert
  RAISE sqlstate 'PT200' using
  message = 'ROLLBACK',
  detail = 'rollback successful insert';
END
$$;


ALTER FUNCTION storage.can_insert_object(bucketid text, name text, owner uuid, metadata jsonb) OWNER TO supabase_storage_admin;

--
-- Name: delete_leaf_prefixes(text[], text[]); Type: FUNCTION; Schema: storage; Owner: supabase_storage_admin
--

CREATE FUNCTION storage.delete_leaf_prefixes(bucket_ids text[], names text[]) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    v_rows_deleted integer;
BEGIN
    LOOP
        WITH candidates AS (
            SELECT DISTINCT
                t.bucket_id,
                unnest(storage.get_prefixes(t.name)) AS name
            FROM unnest(bucket_ids, names) AS t(bucket_id, name)
        ),
        uniq AS (
             SELECT
                 bucket_id,
                 name,
                 storage.get_level(name) AS level
             FROM candidates
             WHERE name <> ''
             GROUP BY bucket_id, name
        ),
        leaf AS (
             SELECT
                 p.bucket_id,
                 p.name,
                 p.level
             FROM storage.prefixes AS p
                  JOIN uniq AS u
                       ON u.bucket_id = p.bucket_id
                           AND u.name = p.name
                           AND u.level = p.level
             WHERE NOT EXISTS (
                 SELECT 1
                 FROM storage.objects AS o
                 WHERE o.bucket_id = p.bucket_id
                   AND o.level = p.level + 1
                   AND o.name COLLATE "C" LIKE p.name || '/%'
             )
             AND NOT EXISTS (
                 SELECT 1
                 FROM storage.prefixes AS c
                 WHERE c.bucket_id = p.bucket_id
                   AND c.level = p.level + 1
                   AND c.name COLLATE "C" LIKE p.name || '/%'
             )
        )
        DELETE
        FROM storage.prefixes AS p
            USING leaf AS l
        WHERE p.bucket_id = l.bucket_id
          AND p.name = l.name
          AND p.level = l.level;

        GET DIAGNOSTICS v_rows_deleted = ROW_COUNT;
        EXIT WHEN v_rows_deleted = 0;
    END LOOP;
END;
$$;


ALTER FUNCTION storage.delete_leaf_prefixes(bucket_ids text[], names text[]) OWNER TO supabase_storage_admin;

--
-- Name: delete_prefix(text, text); Type: FUNCTION; Schema: storage; Owner: supabase_storage_admin
--

CREATE FUNCTION storage.delete_prefix(_bucket_id text, _name text) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
    -- Check if we can delete the prefix
    IF EXISTS(
        SELECT FROM "storage"."prefixes"
        WHERE "prefixes"."bucket_id" = "_bucket_id"
          AND level = "storage"."get_level"("_name") + 1
          AND "prefixes"."name" COLLATE "C" LIKE "_name" || '/%'
        LIMIT 1
    )
    OR EXISTS(
        SELECT FROM "storage"."objects"
        WHERE "objects"."bucket_id" = "_bucket_id"
          AND "storage"."get_level"("objects"."name") = "storage"."get_level"("_name") + 1
          AND "objects"."name" COLLATE "C" LIKE "_name" || '/%'
        LIMIT 1
    ) THEN
    -- There are sub-objects, skip deletion
    RETURN false;
    ELSE
        DELETE FROM "storage"."prefixes"
        WHERE "prefixes"."bucket_id" = "_bucket_id"
          AND level = "storage"."get_level"("_name")
          AND "prefixes"."name" = "_name";
        RETURN true;
    END IF;
END;
$$;


ALTER FUNCTION storage.delete_prefix(_bucket_id text, _name text) OWNER TO supabase_storage_admin;

--
-- Name: delete_prefix_hierarchy_trigger(); Type: FUNCTION; Schema: storage; Owner: supabase_storage_admin
--

CREATE FUNCTION storage.delete_prefix_hierarchy_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    prefix text;
BEGIN
    prefix := "storage"."get_prefix"(OLD."name");

    IF coalesce(prefix, '') != '' THEN
        PERFORM "storage"."delete_prefix"(OLD."bucket_id", prefix);
    END IF;

    RETURN OLD;
END;
$$;


ALTER FUNCTION storage.delete_prefix_hierarchy_trigger() OWNER TO supabase_storage_admin;

--
-- Name: enforce_bucket_name_length(); Type: FUNCTION; Schema: storage; Owner: supabase_storage_admin
--

CREATE FUNCTION storage.enforce_bucket_name_length() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
    if length(new.name) > 100 then
        raise exception 'bucket name "%" is too long (% characters). Max is 100.', new.name, length(new.name);
    end if;
    return new;
end;
$$;


ALTER FUNCTION storage.enforce_bucket_name_length() OWNER TO supabase_storage_admin;

--
-- Name: extension(text); Type: FUNCTION; Schema: storage; Owner: supabase_storage_admin
--

CREATE FUNCTION storage.extension(name text) RETURNS text
    LANGUAGE plpgsql IMMUTABLE
    AS $$
DECLARE
    _parts text[];
    _filename text;
BEGIN
    SELECT string_to_array(name, '/') INTO _parts;
    SELECT _parts[array_length(_parts,1)] INTO _filename;
    RETURN reverse(split_part(reverse(_filename), '.', 1));
END
$$;


ALTER FUNCTION storage.extension(name text) OWNER TO supabase_storage_admin;

--
-- Name: filename(text); Type: FUNCTION; Schema: storage; Owner: supabase_storage_admin
--

CREATE FUNCTION storage.filename(name text) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
_parts text[];
BEGIN
	select string_to_array(name, '/') into _parts;
	return _parts[array_length(_parts,1)];
END
$$;


ALTER FUNCTION storage.filename(name text) OWNER TO supabase_storage_admin;

--
-- Name: foldername(text); Type: FUNCTION; Schema: storage; Owner: supabase_storage_admin
--

CREATE FUNCTION storage.foldername(name text) RETURNS text[]
    LANGUAGE plpgsql IMMUTABLE
    AS $$
DECLARE
    _parts text[];
BEGIN
    -- Split on "/" to get path segments
    SELECT string_to_array(name, '/') INTO _parts;
    -- Return everything except the last segment
    RETURN _parts[1 : array_length(_parts,1) - 1];
END
$$;


ALTER FUNCTION storage.foldername(name text) OWNER TO supabase_storage_admin;

--
-- Name: get_level(text); Type: FUNCTION; Schema: storage; Owner: supabase_storage_admin
--

CREATE FUNCTION storage.get_level(name text) RETURNS integer
    LANGUAGE sql IMMUTABLE STRICT
    AS $$
SELECT array_length(string_to_array("name", '/'), 1);
$$;


ALTER FUNCTION storage.get_level(name text) OWNER TO supabase_storage_admin;

--
-- Name: get_prefix(text); Type: FUNCTION; Schema: storage; Owner: supabase_storage_admin
--

CREATE FUNCTION storage.get_prefix(name text) RETURNS text
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
SELECT
    CASE WHEN strpos("name", '/') > 0 THEN
             regexp_replace("name", '[\/]{1}[^\/]+\/?$', '')
         ELSE
             ''
        END;
$_$;


ALTER FUNCTION storage.get_prefix(name text) OWNER TO supabase_storage_admin;

--
-- Name: get_prefixes(text); Type: FUNCTION; Schema: storage; Owner: supabase_storage_admin
--

CREATE FUNCTION storage.get_prefixes(name text) RETURNS text[]
    LANGUAGE plpgsql IMMUTABLE STRICT
    AS $$
DECLARE
    parts text[];
    prefixes text[];
    prefix text;
BEGIN
    -- Split the name into parts by '/'
    parts := string_to_array("name", '/');
    prefixes := '{}';

    -- Construct the prefixes, stopping one level below the last part
    FOR i IN 1..array_length(parts, 1) - 1 LOOP
            prefix := array_to_string(parts[1:i], '/');
            prefixes := array_append(prefixes, prefix);
    END LOOP;

    RETURN prefixes;
END;
$$;


ALTER FUNCTION storage.get_prefixes(name text) OWNER TO supabase_storage_admin;

--
-- Name: get_size_by_bucket(); Type: FUNCTION; Schema: storage; Owner: supabase_storage_admin
--

CREATE FUNCTION storage.get_size_by_bucket() RETURNS TABLE(size bigint, bucket_id text)
    LANGUAGE plpgsql STABLE
    AS $$
BEGIN
    return query
        select sum((metadata->>'size')::bigint) as size, obj.bucket_id
        from "storage".objects as obj
        group by obj.bucket_id;
END
$$;


ALTER FUNCTION storage.get_size_by_bucket() OWNER TO supabase_storage_admin;

--
-- Name: list_multipart_uploads_with_delimiter(text, text, text, integer, text, text); Type: FUNCTION; Schema: storage; Owner: supabase_storage_admin
--

CREATE FUNCTION storage.list_multipart_uploads_with_delimiter(bucket_id text, prefix_param text, delimiter_param text, max_keys integer DEFAULT 100, next_key_token text DEFAULT ''::text, next_upload_token text DEFAULT ''::text) RETURNS TABLE(key text, id text, created_at timestamp with time zone)
    LANGUAGE plpgsql
    AS $_$
BEGIN
    RETURN QUERY EXECUTE
        'SELECT DISTINCT ON(key COLLATE "C") * from (
            SELECT
                CASE
                    WHEN position($2 IN substring(key from length($1) + 1)) > 0 THEN
                        substring(key from 1 for length($1) + position($2 IN substring(key from length($1) + 1)))
                    ELSE
                        key
                END AS key, id, created_at
            FROM
                storage.s3_multipart_uploads
            WHERE
                bucket_id = $5 AND
                key ILIKE $1 || ''%'' AND
                CASE
                    WHEN $4 != '''' AND $6 = '''' THEN
                        CASE
                            WHEN position($2 IN substring(key from length($1) + 1)) > 0 THEN
                                substring(key from 1 for length($1) + position($2 IN substring(key from length($1) + 1))) COLLATE "C" > $4
                            ELSE
                                key COLLATE "C" > $4
                            END
                    ELSE
                        true
                END AND
                CASE
                    WHEN $6 != '''' THEN
                        id COLLATE "C" > $6
                    ELSE
                        true
                    END
            ORDER BY
                key COLLATE "C" ASC, created_at ASC) as e order by key COLLATE "C" LIMIT $3'
        USING prefix_param, delimiter_param, max_keys, next_key_token, bucket_id, next_upload_token;
END;
$_$;


ALTER FUNCTION storage.list_multipart_uploads_with_delimiter(bucket_id text, prefix_param text, delimiter_param text, max_keys integer, next_key_token text, next_upload_token text) OWNER TO supabase_storage_admin;

--
-- Name: list_objects_with_delimiter(text, text, text, integer, text, text); Type: FUNCTION; Schema: storage; Owner: supabase_storage_admin
--

CREATE FUNCTION storage.list_objects_with_delimiter(bucket_id text, prefix_param text, delimiter_param text, max_keys integer DEFAULT 100, start_after text DEFAULT ''::text, next_token text DEFAULT ''::text) RETURNS TABLE(name text, id uuid, metadata jsonb, updated_at timestamp with time zone)
    LANGUAGE plpgsql
    AS $_$
BEGIN
    RETURN QUERY EXECUTE
        'SELECT DISTINCT ON(name COLLATE "C") * from (
            SELECT
                CASE
                    WHEN position($2 IN substring(name from length($1) + 1)) > 0 THEN
                        substring(name from 1 for length($1) + position($2 IN substring(name from length($1) + 1)))
                    ELSE
                        name
                END AS name, id, metadata, updated_at
            FROM
                storage.objects
            WHERE
                bucket_id = $5 AND
                name ILIKE $1 || ''%'' AND
                CASE
                    WHEN $6 != '''' THEN
                    name COLLATE "C" > $6
                ELSE true END
                AND CASE
                    WHEN $4 != '''' THEN
                        CASE
                            WHEN position($2 IN substring(name from length($1) + 1)) > 0 THEN
                                substring(name from 1 for length($1) + position($2 IN substring(name from length($1) + 1))) COLLATE "C" > $4
                            ELSE
                                name COLLATE "C" > $4
                            END
                    ELSE
                        true
                END
            ORDER BY
                name COLLATE "C" ASC) as e order by name COLLATE "C" LIMIT $3'
        USING prefix_param, delimiter_param, max_keys, next_token, bucket_id, start_after;
END;
$_$;


ALTER FUNCTION storage.list_objects_with_delimiter(bucket_id text, prefix_param text, delimiter_param text, max_keys integer, start_after text, next_token text) OWNER TO supabase_storage_admin;

--
-- Name: lock_top_prefixes(text[], text[]); Type: FUNCTION; Schema: storage; Owner: supabase_storage_admin
--

CREATE FUNCTION storage.lock_top_prefixes(bucket_ids text[], names text[]) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    v_bucket text;
    v_top text;
BEGIN
    FOR v_bucket, v_top IN
        SELECT DISTINCT t.bucket_id,
            split_part(t.name, '/', 1) AS top
        FROM unnest(bucket_ids, names) AS t(bucket_id, name)
        WHERE t.name <> ''
        ORDER BY 1, 2
        LOOP
            PERFORM pg_advisory_xact_lock(hashtextextended(v_bucket || '/' || v_top, 0));
        END LOOP;
END;
$$;


ALTER FUNCTION storage.lock_top_prefixes(bucket_ids text[], names text[]) OWNER TO supabase_storage_admin;

--
-- Name: objects_delete_cleanup(); Type: FUNCTION; Schema: storage; Owner: supabase_storage_admin
--

CREATE FUNCTION storage.objects_delete_cleanup() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    v_bucket_ids text[];
    v_names      text[];
BEGIN
    IF current_setting('storage.gc.prefixes', true) = '1' THEN
        RETURN NULL;
    END IF;

    PERFORM set_config('storage.gc.prefixes', '1', true);

    SELECT COALESCE(array_agg(d.bucket_id), '{}'),
           COALESCE(array_agg(d.name), '{}')
    INTO v_bucket_ids, v_names
    FROM deleted AS d
    WHERE d.name <> '';

    PERFORM storage.lock_top_prefixes(v_bucket_ids, v_names);
    PERFORM storage.delete_leaf_prefixes(v_bucket_ids, v_names);

    RETURN NULL;
END;
$$;


ALTER FUNCTION storage.objects_delete_cleanup() OWNER TO supabase_storage_admin;

--
-- Name: objects_insert_prefix_trigger(); Type: FUNCTION; Schema: storage; Owner: supabase_storage_admin
--

CREATE FUNCTION storage.objects_insert_prefix_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    PERFORM "storage"."add_prefixes"(NEW."bucket_id", NEW."name");
    NEW.level := "storage"."get_level"(NEW."name");

    RETURN NEW;
END;
$$;


ALTER FUNCTION storage.objects_insert_prefix_trigger() OWNER TO supabase_storage_admin;

--
-- Name: objects_update_cleanup(); Type: FUNCTION; Schema: storage; Owner: supabase_storage_admin
--

CREATE FUNCTION storage.objects_update_cleanup() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    -- NEW - OLD (destinations to create prefixes for)
    v_add_bucket_ids text[];
    v_add_names      text[];

    -- OLD - NEW (sources to prune)
    v_src_bucket_ids text[];
    v_src_names      text[];
BEGIN
    IF TG_OP <> 'UPDATE' THEN
        RETURN NULL;
    END IF;

    -- 1) Compute NEW−OLD (added paths) and OLD−NEW (moved-away paths)
    WITH added AS (
        SELECT n.bucket_id, n.name
        FROM new_rows n
        WHERE n.name <> '' AND position('/' in n.name) > 0
        EXCEPT
        SELECT o.bucket_id, o.name FROM old_rows o WHERE o.name <> ''
    ),
    moved AS (
         SELECT o.bucket_id, o.name
         FROM old_rows o
         WHERE o.name <> ''
         EXCEPT
         SELECT n.bucket_id, n.name FROM new_rows n WHERE n.name <> ''
    )
    SELECT
        -- arrays for ADDED (dest) in stable order
        COALESCE( (SELECT array_agg(a.bucket_id ORDER BY a.bucket_id, a.name) FROM added a), '{}' ),
        COALESCE( (SELECT array_agg(a.name      ORDER BY a.bucket_id, a.name) FROM added a), '{}' ),
        -- arrays for MOVED (src) in stable order
        COALESCE( (SELECT array_agg(m.bucket_id ORDER BY m.bucket_id, m.name) FROM moved m), '{}' ),
        COALESCE( (SELECT array_agg(m.name      ORDER BY m.bucket_id, m.name) FROM moved m), '{}' )
    INTO v_add_bucket_ids, v_add_names, v_src_bucket_ids, v_src_names;

    -- Nothing to do?
    IF (array_length(v_add_bucket_ids, 1) IS NULL) AND (array_length(v_src_bucket_ids, 1) IS NULL) THEN
        RETURN NULL;
    END IF;

    -- 2) Take per-(bucket, top) locks: ALL prefixes in consistent global order to prevent deadlocks
    DECLARE
        v_all_bucket_ids text[];
        v_all_names text[];
    BEGIN
        -- Combine source and destination arrays for consistent lock ordering
        v_all_bucket_ids := COALESCE(v_src_bucket_ids, '{}') || COALESCE(v_add_bucket_ids, '{}');
        v_all_names := COALESCE(v_src_names, '{}') || COALESCE(v_add_names, '{}');

        -- Single lock call ensures consistent global ordering across all transactions
        IF array_length(v_all_bucket_ids, 1) IS NOT NULL THEN
            PERFORM storage.lock_top_prefixes(v_all_bucket_ids, v_all_names);
        END IF;
    END;

    -- 3) Create destination prefixes (NEW−OLD) BEFORE pruning sources
    IF array_length(v_add_bucket_ids, 1) IS NOT NULL THEN
        WITH candidates AS (
            SELECT DISTINCT t.bucket_id, unnest(storage.get_prefixes(t.name)) AS name
            FROM unnest(v_add_bucket_ids, v_add_names) AS t(bucket_id, name)
            WHERE name <> ''
        )
        INSERT INTO storage.prefixes (bucket_id, name)
        SELECT c.bucket_id, c.name
        FROM candidates c
        ON CONFLICT DO NOTHING;
    END IF;

    -- 4) Prune source prefixes bottom-up for OLD−NEW
    IF array_length(v_src_bucket_ids, 1) IS NOT NULL THEN
        -- re-entrancy guard so DELETE on prefixes won't recurse
        IF current_setting('storage.gc.prefixes', true) <> '1' THEN
            PERFORM set_config('storage.gc.prefixes', '1', true);
        END IF;

        PERFORM storage.delete_leaf_prefixes(v_src_bucket_ids, v_src_names);
    END IF;

    RETURN NULL;
END;
$$;


ALTER FUNCTION storage.objects_update_cleanup() OWNER TO supabase_storage_admin;

--
-- Name: objects_update_level_trigger(); Type: FUNCTION; Schema: storage; Owner: supabase_storage_admin
--

CREATE FUNCTION storage.objects_update_level_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Ensure this is an update operation and the name has changed
    IF TG_OP = 'UPDATE' AND (NEW."name" <> OLD."name" OR NEW."bucket_id" <> OLD."bucket_id") THEN
        -- Set the new level
        NEW."level" := "storage"."get_level"(NEW."name");
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION storage.objects_update_level_trigger() OWNER TO supabase_storage_admin;

--
-- Name: objects_update_prefix_trigger(); Type: FUNCTION; Schema: storage; Owner: supabase_storage_admin
--

CREATE FUNCTION storage.objects_update_prefix_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    old_prefixes TEXT[];
BEGIN
    -- Ensure this is an update operation and the name has changed
    IF TG_OP = 'UPDATE' AND (NEW."name" <> OLD."name" OR NEW."bucket_id" <> OLD."bucket_id") THEN
        -- Retrieve old prefixes
        old_prefixes := "storage"."get_prefixes"(OLD."name");

        -- Remove old prefixes that are only used by this object
        WITH all_prefixes as (
            SELECT unnest(old_prefixes) as prefix
        ),
        can_delete_prefixes as (
             SELECT prefix
             FROM all_prefixes
             WHERE NOT EXISTS (
                 SELECT 1 FROM "storage"."objects"
                 WHERE "bucket_id" = OLD."bucket_id"
                   AND "name" <> OLD."name"
                   AND "name" LIKE (prefix || '%')
             )
         )
        DELETE FROM "storage"."prefixes" WHERE name IN (SELECT prefix FROM can_delete_prefixes);

        -- Add new prefixes
        PERFORM "storage"."add_prefixes"(NEW."bucket_id", NEW."name");
    END IF;
    -- Set the new level
    NEW."level" := "storage"."get_level"(NEW."name");

    RETURN NEW;
END;
$$;


ALTER FUNCTION storage.objects_update_prefix_trigger() OWNER TO supabase_storage_admin;

--
-- Name: operation(); Type: FUNCTION; Schema: storage; Owner: supabase_storage_admin
--

CREATE FUNCTION storage.operation() RETURNS text
    LANGUAGE plpgsql STABLE
    AS $$
BEGIN
    RETURN current_setting('storage.operation', true);
END;
$$;


ALTER FUNCTION storage.operation() OWNER TO supabase_storage_admin;

--
-- Name: prefixes_delete_cleanup(); Type: FUNCTION; Schema: storage; Owner: supabase_storage_admin
--

CREATE FUNCTION storage.prefixes_delete_cleanup() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    v_bucket_ids text[];
    v_names      text[];
BEGIN
    IF current_setting('storage.gc.prefixes', true) = '1' THEN
        RETURN NULL;
    END IF;

    PERFORM set_config('storage.gc.prefixes', '1', true);

    SELECT COALESCE(array_agg(d.bucket_id), '{}'),
           COALESCE(array_agg(d.name), '{}')
    INTO v_bucket_ids, v_names
    FROM deleted AS d
    WHERE d.name <> '';

    PERFORM storage.lock_top_prefixes(v_bucket_ids, v_names);
    PERFORM storage.delete_leaf_prefixes(v_bucket_ids, v_names);

    RETURN NULL;
END;
$$;


ALTER FUNCTION storage.prefixes_delete_cleanup() OWNER TO supabase_storage_admin;

--
-- Name: prefixes_insert_trigger(); Type: FUNCTION; Schema: storage; Owner: supabase_storage_admin
--

CREATE FUNCTION storage.prefixes_insert_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    PERFORM "storage"."add_prefixes"(NEW."bucket_id", NEW."name");
    RETURN NEW;
END;
$$;


ALTER FUNCTION storage.prefixes_insert_trigger() OWNER TO supabase_storage_admin;

--
-- Name: search(text, text, integer, integer, integer, text, text, text); Type: FUNCTION; Schema: storage; Owner: supabase_storage_admin
--

CREATE FUNCTION storage.search(prefix text, bucketname text, limits integer DEFAULT 100, levels integer DEFAULT 1, offsets integer DEFAULT 0, search text DEFAULT ''::text, sortcolumn text DEFAULT 'name'::text, sortorder text DEFAULT 'asc'::text) RETURNS TABLE(name text, id uuid, updated_at timestamp with time zone, created_at timestamp with time zone, last_accessed_at timestamp with time zone, metadata jsonb)
    LANGUAGE plpgsql
    AS $$
declare
    can_bypass_rls BOOLEAN;
begin
    SELECT rolbypassrls
    INTO can_bypass_rls
    FROM pg_roles
    WHERE rolname = coalesce(nullif(current_setting('role', true), 'none'), current_user);

    IF can_bypass_rls THEN
        RETURN QUERY SELECT * FROM storage.search_v1_optimised(prefix, bucketname, limits, levels, offsets, search, sortcolumn, sortorder);
    ELSE
        RETURN QUERY SELECT * FROM storage.search_legacy_v1(prefix, bucketname, limits, levels, offsets, search, sortcolumn, sortorder);
    END IF;
end;
$$;


ALTER FUNCTION storage.search(prefix text, bucketname text, limits integer, levels integer, offsets integer, search text, sortcolumn text, sortorder text) OWNER TO supabase_storage_admin;

--
-- Name: search_legacy_v1(text, text, integer, integer, integer, text, text, text); Type: FUNCTION; Schema: storage; Owner: supabase_storage_admin
--

CREATE FUNCTION storage.search_legacy_v1(prefix text, bucketname text, limits integer DEFAULT 100, levels integer DEFAULT 1, offsets integer DEFAULT 0, search text DEFAULT ''::text, sortcolumn text DEFAULT 'name'::text, sortorder text DEFAULT 'asc'::text) RETURNS TABLE(name text, id uuid, updated_at timestamp with time zone, created_at timestamp with time zone, last_accessed_at timestamp with time zone, metadata jsonb)
    LANGUAGE plpgsql STABLE
    AS $_$
declare
    v_order_by text;
    v_sort_order text;
begin
    case
        when sortcolumn = 'name' then
            v_order_by = 'name';
        when sortcolumn = 'updated_at' then
            v_order_by = 'updated_at';
        when sortcolumn = 'created_at' then
            v_order_by = 'created_at';
        when sortcolumn = 'last_accessed_at' then
            v_order_by = 'last_accessed_at';
        else
            v_order_by = 'name';
        end case;

    case
        when sortorder = 'asc' then
            v_sort_order = 'asc';
        when sortorder = 'desc' then
            v_sort_order = 'desc';
        else
            v_sort_order = 'asc';
        end case;

    v_order_by = v_order_by || ' ' || v_sort_order;

    return query execute
        'with folders as (
           select path_tokens[$1] as folder
           from storage.objects
             where objects.name ilike $2 || $3 || ''%''
               and bucket_id = $4
               and array_length(objects.path_tokens, 1) <> $1
           group by folder
           order by folder ' || v_sort_order || '
     )
     (select folder as "name",
            null as id,
            null as updated_at,
            null as created_at,
            null as last_accessed_at,
            null as metadata from folders)
     union all
     (select path_tokens[$1] as "name",
            id,
            updated_at,
            created_at,
            last_accessed_at,
            metadata
     from storage.objects
     where objects.name ilike $2 || $3 || ''%''
       and bucket_id = $4
       and array_length(objects.path_tokens, 1) = $1
     order by ' || v_order_by || ')
     limit $5
     offset $6' using levels, prefix, search, bucketname, limits, offsets;
end;
$_$;


ALTER FUNCTION storage.search_legacy_v1(prefix text, bucketname text, limits integer, levels integer, offsets integer, search text, sortcolumn text, sortorder text) OWNER TO supabase_storage_admin;

--
-- Name: search_v1_optimised(text, text, integer, integer, integer, text, text, text); Type: FUNCTION; Schema: storage; Owner: supabase_storage_admin
--

CREATE FUNCTION storage.search_v1_optimised(prefix text, bucketname text, limits integer DEFAULT 100, levels integer DEFAULT 1, offsets integer DEFAULT 0, search text DEFAULT ''::text, sortcolumn text DEFAULT 'name'::text, sortorder text DEFAULT 'asc'::text) RETURNS TABLE(name text, id uuid, updated_at timestamp with time zone, created_at timestamp with time zone, last_accessed_at timestamp with time zone, metadata jsonb)
    LANGUAGE plpgsql STABLE
    AS $_$
declare
    v_order_by text;
    v_sort_order text;
begin
    case
        when sortcolumn = 'name' then
            v_order_by = 'name';
        when sortcolumn = 'updated_at' then
            v_order_by = 'updated_at';
        when sortcolumn = 'created_at' then
            v_order_by = 'created_at';
        when sortcolumn = 'last_accessed_at' then
            v_order_by = 'last_accessed_at';
        else
            v_order_by = 'name';
        end case;

    case
        when sortorder = 'asc' then
            v_sort_order = 'asc';
        when sortorder = 'desc' then
            v_sort_order = 'desc';
        else
            v_sort_order = 'asc';
        end case;

    v_order_by = v_order_by || ' ' || v_sort_order;

    return query execute
        'with folders as (
           select (string_to_array(name, ''/''))[level] as name
           from storage.prefixes
             where lower(prefixes.name) like lower($2 || $3) || ''%''
               and bucket_id = $4
               and level = $1
           order by name ' || v_sort_order || '
     )
     (select name,
            null as id,
            null as updated_at,
            null as created_at,
            null as last_accessed_at,
            null as metadata from folders)
     union all
     (select path_tokens[level] as "name",
            id,
            updated_at,
            created_at,
            last_accessed_at,
            metadata
     from storage.objects
     where lower(objects.name) like lower($2 || $3) || ''%''
       and bucket_id = $4
       and level = $1
     order by ' || v_order_by || ')
     limit $5
     offset $6' using levels, prefix, search, bucketname, limits, offsets;
end;
$_$;


ALTER FUNCTION storage.search_v1_optimised(prefix text, bucketname text, limits integer, levels integer, offsets integer, search text, sortcolumn text, sortorder text) OWNER TO supabase_storage_admin;

--
-- Name: search_v2(text, text, integer, integer, text, text, text, text); Type: FUNCTION; Schema: storage; Owner: supabase_storage_admin
--

CREATE FUNCTION storage.search_v2(prefix text, bucket_name text, limits integer DEFAULT 100, levels integer DEFAULT 1, start_after text DEFAULT ''::text, sort_order text DEFAULT 'asc'::text, sort_column text DEFAULT 'name'::text, sort_column_after text DEFAULT ''::text) RETURNS TABLE(key text, name text, id uuid, updated_at timestamp with time zone, created_at timestamp with time zone, last_accessed_at timestamp with time zone, metadata jsonb)
    LANGUAGE plpgsql STABLE
    AS $_$
DECLARE
    sort_col text;
    sort_ord text;
    cursor_op text;
    cursor_expr text;
    sort_expr text;
BEGIN
    -- Validate sort_order
    sort_ord := lower(sort_order);
    IF sort_ord NOT IN ('asc', 'desc') THEN
        sort_ord := 'asc';
    END IF;

    -- Determine cursor comparison operator
    IF sort_ord = 'asc' THEN
        cursor_op := '>';
    ELSE
        cursor_op := '<';
    END IF;
    
    sort_col := lower(sort_column);
    -- Validate sort column  
    IF sort_col IN ('updated_at', 'created_at') THEN
        cursor_expr := format(
            '($5 = '''' OR ROW(date_trunc(''milliseconds'', %I), name COLLATE "C") %s ROW(COALESCE(NULLIF($6, '''')::timestamptz, ''epoch''::timestamptz), $5))',
            sort_col, cursor_op
        );
        sort_expr := format(
            'COALESCE(date_trunc(''milliseconds'', %I), ''epoch''::timestamptz) %s, name COLLATE "C" %s',
            sort_col, sort_ord, sort_ord
        );
    ELSE
        cursor_expr := format('($5 = '''' OR name COLLATE "C" %s $5)', cursor_op);
        sort_expr := format('name COLLATE "C" %s', sort_ord);
    END IF;

    RETURN QUERY EXECUTE format(
        $sql$
        SELECT * FROM (
            (
                SELECT
                    split_part(name, '/', $4) AS key,
                    name,
                    NULL::uuid AS id,
                    updated_at,
                    created_at,
                    NULL::timestamptz AS last_accessed_at,
                    NULL::jsonb AS metadata
                FROM storage.prefixes
                WHERE name COLLATE "C" LIKE $1 || '%%'
                    AND bucket_id = $2
                    AND level = $4
                    AND %s
                ORDER BY %s
                LIMIT $3
            )
            UNION ALL
            (
                SELECT
                    split_part(name, '/', $4) AS key,
                    name,
                    id,
                    updated_at,
                    created_at,
                    last_accessed_at,
                    metadata
                FROM storage.objects
                WHERE name COLLATE "C" LIKE $1 || '%%'
                    AND bucket_id = $2
                    AND level = $4
                    AND %s
                ORDER BY %s
                LIMIT $3
            )
        ) obj
        ORDER BY %s
        LIMIT $3
        $sql$,
        cursor_expr,    -- prefixes WHERE
        sort_expr,      -- prefixes ORDER BY
        cursor_expr,    -- objects WHERE
        sort_expr,      -- objects ORDER BY
        sort_expr       -- final ORDER BY
    )
    USING prefix, bucket_name, limits, levels, start_after, sort_column_after;
END;
$_$;


ALTER FUNCTION storage.search_v2(prefix text, bucket_name text, limits integer, levels integer, start_after text, sort_order text, sort_column text, sort_column_after text) OWNER TO supabase_storage_admin;

--
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: storage; Owner: supabase_storage_admin
--

CREATE FUNCTION storage.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW; 
END;
$$;


ALTER FUNCTION storage.update_updated_at_column() OWNER TO supabase_storage_admin;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: audit_log_entries; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.audit_log_entries (
    instance_id uuid,
    id uuid NOT NULL,
    payload json,
    created_at timestamp with time zone,
    ip_address character varying(64) DEFAULT ''::character varying NOT NULL
);


ALTER TABLE auth.audit_log_entries OWNER TO supabase_auth_admin;

--
-- Name: TABLE audit_log_entries; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON TABLE auth.audit_log_entries IS 'Auth: Audit trail for user actions.';


--
-- Name: flow_state; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.flow_state (
    id uuid NOT NULL,
    user_id uuid,
    auth_code text NOT NULL,
    code_challenge_method auth.code_challenge_method NOT NULL,
    code_challenge text NOT NULL,
    provider_type text NOT NULL,
    provider_access_token text,
    provider_refresh_token text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    authentication_method text NOT NULL,
    auth_code_issued_at timestamp with time zone
);


ALTER TABLE auth.flow_state OWNER TO supabase_auth_admin;

--
-- Name: TABLE flow_state; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON TABLE auth.flow_state IS 'stores metadata for pkce logins';


--
-- Name: identities; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.identities (
    provider_id text NOT NULL,
    user_id uuid NOT NULL,
    identity_data jsonb NOT NULL,
    provider text NOT NULL,
    last_sign_in_at timestamp with time zone,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    email text GENERATED ALWAYS AS (lower((identity_data ->> 'email'::text))) STORED,
    id uuid DEFAULT gen_random_uuid() NOT NULL
);


ALTER TABLE auth.identities OWNER TO supabase_auth_admin;

--
-- Name: TABLE identities; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON TABLE auth.identities IS 'Auth: Stores identities associated to a user.';


--
-- Name: COLUMN identities.email; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON COLUMN auth.identities.email IS 'Auth: Email is a generated column that references the optional email property in the identity_data';


--
-- Name: instances; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.instances (
    id uuid NOT NULL,
    uuid uuid,
    raw_base_config text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


ALTER TABLE auth.instances OWNER TO supabase_auth_admin;

--
-- Name: TABLE instances; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON TABLE auth.instances IS 'Auth: Manages users across multiple sites.';


--
-- Name: mfa_amr_claims; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.mfa_amr_claims (
    session_id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    authentication_method text NOT NULL,
    id uuid NOT NULL
);


ALTER TABLE auth.mfa_amr_claims OWNER TO supabase_auth_admin;

--
-- Name: TABLE mfa_amr_claims; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON TABLE auth.mfa_amr_claims IS 'auth: stores authenticator method reference claims for multi factor authentication';


--
-- Name: mfa_challenges; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.mfa_challenges (
    id uuid NOT NULL,
    factor_id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL,
    verified_at timestamp with time zone,
    ip_address inet NOT NULL,
    otp_code text,
    web_authn_session_data jsonb
);


ALTER TABLE auth.mfa_challenges OWNER TO supabase_auth_admin;

--
-- Name: TABLE mfa_challenges; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON TABLE auth.mfa_challenges IS 'auth: stores metadata about challenge requests made';


--
-- Name: mfa_factors; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.mfa_factors (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    friendly_name text,
    factor_type auth.factor_type NOT NULL,
    status auth.factor_status NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    secret text,
    phone text,
    last_challenged_at timestamp with time zone,
    web_authn_credential jsonb,
    web_authn_aaguid uuid
);


ALTER TABLE auth.mfa_factors OWNER TO supabase_auth_admin;

--
-- Name: TABLE mfa_factors; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON TABLE auth.mfa_factors IS 'auth: stores metadata about factors';


--
-- Name: oauth_authorizations; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.oauth_authorizations (
    id uuid NOT NULL,
    authorization_id text NOT NULL,
    client_id uuid NOT NULL,
    user_id uuid,
    redirect_uri text NOT NULL,
    scope text NOT NULL,
    state text,
    resource text,
    code_challenge text,
    code_challenge_method auth.code_challenge_method,
    response_type auth.oauth_response_type DEFAULT 'code'::auth.oauth_response_type NOT NULL,
    status auth.oauth_authorization_status DEFAULT 'pending'::auth.oauth_authorization_status NOT NULL,
    authorization_code text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    expires_at timestamp with time zone DEFAULT (now() + '00:03:00'::interval) NOT NULL,
    approved_at timestamp with time zone,
    CONSTRAINT oauth_authorizations_authorization_code_length CHECK ((char_length(authorization_code) <= 255)),
    CONSTRAINT oauth_authorizations_code_challenge_length CHECK ((char_length(code_challenge) <= 128)),
    CONSTRAINT oauth_authorizations_expires_at_future CHECK ((expires_at > created_at)),
    CONSTRAINT oauth_authorizations_redirect_uri_length CHECK ((char_length(redirect_uri) <= 2048)),
    CONSTRAINT oauth_authorizations_resource_length CHECK ((char_length(resource) <= 2048)),
    CONSTRAINT oauth_authorizations_scope_length CHECK ((char_length(scope) <= 4096)),
    CONSTRAINT oauth_authorizations_state_length CHECK ((char_length(state) <= 4096))
);


ALTER TABLE auth.oauth_authorizations OWNER TO supabase_auth_admin;

--
-- Name: oauth_clients; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.oauth_clients (
    id uuid NOT NULL,
    client_secret_hash text,
    registration_type auth.oauth_registration_type NOT NULL,
    redirect_uris text NOT NULL,
    grant_types text NOT NULL,
    client_name text,
    client_uri text,
    logo_uri text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone,
    client_type auth.oauth_client_type DEFAULT 'confidential'::auth.oauth_client_type NOT NULL,
    CONSTRAINT oauth_clients_client_name_length CHECK ((char_length(client_name) <= 1024)),
    CONSTRAINT oauth_clients_client_uri_length CHECK ((char_length(client_uri) <= 2048)),
    CONSTRAINT oauth_clients_logo_uri_length CHECK ((char_length(logo_uri) <= 2048))
);


ALTER TABLE auth.oauth_clients OWNER TO supabase_auth_admin;

--
-- Name: oauth_consents; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.oauth_consents (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    client_id uuid NOT NULL,
    scopes text NOT NULL,
    granted_at timestamp with time zone DEFAULT now() NOT NULL,
    revoked_at timestamp with time zone,
    CONSTRAINT oauth_consents_revoked_after_granted CHECK (((revoked_at IS NULL) OR (revoked_at >= granted_at))),
    CONSTRAINT oauth_consents_scopes_length CHECK ((char_length(scopes) <= 2048)),
    CONSTRAINT oauth_consents_scopes_not_empty CHECK ((char_length(TRIM(BOTH FROM scopes)) > 0))
);


ALTER TABLE auth.oauth_consents OWNER TO supabase_auth_admin;

--
-- Name: one_time_tokens; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.one_time_tokens (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    token_type auth.one_time_token_type NOT NULL,
    token_hash text NOT NULL,
    relates_to text NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    CONSTRAINT one_time_tokens_token_hash_check CHECK ((char_length(token_hash) > 0))
);


ALTER TABLE auth.one_time_tokens OWNER TO supabase_auth_admin;

--
-- Name: refresh_tokens; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.refresh_tokens (
    instance_id uuid,
    id bigint NOT NULL,
    token character varying(255),
    user_id character varying(255),
    revoked boolean,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    parent character varying(255),
    session_id uuid
);


ALTER TABLE auth.refresh_tokens OWNER TO supabase_auth_admin;

--
-- Name: TABLE refresh_tokens; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON TABLE auth.refresh_tokens IS 'Auth: Store of tokens used to refresh JWT tokens once they expire.';


--
-- Name: refresh_tokens_id_seq; Type: SEQUENCE; Schema: auth; Owner: supabase_auth_admin
--

CREATE SEQUENCE auth.refresh_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE auth.refresh_tokens_id_seq OWNER TO supabase_auth_admin;

--
-- Name: refresh_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: auth; Owner: supabase_auth_admin
--

ALTER SEQUENCE auth.refresh_tokens_id_seq OWNED BY auth.refresh_tokens.id;


--
-- Name: saml_providers; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.saml_providers (
    id uuid NOT NULL,
    sso_provider_id uuid NOT NULL,
    entity_id text NOT NULL,
    metadata_xml text NOT NULL,
    metadata_url text,
    attribute_mapping jsonb,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    name_id_format text,
    CONSTRAINT "entity_id not empty" CHECK ((char_length(entity_id) > 0)),
    CONSTRAINT "metadata_url not empty" CHECK (((metadata_url = NULL::text) OR (char_length(metadata_url) > 0))),
    CONSTRAINT "metadata_xml not empty" CHECK ((char_length(metadata_xml) > 0))
);


ALTER TABLE auth.saml_providers OWNER TO supabase_auth_admin;

--
-- Name: TABLE saml_providers; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON TABLE auth.saml_providers IS 'Auth: Manages SAML Identity Provider connections.';


--
-- Name: saml_relay_states; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.saml_relay_states (
    id uuid NOT NULL,
    sso_provider_id uuid NOT NULL,
    request_id text NOT NULL,
    for_email text,
    redirect_to text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    flow_state_id uuid,
    CONSTRAINT "request_id not empty" CHECK ((char_length(request_id) > 0))
);


ALTER TABLE auth.saml_relay_states OWNER TO supabase_auth_admin;

--
-- Name: TABLE saml_relay_states; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON TABLE auth.saml_relay_states IS 'Auth: Contains SAML Relay State information for each Service Provider initiated login.';


--
-- Name: schema_migrations; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.schema_migrations (
    version character varying(255) NOT NULL
);


ALTER TABLE auth.schema_migrations OWNER TO supabase_auth_admin;

--
-- Name: TABLE schema_migrations; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON TABLE auth.schema_migrations IS 'Auth: Manages updates to the auth system.';


--
-- Name: sessions; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.sessions (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    factor_id uuid,
    aal auth.aal_level,
    not_after timestamp with time zone,
    refreshed_at timestamp without time zone,
    user_agent text,
    ip inet,
    tag text,
    oauth_client_id uuid
);


ALTER TABLE auth.sessions OWNER TO supabase_auth_admin;

--
-- Name: TABLE sessions; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON TABLE auth.sessions IS 'Auth: Stores session data associated to a user.';


--
-- Name: COLUMN sessions.not_after; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON COLUMN auth.sessions.not_after IS 'Auth: Not after is a nullable column that contains a timestamp after which the session should be regarded as expired.';


--
-- Name: sso_domains; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.sso_domains (
    id uuid NOT NULL,
    sso_provider_id uuid NOT NULL,
    domain text NOT NULL,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    CONSTRAINT "domain not empty" CHECK ((char_length(domain) > 0))
);


ALTER TABLE auth.sso_domains OWNER TO supabase_auth_admin;

--
-- Name: TABLE sso_domains; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON TABLE auth.sso_domains IS 'Auth: Manages SSO email address domain mapping to an SSO Identity Provider.';


--
-- Name: sso_providers; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.sso_providers (
    id uuid NOT NULL,
    resource_id text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    disabled boolean,
    CONSTRAINT "resource_id not empty" CHECK (((resource_id = NULL::text) OR (char_length(resource_id) > 0)))
);


ALTER TABLE auth.sso_providers OWNER TO supabase_auth_admin;

--
-- Name: TABLE sso_providers; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON TABLE auth.sso_providers IS 'Auth: Manages SSO identity provider information; see saml_providers for SAML.';


--
-- Name: COLUMN sso_providers.resource_id; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON COLUMN auth.sso_providers.resource_id IS 'Auth: Uniquely identifies a SSO provider according to a user-chosen resource ID (case insensitive), useful in infrastructure as code.';


--
-- Name: users; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.users (
    instance_id uuid,
    id uuid NOT NULL,
    aud character varying(255),
    role character varying(255),
    email character varying(255),
    encrypted_password character varying(255),
    email_confirmed_at timestamp with time zone,
    invited_at timestamp with time zone,
    confirmation_token character varying(255),
    confirmation_sent_at timestamp with time zone,
    recovery_token character varying(255),
    recovery_sent_at timestamp with time zone,
    email_change_token_new character varying(255),
    email_change character varying(255),
    email_change_sent_at timestamp with time zone,
    last_sign_in_at timestamp with time zone,
    raw_app_meta_data jsonb,
    raw_user_meta_data jsonb,
    is_super_admin boolean,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    phone text DEFAULT NULL::character varying,
    phone_confirmed_at timestamp with time zone,
    phone_change text DEFAULT ''::character varying,
    phone_change_token character varying(255) DEFAULT ''::character varying,
    phone_change_sent_at timestamp with time zone,
    confirmed_at timestamp with time zone GENERATED ALWAYS AS (LEAST(email_confirmed_at, phone_confirmed_at)) STORED,
    email_change_token_current character varying(255) DEFAULT ''::character varying,
    email_change_confirm_status smallint DEFAULT 0,
    banned_until timestamp with time zone,
    reauthentication_token character varying(255) DEFAULT ''::character varying,
    reauthentication_sent_at timestamp with time zone,
    is_sso_user boolean DEFAULT false NOT NULL,
    deleted_at timestamp with time zone,
    is_anonymous boolean DEFAULT false NOT NULL,
    CONSTRAINT users_email_change_confirm_status_check CHECK (((email_change_confirm_status >= 0) AND (email_change_confirm_status <= 2)))
);


ALTER TABLE auth.users OWNER TO supabase_auth_admin;

--
-- Name: TABLE users; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON TABLE auth.users IS 'Auth: Stores user login data within a secure schema.';


--
-- Name: COLUMN users.is_sso_user; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON COLUMN auth.users.is_sso_user IS 'Auth: Set this column to true when the account comes from SSO. These accounts can have duplicate emails.';


--
-- Name: attestations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.attestations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    username text NOT NULL,
    wallet_address text NOT NULL,
    tx_hash text NOT NULL,
    attestation_uid text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    is_demo boolean DEFAULT false,
    fid bigint
);


ALTER TABLE public.attestations OWNER TO postgres;

--
-- Name: TABLE attestations; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.attestations IS 'Stores Ethereum Attestation Service (EAS) attestation records linking usernames to wallet addresses';


--
-- Name: COLUMN attestations.fid; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.attestations.fid IS 'Farcaster ID of the user who owns this attestation';


--
-- Name: auto_match_runs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.auto_match_runs (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    started_at timestamp with time zone DEFAULT now(),
    completed_at timestamp with time zone,
    users_processed integer DEFAULT 0,
    matches_created integer DEFAULT 0,
    status text DEFAULT 'running'::text,
    error_message text,
    CONSTRAINT auto_match_runs_status_check CHECK ((status = ANY (ARRAY['running'::text, 'completed'::text, 'failed'::text])))
);


ALTER TABLE public.auto_match_runs OWNER TO postgres;

--
-- Name: TABLE auto_match_runs; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.auto_match_runs IS 'Logs of automatic matching system runs';


--
-- Name: chat_messages; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.chat_messages (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    room_id uuid NOT NULL,
    sender_fid bigint NOT NULL,
    body text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.chat_messages OWNER TO postgres;

--
-- Name: chat_participants; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.chat_participants (
    room_id uuid NOT NULL,
    fid bigint NOT NULL,
    joined_at timestamp with time zone DEFAULT now() NOT NULL,
    completed_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.chat_participants OWNER TO postgres;

--
-- Name: chat_rooms; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.chat_rooms (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    match_id uuid NOT NULL,
    opened_at timestamp with time zone DEFAULT now() NOT NULL,
    first_join_at timestamp with time zone,
    closed_at timestamp with time zone,
    ttl_seconds integer DEFAULT 7200 NOT NULL,
    is_closed boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.chat_rooms OWNER TO postgres;

--
-- Name: match_cooldowns; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.match_cooldowns (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    user_a_fid bigint NOT NULL,
    user_b_fid bigint NOT NULL,
    declined_at timestamp with time zone DEFAULT now(),
    cooldown_until timestamp with time zone DEFAULT (now() + '7 days'::interval),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT different_users_cooldown CHECK ((user_a_fid <> user_b_fid))
);


ALTER TABLE public.match_cooldowns OWNER TO postgres;

--
-- Name: TABLE match_cooldowns; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.match_cooldowns IS 'Tracks cooldown periods between users after declined matches';


--
-- Name: matches; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.matches (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    user_a_fid bigint NOT NULL,
    user_b_fid bigint NOT NULL,
    created_by_fid bigint NOT NULL,
    status text DEFAULT 'pending'::text NOT NULL,
    message text,
    a_accepted boolean DEFAULT false,
    b_accepted boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    created_by text DEFAULT 'system'::text,
    rationale jsonb,
    meeting_link text,
    scheduled_at timestamp with time zone,
    completed_at timestamp with time zone,
    a_completed boolean DEFAULT false,
    b_completed boolean DEFAULT false,
    meeting_started_at timestamp with time zone,
    meeting_expires_at timestamp with time zone,
    meeting_closed_at timestamp with time zone,
    meeting_state text DEFAULT 'scheduled'::text,
    CONSTRAINT different_users CHECK ((user_a_fid <> user_b_fid)),
    CONSTRAINT matches_meeting_state_check CHECK ((meeting_state = ANY (ARRAY['scheduled'::text, 'in_progress'::text, 'closed'::text]))),
    CONSTRAINT matches_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'proposed'::text, 'pending_external'::text, 'accepted_by_a'::text, 'accepted_by_b'::text, 'accepted'::text, 'declined'::text, 'cancelled'::text, 'completed'::text, 'expired'::text])))
);


ALTER TABLE public.matches OWNER TO postgres;

--
-- Name: TABLE matches; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.matches IS 'Stores match/introduction records between users';


--
-- Name: COLUMN matches.created_by; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.matches.created_by IS 'Either "system" or "admin:<fid>" to track match origin';


--
-- Name: COLUMN matches.rationale; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.matches.rationale IS 'JSON object with trait overlap, bio keywords, and match score';


--
-- Name: COLUMN matches.meeting_link; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.matches.meeting_link IS 'Generated meeting URL after both users accept';


--
-- Name: COLUMN matches.scheduled_at; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.matches.scheduled_at IS 'When the meeting is scheduled to occur';


--
-- Name: COLUMN matches.a_completed; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.matches.a_completed IS 'User A has marked the meeting as completed';


--
-- Name: COLUMN matches.b_completed; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.matches.b_completed IS 'User B has marked the meeting as completed';


--
-- Name: COLUMN matches.meeting_started_at; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.matches.meeting_started_at IS 'When first participant joined the meeting room';


--
-- Name: COLUMN matches.meeting_expires_at; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.matches.meeting_expires_at IS 'When the room should auto-close (started_at + 2 hours)';


--
-- Name: COLUMN matches.meeting_closed_at; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.matches.meeting_closed_at IS 'When the room was actually closed';


--
-- Name: COLUMN matches.meeting_state; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.matches.meeting_state IS 'Room state: scheduled (not started), in_progress (started, not expired), closed (ended or expired)';


--
-- Name: CONSTRAINT matches_status_check ON matches; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON CONSTRAINT matches_status_check ON public.matches IS 'Allowed match statuses: pending (legacy), proposed (internal), pending_external (external Farcaster), accepted_by_a, accepted_by_b, accepted, declined, cancelled, completed, expired';


--
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    fid bigint NOT NULL,
    username text NOT NULL,
    display_name text,
    avatar_url text,
    bio text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    user_code character(10),
    traits jsonb DEFAULT '[]'::jsonb,
    has_joined_meetshipper boolean DEFAULT false NOT NULL,
    CONSTRAINT traits_is_array_chk CHECK ((jsonb_typeof(traits) = 'array'::text)),
    CONSTRAINT traits_length_chk CHECK (((jsonb_array_length(traits) >= 0) AND (jsonb_array_length(traits) <= 10))),
    CONSTRAINT user_code_format_chk CHECK (((user_code ~ '^[0-9]{10}$'::text) OR (user_code IS NULL)))
);


ALTER TABLE public.users OWNER TO postgres;

--
-- Name: TABLE users; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.users IS 'Stores Farcaster user information';


--
-- Name: COLUMN users.bio; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.users.bio IS 'User biography/description (max 500 characters)';


--
-- Name: COLUMN users.user_code; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.users.user_code IS 'Unique 10-digit numeric identifier, automatically generated on insert';


--
-- Name: COLUMN users.traits; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.users.traits IS 'User personality traits/tags as JSONB array (5-10 items from predefined list)';


--
-- Name: COLUMN users.has_joined_meetshipper; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.users.has_joined_meetshipper IS 'True if user has logged into MeetShipper, false if they are only known from Farcaster (external user)';


--
-- Name: match_details; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.match_details AS
 SELECT m.id,
    m.user_a_fid,
    ua.username AS user_a_username,
    ua.display_name AS user_a_display_name,
    ua.avatar_url AS user_a_avatar_url,
    ua.traits AS user_a_traits,
    m.user_b_fid,
    ub.username AS user_b_username,
    ub.display_name AS user_b_display_name,
    ub.avatar_url AS user_b_avatar_url,
    ub.traits AS user_b_traits,
    m.created_by_fid,
    m.created_by,
    uc.username AS creator_username,
    uc.display_name AS creator_display_name,
    uc.avatar_url AS creator_avatar_url,
    m.status,
    m.message,
    m.rationale,
    m.a_accepted,
    m.b_accepted,
    m.a_completed,
    m.b_completed,
    m.meeting_link,
    m.scheduled_at,
    m.completed_at,
    m.created_at,
    m.updated_at
   FROM (((public.matches m
     LEFT JOIN public.users ua ON ((m.user_a_fid = ua.fid)))
     LEFT JOIN public.users ub ON ((m.user_b_fid = ub.fid)))
     LEFT JOIN public.users uc ON ((m.created_by_fid = uc.fid)));


ALTER VIEW public.match_details OWNER TO postgres;

--
-- Name: match_suggestion_cooldowns; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.match_suggestion_cooldowns (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_a_fid bigint NOT NULL,
    user_b_fid bigint NOT NULL,
    cooldown_until timestamp with time zone NOT NULL,
    declined_suggestion_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT cooldown_different_users CHECK ((user_a_fid <> user_b_fid))
);


ALTER TABLE public.match_suggestion_cooldowns OWNER TO postgres;

--
-- Name: match_suggestions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.match_suggestions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_by_fid bigint NOT NULL,
    user_a_fid bigint NOT NULL,
    user_b_fid bigint NOT NULL,
    message text NOT NULL,
    status text DEFAULT 'proposed'::text NOT NULL,
    a_accepted boolean DEFAULT false NOT NULL,
    b_accepted boolean DEFAULT false NOT NULL,
    chat_room_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    rationale jsonb,
    CONSTRAINT different_from_creator CHECK (((created_by_fid <> user_a_fid) AND (created_by_fid <> user_b_fid))),
    CONSTRAINT different_users CHECK ((user_a_fid <> user_b_fid)),
    CONSTRAINT match_suggestions_status_check CHECK ((status = ANY (ARRAY['proposed'::text, 'pending_external'::text, 'accepted_by_a'::text, 'accepted_by_b'::text, 'accepted'::text, 'declined'::text, 'cancelled'::text])))
);


ALTER TABLE public.match_suggestions OWNER TO postgres;

--
-- Name: CONSTRAINT match_suggestions_status_check ON match_suggestions; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON CONSTRAINT match_suggestions_status_check ON public.match_suggestions IS 'Allowed suggestion statuses: proposed (internal), pending_external (external Farcaster), accepted_by_a, accepted_by_b, accepted, declined, cancelled';


--
-- Name: match_suggestions_with_details; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.match_suggestions_with_details AS
 SELECT ms.id,
    ms.created_by_fid,
    ms.user_a_fid,
    ms.user_b_fid,
    ms.message,
    ms.status,
    ms.a_accepted,
    ms.b_accepted,
    ms.chat_room_id,
    ms.created_at,
    ms.updated_at,
    ua.username AS user_a_username,
    ua.display_name AS user_a_display_name,
    ua.avatar_url AS user_a_avatar_url,
    ub.username AS user_b_username,
    ub.display_name AS user_b_display_name,
    ub.avatar_url AS user_b_avatar_url
   FROM ((public.match_suggestions ms
     LEFT JOIN public.users ua ON ((ms.user_a_fid = ua.fid)))
     LEFT JOIN public.users ub ON ((ms.user_b_fid = ub.fid)));


ALTER VIEW public.match_suggestions_with_details OWNER TO postgres;

--
-- Name: messages; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.messages (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    match_id uuid NOT NULL,
    sender_fid bigint NOT NULL,
    content text NOT NULL,
    is_system_message boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.messages OWNER TO postgres;

--
-- Name: TABLE messages; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.messages IS 'Stores chat messages between matched users';


--
-- Name: message_details; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.message_details AS
 SELECT msg.id,
    msg.match_id,
    msg.sender_fid,
    u.username AS sender_username,
    u.display_name AS sender_display_name,
    u.avatar_url AS sender_avatar_url,
    msg.content,
    msg.is_system_message,
    msg.created_at
   FROM (public.messages msg
     LEFT JOIN public.users u ON ((msg.sender_fid = u.fid)));


ALTER VIEW public.message_details OWNER TO postgres;

--
-- Name: user_achievements; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_achievements (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_fid bigint NOT NULL,
    code text NOT NULL,
    points integer NOT NULL,
    awarded_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT user_achievements_code_check CHECK ((code <> ''::text)),
    CONSTRAINT user_achievements_points_check CHECK ((points > 0))
);


ALTER TABLE public.user_achievements OWNER TO postgres;

--
-- Name: TABLE user_achievements; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.user_achievements IS 'Achievement codes:
- bio_done: Fill bio (+50 points)
- traits_done: Fill personal traits (+50 points)
- sent_5: Send match requests to 5 unique users (+100 points)
- sent_10: Send match requests to 10 unique users (+100 points)
- sent_20: Send match requests to 20 unique users (+100 points)
- sent_30: Send match requests to 30 unique users (+100 points)
- joined_1: Join 1 completed meeting (+400 points)
- joined_5: Join 5 completed meetings (+400 points)
- joined_10: Join 10 completed meetings (+400 points)
- joined_40: Join 40 completed meetings (+400 points)

Wave 1: bio_done, traits_done, sent_5 (200 points = Level 2)
Wave 2: sent_10, sent_20, sent_30 (300 points = Level 5)
Wave 3: joined_1, joined_5, joined_10 (1200 points = Level 17)
Wave 4: joined_40 (400 points = Level 20 - MAX)';


--
-- Name: user_friends; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_friends (
    user_fid bigint NOT NULL,
    friend_fid bigint NOT NULL,
    friend_username text NOT NULL,
    friend_display_name text,
    friend_avatar_url text,
    cached_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.user_friends OWNER TO postgres;

--
-- Name: TABLE user_friends; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.user_friends IS 'Caches Farcaster follow relationships';


--
-- Name: user_levels; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_levels (
    user_fid bigint NOT NULL,
    points_total integer DEFAULT 0 NOT NULL,
    level integer GENERATED ALWAYS AS (LEAST(floor(((points_total / 100))::double precision), (20)::double precision)) STORED,
    level_progress integer GENERATED ALWAYS AS (
CASE
    WHEN (points_total >= 2000) THEN 100
    ELSE (points_total % 100)
END) STORED,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT user_levels_points_total_check CHECK ((points_total >= 0))
);


ALTER TABLE public.user_levels OWNER TO postgres;

--
-- Name: user_wallets; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_wallets (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    fid integer NOT NULL,
    wallet_address text NOT NULL,
    chain_id integer NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.user_wallets OWNER TO postgres;

--
-- Name: TABLE user_wallets; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.user_wallets IS 'Stores wallet addresses linked to Farcaster users';


--
-- Name: COLUMN user_wallets.fid; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.user_wallets.fid IS 'Farcaster ID of the user';


--
-- Name: COLUMN user_wallets.wallet_address; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.user_wallets.wallet_address IS 'Ethereum wallet address (0x...)';


--
-- Name: COLUMN user_wallets.chain_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.user_wallets.chain_id IS 'Chain ID (8453 for Base, 84532 for Base Sepolia)';


--
-- Name: messages; Type: TABLE; Schema: realtime; Owner: supabase_realtime_admin
--

CREATE TABLE realtime.messages (
    topic text NOT NULL,
    extension text NOT NULL,
    payload jsonb,
    event text,
    private boolean DEFAULT false,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    inserted_at timestamp without time zone DEFAULT now() NOT NULL,
    id uuid DEFAULT gen_random_uuid() NOT NULL
)
PARTITION BY RANGE (inserted_at);


ALTER TABLE realtime.messages OWNER TO supabase_realtime_admin;

--
-- Name: messages_2025_10_26; Type: TABLE; Schema: realtime; Owner: supabase_admin
--

CREATE TABLE realtime.messages_2025_10_26 (
    topic text NOT NULL,
    extension text NOT NULL,
    payload jsonb,
    event text,
    private boolean DEFAULT false,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    inserted_at timestamp without time zone DEFAULT now() NOT NULL,
    id uuid DEFAULT gen_random_uuid() NOT NULL
);


ALTER TABLE realtime.messages_2025_10_26 OWNER TO supabase_admin;

--
-- Name: messages_2025_10_27; Type: TABLE; Schema: realtime; Owner: supabase_admin
--

CREATE TABLE realtime.messages_2025_10_27 (
    topic text NOT NULL,
    extension text NOT NULL,
    payload jsonb,
    event text,
    private boolean DEFAULT false,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    inserted_at timestamp without time zone DEFAULT now() NOT NULL,
    id uuid DEFAULT gen_random_uuid() NOT NULL
);


ALTER TABLE realtime.messages_2025_10_27 OWNER TO supabase_admin;

--
-- Name: messages_2025_10_28; Type: TABLE; Schema: realtime; Owner: supabase_admin
--

CREATE TABLE realtime.messages_2025_10_28 (
    topic text NOT NULL,
    extension text NOT NULL,
    payload jsonb,
    event text,
    private boolean DEFAULT false,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    inserted_at timestamp without time zone DEFAULT now() NOT NULL,
    id uuid DEFAULT gen_random_uuid() NOT NULL
);


ALTER TABLE realtime.messages_2025_10_28 OWNER TO supabase_admin;

--
-- Name: messages_2025_10_29; Type: TABLE; Schema: realtime; Owner: supabase_admin
--

CREATE TABLE realtime.messages_2025_10_29 (
    topic text NOT NULL,
    extension text NOT NULL,
    payload jsonb,
    event text,
    private boolean DEFAULT false,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    inserted_at timestamp without time zone DEFAULT now() NOT NULL,
    id uuid DEFAULT gen_random_uuid() NOT NULL
);


ALTER TABLE realtime.messages_2025_10_29 OWNER TO supabase_admin;

--
-- Name: messages_2025_10_30; Type: TABLE; Schema: realtime; Owner: supabase_admin
--

CREATE TABLE realtime.messages_2025_10_30 (
    topic text NOT NULL,
    extension text NOT NULL,
    payload jsonb,
    event text,
    private boolean DEFAULT false,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    inserted_at timestamp without time zone DEFAULT now() NOT NULL,
    id uuid DEFAULT gen_random_uuid() NOT NULL
);


ALTER TABLE realtime.messages_2025_10_30 OWNER TO supabase_admin;

--
-- Name: messages_2025_10_31; Type: TABLE; Schema: realtime; Owner: supabase_admin
--

CREATE TABLE realtime.messages_2025_10_31 (
    topic text NOT NULL,
    extension text NOT NULL,
    payload jsonb,
    event text,
    private boolean DEFAULT false,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    inserted_at timestamp without time zone DEFAULT now() NOT NULL,
    id uuid DEFAULT gen_random_uuid() NOT NULL
);


ALTER TABLE realtime.messages_2025_10_31 OWNER TO supabase_admin;

--
-- Name: messages_2025_11_01; Type: TABLE; Schema: realtime; Owner: supabase_admin
--

CREATE TABLE realtime.messages_2025_11_01 (
    topic text NOT NULL,
    extension text NOT NULL,
    payload jsonb,
    event text,
    private boolean DEFAULT false,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    inserted_at timestamp without time zone DEFAULT now() NOT NULL,
    id uuid DEFAULT gen_random_uuid() NOT NULL
);


ALTER TABLE realtime.messages_2025_11_01 OWNER TO supabase_admin;

--
-- Name: schema_migrations; Type: TABLE; Schema: realtime; Owner: supabase_admin
--

CREATE TABLE realtime.schema_migrations (
    version bigint NOT NULL,
    inserted_at timestamp(0) without time zone
);


ALTER TABLE realtime.schema_migrations OWNER TO supabase_admin;

--
-- Name: subscription; Type: TABLE; Schema: realtime; Owner: supabase_admin
--

CREATE TABLE realtime.subscription (
    id bigint NOT NULL,
    subscription_id uuid NOT NULL,
    entity regclass NOT NULL,
    filters realtime.user_defined_filter[] DEFAULT '{}'::realtime.user_defined_filter[] NOT NULL,
    claims jsonb NOT NULL,
    claims_role regrole GENERATED ALWAYS AS (realtime.to_regrole((claims ->> 'role'::text))) STORED NOT NULL,
    created_at timestamp without time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);


ALTER TABLE realtime.subscription OWNER TO supabase_admin;

--
-- Name: subscription_id_seq; Type: SEQUENCE; Schema: realtime; Owner: supabase_admin
--

ALTER TABLE realtime.subscription ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME realtime.subscription_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: buckets; Type: TABLE; Schema: storage; Owner: supabase_storage_admin
--

CREATE TABLE storage.buckets (
    id text NOT NULL,
    name text NOT NULL,
    owner uuid,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    public boolean DEFAULT false,
    avif_autodetection boolean DEFAULT false,
    file_size_limit bigint,
    allowed_mime_types text[],
    owner_id text,
    type storage.buckettype DEFAULT 'STANDARD'::storage.buckettype NOT NULL
);


ALTER TABLE storage.buckets OWNER TO supabase_storage_admin;

--
-- Name: COLUMN buckets.owner; Type: COMMENT; Schema: storage; Owner: supabase_storage_admin
--

COMMENT ON COLUMN storage.buckets.owner IS 'Field is deprecated, use owner_id instead';


--
-- Name: buckets_analytics; Type: TABLE; Schema: storage; Owner: supabase_storage_admin
--

CREATE TABLE storage.buckets_analytics (
    id text NOT NULL,
    type storage.buckettype DEFAULT 'ANALYTICS'::storage.buckettype NOT NULL,
    format text DEFAULT 'ICEBERG'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE storage.buckets_analytics OWNER TO supabase_storage_admin;

--
-- Name: migrations; Type: TABLE; Schema: storage; Owner: supabase_storage_admin
--

CREATE TABLE storage.migrations (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    hash character varying(40) NOT NULL,
    executed_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE storage.migrations OWNER TO supabase_storage_admin;

--
-- Name: objects; Type: TABLE; Schema: storage; Owner: supabase_storage_admin
--

CREATE TABLE storage.objects (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    bucket_id text,
    name text,
    owner uuid,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    last_accessed_at timestamp with time zone DEFAULT now(),
    metadata jsonb,
    path_tokens text[] GENERATED ALWAYS AS (string_to_array(name, '/'::text)) STORED,
    version text,
    owner_id text,
    user_metadata jsonb,
    level integer
);


ALTER TABLE storage.objects OWNER TO supabase_storage_admin;

--
-- Name: COLUMN objects.owner; Type: COMMENT; Schema: storage; Owner: supabase_storage_admin
--

COMMENT ON COLUMN storage.objects.owner IS 'Field is deprecated, use owner_id instead';


--
-- Name: prefixes; Type: TABLE; Schema: storage; Owner: supabase_storage_admin
--

CREATE TABLE storage.prefixes (
    bucket_id text NOT NULL,
    name text NOT NULL COLLATE pg_catalog."C",
    level integer GENERATED ALWAYS AS (storage.get_level(name)) STORED NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE storage.prefixes OWNER TO supabase_storage_admin;

--
-- Name: s3_multipart_uploads; Type: TABLE; Schema: storage; Owner: supabase_storage_admin
--

CREATE TABLE storage.s3_multipart_uploads (
    id text NOT NULL,
    in_progress_size bigint DEFAULT 0 NOT NULL,
    upload_signature text NOT NULL,
    bucket_id text NOT NULL,
    key text NOT NULL COLLATE pg_catalog."C",
    version text NOT NULL,
    owner_id text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    user_metadata jsonb
);


ALTER TABLE storage.s3_multipart_uploads OWNER TO supabase_storage_admin;

--
-- Name: s3_multipart_uploads_parts; Type: TABLE; Schema: storage; Owner: supabase_storage_admin
--

CREATE TABLE storage.s3_multipart_uploads_parts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    upload_id text NOT NULL,
    size bigint DEFAULT 0 NOT NULL,
    part_number integer NOT NULL,
    bucket_id text NOT NULL,
    key text NOT NULL COLLATE pg_catalog."C",
    etag text NOT NULL,
    owner_id text,
    version text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE storage.s3_multipart_uploads_parts OWNER TO supabase_storage_admin;

--
-- Name: messages_2025_10_26; Type: TABLE ATTACH; Schema: realtime; Owner: supabase_admin
--

ALTER TABLE ONLY realtime.messages ATTACH PARTITION realtime.messages_2025_10_26 FOR VALUES FROM ('2025-10-26 00:00:00') TO ('2025-10-27 00:00:00');


--
-- Name: messages_2025_10_27; Type: TABLE ATTACH; Schema: realtime; Owner: supabase_admin
--

ALTER TABLE ONLY realtime.messages ATTACH PARTITION realtime.messages_2025_10_27 FOR VALUES FROM ('2025-10-27 00:00:00') TO ('2025-10-28 00:00:00');


--
-- Name: messages_2025_10_28; Type: TABLE ATTACH; Schema: realtime; Owner: supabase_admin
--

ALTER TABLE ONLY realtime.messages ATTACH PARTITION realtime.messages_2025_10_28 FOR VALUES FROM ('2025-10-28 00:00:00') TO ('2025-10-29 00:00:00');


--
-- Name: messages_2025_10_29; Type: TABLE ATTACH; Schema: realtime; Owner: supabase_admin
--

ALTER TABLE ONLY realtime.messages ATTACH PARTITION realtime.messages_2025_10_29 FOR VALUES FROM ('2025-10-29 00:00:00') TO ('2025-10-30 00:00:00');


--
-- Name: messages_2025_10_30; Type: TABLE ATTACH; Schema: realtime; Owner: supabase_admin
--

ALTER TABLE ONLY realtime.messages ATTACH PARTITION realtime.messages_2025_10_30 FOR VALUES FROM ('2025-10-30 00:00:00') TO ('2025-10-31 00:00:00');


--
-- Name: messages_2025_10_31; Type: TABLE ATTACH; Schema: realtime; Owner: supabase_admin
--

ALTER TABLE ONLY realtime.messages ATTACH PARTITION realtime.messages_2025_10_31 FOR VALUES FROM ('2025-10-31 00:00:00') TO ('2025-11-01 00:00:00');


--
-- Name: messages_2025_11_01; Type: TABLE ATTACH; Schema: realtime; Owner: supabase_admin
--

ALTER TABLE ONLY realtime.messages ATTACH PARTITION realtime.messages_2025_11_01 FOR VALUES FROM ('2025-11-01 00:00:00') TO ('2025-11-02 00:00:00');


--
-- Name: refresh_tokens id; Type: DEFAULT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.refresh_tokens ALTER COLUMN id SET DEFAULT nextval('auth.refresh_tokens_id_seq'::regclass);


--
-- Data for Name: audit_log_entries; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) FROM stdin;
\.


--
-- Data for Name: flow_state; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.flow_state (id, user_id, auth_code, code_challenge_method, code_challenge, provider_type, provider_access_token, provider_refresh_token, created_at, updated_at, authentication_method, auth_code_issued_at) FROM stdin;
\.


--
-- Data for Name: identities; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.identities (provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, id) FROM stdin;
\.


--
-- Data for Name: instances; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.instances (id, uuid, raw_base_config, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: mfa_amr_claims; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) FROM stdin;
\.


--
-- Data for Name: mfa_challenges; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.mfa_challenges (id, factor_id, created_at, verified_at, ip_address, otp_code, web_authn_session_data) FROM stdin;
\.


--
-- Data for Name: mfa_factors; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.mfa_factors (id, user_id, friendly_name, factor_type, status, created_at, updated_at, secret, phone, last_challenged_at, web_authn_credential, web_authn_aaguid) FROM stdin;
\.


--
-- Data for Name: oauth_authorizations; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.oauth_authorizations (id, authorization_id, client_id, user_id, redirect_uri, scope, state, resource, code_challenge, code_challenge_method, response_type, status, authorization_code, created_at, expires_at, approved_at) FROM stdin;
\.


--
-- Data for Name: oauth_clients; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.oauth_clients (id, client_secret_hash, registration_type, redirect_uris, grant_types, client_name, client_uri, logo_uri, created_at, updated_at, deleted_at, client_type) FROM stdin;
\.


--
-- Data for Name: oauth_consents; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.oauth_consents (id, user_id, client_id, scopes, granted_at, revoked_at) FROM stdin;
\.


--
-- Data for Name: one_time_tokens; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.one_time_tokens (id, user_id, token_type, token_hash, relates_to, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: refresh_tokens; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) FROM stdin;
\.


--
-- Data for Name: saml_providers; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.saml_providers (id, sso_provider_id, entity_id, metadata_xml, metadata_url, attribute_mapping, created_at, updated_at, name_id_format) FROM stdin;
\.


--
-- Data for Name: saml_relay_states; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.saml_relay_states (id, sso_provider_id, request_id, for_email, redirect_to, created_at, updated_at, flow_state_id) FROM stdin;
\.


--
-- Data for Name: schema_migrations; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.schema_migrations (version) FROM stdin;
20171026211738
20171026211808
20171026211834
20180103212743
20180108183307
20180119214651
20180125194653
00
20210710035447
20210722035447
20210730183235
20210909172000
20210927181326
20211122151130
20211124214934
20211202183645
20220114185221
20220114185340
20220224000811
20220323170000
20220429102000
20220531120530
20220614074223
20220811173540
20221003041349
20221003041400
20221011041400
20221020193600
20221021073300
20221021082433
20221027105023
20221114143122
20221114143410
20221125140132
20221208132122
20221215195500
20221215195800
20221215195900
20230116124310
20230116124412
20230131181311
20230322519590
20230402418590
20230411005111
20230508135423
20230523124323
20230818113222
20230914180801
20231027141322
20231114161723
20231117164230
20240115144230
20240214120130
20240306115329
20240314092811
20240427152123
20240612123726
20240729123726
20240802193726
20240806073726
20241009103726
20250717082212
20250731150234
20250804100000
20250901200500
20250903112500
20250904133000
\.


--
-- Data for Name: sessions; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id) FROM stdin;
\.


--
-- Data for Name: sso_domains; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.sso_domains (id, sso_provider_id, domain, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: sso_providers; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.sso_providers (id, resource_id, created_at, updated_at, disabled) FROM stdin;
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, invited_at, confirmation_token, confirmation_sent_at, recovery_token, recovery_sent_at, email_change_token_new, email_change, email_change_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, is_super_admin, created_at, updated_at, phone, phone_confirmed_at, phone_change, phone_change_token, phone_change_sent_at, email_change_token_current, email_change_confirm_status, banned_until, reauthentication_token, reauthentication_sent_at, is_sso_user, deleted_at, is_anonymous) FROM stdin;
\.


--
-- Data for Name: job; Type: TABLE DATA; Schema: cron; Owner: supabase_admin
--

COPY cron.job (jobid, schedule, command, nodename, nodeport, database, username, active, jobname) FROM stdin;
1	*/10 * * * *	SELECT close_expired_chat_rooms()	localhost	5432	postgres	postgres	t	close-expired-chat-rooms
\.


--
-- Data for Name: job_run_details; Type: TABLE DATA; Schema: cron; Owner: supabase_admin
--

COPY cron.job_run_details (jobid, runid, job_pid, database, username, command, status, return_message, start_time, end_time) FROM stdin;
1	35	126106	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 10:10:00.026124+00	2025-10-21 10:10:00.180657+00
1	22	122327	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 08:00:00.02092+00	2025-10-21 08:00:00.03294+00
1	1	115746	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 04:30:00.159225+00	2025-10-21 04:30:00.175814+00
1	13	119608	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 06:30:00.028419+00	2025-10-21 06:30:00.147614+00
1	2	116058	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 04:40:00.148059+00	2025-10-21 04:40:00.158976+00
1	49	130176	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 12:30:00.04165+00	2025-10-21 12:30:00.203606+00
1	30	124649	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 09:20:00.117815+00	2025-10-21 09:20:00.237123+00
1	14	120011	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 06:40:00.017853+00	2025-10-21 06:40:00.021724+00
1	3	116434	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 04:50:00.134309+00	2025-10-21 04:50:00.139587+00
1	23	122616	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 08:10:00.020909+00	2025-10-21 08:10:00.031977+00
1	4	116825	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 05:00:00.116152+00	2025-10-21 05:00:00.12432+00
1	15	120301	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 06:50:00.032302+00	2025-10-21 06:50:00.166417+00
1	5	117198	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 05:10:00.115951+00	2025-10-21 05:10:00.123559+00
1	43	128434	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 11:30:00.025127+00	2025-10-21 11:30:00.124483+00
1	24	122908	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 08:20:00.040697+00	2025-10-21 08:20:00.197103+00
1	6	117543	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 05:20:00.164184+00	2025-10-21 05:20:00.195907+00
1	16	120591	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 07:00:00.023053+00	2025-10-21 07:00:00.036965+00
1	7	117857	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 05:30:00.138988+00	2025-10-21 05:30:00.143491+00
1	36	126400	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 10:20:00.025471+00	2025-10-21 10:20:00.037262+00
1	31	124943	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 09:30:00.03975+00	2025-10-21 09:30:00.147276+00
1	17	120881	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 07:10:00.034787+00	2025-10-21 07:10:00.051131+00
1	8	118162	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 05:40:00.165674+00	2025-10-21 05:40:00.20139+00
1	25	123200	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 08:30:00.155625+00	2025-10-21 08:30:00.28366+00
1	9	118446	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 05:50:00.138039+00	2025-10-21 05:50:00.254518+00
1	18	121171	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 07:20:00.075904+00	2025-10-21 07:20:00.195828+00
1	10	118738	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 06:00:00.144252+00	2025-10-21 06:00:00.24098+00
1	40	127563	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 11:00:00.024102+00	2025-10-21 11:00:00.13332+00
1	11	119025	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 06:10:00.022339+00	2025-10-21 06:10:00.056153+00
1	19	121458	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 07:30:00.025832+00	2025-10-21 07:30:00.099741+00
1	26	123488	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 08:40:00.025695+00	2025-10-21 08:40:00.088987+00
1	12	119315	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 06:20:00.037653+00	2025-10-21 06:20:00.172981+00
1	32	125234	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 09:40:00.021072+00	2025-10-21 09:40:00.058206+00
1	20	121747	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 07:40:00.023392+00	2025-10-21 07:40:00.053853+00
1	27	123775	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 08:50:00.027678+00	2025-10-21 08:50:00.160594+00
1	21	122039	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 07:50:00.045251+00	2025-10-21 07:50:00.199053+00
1	37	126690	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 10:30:00.109022+00	2025-10-21 10:30:00.141861+00
1	33	125526	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 09:50:00.022989+00	2025-10-21 09:50:00.043019+00
1	28	124066	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 09:00:00.123663+00	2025-10-21 09:00:00.248474+00
1	52	131041	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 13:00:00.104785+00	2025-10-21 13:00:00.23091+00
1	46	129304	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 12:00:00.029674+00	2025-10-21 12:00:00.190131+00
1	41	127852	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 11:10:00.023224+00	2025-10-21 11:10:00.104414+00
1	29	124353	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 09:10:00.020051+00	2025-10-21 09:10:00.032402+00
1	34	125817	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 10:00:00.031208+00	2025-10-21 10:00:00.133992+00
1	38	126979	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 10:40:00.030266+00	2025-10-21 10:40:00.154307+00
1	44	128727	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 11:40:00.035123+00	2025-10-21 11:40:00.152424+00
1	39	127271	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 10:50:00.101417+00	2025-10-21 10:50:00.21031+00
1	42	128144	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 11:20:00.02337+00	2025-10-21 11:20:00.048713+00
1	48	129885	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 12:20:00.036831+00	2025-10-21 12:20:00.040981+00
1	47	129595	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 12:10:00.026901+00	2025-10-21 12:10:00.129612+00
1	45	129012	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 11:50:00.093653+00	2025-10-21 11:50:00.234206+00
1	53	131330	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 13:10:00.033803+00	2025-10-21 13:10:00.11472+00
1	51	130749	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 12:50:00.023323+00	2025-10-21 12:50:00.034263+00
1	50	130464	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 12:40:00.027443+00	2025-10-21 12:40:00.109166+00
1	54	131620	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 13:20:00.055992+00	2025-10-21 13:20:00.23708+00
1	55	131911	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 13:30:00.031991+00	2025-10-21 13:30:00.147766+00
1	56	132204	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 13:40:00.018056+00	2025-10-21 13:40:00.024816+00
1	57	132495	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 13:50:00.032664+00	2025-10-21 13:50:00.076963+00
1	58	132784	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 14:00:00.024982+00	2025-10-21 14:00:00.167943+00
1	59	133077	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 14:10:00.019964+00	2025-10-21 14:10:00.036875+00
1	94	144065	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 20:00:00.795328+00	2025-10-21 20:00:00.896657+00
1	81	139847	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 17:50:00.146134+00	2025-10-21 17:50:00.161013+00
1	60	133371	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 14:20:00.033016+00	2025-10-21 14:20:00.142523+00
1	72	137044	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 16:20:00.020252+00	2025-10-21 16:20:00.025738+00
1	61	133668	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 14:30:00.066871+00	2025-10-21 14:30:00.073389+00
1	108	148239	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 22:20:00.153292+00	2025-10-21 22:20:00.287659+00
1	89	142557	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 19:10:00.771489+00	2025-10-21 19:10:00.831739+00
1	73	137336	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 16:30:00.054645+00	2025-10-21 16:30:00.085486+00
1	62	134068	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 14:40:00.042098+00	2025-10-21 14:40:00.056272+00
1	82	140171	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 18:00:00.145169+00	2025-10-21 18:00:00.154908+00
1	63	134368	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 14:50:00.091687+00	2025-10-21 14:50:00.102216+00
1	74	137649	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 16:40:00.018101+00	2025-10-21 16:40:00.022794+00
1	64	134660	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 15:00:00.026829+00	2025-10-21 15:00:00.036559+00
1	102	146473	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 21:20:00.079877+00	2025-10-21 21:20:00.150881+00
1	83	140610	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 18:10:00.219655+00	2025-10-21 18:10:00.243667+00
1	65	134948	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 15:10:00.131217+00	2025-10-21 15:10:00.20932+00
1	75	137953	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 16:50:00.142811+00	2025-10-21 16:50:00.16013+00
1	66	135242	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 15:20:00.018499+00	2025-10-21 15:20:00.026562+00
1	95	144390	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 20:10:00.468524+00	2025-10-21 20:10:00.552348+00
1	90	142863	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 19:20:00.395562+00	2025-10-21 19:20:00.439268+00
1	76	138257	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 17:00:00.136212+00	2025-10-21 17:00:00.145271+00
1	67	135540	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 15:30:00.07384+00	2025-10-21 15:30:00.113376+00
1	84	140957	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 18:20:00.565719+00	2025-10-21 18:20:00.599918+00
1	68	135842	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 15:40:00.029971+00	2025-10-21 15:40:00.051168+00
1	77	138577	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 17:10:00.108592+00	2025-10-21 17:10:00.115231+00
1	69	136149	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 15:50:00.062939+00	2025-10-21 15:50:00.071362+00
1	99	145586	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 20:50:00.146256+00	2025-10-21 20:50:00.220908+00
1	70	136458	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 16:00:00.076923+00	2025-10-21 16:00:00.091135+00
1	78	138905	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 17:20:00.138946+00	2025-10-21 17:20:00.163067+00
1	85	141302	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 18:30:00.580402+00	2025-10-21 18:30:00.67462+00
1	71	136748	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 16:10:00.132022+00	2025-10-21 16:10:00.168382+00
1	91	143159	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 19:30:00.580958+00	2025-10-21 19:30:00.753907+00
1	79	139232	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 17:30:00.131859+00	2025-10-21 17:30:00.154143+00
1	86	141630	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 18:40:00.356121+00	2025-10-21 18:40:00.434938+00
1	80	139551	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 17:40:00.128779+00	2025-10-21 17:40:00.136639+00
1	96	144706	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 20:20:00.24159+00	2025-10-21 20:20:00.271128+00
1	92	143464	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 19:40:00.67464+00	2025-10-21 19:40:00.986968+00
1	87	141949	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 18:50:00.634198+00	2025-10-21 18:50:00.73285+00
1	111	149120	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 22:50:00.137042+00	2025-10-21 22:50:00.26635+00
1	105	147360	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 21:50:00.045758+00	2025-10-21 21:50:00.135028+00
1	100	145880	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 21:00:00.021883+00	2025-10-21 21:00:00.03039+00
1	88	142242	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 19:00:00.687658+00	2025-10-21 19:00:01.191897+00
1	93	143757	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 19:50:00.176596+00	2025-10-21 19:50:00.272038+00
1	97	145001	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 20:30:00.495235+00	2025-10-21 20:30:00.57973+00
1	103	146769	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 21:30:00.042681+00	2025-10-21 21:30:00.070543+00
1	98	145294	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 20:40:00.079334+00	2025-10-21 20:40:00.116264+00
1	101	146175	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 21:10:00.152287+00	2025-10-21 21:10:00.266071+00
1	107	147941	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 22:10:00.043725+00	2025-10-21 22:10:00.124688+00
1	106	147650	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 22:00:00.01876+00	2025-10-21 22:00:00.031117+00
1	104	147064	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 21:40:00.144761+00	2025-10-21 21:40:00.270648+00
1	112	149417	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 23:00:00.021479+00	2025-10-21 23:00:00.031294+00
1	110	148823	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 22:40:00.021876+00	2025-10-21 22:40:00.035966+00
1	109	148533	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 22:30:00.030455+00	2025-10-21 22:30:00.127082+00
1	113	149708	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 23:10:00.153361+00	2025-10-21 23:10:00.292638+00
1	114	150007	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 23:20:00.017553+00	2025-10-21 23:20:00.031058+00
1	115	150299	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 23:30:00.103019+00	2025-10-21 23:30:00.112921+00
1	116	150593	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 23:40:00.11757+00	2025-10-21 23:40:00.243815+00
1	117	150883	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-21 23:50:00.01724+00	2025-10-21 23:50:00.028555+00
1	118	151181	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 00:00:00.022106+00	2025-10-22 00:00:00.039277+00
1	153	162134	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 05:50:00.147891+00	2025-10-22 05:50:00.192209+00
1	140	157700	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 03:40:00.102264+00	2025-10-22 03:40:00.105713+00
1	119	151493	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 00:10:00.04028+00	2025-10-22 00:10:00.143947+00
1	131	155021	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 02:10:00.094745+00	2025-10-22 02:10:00.18474+00
1	120	151789	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 00:20:00.020768+00	2025-10-22 00:20:00.167929+00
1	167	166661	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 08:10:00.051406+00	2025-10-22 08:10:00.100193+00
1	148	160582	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 05:00:00.13974+00	2025-10-22 05:00:00.21086+00
1	132	155319	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 02:20:00.022409+00	2025-10-22 02:20:00.032832+00
1	121	152082	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 00:30:00.041734+00	2025-10-22 00:30:00.139583+00
1	141	158413	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 03:50:00.162176+00	2025-10-22 03:50:00.167444+00
1	122	152376	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 00:40:00.022048+00	2025-10-22 00:40:00.159445+00
1	133	155613	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 02:30:00.021019+00	2025-10-22 02:30:00.073118+00
1	123	152669	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 00:50:00.023352+00	2025-10-22 00:50:00.037472+00
1	161	164832	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 07:10:00.046759+00	2025-10-22 07:10:00.06762+00
1	142	158721	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 04:00:00.139447+00	2025-10-22 04:00:00.153646+00
1	124	152960	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 01:00:00.016626+00	2025-10-22 01:00:00.025418+00
1	134	155910	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 02:40:00.021741+00	2025-10-22 02:40:00.120055+00
1	125	153252	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 01:10:00.025719+00	2025-10-22 01:10:00.046948+00
1	154	162427	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 06:00:00.147579+00	2025-10-22 06:00:00.197579+00
1	149	160895	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 05:10:00.140587+00	2025-10-22 05:10:00.166+00
1	135	156213	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 02:50:00.025838+00	2025-10-22 02:50:00.046403+00
1	126	153548	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 01:20:00.113485+00	2025-10-22 01:20:00.235581+00
1	143	159016	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 04:10:00.033678+00	2025-10-22 04:10:00.047886+00
1	127	153843	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 01:30:00.02888+00	2025-10-22 01:30:00.096262+00
1	136	156503	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 03:00:00.044956+00	2025-10-22 03:00:00.118708+00
1	128	154139	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 01:40:00.023942+00	2025-10-22 01:40:00.169778+00
1	158	163822	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 06:40:00.06444+00	2025-10-22 06:40:00.130003+00
1	129	154430	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 01:50:00.025529+00	2025-10-22 01:50:00.036278+00
1	137	156796	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 03:10:00.028395+00	2025-10-22 03:10:00.153812+00
1	144	159339	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 04:20:00.137839+00	2025-10-22 04:20:00.158837+00
1	130	154724	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 02:00:00.093809+00	2025-10-22 02:00:00.228044+00
1	150	161210	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 05:20:00.09198+00	2025-10-22 05:20:00.117524+00
1	138	157089	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 03:20:00.10571+00	2025-10-22 03:20:00.204473+00
1	145	159651	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 04:30:00.138489+00	2025-10-22 04:30:00.164074+00
1	139	157384	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 03:30:00.02509+00	2025-10-22 03:30:00.139878+00
1	155	162893	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 06:10:00.167933+00	2025-10-22 06:10:00.261061+00
1	151	161519	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 05:30:00.15112+00	2025-10-22 05:30:00.208635+00
1	146	159957	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 04:40:00.034267+00	2025-10-22 04:40:00.039157+00
1	170	167595	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 08:40:00.023474+00	2025-10-22 08:40:00.045781+00
1	164	165742	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 07:40:00.061815+00	2025-10-22 07:40:00.147198+00
1	159	164128	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 06:50:00.129435+00	2025-10-22 06:50:00.172213+00
1	147	160271	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 04:50:00.151346+00	2025-10-22 04:50:00.205722+00
1	152	161829	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 05:40:00.133512+00	2025-10-22 05:40:00.220022+00
1	156	163200	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 06:20:00.135577+00	2025-10-22 06:20:00.169136+00
1	162	165142	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 07:20:00.134588+00	2025-10-22 07:20:00.176239+00
1	157	163516	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 06:30:00.018484+00	2025-10-22 06:30:00.022828+00
1	160	164435	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 07:00:00.037686+00	2025-10-22 07:00:00.064733+00
1	166	166356	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 08:00:00.051655+00	2025-10-22 08:00:00.106685+00
1	165	166049	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 07:50:00.051194+00	2025-10-22 07:50:00.121282+00
1	163	165446	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 07:30:00.04175+00	2025-10-22 07:30:00.079333+00
1	171	167900	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 08:50:00.021857+00	2025-10-22 08:50:00.096455+00
1	169	167283	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 08:30:00.048612+00	2025-10-22 08:30:00.088855+00
1	168	166976	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 08:20:00.022765+00	2025-10-22 08:20:00.028961+00
1	172	168193	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 09:00:00.033811+00	2025-10-22 09:00:00.038753+00
1	173	168500	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 09:10:00.152972+00	2025-10-22 09:10:00.212451+00
1	174	168810	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 09:20:00.022871+00	2025-10-22 09:20:00.059145+00
1	175	169123	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 09:30:00.098465+00	2025-10-22 09:30:00.128722+00
1	176	169434	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 09:40:00.018062+00	2025-10-22 09:40:00.032707+00
1	177	169740	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 09:50:00.102946+00	2025-10-22 09:50:00.14826+00
1	212	180480	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 15:40:00.024919+00	2025-10-22 15:40:00.093242+00
1	199	176534	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 13:30:00.017788+00	2025-10-22 13:30:00.086233+00
1	178	170045	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 10:00:00.02426+00	2025-10-22 10:00:00.070611+00
1	190	173765	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 12:00:00.032952+00	2025-10-22 12:00:00.082604+00
1	179	170344	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 10:10:00.021698+00	2025-10-22 10:10:00.026852+00
1	226	184594	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 18:00:00.022048+00	2025-10-22 18:00:00.046335+00
1	207	178993	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 14:50:00.026707+00	2025-10-22 14:50:00.05025+00
1	191	174077	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 12:10:00.026171+00	2025-10-22 12:10:00.05273+00
1	180	170656	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 10:20:00.020958+00	2025-10-22 10:20:00.073142+00
1	200	176846	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 13:40:00.099513+00	2025-10-22 13:40:00.151089+00
1	181	170969	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 10:30:00.021834+00	2025-10-22 10:30:00.060848+00
1	192	174388	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 12:20:00.117101+00	2025-10-22 12:20:00.152343+00
1	182	171280	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 10:40:00.021376+00	2025-10-22 10:40:00.086389+00
1	220	182830	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 17:00:00.031738+00	2025-10-22 17:00:00.125066+00
1	201	177152	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 13:50:00.047287+00	2025-10-22 13:50:00.10687+00
1	183	171586	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 10:50:00.023724+00	2025-10-22 10:50:00.029638+00
1	193	174685	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 12:30:00.021867+00	2025-10-22 12:30:00.039278+00
1	184	171894	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 11:00:00.096136+00	2025-10-22 11:00:00.161243+00
1	213	180774	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 15:50:00.025921+00	2025-10-22 15:50:00.148674+00
1	208	179299	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 15:00:00.017705+00	2025-10-22 15:00:00.021702+00
1	194	174994	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 12:40:00.107483+00	2025-10-22 12:40:00.167776+00
1	185	172206	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 11:10:00.033004+00	2025-10-22 11:10:00.042069+00
1	202	177447	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 14:00:00.083653+00	2025-10-22 14:00:00.145935+00
1	186	172504	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 11:20:00.107651+00	2025-10-22 11:20:00.169361+00
1	195	175302	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 12:50:00.02524+00	2025-10-22 12:50:00.082668+00
1	187	172839	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 11:30:00.019303+00	2025-10-22 11:30:00.025353+00
1	217	181947	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 16:30:00.024914+00	2025-10-22 16:30:00.171091+00
1	188	173149	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 11:40:00.031407+00	2025-10-22 11:40:00.07873+00
1	196	175609	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 13:00:00.023895+00	2025-10-22 13:00:00.031183+00
1	203	177756	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 14:10:00.035637+00	2025-10-22 14:10:00.068576+00
1	189	173458	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 11:50:00.019962+00	2025-10-22 11:50:00.031145+00
1	209	179589	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 15:10:00.151507+00	2025-10-22 15:10:00.262764+00
1	197	175920	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 13:10:00.101824+00	2025-10-22 13:10:00.168702+00
1	204	178068	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 14:20:00.027655+00	2025-10-22 14:20:00.044275+00
1	198	176229	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 13:20:00.017585+00	2025-10-22 13:20:00.035708+00
1	214	181064	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 16:00:00.021635+00	2025-10-22 16:00:00.045269+00
1	210	179887	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 15:20:00.020653+00	2025-10-22 15:20:00.0304+00
1	205	178378	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 14:30:00.022782+00	2025-10-22 14:30:00.086173+00
1	229	185474	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 18:30:00.052071+00	2025-10-22 18:30:00.123884+00
1	223	183709	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 17:30:00.127316+00	2025-10-22 17:30:00.236748+00
1	218	182243	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 16:40:00.035111+00	2025-10-22 16:40:00.041217+00
1	206	178682	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 14:40:00.026307+00	2025-10-22 14:40:00.094845+00
1	211	180180	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 15:30:00.022399+00	2025-10-22 15:30:00.079571+00
1	215	181357	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 16:10:00.036993+00	2025-10-22 16:10:00.083655+00
1	221	183124	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 17:10:00.025568+00	2025-10-22 17:10:00.14267+00
1	216	181650	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 16:20:00.128969+00	2025-10-22 16:20:00.300651+00
1	219	182536	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 16:50:00.125042+00	2025-10-22 16:50:00.242557+00
1	225	184301	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 17:50:00.129592+00	2025-10-22 17:50:00.24445+00
1	224	184005	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 17:40:00.027611+00	2025-10-22 17:40:00.040172+00
1	222	183417	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 17:20:00.02841+00	2025-10-22 17:20:00.113491+00
1	230	185770	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 18:40:00.040755+00	2025-10-22 18:40:00.197049+00
1	228	185182	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 18:20:00.036636+00	2025-10-22 18:20:00.151228+00
1	227	184884	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 18:10:00.114465+00	2025-10-22 18:10:00.260895+00
1	231	186063	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 18:50:00.034702+00	2025-10-22 18:50:00.111971+00
1	232	186359	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 19:00:00.03582+00	2025-10-22 19:00:00.115583+00
1	233	186651	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 19:10:00.030087+00	2025-10-22 19:10:00.040135+00
1	234	186948	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 19:20:00.041643+00	2025-10-22 19:20:00.142752+00
1	235	187244	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 19:30:00.041318+00	2025-10-22 19:30:00.197863+00
1	236	187538	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 19:40:00.037477+00	2025-10-22 19:40:00.186456+00
1	271	198302	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 01:30:00.04112+00	2025-10-23 01:30:00.100197+00
1	258	194023	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 23:20:00.150785+00	2025-10-22 23:20:00.160696+00
1	237	187829	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 19:50:00.040844+00	2025-10-22 19:50:00.133849+00
1	249	191357	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 21:50:00.055106+00	2025-10-22 21:50:00.128823+00
1	238	188124	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 20:00:00.033603+00	2025-10-22 20:00:00.126657+00
1	285	202767	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 03:50:00.121812+00	2025-10-23 03:50:00.128516+00
1	266	196829	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 00:40:00.124504+00	2025-10-23 00:40:00.147452+00
1	250	191653	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 22:00:00.089567+00	2025-10-22 22:00:00.219316+00
1	239	188414	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 20:10:00.026704+00	2025-10-22 20:10:00.041943+00
1	259	194377	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 23:30:00.13292+00	2025-10-22 23:30:00.140918+00
1	240	188711	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 20:20:00.038327+00	2025-10-22 20:20:00.158012+00
1	251	191945	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 22:10:00.042217+00	2025-10-22 22:10:00.102358+00
1	241	189004	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 20:30:00.034158+00	2025-10-22 20:30:00.12943+00
1	279	200819	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 02:50:00.133692+00	2025-10-23 02:50:00.158593+00
1	260	194799	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 23:40:00.151168+00	2025-10-22 23:40:00.161883+00
1	242	189298	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 20:40:00.02573+00	2025-10-22 20:40:00.153101+00
1	252	192239	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 22:20:00.075177+00	2025-10-22 22:20:00.160437+00
1	243	189591	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 20:50:00.022797+00	2025-10-22 20:50:00.163676+00
1	272	198606	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 01:40:00.14861+00	2025-10-23 01:40:00.240572+00
1	267	197121	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 00:50:00.03438+00	2025-10-23 00:50:00.090849+00
1	253	192533	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 22:30:00.034322+00	2025-10-22 22:30:00.141245+00
1	244	189882	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 21:00:00.0325+00	2025-10-22 21:00:00.039598+00
1	261	195129	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 23:50:00.171134+00	2025-10-22 23:50:00.190567+00
1	245	190178	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 21:10:00.116242+00	2025-10-22 21:10:00.145877+00
1	254	192829	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 22:40:00.063952+00	2025-10-22 22:40:00.126008+00
1	246	190477	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 21:20:00.022494+00	2025-10-22 21:20:00.139262+00
1	276	199936	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 02:20:00.153506+00	2025-10-23 02:20:00.313075+00
1	247	190771	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 21:30:00.045901+00	2025-10-22 21:30:00.154341+00
1	255	193118	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 22:50:00.037159+00	2025-10-22 22:50:00.133167+00
1	262	195436	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 00:00:00.113893+00	2025-10-23 00:00:00.118841+00
1	248	191068	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 21:40:00.02027+00	2025-10-22 21:40:00.035275+00
1	268	197416	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 01:00:00.158168+00	2025-10-23 01:00:00.306834+00
1	256	193415	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 23:00:00.017552+00	2025-10-22 23:00:00.035986+00
1	263	195894	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 00:10:00.112848+00	2025-10-23 00:10:00.120188+00
1	257	193704	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-22 23:10:00.021675+00	2025-10-22 23:10:00.134298+00
1	273	198932	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 01:50:00.064076+00	2025-10-23 01:50:00.068593+00
1	269	197714	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 01:10:00.036596+00	2025-10-23 01:10:00.196654+00
1	264	196236	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 00:20:00.123732+00	2025-10-23 00:20:00.130481+00
1	282	201792	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 03:20:00.115662+00	2025-10-23 03:20:00.125908+00
1	277	200227	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 02:30:00.030935+00	2025-10-23 02:30:00.04407+00
1	265	196536	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 00:30:00.12508+00	2025-10-23 00:30:00.136936+00
1	270	198009	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 01:20:00.027723+00	2025-10-23 01:20:00.104606+00
1	274	199274	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 02:00:00.114089+00	2025-10-23 02:00:00.119333+00
1	280	201118	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 03:00:00.157783+00	2025-10-23 03:00:00.182041+00
1	275	199638	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 02:10:00.090466+00	2025-10-23 02:10:00.09734+00
1	278	200525	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 02:40:00.074081+00	2025-10-23 02:40:00.080028+00
1	284	202426	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 03:40:00.026951+00	2025-10-23 03:40:00.074886+00
1	288	204092	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 04:20:00.110883+00	2025-10-23 04:20:00.121284+00
1	283	202135	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 03:30:00.163636+00	2025-10-23 03:30:00.261486+00
1	281	201434	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 03:10:00.017045+00	2025-10-23 03:10:00.02309+00
1	289	204390	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 04:30:00.152118+00	2025-10-23 04:30:00.281578+00
1	286	203205	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 04:00:00.049429+00	2025-10-23 04:00:00.057935+00
1	287	203628	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 04:10:00.130167+00	2025-10-23 04:10:00.138684+00
1	290	204704	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 04:40:00.115862+00	2025-10-23 04:40:00.121782+00
1	291	205010	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 04:50:00.159398+00	2025-10-23 04:50:00.229566+00
1	292	205300	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 05:00:00.030345+00	2025-10-23 05:00:00.036167+00
1	293	205610	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 05:10:00.167755+00	2025-10-23 05:10:00.228039+00
1	294	205915	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 05:20:00.157742+00	2025-10-23 05:20:00.219252+00
1	295	206207	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 05:30:00.152342+00	2025-10-23 05:30:00.275495+00
1	330	216802	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 11:20:00.095656+00	2025-10-23 11:20:00.231945+00
1	317	212971	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 09:10:00.103835+00	2025-10-23 09:10:00.211831+00
1	296	206525	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 05:40:00.140412+00	2025-10-23 05:40:00.159998+00
1	308	210325	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 07:40:00.043982+00	2025-10-23 07:40:00.154315+00
1	297	206841	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 05:50:00.145942+00	2025-10-23 05:50:00.159323+00
1	344	220922	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 13:40:00.023631+00	2025-10-23 13:40:00.119504+00
1	325	215330	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 10:30:00.038514+00	2025-10-23 10:30:00.121965+00
1	309	210619	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 07:50:00.051114+00	2025-10-23 07:50:00.187782+00
1	298	207130	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 06:00:00.17585+00	2025-10-23 06:00:00.2479+00
1	318	213267	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 09:20:00.04143+00	2025-10-23 09:20:00.150138+00
1	299	207435	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 06:10:00.143732+00	2025-10-23 06:10:00.219477+00
1	310	210912	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 08:00:00.035001+00	2025-10-23 08:00:00.042603+00
1	300	207756	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 06:20:00.112862+00	2025-10-23 06:20:00.126563+00
1	338	219155	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 12:40:00.147994+00	2025-10-23 12:40:00.244035+00
1	319	213562	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 09:30:00.021268+00	2025-10-23 09:30:00.064523+00
1	301	208108	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 06:30:00.126743+00	2025-10-23 06:30:00.13226+00
1	311	211203	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 08:10:00.156193+00	2025-10-23 08:10:00.245896+00
1	302	208413	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 06:40:00.153992+00	2025-10-23 06:40:00.257982+00
1	331	217093	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 11:30:00.09364+00	2025-10-23 11:30:00.188506+00
1	326	215624	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 10:40:00.091553+00	2025-10-23 10:40:00.242917+00
1	312	211497	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 08:20:00.022144+00	2025-10-23 08:20:00.150177+00
1	303	208825	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 06:50:00.124999+00	2025-10-23 06:50:00.147067+00
1	320	213856	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 09:40:00.02345+00	2025-10-23 09:40:00.10663+00
1	304	209126	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 07:00:00.046455+00	2025-10-23 07:00:00.062707+00
1	313	211792	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 08:30:00.027017+00	2025-10-23 08:30:00.052141+00
1	305	209441	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 07:10:00.080259+00	2025-10-23 07:10:00.09782+00
1	335	218273	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 12:10:00.025343+00	2025-10-23 12:10:00.194223+00
1	306	209737	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 07:20:00.063058+00	2025-10-23 07:20:00.104746+00
1	314	212087	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 08:40:00.159692+00	2025-10-23 08:40:00.306404+00
1	321	214151	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 09:50:00.033579+00	2025-10-23 09:50:00.059801+00
1	307	210030	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 07:30:00.145762+00	2025-10-23 07:30:00.248904+00
1	327	215916	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 10:50:00.033363+00	2025-10-23 10:50:00.141819+00
1	315	212379	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 08:50:00.030808+00	2025-10-23 08:50:00.13527+00
1	322	214442	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 10:00:00.102618+00	2025-10-23 10:00:00.239696+00
1	316	212674	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 09:00:00.035309+00	2025-10-23 09:00:00.058441+00
1	332	217390	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 11:40:00.036226+00	2025-10-23 11:40:00.040423+00
1	328	216212	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 11:00:00.021971+00	2025-10-23 11:00:00.124281+00
1	323	214738	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 10:10:00.020597+00	2025-10-23 10:10:00.029048+00
1	347	221804	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 14:10:00.023697+00	2025-10-23 14:10:00.183794+00
1	341	220038	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 13:10:00.027038+00	2025-10-23 13:10:00.04109+00
1	336	218572	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 12:20:00.030044+00	2025-10-23 12:20:00.121459+00
1	324	215036	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 10:20:00.044452+00	2025-10-23 10:20:00.137491+00
1	329	216502	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 11:10:00.039688+00	2025-10-23 11:10:00.062209+00
1	333	217685	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 11:50:00.094169+00	2025-10-23 11:50:00.222055+00
1	339	219451	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 12:50:00.037901+00	2025-10-23 12:50:00.15151+00
1	334	217980	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 12:00:00.02075+00	2025-10-23 12:00:00.045082+00
1	337	218865	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 12:30:00.040049+00	2025-10-23 12:30:00.178418+00
1	343	220626	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 13:30:00.022347+00	2025-10-23 13:30:00.036181+00
1	342	220335	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 13:20:00.105436+00	2025-10-23 13:20:00.238763+00
1	340	219745	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 13:00:00.022563+00	2025-10-23 13:00:00.129916+00
1	348	222104	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 14:20:00.040939+00	2025-10-23 14:20:00.074696+00
1	346	221511	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 14:00:00.122585+00	2025-10-23 14:00:00.287851+00
1	345	221218	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 13:50:00.03754+00	2025-10-23 13:50:00.053215+00
1	349	222398	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 14:30:00.024407+00	2025-10-23 14:30:00.103453+00
1	350	222694	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 14:40:00.017885+00	2025-10-23 14:40:00.026662+00
1	351	222989	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 14:50:00.024085+00	2025-10-23 14:50:00.038079+00
1	352	223291	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 15:00:00.045826+00	2025-10-23 15:00:00.062933+00
1	353	223586	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 15:10:00.025677+00	2025-10-23 15:10:00.16891+00
1	354	223881	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 15:20:00.032602+00	2025-10-23 15:20:00.147465+00
1	389	234839	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 21:10:00.132717+00	2025-10-23 21:10:00.148901+00
1	376	230836	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 19:00:00.165449+00	2025-10-23 19:00:00.190679+00
1	355	224173	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 15:30:00.025109+00	2025-10-23 15:30:00.164093+00
1	367	227759	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 17:30:00.027257+00	2025-10-23 17:30:00.034127+00
1	356	224470	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 15:40:00.02767+00	2025-10-23 15:40:00.115476+00
1	403	239118	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 23:30:00.118435+00	2025-10-23 23:30:00.229811+00
1	384	233279	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 20:20:00.026896+00	2025-10-23 20:20:00.132901+00
1	368	228057	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 17:40:00.054377+00	2025-10-23 17:40:00.148016+00
1	357	224767	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 15:50:00.132823+00	2025-10-23 15:50:00.258143+00
1	377	231144	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 19:10:00.057695+00	2025-10-23 19:10:00.093388+00
1	358	225060	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 16:00:00.033924+00	2025-10-23 16:00:00.172826+00
1	369	228739	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 17:50:00.064951+00	2025-10-23 17:50:00.204792+00
1	359	225361	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 16:10:00.019104+00	2025-10-23 16:10:00.026684+00
1	397	237348	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 22:30:00.028877+00	2025-10-23 22:30:00.150181+00
1	378	231452	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 19:20:00.140445+00	2025-10-23 19:20:00.189431+00
1	360	225657	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 16:20:00.116895+00	2025-10-23 16:20:00.197015+00
1	370	229035	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 18:00:00.14065+00	2025-10-23 18:00:00.226363+00
1	361	225948	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 16:30:00.021432+00	2025-10-23 16:30:00.052549+00
1	390	235170	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 21:20:00.032421+00	2025-10-23 21:20:00.047936+00
1	385	233571	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 20:30:00.036055+00	2025-10-23 20:30:00.182427+00
1	371	229330	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 18:10:00.067163+00	2025-10-23 18:10:00.220241+00
1	362	226249	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 16:40:00.148525+00	2025-10-23 16:40:00.297855+00
1	379	231763	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 19:30:00.047561+00	2025-10-23 19:30:00.081636+00
1	363	226541	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 16:50:00.026469+00	2025-10-23 16:50:00.1587+00
1	372	229624	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 18:20:00.111803+00	2025-10-23 18:20:00.19797+00
1	364	226833	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 17:00:00.024752+00	2025-10-23 17:00:00.05156+00
1	394	236369	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 22:00:00.03829+00	2025-10-23 22:00:00.15169+00
1	365	227144	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 17:10:00.054019+00	2025-10-23 17:10:00.075288+00
1	373	229921	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 18:30:00.054237+00	2025-10-23 18:30:00.18868+00
1	380	232075	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 19:40:00.053547+00	2025-10-23 19:40:00.08694+00
1	366	227453	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 17:20:00.043075+00	2025-10-23 17:20:00.065062+00
1	386	233863	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 20:40:00.051448+00	2025-10-23 20:40:00.147831+00
1	374	230213	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 18:40:00.113127+00	2025-10-23 18:40:00.20482+00
1	381	232386	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 19:50:00.056468+00	2025-10-23 19:50:00.111596+00
1	375	230518	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 18:50:00.02949+00	2025-10-23 18:50:00.042792+00
1	391	235482	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 21:30:00.036922+00	2025-10-23 21:30:00.084575+00
1	387	234167	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 20:50:00.024919+00	2025-10-23 20:50:00.068874+00
1	382	232689	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 20:00:00.035443+00	2025-10-23 20:00:00.094673+00
1	406	240010	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 00:00:00.031613+00	2025-10-24 00:00:00.03562+00
1	400	238226	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 23:00:00.034054+00	2025-10-23 23:00:00.124201+00
1	395	236667	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 22:10:00.031724+00	2025-10-23 22:10:00.149524+00
1	383	232985	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 20:10:00.025001+00	2025-10-23 20:10:00.061598+00
1	388	234480	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 21:00:00.044668+00	2025-10-23 21:00:00.059571+00
1	392	235777	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 21:40:00.053662+00	2025-10-23 21:40:00.16829+00
1	398	237645	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 22:40:00.019626+00	2025-10-23 22:40:00.036817+00
1	393	236070	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 21:50:00.103269+00	2025-10-23 21:50:00.205107+00
1	396	236963	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 22:20:00.024945+00	2025-10-23 22:20:00.040383+00
1	402	238820	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 23:20:00.039947+00	2025-10-23 23:20:00.157194+00
1	401	238522	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 23:10:00.022053+00	2025-10-23 23:10:00.15552+00
1	399	237936	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 22:50:00.103414+00	2025-10-23 22:50:00.198593+00
1	407	240324	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 00:10:00.098662+00	2025-10-24 00:10:00.217524+00
1	405	239704	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 23:50:00.024046+00	2025-10-23 23:50:00.118515+00
1	404	239411	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-23 23:40:00.044138+00	2025-10-23 23:40:00.192993+00
1	408	240619	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 00:20:00.029627+00	2025-10-24 00:20:00.039246+00
1	409	240972	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 00:30:00.120293+00	2025-10-24 00:30:00.125812+00
1	410	241286	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 00:40:00.134749+00	2025-10-24 00:40:00.143834+00
1	411	241600	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 00:50:00.150055+00	2025-10-24 00:50:00.156286+00
1	412	241896	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 01:00:00.153761+00	2025-10-24 01:00:00.27976+00
1	413	242190	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 01:10:00.137207+00	2025-10-24 01:10:00.27801+00
1	448	255808	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 07:00:00.150897+00	2025-10-24 07:00:00.160462+00
1	435	249243	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 04:50:00.138636+00	2025-10-24 04:50:00.147784+00
1	414	242486	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 01:20:00.019304+00	2025-10-24 01:20:00.027557+00
1	426	246322	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 03:20:00.151688+00	2025-10-24 03:20:00.190481+00
1	415	242795	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 01:30:00.047407+00	2025-10-24 01:30:00.053634+00
1	462	260081	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 09:20:00.032638+00	2025-10-24 09:20:00.098899+00
1	443	251745	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 06:10:00.017845+00	2025-10-24 06:10:00.021393+00
1	427	246645	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 03:30:00.1621+00	2025-10-24 03:30:00.178796+00
1	416	243106	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 01:40:00.161075+00	2025-10-24 01:40:00.182119+00
1	436	249548	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 05:00:00.138965+00	2025-10-24 05:00:00.165661+00
1	417	243456	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 01:50:00.143809+00	2025-10-24 01:50:00.151377+00
1	428	246948	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 03:40:00.163307+00	2025-10-24 03:40:00.222627+00
1	418	243778	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 02:00:00.101925+00	2025-10-24 02:00:00.107163+00
1	456	258256	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 08:20:00.093353+00	2025-10-24 08:20:00.201897+00
1	437	249848	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 05:10:00.136841+00	2025-10-24 05:10:00.186902+00
1	419	244085	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 02:10:00.143207+00	2025-10-24 02:10:00.157727+00
1	429	247283	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 03:50:00.168961+00	2025-10-24 03:50:00.194615+00
1	420	244394	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 02:20:00.149369+00	2025-10-24 02:20:00.189656+00
1	449	256123	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 07:10:00.166108+00	2025-10-24 07:10:00.201469+00
1	444	252054	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 06:20:00.113832+00	2025-10-24 06:20:00.134741+00
1	430	247620	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 04:00:00.141819+00	2025-10-24 04:00:00.160344+00
1	421	244707	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 02:30:00.081968+00	2025-10-24 02:30:00.098156+00
1	438	250156	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 05:20:00.127726+00	2025-10-24 05:20:00.177984+00
1	422	245018	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 02:40:00.140661+00	2025-10-24 02:40:00.196082+00
1	431	247959	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 04:10:00.119315+00	2025-10-24 04:10:00.123427+00
1	423	245340	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 02:50:00.159396+00	2025-10-24 02:50:00.171821+00
1	453	257342	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 07:50:00.144587+00	2025-10-24 07:50:00.224383+00
1	424	245643	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 03:00:00.139209+00	2025-10-24 03:00:00.150133+00
1	432	248292	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 04:20:00.121882+00	2025-10-24 04:20:00.127433+00
1	439	250487	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 05:30:00.128271+00	2025-10-24 05:30:00.134239+00
1	425	245950	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 03:10:00.041574+00	2025-10-24 03:10:00.059158+00
1	445	252766	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 06:30:00.142335+00	2025-10-24 06:30:00.157349+00
1	433	248595	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 04:30:00.153646+00	2025-10-24 04:30:00.175313+00
1	440	250839	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 05:40:00.123111+00	2025-10-24 05:40:00.164158+00
1	434	248910	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 04:40:00.167291+00	2025-10-24 04:40:00.273219+00
1	450	256431	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 07:20:00.148336+00	2025-10-24 07:20:00.168926+00
1	446	253058	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 06:40:00.146654+00	2025-10-24 06:40:00.202449+00
1	441	251145	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 05:50:00.134543+00	2025-10-24 05:50:00.146748+00
1	465	260996	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 09:50:00.031469+00	2025-10-24 09:50:00.136605+00
1	459	259168	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 08:50:00.024747+00	2025-10-24 08:50:00.10294+00
1	454	257644	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 08:00:00.089707+00	2025-10-24 08:00:00.098387+00
1	442	251442	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 06:00:00.164588+00	2025-10-24 06:00:00.321184+00
1	447	255493	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 06:50:00.210819+00	2025-10-24 06:50:00.3902+00
1	451	256733	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 07:30:00.070713+00	2025-10-24 07:30:00.15081+00
1	457	258558	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 08:30:00.031256+00	2025-10-24 08:30:00.038746+00
1	452	257040	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 07:40:00.146295+00	2025-10-24 07:40:00.201018+00
1	455	257949	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 08:10:00.123431+00	2025-10-24 08:10:00.177755+00
1	461	259775	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 09:10:00.125382+00	2025-10-24 09:10:00.158685+00
1	460	259470	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 09:00:00.020823+00	2025-10-24 09:00:00.085128+00
1	458	258864	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 08:40:00.137848+00	2025-10-24 08:40:00.205039+00
1	466	261303	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 10:00:00.030668+00	2025-10-24 10:00:00.072518+00
1	464	260691	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 09:40:00.018603+00	2025-10-24 09:40:00.070484+00
1	463	260387	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 09:30:00.123398+00	2025-10-24 09:30:00.197639+00
1	467	261605	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 10:10:00.065378+00	2025-10-24 10:10:00.11227+00
1	468	261914	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 10:20:00.14872+00	2025-10-24 10:20:00.221048+00
1	469	262219	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 10:30:00.021884+00	2025-10-24 10:30:00.084146+00
1	470	262522	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 10:40:00.116185+00	2025-10-24 10:40:00.184514+00
1	471	262828	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 10:50:00.087678+00	2025-10-24 10:50:00.159286+00
1	472	263133	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 11:00:00.106107+00	2025-10-24 11:00:00.180987+00
1	507	273814	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 16:50:00.025456+00	2025-10-24 16:50:00.081048+00
1	494	269857	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 14:40:00.058582+00	2025-10-24 14:40:00.148265+00
1	473	263440	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 11:10:00.158752+00	2025-10-24 11:10:00.218402+00
1	485	267104	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 13:10:00.164758+00	2025-10-24 13:10:00.233961+00
1	474	263747	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 11:20:00.019334+00	2025-10-24 11:20:00.028657+00
1	521	278089	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 19:10:00.022414+00	2025-10-24 19:10:00.027674+00
1	502	272309	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 16:00:00.114723+00	2025-10-24 16:00:00.178148+00
1	486	267415	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 13:20:00.017118+00	2025-10-24 13:20:00.023697+00
1	475	264058	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 11:30:00.065386+00	2025-10-24 11:30:00.138223+00
1	495	270158	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 14:50:00.020131+00	2025-10-24 14:50:00.035671+00
1	476	264364	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 11:40:00.117679+00	2025-10-24 11:40:00.195146+00
1	487	267724	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 13:30:00.053121+00	2025-10-24 13:30:00.134408+00
1	477	264667	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 11:50:00.071437+00	2025-10-24 11:50:00.122296+00
1	515	276254	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 18:10:00.039724+00	2025-10-24 18:10:00.150306+00
1	496	270465	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 15:00:00.133641+00	2025-10-24 15:00:00.224908+00
1	478	264975	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 12:00:00.024978+00	2025-10-24 12:00:00.029189+00
1	488	268029	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 13:40:00.145196+00	2025-10-24 13:40:00.200663+00
1	479	265279	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 12:10:00.108074+00	2025-10-24 12:10:00.226712+00
1	508	274120	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 17:00:00.050993+00	2025-10-24 17:00:00.133599+00
1	503	272614	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 16:10:00.032687+00	2025-10-24 16:10:00.088163+00
1	489	268334	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 13:50:00.019488+00	2025-10-24 13:50:00.029862+00
1	480	265585	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 12:20:00.026341+00	2025-10-24 12:20:00.034137+00
1	497	270773	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 15:10:00.01792+00	2025-10-24 15:10:00.023012+00
1	481	265892	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 12:30:00.150852+00	2025-10-24 12:30:00.22968+00
1	490	268635	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 14:00:00.057252+00	2025-10-24 14:00:00.112039+00
1	482	266194	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 12:40:00.017106+00	2025-10-24 12:40:00.020593+00
1	512	275343	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 17:40:00.02627+00	2025-10-24 17:40:00.077488+00
1	483	266498	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 12:50:00.04547+00	2025-10-24 12:50:00.102264+00
1	491	268943	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 14:10:00.133341+00	2025-10-24 14:10:00.203636+00
1	498	271079	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 15:20:00.030319+00	2025-10-24 15:20:00.089221+00
1	484	266800	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 13:00:00.037049+00	2025-10-24 13:00:00.118516+00
1	504	272925	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 16:20:00.035638+00	2025-10-24 16:20:00.11118+00
1	492	269251	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 14:20:00.029903+00	2025-10-24 14:20:00.137893+00
1	499	271383	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 15:30:00.122812+00	2025-10-24 15:30:00.174858+00
1	493	269551	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 14:30:00.045405+00	2025-10-24 14:30:00.151435+00
1	509	274422	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 17:10:00.025159+00	2025-10-24 17:10:00.078567+00
1	505	273220	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 16:30:00.022674+00	2025-10-24 16:30:00.138353+00
1	500	271698	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 15:40:00.018101+00	2025-10-24 15:40:00.025129+00
1	524	279008	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 19:40:00.027488+00	2025-10-24 19:40:00.062199+00
1	518	277173	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 18:40:00.119428+00	2025-10-24 18:40:00.165792+00
1	513	275645	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 17:50:00.108551+00	2025-10-24 17:50:00.175637+00
1	501	272001	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 15:50:00.026867+00	2025-10-24 15:50:00.101118+00
1	506	273513	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 16:40:00.025177+00	2025-10-24 16:40:00.035409+00
1	510	274730	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 17:20:00.027402+00	2025-10-24 17:20:00.090317+00
1	516	276563	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 18:20:00.144224+00	2025-10-24 18:20:00.232066+00
1	511	275036	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 17:30:00.101846+00	2025-10-24 17:30:00.154328+00
1	514	275947	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 18:00:00.021481+00	2025-10-24 18:00:00.070955+00
1	520	277784	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 19:00:00.10725+00	2025-10-24 19:00:00.184424+00
1	519	277478	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 18:50:00.022141+00	2025-10-24 18:50:00.098254+00
1	517	276869	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 18:30:00.019849+00	2025-10-24 18:30:00.113408+00
1	525	279314	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 19:50:00.060772+00	2025-10-24 19:50:00.132967+00
1	523	278705	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 19:30:00.022996+00	2025-10-24 19:30:00.111079+00
1	522	278402	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 19:20:00.026091+00	2025-10-24 19:20:00.078428+00
1	526	279617	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 20:00:00.020248+00	2025-10-24 20:00:00.119426+00
1	527	279922	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 20:10:00.024387+00	2025-10-24 20:10:00.031679+00
1	528	280231	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 20:20:00.128087+00	2025-10-24 20:20:00.177897+00
1	529	280534	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 20:30:00.018891+00	2025-10-24 20:30:00.024835+00
1	530	280844	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 20:40:00.02415+00	2025-10-24 20:40:00.068216+00
1	531	281151	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 20:50:00.019236+00	2025-10-24 20:50:00.070722+00
1	566	291915	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 02:40:00.121331+00	2025-10-25 02:40:00.203012+00
1	553	287931	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 00:30:00.041598+00	2025-10-25 00:30:00.104254+00
1	532	281456	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 21:00:00.035668+00	2025-10-24 21:00:00.114321+00
1	544	285114	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 23:00:00.13654+00	2025-10-24 23:00:00.208073+00
1	533	281759	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 21:10:00.134802+00	2025-10-24 21:10:00.188256+00
1	580	296200	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 05:00:00.128133+00	2025-10-25 05:00:00.209706+00
1	561	290388	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 01:50:00.027922+00	2025-10-25 01:50:00.10017+00
1	545	285415	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 23:10:00.067119+00	2025-10-24 23:10:00.13246+00
1	534	282065	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 21:20:00.12395+00	2025-10-24 21:20:00.185579+00
1	554	288238	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 00:40:00.069355+00	2025-10-25 00:40:00.11659+00
1	535	282370	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 21:30:00.142278+00	2025-10-24 21:30:00.237857+00
1	546	285721	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 23:20:00.085773+00	2025-10-24 23:20:00.136731+00
1	536	282675	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 21:40:00.144313+00	2025-10-24 21:40:00.20604+00
1	574	294351	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 04:00:00.116733+00	2025-10-25 04:00:00.207201+00
1	555	288543	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 00:50:00.023013+00	2025-10-25 00:50:00.099702+00
1	537	282980	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 21:50:00.144661+00	2025-10-24 21:50:00.235572+00
1	547	286026	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 23:30:00.089154+00	2025-10-24 23:30:00.137449+00
1	538	283286	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 22:00:00.150715+00	2025-10-24 22:00:00.222788+00
1	567	292219	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 02:50:00.121805+00	2025-10-25 02:50:00.200644+00
1	562	290692	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 02:00:00.054858+00	2025-10-25 02:00:00.150786+00
1	548	286331	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 23:40:00.107109+00	2025-10-24 23:40:00.20911+00
1	539	283591	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 22:10:00.123433+00	2025-10-24 22:10:00.204674+00
1	556	288852	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 01:00:00.050401+00	2025-10-25 01:00:00.064137+00
1	540	283896	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 22:20:00.13118+00	2025-10-24 22:20:00.15346+00
1	549	286638	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 23:50:00.062559+00	2025-10-24 23:50:00.114547+00
1	541	284201	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 22:30:00.14323+00	2025-10-24 22:30:00.226485+00
1	571	293436	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 03:30:00.019799+00	2025-10-25 03:30:00.026583+00
1	542	284505	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 22:40:00.098793+00	2025-10-24 22:40:00.169764+00
1	550	286945	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 00:00:00.04426+00	2025-10-25 00:00:00.055442+00
1	557	289159	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 01:10:00.047522+00	2025-10-25 01:10:00.075774+00
1	543	284809	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-24 22:50:00.076622+00	2025-10-24 22:50:00.090012+00
1	563	290993	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 02:10:00.018688+00	2025-10-25 02:10:00.026422+00
1	551	287319	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 00:10:00.137933+00	2025-10-25 00:10:00.190474+00
1	558	289473	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 01:20:00.028119+00	2025-10-25 01:20:00.078385+00
1	552	287628	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 00:20:00.019396+00	2025-10-25 00:20:00.02966+00
1	568	292523	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 03:00:00.034046+00	2025-10-25 03:00:00.043542+00
1	564	291301	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 02:20:00.040248+00	2025-10-25 02:20:00.102932+00
1	559	289777	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 01:30:00.018002+00	2025-10-25 01:30:00.045692+00
1	583	297501	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 05:30:00.039087+00	2025-10-25 05:30:00.078494+00
1	577	295267	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 04:30:00.114426+00	2025-10-25 04:30:00.168129+00
1	572	293743	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 03:40:00.03461+00	2025-10-25 03:40:00.084209+00
1	560	290083	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 01:40:00.039034+00	2025-10-25 01:40:00.117937+00
1	565	291606	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 02:30:00.122904+00	2025-10-25 02:30:00.223044+00
1	569	292826	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 03:10:00.041207+00	2025-10-25 03:10:00.105916+00
1	575	294653	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 04:10:00.123099+00	2025-10-25 04:10:00.193628+00
1	570	293134	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 03:20:00.144311+00	2025-10-25 03:20:00.221671+00
1	573	294049	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 03:50:00.023152+00	2025-10-25 03:50:00.03844+00
1	579	295905	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 04:50:00.078901+00	2025-10-25 04:50:00.091205+00
1	578	295603	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 04:40:00.126108+00	2025-10-25 04:40:00.131578+00
1	576	294962	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 04:20:00.118375+00	2025-10-25 04:20:00.156208+00
1	584	297794	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 05:40:00.113469+00	2025-10-25 05:40:00.136157+00
1	582	297204	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 05:20:00.018093+00	2025-10-25 05:20:00.024258+00
1	581	296895	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 05:10:00.153005+00	2025-10-25 05:10:00.240042+00
1	585	298089	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 05:50:00.055908+00	2025-10-25 05:50:00.142023+00
1	586	298383	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 06:00:00.120978+00	2025-10-25 06:00:00.229062+00
1	587	298677	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 06:10:00.026136+00	2025-10-25 06:10:00.036196+00
1	588	299092	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 06:20:00.098652+00	2025-10-25 06:20:00.182492+00
1	589	299396	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 06:30:00.031892+00	2025-10-25 06:30:00.040954+00
1	590	299708	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 06:40:00.053576+00	2025-10-25 06:40:00.108023+00
1	625	310191	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 12:30:00.025736+00	2025-10-25 12:30:00.182921+00
1	612	306350	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 10:20:00.029648+00	2025-10-25 10:20:00.104072+00
1	591	300019	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 06:50:00.131974+00	2025-10-25 06:50:00.193671+00
1	603	303608	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 08:50:00.041372+00	2025-10-25 08:50:00.120076+00
1	592	300328	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 07:00:00.148163+00	2025-10-25 07:00:00.210246+00
1	639	314318	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 14:50:00.06399+00	2025-10-25 14:50:00.192181+00
1	620	308713	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 11:40:00.024696+00	2025-10-25 11:40:00.116648+00
1	604	303902	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 09:00:00.047307+00	2025-10-25 09:00:00.192248+00
1	593	300640	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 07:10:00.162307+00	2025-10-25 07:10:00.244319+00
1	613	306650	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 10:30:00.031571+00	2025-10-25 10:30:00.162363+00
1	594	300939	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 07:20:00.127251+00	2025-10-25 07:20:00.200288+00
1	605	304196	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 09:10:00.052292+00	2025-10-25 09:10:00.198098+00
1	595	301248	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 07:30:00.114289+00	2025-10-25 07:30:00.125018+00
1	633	312544	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 13:50:00.038862+00	2025-10-25 13:50:00.141709+00
1	614	306946	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 10:40:00.037309+00	2025-10-25 10:40:00.044137+00
1	596	301556	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 07:40:00.137103+00	2025-10-25 07:40:00.168671+00
1	606	304495	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 09:20:00.050219+00	2025-10-25 09:20:00.160497+00
1	597	301848	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 07:50:00.1516+00	2025-10-25 07:50:00.211017+00
1	626	310486	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 12:40:00.024662+00	2025-10-25 12:40:00.147229+00
1	621	309007	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 11:50:00.030762+00	2025-10-25 11:50:00.193216+00
1	607	304790	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 09:30:00.047569+00	2025-10-25 09:30:00.149895+00
1	598	302140	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 08:00:00.150266+00	2025-10-25 08:00:00.24709+00
1	615	307233	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 10:50:00.021055+00	2025-10-25 10:50:00.106593+00
1	599	302435	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 08:10:00.020993+00	2025-10-25 08:10:00.03066+00
1	608	305086	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 09:40:00.052396+00	2025-10-25 09:40:00.185462+00
1	600	302730	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 08:20:00.141132+00	2025-10-25 08:20:00.209505+00
1	630	311667	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 13:20:00.02066+00	2025-10-25 13:20:00.030981+00
1	601	303020	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 08:30:00.035597+00	2025-10-25 08:30:00.157998+00
1	609	305467	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 09:50:00.034178+00	2025-10-25 09:50:00.044557+00
1	616	307524	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 11:00:00.052519+00	2025-10-25 11:00:00.25188+00
1	602	303313	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 08:40:00.122179+00	2025-10-25 08:40:00.224843+00
1	622	309305	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 12:00:00.024772+00	2025-10-25 12:00:00.122618+00
1	610	305760	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 10:00:00.030066+00	2025-10-25 10:00:00.174816+00
1	617	307821	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 11:10:00.027744+00	2025-10-25 11:10:00.126183+00
1	611	306052	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 10:10:00.04598+00	2025-10-25 10:10:00.190626+00
1	627	310778	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 12:50:00.031245+00	2025-10-25 12:50:00.170349+00
1	623	309597	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 12:10:00.029718+00	2025-10-25 12:10:00.170168+00
1	618	308120	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 11:20:00.027622+00	2025-10-25 11:20:00.097429+00
1	642	315202	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 15:20:00.022104+00	2025-10-25 15:20:00.067687+00
1	636	313431	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 14:20:00.024388+00	2025-10-25 14:20:00.042136+00
1	631	311960	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 13:30:00.090953+00	2025-10-25 13:30:00.20074+00
1	619	308417	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 11:30:00.051463+00	2025-10-25 11:30:00.238139+00
1	624	309895	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 12:20:00.023442+00	2025-10-25 12:20:00.149368+00
1	628	311072	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 13:00:00.147176+00	2025-10-25 13:00:00.285636+00
1	634	312840	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 14:00:00.02332+00	2025-10-25 14:00:00.123846+00
1	629	311367	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 13:10:00.025919+00	2025-10-25 13:10:00.090222+00
1	632	312253	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 13:40:00.027046+00	2025-10-25 13:40:00.041065+00
1	638	314024	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 14:40:00.031494+00	2025-10-25 14:40:00.158248+00
1	637	313727	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 14:30:00.094273+00	2025-10-25 14:30:00.209455+00
1	635	313132	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 14:10:00.022453+00	2025-10-25 14:10:00.127092+00
1	643	315490	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 15:30:00.179297+00	2025-10-25 15:30:00.299159+00
1	641	314901	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 15:10:00.020784+00	2025-10-25 15:10:00.084771+00
1	640	314608	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 15:00:00.032121+00	2025-10-25 15:00:00.038998+00
1	644	315789	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 15:40:00.145109+00	2025-10-25 15:40:00.215159+00
1	645	316083	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 15:50:00.090548+00	2025-10-25 15:50:00.128765+00
1	646	316379	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 16:00:00.049746+00	2025-10-25 16:00:00.070834+00
1	647	316671	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 16:10:00.071642+00	2025-10-25 16:10:00.1875+00
1	648	316965	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 16:20:00.161324+00	2025-10-25 16:20:00.267073+00
1	649	317260	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 16:30:00.060381+00	2025-10-25 16:30:00.178965+00
1	684	327575	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 22:20:00.021818+00	2025-10-25 22:20:00.050846+00
1	671	323733	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 20:10:00.038406+00	2025-10-25 20:10:00.058781+00
1	650	317552	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 16:40:00.030822+00	2025-10-25 16:40:00.044306+00
1	662	321088	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 18:40:00.043616+00	2025-10-25 18:40:00.127631+00
1	651	317844	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 16:50:00.031046+00	2025-10-25 16:50:00.055915+00
1	698	331816	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 00:40:00.026271+00	2025-10-26 00:40:00.046035+00
1	679	326090	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 21:30:00.025417+00	2025-10-25 21:30:00.106516+00
1	663	321377	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 18:50:00.022227+00	2025-10-25 18:50:00.033493+00
1	652	318137	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 17:00:00.162187+00	2025-10-25 17:00:00.276342+00
1	672	324033	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 20:20:00.128346+00	2025-10-25 20:20:00.272818+00
1	653	318432	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 17:10:00.023303+00	2025-10-25 17:10:00.031146+00
1	664	321668	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 19:00:00.023288+00	2025-10-25 19:00:00.168474+00
1	654	318730	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 17:20:00.15477+00	2025-10-25 17:20:00.316284+00
1	692	329920	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 23:40:00.031568+00	2025-10-25 23:40:00.164903+00
1	673	324322	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 20:30:00.018989+00	2025-10-25 20:30:00.028444+00
1	655	319019	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 17:30:00.027345+00	2025-10-25 17:30:00.039184+00
1	665	321962	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 19:10:00.024678+00	2025-10-25 19:10:00.040961+00
1	656	319318	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 17:40:00.133711+00	2025-10-25 17:40:00.259053+00
1	685	327865	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 22:30:00.02472+00	2025-10-25 22:30:00.044172+00
1	680	326387	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 21:40:00.029947+00	2025-10-25 21:40:00.034727+00
1	666	322262	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 19:20:00.044203+00	2025-10-25 19:20:00.058634+00
1	657	319612	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 17:50:00.043411+00	2025-10-25 17:50:00.190683+00
1	674	324617	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 20:40:00.026824+00	2025-10-25 20:40:00.045007+00
1	658	319904	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 18:00:00.022774+00	2025-10-25 18:00:00.046752+00
1	667	322559	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 19:30:00.067245+00	2025-10-25 19:30:00.184294+00
1	659	320197	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 18:10:00.043485+00	2025-10-25 18:10:00.10599+00
1	689	329040	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 23:10:00.02113+00	2025-10-25 23:10:00.034772+00
1	660	320494	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 18:20:00.02326+00	2025-10-25 18:20:00.122791+00
1	668	322855	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 19:40:00.028344+00	2025-10-25 19:40:00.049496+00
1	675	324912	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 20:50:00.111816+00	2025-10-25 20:50:00.219035+00
1	661	320790	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 18:30:00.040989+00	2025-10-25 18:30:00.096594+00
1	681	326682	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 21:50:00.029441+00	2025-10-25 21:50:00.152812+00
1	669	323149	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 19:50:00.050866+00	2025-10-25 19:50:00.10714+00
1	676	325204	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 21:00:00.035224+00	2025-10-25 21:00:00.064709+00
1	670	323443	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 20:00:00.033027+00	2025-10-25 20:00:00.14194+00
1	686	328154	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 22:40:00.039968+00	2025-10-25 22:40:00.183179+00
1	682	326977	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 22:00:00.094876+00	2025-10-25 22:00:00.200208+00
1	677	325497	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 21:10:00.042076+00	2025-10-25 21:10:00.052722+00
1	701	332695	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 01:10:00.041607+00	2025-10-26 01:10:00.160361+00
1	695	330929	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 00:10:00.038793+00	2025-10-26 00:10:00.156373+00
1	690	329337	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 23:20:00.036692+00	2025-10-25 23:20:00.050804+00
1	678	325795	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 21:20:00.019447+00	2025-10-25 21:20:00.161003+00
1	683	327273	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 22:10:00.032513+00	2025-10-25 22:10:00.161118+00
1	687	328448	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 22:50:00.130651+00	2025-10-25 22:50:00.260331+00
1	693	330314	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 23:50:00.115584+00	2025-10-25 23:50:00.177442+00
1	688	328744	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 23:00:00.031238+00	2025-10-25 23:00:00.118045+00
1	691	329626	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-25 23:30:00.131293+00	2025-10-25 23:30:00.253724+00
1	697	331522	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 00:30:00.016885+00	2025-10-26 00:30:00.020875+00
1	696	331229	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 00:20:00.132872+00	2025-10-26 00:20:00.260306+00
1	694	330611	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 00:00:00.025995+00	2025-10-26 00:00:00.039227+00
1	702	332991	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 01:20:00.026301+00	2025-10-26 01:20:00.103903+00
1	700	332402	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 01:00:00.036649+00	2025-10-26 01:00:00.142064+00
1	699	332108	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 00:50:00.092048+00	2025-10-26 00:50:00.103518+00
1	703	333283	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 01:30:00.023654+00	2025-10-26 01:30:00.197648+00
1	704	333578	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 01:40:00.032327+00	2025-10-26 01:40:00.04407+00
1	705	333872	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 01:50:00.041617+00	2025-10-26 01:50:00.154411+00
1	706	334169	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 02:00:00.021139+00	2025-10-26 02:00:00.028951+00
1	707	334461	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 02:10:00.171755+00	2025-10-26 02:10:00.291881+00
1	708	334757	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 02:20:00.020423+00	2025-10-26 02:20:00.122528+00
1	743	345221	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 08:10:00.024675+00	2025-10-26 08:10:00.137633+00
1	730	341270	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 06:00:00.019095+00	2025-10-26 06:00:00.035773+00
1	709	335054	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 02:30:00.027936+00	2025-10-26 02:30:00.046669+00
1	721	338604	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 04:30:00.061973+00	2025-10-26 04:30:00.16725+00
1	710	335349	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 02:40:00.048505+00	2025-10-26 02:40:00.174669+00
1	757	349349	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 10:30:00.021964+00	2025-10-26 10:30:00.037703+00
1	738	343752	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 07:20:00.113149+00	2025-10-26 07:20:00.235176+00
1	722	338901	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 04:40:00.041989+00	2025-10-26 04:40:00.22467+00
1	711	335644	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 02:50:00.020712+00	2025-10-26 02:50:00.033055+00
1	731	341565	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 06:10:00.037425+00	2025-10-26 06:10:00.187756+00
1	712	335941	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 03:00:00.041795+00	2025-10-26 03:00:00.169454+00
1	723	339197	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 04:50:00.102262+00	2025-10-26 04:50:00.196892+00
1	713	336239	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 03:10:00.025736+00	2025-10-26 03:10:00.044334+00
1	751	347582	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 09:30:00.025382+00	2025-10-26 09:30:00.119988+00
1	732	341864	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 06:20:00.16093+00	2025-10-26 06:20:00.249039+00
1	714	336537	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 03:20:00.037617+00	2025-10-26 03:20:00.108811+00
1	724	339503	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 05:00:00.025266+00	2025-10-26 05:00:00.03148+00
1	715	336832	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 03:30:00.030389+00	2025-10-26 03:30:00.1196+00
1	744	345515	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 08:20:00.021875+00	2025-10-26 08:20:00.063545+00
1	739	344042	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 07:30:00.038192+00	2025-10-26 07:30:00.044521+00
1	725	339796	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 05:10:00.025153+00	2025-10-26 05:10:00.185829+00
1	716	337130	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 03:40:00.028889+00	2025-10-26 03:40:00.044457+00
1	733	342274	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 06:30:00.029013+00	2025-10-26 06:30:00.043692+00
1	717	337422	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 03:50:00.02141+00	2025-10-26 03:50:00.157364+00
1	726	340094	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 05:20:00.029977+00	2025-10-26 05:20:00.158452+00
1	718	337719	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 04:00:00.029272+00	2025-10-26 04:00:00.18012+00
1	748	346696	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 09:00:00.022906+00	2025-10-26 09:00:00.078724+00
1	719	338014	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 04:10:00.025934+00	2025-10-26 04:10:00.119819+00
1	727	340387	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 05:30:00.019136+00	2025-10-26 05:30:00.038348+00
1	734	342567	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 06:40:00.025308+00	2025-10-26 06:40:00.122568+00
1	720	338310	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 04:20:00.043391+00	2025-10-26 04:20:00.100229+00
1	740	344338	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 07:40:00.023218+00	2025-10-26 07:40:00.189463+00
1	728	340683	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 05:40:00.034121+00	2025-10-26 05:40:00.048897+00
1	735	342862	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 06:50:00.026122+00	2025-10-26 06:50:00.124234+00
1	729	340976	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 05:50:00.118195+00	2025-10-26 05:50:00.267093+00
1	745	345808	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 08:30:00.025049+00	2025-10-26 08:30:00.121687+00
1	741	344633	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 07:50:00.023326+00	2025-10-26 07:50:00.03624+00
1	736	343158	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 07:00:00.025603+00	2025-10-26 07:00:00.146874+00
1	760	350233	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 11:00:00.081167+00	2025-10-26 11:00:00.243066+00
1	754	348464	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 10:00:00.023344+00	2025-10-26 10:00:00.117188+00
1	749	346993	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 09:10:00.020662+00	2025-10-26 09:10:00.064154+00
1	737	343452	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 07:10:00.027677+00	2025-10-26 07:10:00.03864+00
1	742	344928	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 08:00:00.092108+00	2025-10-26 08:00:00.194981+00
1	746	346106	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 08:40:00.032624+00	2025-10-26 08:40:00.105229+00
1	752	347878	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 09:40:00.107699+00	2025-10-26 09:40:00.241294+00
1	747	346400	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 08:50:00.12256+00	2025-10-26 08:50:00.231649+00
1	750	347288	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 09:20:00.132811+00	2025-10-26 09:20:00.24909+00
1	756	349054	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 10:20:00.018849+00	2025-10-26 10:20:00.048733+00
1	755	348759	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 10:10:00.03367+00	2025-10-26 10:10:00.154553+00
1	753	348173	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 09:50:00.023394+00	2025-10-26 09:50:00.080068+00
1	761	350529	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 11:10:00.049841+00	2025-10-26 11:10:00.161209+00
1	759	349945	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 10:50:00.031701+00	2025-10-26 10:50:00.157212+00
1	758	349647	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 10:40:00.096265+00	2025-10-26 10:40:00.247759+00
1	762	350828	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 11:20:00.019586+00	2025-10-26 11:20:00.043088+00
1	763	351123	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 11:30:00.032606+00	2025-10-26 11:30:00.113865+00
1	764	351418	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 11:40:00.046002+00	2025-10-26 11:40:00.141171+00
1	765	351709	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 11:50:00.036505+00	2025-10-26 11:50:00.113592+00
1	766	352004	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 12:00:00.021406+00	2025-10-26 12:00:00.079288+00
1	767	352299	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 12:10:00.046821+00	2025-10-26 12:10:00.147977+00
1	802	363009	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 18:00:00.10796+00	2025-10-26 18:00:00.226849+00
1	789	359176	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 15:50:00.021096+00	2025-10-26 15:50:00.033293+00
1	768	352597	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 12:20:00.107398+00	2025-10-26 12:20:00.236689+00
1	780	356522	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 14:20:00.038363+00	2025-10-26 14:20:00.082001+00
1	769	352888	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 12:30:00.037195+00	2025-10-26 12:30:00.072295+00
1	816	367138	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 20:20:00.021672+00	2025-10-26 20:20:00.038258+00
1	797	361538	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 17:10:00.033099+00	2025-10-26 17:10:00.041394+00
1	781	356814	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 14:30:00.045703+00	2025-10-26 14:30:00.143894+00
1	770	353180	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 12:40:00.029147+00	2025-10-26 12:40:00.102968+00
1	790	359472	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 16:00:00.041764+00	2025-10-26 16:00:00.178273+00
1	771	353475	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 12:50:00.018155+00	2025-10-26 12:50:00.036313+00
1	782	357106	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 14:40:00.01735+00	2025-10-26 14:40:00.032374+00
1	772	353768	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 13:00:00.041764+00	2025-10-26 13:00:00.193475+00
1	810	365369	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 19:20:00.02898+00	2025-10-26 19:20:00.072039+00
1	791	359765	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 16:10:00.032499+00	2025-10-26 16:10:00.110334+00
1	773	354063	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 13:10:00.025784+00	2025-10-26 13:10:00.101375+00
1	783	357399	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 14:50:00.045465+00	2025-10-26 14:50:00.183315+00
1	774	354363	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 13:20:00.044198+00	2025-10-26 13:20:00.085451+00
1	803	363304	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 18:10:00.020318+00	2025-10-26 18:10:00.03073+00
1	798	361833	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 17:20:00.024771+00	2025-10-26 17:20:00.19022+00
1	784	357694	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 15:00:00.02794+00	2025-10-26 15:00:00.128467+00
1	775	354658	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 13:30:00.146986+00	2025-10-26 13:30:00.286509+00
1	792	360067	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 16:20:00.051897+00	2025-10-26 16:20:00.175061+00
1	776	355341	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 13:40:00.155216+00	2025-10-26 13:40:00.199923+00
1	785	357989	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 15:10:00.023037+00	2025-10-26 15:10:00.19575+00
1	777	355636	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 13:50:00.146738+00	2025-10-26 13:50:00.21587+00
1	807	364482	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 18:50:00.104623+00	2025-10-26 18:50:00.185462+00
1	778	355933	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 14:00:00.140239+00	2025-10-26 14:00:00.272936+00
1	786	358288	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 15:20:00.024653+00	2025-10-26 15:20:00.053027+00
1	793	360362	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 16:30:00.023108+00	2025-10-26 16:30:00.101169+00
1	779	356226	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 14:10:00.031739+00	2025-10-26 14:10:00.046749+00
1	799	362124	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 17:30:00.0336+00	2025-10-26 17:30:00.18828+00
1	787	358582	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 15:30:00.026612+00	2025-10-26 15:30:00.172997+00
1	794	360655	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 16:40:00.03491+00	2025-10-26 16:40:00.066438+00
1	788	358877	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 15:40:00.028928+00	2025-10-26 15:40:00.121895+00
1	804	363602	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 18:20:00.019076+00	2025-10-26 18:20:00.034564+00
1	800	362418	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 17:40:00.025645+00	2025-10-26 17:40:00.117585+00
1	795	360948	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 16:50:00.023673+00	2025-10-26 16:50:00.145718+00
1	819	368020	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 20:50:00.028148+00	2025-10-26 20:50:00.091651+00
1	813	366253	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 19:50:00.091518+00	2025-10-26 19:50:00.170481+00
1	808	364781	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 19:00:00.028647+00	2025-10-26 19:00:00.147046+00
1	796	361242	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 17:00:00.017459+00	2025-10-26 17:00:00.033808+00
1	801	362713	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 17:50:00.027254+00	2025-10-26 17:50:00.0341+00
1	805	363892	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 18:30:00.016269+00	2025-10-26 18:30:00.107155+00
1	811	365662	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 19:30:00.101776+00	2025-10-26 19:30:00.22932+00
1	806	364187	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 18:40:00.02329+00	2025-10-26 18:40:00.140852+00
1	809	365076	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 19:10:00.022169+00	2025-10-26 19:10:00.100634+00
1	815	366841	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 20:10:00.061009+00	2025-10-26 20:10:00.196338+00
1	814	366548	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 20:00:00.024563+00	2025-10-26 20:00:00.056685+00
1	812	365957	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 19:40:00.024226+00	2025-10-26 19:40:00.035138+00
1	820	368312	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 21:00:00.027196+00	2025-10-26 21:00:00.06062+00
1	818	367731	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 20:40:00.041565+00	2025-10-26 20:40:00.174024+00
1	817	367432	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 20:30:00.027901+00	2025-10-26 20:30:00.154767+00
1	821	368604	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 21:10:00.019901+00	2025-10-26 21:10:00.041565+00
1	822	368903	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 21:20:00.041658+00	2025-10-26 21:20:00.132836+00
1	823	369194	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 21:30:00.157671+00	2025-10-26 21:30:00.276429+00
1	824	369489	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 21:40:00.024546+00	2025-10-26 21:40:00.184954+00
1	825	369779	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 21:50:00.020992+00	2025-10-26 21:50:00.0331+00
1	826	370072	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 22:00:00.024988+00	2025-10-26 22:00:00.147867+00
1	861	381149	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 03:50:00.117085+00	2025-10-27 03:50:00.136283+00
1	848	377119	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 01:40:00.020798+00	2025-10-27 01:40:00.026714+00
1	827	370369	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 22:10:00.029283+00	2025-10-26 22:10:00.14803+00
1	839	374039	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 00:10:00.152583+00	2025-10-27 00:10:00.282068+00
1	828	370667	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 22:20:00.125821+00	2025-10-26 22:20:00.27331+00
1	875	385558	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 06:10:00.113965+00	2025-10-27 06:10:00.138229+00
1	856	379664	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 03:00:00.148613+00	2025-10-27 03:00:00.187471+00
1	840	374726	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 00:20:00.171074+00	2025-10-27 00:20:00.285317+00
1	829	370956	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 22:30:00.02306+00	2025-10-26 22:30:00.11835+00
1	849	377435	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 01:50:00.13705+00	2025-10-27 01:50:00.146079+00
1	830	371252	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 22:40:00.036208+00	2025-10-26 22:40:00.14689+00
1	841	375016	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 00:30:00.035406+00	2025-10-27 00:30:00.047655+00
1	831	371574	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 22:50:00.166869+00	2025-10-26 22:50:00.176106+00
1	869	383619	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 05:10:00.145826+00	2025-10-27 05:10:00.157429+00
1	850	377762	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 02:00:00.121934+00	2025-10-27 02:00:00.148326+00
1	832	371874	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 23:00:00.038145+00	2025-10-26 23:00:00.06318+00
1	842	375312	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 00:40:00.169261+00	2025-10-27 00:40:00.26228+00
1	833	372205	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 23:10:00.150144+00	2025-10-26 23:10:00.159125+00
1	862	381450	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 04:00:00.027313+00	2025-10-27 04:00:00.042434+00
1	857	379956	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 03:10:00.10532+00	2025-10-27 03:10:00.248958+00
1	843	375608	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 00:50:00.017444+00	2025-10-27 00:50:00.020764+00
1	834	372514	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 23:20:00.167818+00	2025-10-26 23:20:00.229173+00
1	851	378087	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 02:10:00.105371+00	2025-10-27 02:10:00.123018+00
1	835	372832	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 23:30:00.146575+00	2025-10-26 23:30:00.156509+00
1	844	375904	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 01:00:00.167272+00	2025-10-27 01:00:00.271927+00
1	836	373131	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 23:40:00.152668+00	2025-10-26 23:40:00.196752+00
1	866	382682	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 04:40:00.169178+00	2025-10-27 04:40:00.284715+00
1	837	373428	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-26 23:50:00.107438+00	2025-10-26 23:50:00.118498+00
1	845	376202	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 01:10:00.128414+00	2025-10-27 01:10:00.215195+00
1	852	378403	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 02:20:00.136093+00	2025-10-27 02:20:00.158874+00
1	838	373725	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 00:00:00.166824+00	2025-10-27 00:00:00.284122+00
1	858	380258	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 03:20:00.024361+00	2025-10-27 03:20:00.031172+00
1	846	376503	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 01:20:00.149363+00	2025-10-27 01:20:00.231316+00
1	853	378729	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 02:30:00.135192+00	2025-10-27 02:30:00.171484+00
1	847	376798	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 01:30:00.16331+00	2025-10-27 01:30:00.28058+00
1	863	381768	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 04:10:00.032368+00	2025-10-27 04:10:00.054026+00
1	859	380550	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 03:30:00.126615+00	2025-10-27 03:30:00.217928+00
1	854	379049	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 02:40:00.131669+00	2025-10-27 02:40:00.142872+00
1	878	386508	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 06:40:00.152897+00	2025-10-27 06:40:00.2017+00
1	872	384608	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 05:40:00.166235+00	2025-10-27 05:40:00.182749+00
1	867	382987	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 04:50:00.135125+00	2025-10-27 04:50:00.170161+00
1	855	379369	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 02:50:00.118217+00	2025-10-27 02:50:00.129697+00
1	860	380847	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 03:40:00.031265+00	2025-10-27 03:40:00.035468+00
1	864	382080	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 04:20:00.046973+00	2025-10-27 04:20:00.080053+00
1	870	383959	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 05:20:00.1601+00	2025-10-27 05:20:00.170831+00
1	865	382379	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 04:30:00.177928+00	2025-10-27 04:30:00.307337+00
1	868	383297	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 05:00:00.158829+00	2025-10-27 05:00:00.190835+00
1	874	385253	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 06:00:00.16635+00	2025-10-27 06:00:00.23597+00
1	873	384939	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 05:50:00.15351+00	2025-10-27 05:50:00.161807+00
1	871	384296	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 05:30:00.146417+00	2025-10-27 05:30:00.154115+00
1	879	386814	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 06:50:00.134591+00	2025-10-27 06:50:00.18718+00
1	877	386200	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 06:30:00.134654+00	2025-10-27 06:30:00.168899+00
1	876	385880	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 06:20:00.132118+00	2025-10-27 06:20:00.146614+00
1	882	387845	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 07:20:00.160832+00	2025-10-27 07:20:00.20669+00
1	880	387239	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 07:00:00.169938+00	2025-10-27 07:00:00.211178+00
1	881	387545	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 07:10:00.167834+00	2025-10-27 07:10:00.199246+00
1	883	388153	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 07:30:00.157523+00	2025-10-27 07:30:00.217612+00
1	884	388466	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 07:40:00.023556+00	2025-10-27 07:40:00.025979+00
1	885	388777	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 07:50:00.144973+00	2025-10-27 07:50:00.20785+00
1	920	399723	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 13:40:00.024995+00	2025-10-27 13:40:00.029481+00
1	907	395780	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 11:30:00.1052+00	2025-10-27 11:30:00.161043+00
1	886	389082	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 08:00:00.150932+00	2025-10-27 08:00:00.202823+00
1	898	392909	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 10:00:00.023296+00	2025-10-27 10:00:00.059954+00
1	887	389391	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 08:10:00.018177+00	2025-10-27 08:10:00.022456+00
1	934	404068	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 16:00:00.132284+00	2025-10-27 16:00:00.170611+00
1	915	398214	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 12:50:00.107249+00	2025-10-27 12:50:00.170082+00
1	899	393209	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 10:10:00.02841+00	2025-10-27 10:10:00.035518+00
1	888	389697	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 08:20:00.136496+00	2025-10-27 08:20:00.165456+00
1	908	396087	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 11:40:00.113596+00	2025-10-27 11:40:00.16069+00
1	889	389994	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 08:30:00.032704+00	2025-10-27 08:30:00.040078+00
1	900	393534	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 10:20:00.113657+00	2025-10-27 10:20:00.146431+00
1	890	390306	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 08:40:00.151151+00	2025-10-27 08:40:00.220612+00
1	928	402172	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 15:00:00.125908+00	2025-10-27 15:00:00.193387+00
1	909	396392	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 11:50:00.098886+00	2025-10-27 11:50:00.152263+00
1	891	390615	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 08:50:00.024046+00	2025-10-27 08:50:00.028093+00
1	901	393863	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 10:30:00.027944+00	2025-10-27 10:30:00.037459+00
1	892	390944	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 09:00:00.053053+00	2025-10-27 09:00:00.100085+00
1	921	400013	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 13:50:00.026658+00	2025-10-27 13:50:00.077622+00
1	916	398519	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 13:00:00.02557+00	2025-10-27 13:00:00.029641+00
1	902	394222	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 10:40:00.093398+00	2025-10-27 10:40:00.152926+00
1	893	391293	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 09:10:00.020407+00	2025-10-27 09:10:00.091438+00
1	910	396693	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 12:00:00.018393+00	2025-10-27 12:00:00.02688+00
1	894	391625	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 09:20:00.021169+00	2025-10-27 09:20:00.055061+00
1	903	394529	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 10:50:00.099295+00	2025-10-27 10:50:00.168623+00
1	895	391931	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 09:30:00.04656+00	2025-10-27 09:30:00.094844+00
1	925	401242	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 14:30:00.050765+00	2025-10-27 14:30:00.079261+00
1	896	392302	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 09:40:00.025396+00	2025-10-27 09:40:00.081236+00
1	904	394840	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 11:00:00.035941+00	2025-10-27 11:00:00.045292+00
1	911	396998	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 12:10:00.114978+00	2025-10-27 12:10:00.169058+00
1	897	392611	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 09:50:00.107663+00	2025-10-27 09:50:00.168718+00
1	917	398823	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 13:10:00.114261+00	2025-10-27 13:10:00.149515+00
1	905	395131	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 11:10:00.139377+00	2025-10-27 11:10:00.18941+00
1	912	397296	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 12:20:00.02089+00	2025-10-27 12:20:00.026101+00
1	906	395468	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 11:20:00.104657+00	2025-10-27 11:20:00.136217+00
1	922	400319	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 14:00:00.032366+00	2025-10-27 14:00:00.039208+00
1	918	399130	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 13:20:00.030038+00	2025-10-27 13:20:00.050505+00
1	913	397601	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 12:30:00.117679+00	2025-10-27 12:30:00.172566+00
1	937	404976	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 16:30:00.030412+00	2025-10-27 16:30:00.034609+00
1	931	403167	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 15:30:00.502711+00	2025-10-27 15:30:00.745608+00
1	926	401556	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 14:40:00.025382+00	2025-10-27 14:40:00.030951+00
1	914	397909	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 12:40:00.039519+00	2025-10-27 12:40:00.10663+00
1	919	399430	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 13:30:00.10779+00	2025-10-27 13:30:00.15282+00
1	923	400625	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 14:10:00.05102+00	2025-10-27 14:10:00.12347+00
1	929	402480	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 15:10:00.133719+00	2025-10-27 15:10:00.178234+00
1	924	400934	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 14:20:00.060771+00	2025-10-27 14:20:00.112025+00
1	927	401859	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 14:50:00.131314+00	2025-10-27 14:50:00.196857+00
1	933	403773	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 15:50:00.109993+00	2025-10-27 15:50:00.155062+00
1	932	403470	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 15:40:00.211483+00	2025-10-27 15:40:00.289512+00
1	930	402866	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 15:20:00.157707+00	2025-10-27 15:20:00.249072+00
1	938	405266	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 16:40:00.144117+00	2025-10-27 16:40:00.202142+00
1	936	404675	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 16:20:00.110284+00	2025-10-27 16:20:00.15544+00
1	935	404368	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 16:10:00.143439+00	2025-10-27 16:10:00.19218+00
1	939	405570	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 16:50:00.045326+00	2025-10-27 16:50:00.113492+00
1	940	405870	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 17:00:00.116904+00	2025-10-27 17:00:00.207735+00
1	941	406157	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 17:10:00.032784+00	2025-10-27 17:10:00.081897+00
1	942	406452	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 17:20:00.022956+00	2025-10-27 17:20:00.082245+00
1	943	406750	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 17:30:00.038371+00	2025-10-27 17:30:00.051659+00
1	944	407037	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 17:40:00.085639+00	2025-10-27 17:40:00.161842+00
1	979	417542	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 23:30:00.024015+00	2025-10-27 23:30:00.069084+00
1	966	413609	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 21:20:00.14757+00	2025-10-27 21:20:00.160218+00
1	945	407329	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 17:50:00.035124+00	2025-10-27 17:50:00.087843+00
1	957	410835	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 19:50:00.135376+00	2025-10-27 19:50:00.254277+00
1	946	407617	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 18:00:00.052202+00	2025-10-27 18:00:00.059711+00
1	993	421789	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 01:50:00.146706+00	2025-10-28 01:50:00.16423+00
1	974	416025	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 22:40:00.029331+00	2025-10-27 22:40:00.037265+00
1	958	411129	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 20:00:00.138572+00	2025-10-27 20:00:00.231243+00
1	947	407910	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 18:10:00.037572+00	2025-10-27 18:10:00.131581+00
1	967	413919	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 21:30:00.151218+00	2025-10-27 21:30:00.174215+00
1	948	408202	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 18:20:00.040861+00	2025-10-27 18:20:00.131053+00
1	959	411423	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 20:10:00.086073+00	2025-10-27 20:10:00.126632+00
1	949	408508	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 18:30:00.125984+00	2025-10-27 18:30:00.144826+00
1	987	419953	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 00:50:00.038982+00	2025-10-28 00:50:00.043098+00
1	968	414214	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 21:40:00.156783+00	2025-10-27 21:40:00.214901+00
1	950	408800	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 18:40:00.022393+00	2025-10-27 18:40:00.029453+00
1	960	411723	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 20:20:00.133959+00	2025-10-27 20:20:00.15181+00
1	951	409092	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 18:50:00.023159+00	2025-10-27 18:50:00.076695+00
1	980	417828	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 23:40:00.151353+00	2025-10-27 23:40:00.313911+00
1	975	416315	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 22:50:00.162937+00	2025-10-27 22:50:00.308329+00
1	961	412034	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 20:30:00.165388+00	2025-10-27 20:30:00.263361+00
1	952	409381	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 19:00:00.025959+00	2025-10-27 19:00:00.155762+00
1	969	414521	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 21:50:00.11332+00	2025-10-27 21:50:00.122112+00
1	953	409673	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 19:10:00.077215+00	2025-10-27 19:10:00.150847+00
1	962	412346	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 20:40:00.103887+00	2025-10-27 20:40:00.11576+00
1	954	409963	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 19:20:00.021124+00	2025-10-27 19:20:00.033451+00
1	984	419040	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 00:20:00.024975+00	2025-10-28 00:20:00.039043+00
1	955	410252	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 19:30:00.119664+00	2025-10-27 19:30:00.23685+00
1	963	412662	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 20:50:00.156563+00	2025-10-27 20:50:00.173751+00
1	970	414820	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 22:00:00.144856+00	2025-10-27 22:00:00.166253+00
1	956	410545	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 19:40:00.085612+00	2025-10-27 19:40:00.184744+00
1	976	416604	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 23:00:00.019145+00	2025-10-27 23:00:00.028957+00
1	964	412969	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 21:00:00.133667+00	2025-10-27 21:00:00.148248+00
1	971	415132	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 22:10:00.15103+00	2025-10-27 22:10:00.161408+00
1	965	413275	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 21:10:00.150329+00	2025-10-27 21:10:00.166288+00
1	981	418131	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 23:50:00.038043+00	2025-10-27 23:50:00.048473+00
1	977	416944	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 23:10:00.041966+00	2025-10-27 23:10:00.051868+00
1	972	415439	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 22:20:00.13994+00	2025-10-27 22:20:00.157943+00
1	996	423056	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 02:20:00.15893+00	2025-10-28 02:20:00.219803+00
1	990	420883	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 01:20:00.163924+00	2025-10-28 01:20:00.171753+00
1	985	419349	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 00:30:00.135726+00	2025-10-28 00:30:00.176505+00
1	973	415734	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 22:30:00.158566+00	2025-10-27 22:30:00.256195+00
1	978	417248	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-27 23:20:00.143511+00	2025-10-27 23:20:00.17571+00
1	982	418435	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 00:00:00.112186+00	2025-10-28 00:00:00.129477+00
1	988	420269	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 01:00:00.139083+00	2025-10-28 01:00:00.147911+00
1	983	418750	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 00:10:00.144991+00	2025-10-28 00:10:00.190261+00
1	986	419657	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 00:40:00.140796+00	2025-10-28 00:40:00.169873+00
1	992	421490	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 01:40:00.137889+00	2025-10-28 01:40:00.148142+00
1	991	421183	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 01:30:00.143182+00	2025-10-28 01:30:00.181807+00
1	989	420568	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 01:10:00.161893+00	2025-10-28 01:10:00.207297+00
1	997	423369	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 02:30:00.046575+00	2025-10-28 02:30:00.051555+00
1	995	422763	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 02:10:00.148696+00	2025-10-28 02:10:00.161117+00
1	994	422078	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 02:00:00.159437+00	2025-10-28 02:00:00.291708+00
1	998	423687	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 02:40:00.152923+00	2025-10-28 02:40:00.157933+00
1	999	424003	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 02:50:00.137591+00	2025-10-28 02:50:00.144144+00
1	1000	424313	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 03:00:00.175114+00	2025-10-28 03:00:00.209912+00
1	1001	424619	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 03:10:00.150251+00	2025-10-28 03:10:00.204101+00
1	1002	424913	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 03:20:00.163762+00	2025-10-28 03:20:00.268731+00
1	1003	425202	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 03:30:00.144663+00	2025-10-28 03:30:00.237669+00
1	1038	435532	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 09:20:00.032411+00	2025-10-28 09:20:00.186398+00
1	1025	431734	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 07:10:00.032136+00	2025-10-28 07:10:00.171121+00
1	1004	425497	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 03:40:00.022942+00	2025-10-28 03:40:00.035294+00
1	1016	428996	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 05:40:00.0379+00	2025-10-28 05:40:00.101746+00
1	1005	425795	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 03:50:00.115365+00	2025-10-28 03:50:00.12133+00
1	1052	439704	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 11:40:00.021733+00	2025-10-28 11:40:00.036504+00
1	1033	434082	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 08:30:00.025949+00	2025-10-28 08:30:00.135273+00
1	1017	429290	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 05:50:00.059641+00	2025-10-28 05:50:00.151553+00
1	1006	426086	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 04:00:00.166328+00	2025-10-28 04:00:00.248784+00
1	1026	432029	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 07:20:00.137973+00	2025-10-28 07:20:00.228524+00
1	1007	426378	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 04:10:00.080009+00	2025-10-28 04:10:00.104827+00
1	1018	429579	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 06:00:00.042987+00	2025-10-28 06:00:00.146092+00
1	1008	426672	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 04:20:00.029602+00	2025-10-28 04:20:00.033574+00
1	1046	437964	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 10:40:00.045104+00	2025-10-28 10:40:00.175237+00
1	1027	432326	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 07:30:00.033116+00	2025-10-28 07:30:00.105694+00
1	1009	426964	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 04:30:00.161864+00	2025-10-28 04:30:00.290587+00
1	1019	429869	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 06:10:00.024697+00	2025-10-28 06:10:00.035199+00
1	1010	427254	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 04:40:00.021083+00	2025-10-28 04:40:00.028848+00
1	1039	435919	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 09:30:00.020551+00	2025-10-28 09:30:00.027264+00
1	1034	434372	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 08:40:00.054972+00	2025-10-28 08:40:00.122494+00
1	1020	430161	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 06:20:00.090227+00	2025-10-28 06:20:00.246333+00
1	1011	427545	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 04:50:00.054178+00	2025-10-28 04:50:00.153758+00
1	1028	432615	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 07:40:00.022114+00	2025-10-28 07:40:00.189385+00
1	1012	427837	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 05:00:00.045357+00	2025-10-28 05:00:00.162792+00
1	1021	430574	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 06:30:00.036746+00	2025-10-28 06:30:00.056935+00
1	1013	428129	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 05:10:00.108847+00	2025-10-28 05:10:00.212508+00
1	1043	437088	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 10:10:00.018847+00	2025-10-28 10:10:00.026213+00
1	1014	428423	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 05:20:00.04526+00	2025-10-28 05:20:00.109969+00
1	1022	430863	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 06:40:00.11007+00	2025-10-28 06:40:00.229575+00
1	1029	432907	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 07:50:00.036747+00	2025-10-28 07:50:00.04321+00
1	1015	428707	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 05:30:00.03293+00	2025-10-28 05:30:00.068314+00
1	1035	434661	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 08:50:00.022439+00	2025-10-28 08:50:00.139096+00
1	1023	431155	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 06:50:00.031083+00	2025-10-28 06:50:00.174015+00
1	1030	433198	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 08:00:00.029743+00	2025-10-28 08:00:00.116505+00
1	1024	431445	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 07:00:00.023346+00	2025-10-28 07:00:00.181696+00
1	1040	436218	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 09:40:00.044626+00	2025-10-28 09:40:00.065373+00
1	1036	434952	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 09:00:00.021181+00	2025-10-28 09:00:00.052126+00
1	1031	433498	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 08:10:00.028308+00	2025-10-28 08:10:00.038981+00
1	1055	440578	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 12:10:00.025628+00	2025-10-28 12:10:00.080396+00
1	1049	438836	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 11:10:00.038113+00	2025-10-28 11:10:00.131421+00
1	1044	437381	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 10:20:00.149571+00	2025-10-28 10:20:00.280126+00
1	1032	433791	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 08:20:00.040669+00	2025-10-28 08:20:00.17078+00
1	1037	435239	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 09:10:00.020459+00	2025-10-28 09:10:00.101059+00
1	1041	436508	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 09:50:00.134637+00	2025-10-28 09:50:00.282109+00
1	1047	438256	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 10:50:00.023434+00	2025-10-28 10:50:00.126315+00
1	1042	436799	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 10:00:00.1346+00	2025-10-28 10:00:00.238641+00
1	1045	437672	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 10:30:00.018324+00	2025-10-28 10:30:00.028723+00
1	1051	439414	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 11:30:00.024365+00	2025-10-28 11:30:00.117359+00
1	1050	439127	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 11:20:00.035602+00	2025-10-28 11:20:00.181804+00
1	1048	438546	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 11:00:00.021634+00	2025-10-28 11:00:00.031789+00
1	1056	440869	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 12:20:00.019857+00	2025-10-28 12:20:00.048641+00
1	1054	440289	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 12:00:00.119633+00	2025-10-28 12:00:00.281587+00
1	1053	440000	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 11:50:00.027065+00	2025-10-28 11:50:00.110945+00
1	1057	441158	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 12:30:00.04322+00	2025-10-28 12:30:00.142898+00
1	1058	441451	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 12:40:00.044142+00	2025-10-28 12:40:00.149685+00
1	1059	441743	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 12:50:00.024974+00	2025-10-28 12:50:00.087453+00
1	1060	442036	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 13:00:00.025146+00	2025-10-28 13:00:00.118265+00
1	1061	442325	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 13:10:00.038187+00	2025-10-28 13:10:00.056822+00
1	1062	442620	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 13:20:00.096264+00	2025-10-28 13:20:00.120651+00
1	1097	452774	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 19:10:00.023082+00	2025-10-28 19:10:00.129067+00
1	1084	448990	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 17:00:00.022346+00	2025-10-28 17:00:00.042498+00
1	1063	442908	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 13:30:00.020996+00	2025-10-28 13:30:00.033507+00
1	1075	446378	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 15:30:00.039602+00	2025-10-28 15:30:00.167909+00
1	1064	443201	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 13:40:00.045193+00	2025-10-28 13:40:00.060861+00
1	1111	456863	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 21:30:00.09385+00	2025-10-28 21:30:00.252401+00
1	1092	451326	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 18:20:00.036898+00	2025-10-28 18:20:00.043518+00
1	1076	446669	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 15:40:00.021938+00	2025-10-28 15:40:00.037852+00
1	1065	443491	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 13:50:00.145144+00	2025-10-28 13:50:00.282707+00
1	1085	449283	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 17:10:00.096239+00	2025-10-28 17:10:00.235136+00
1	1066	443772	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 14:00:00.031762+00	2025-10-28 14:00:00.048366+00
1	1077	446964	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 15:50:00.08281+00	2025-10-28 15:50:00.218859+00
1	1067	444049	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 14:10:00.076544+00	2025-10-28 14:10:00.159574+00
1	1105	455111	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 20:30:00.040079+00	2025-10-28 20:30:00.150488+00
1	1086	449578	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 17:20:00.038888+00	2025-10-28 17:20:00.13715+00
1	1068	444345	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 14:20:00.171782+00	2025-10-28 14:20:00.240322+00
1	1078	447254	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 16:00:00.028637+00	2025-10-28 16:00:00.035444+00
1	1069	444632	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 14:30:00.025121+00	2025-10-28 14:30:00.061243+00
1	1098	453067	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 19:20:00.027415+00	2025-10-28 19:20:00.125353+00
1	1093	451615	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 18:30:00.099546+00	2025-10-28 18:30:00.224268+00
1	1079	447545	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 16:10:00.025523+00	2025-10-28 16:10:00.113198+00
1	1070	444924	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 14:40:00.021906+00	2025-10-28 14:40:00.120109+00
1	1087	449866	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 17:30:00.130302+00	2025-10-28 17:30:00.271176+00
1	1071	445218	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 14:50:00.028634+00	2025-10-28 14:50:00.049661+00
1	1080	447834	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 16:20:00.018258+00	2025-10-28 16:20:00.03001+00
1	1072	445506	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 15:00:00.044311+00	2025-10-28 15:00:00.164155+00
1	1102	454235	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 20:00:00.102937+00	2025-10-28 20:00:00.209234+00
1	1073	445793	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 15:10:00.021692+00	2025-10-28 15:10:00.034696+00
1	1081	448123	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 16:30:00.035281+00	2025-10-28 16:30:00.050317+00
1	1088	450154	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 17:40:00.021106+00	2025-10-28 17:40:00.031851+00
1	1074	446086	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 15:20:00.077181+00	2025-10-28 15:20:00.223968+00
1	1094	451905	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 18:40:00.029552+00	2025-10-28 18:40:00.117939+00
1	1082	448410	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 16:40:00.071294+00	2025-10-28 16:40:00.188114+00
1	1089	450448	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 17:50:00.021263+00	2025-10-28 17:50:00.180323+00
1	1083	448701	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 16:50:00.021153+00	2025-10-28 16:50:00.102249+00
1	1099	453360	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 19:30:00.021266+00	2025-10-28 19:30:00.126379+00
1	1095	452197	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 18:50:00.020416+00	2025-10-28 18:50:00.192033+00
1	1090	450740	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 18:00:00.020149+00	2025-10-28 18:00:00.035922+00
1	1114	457798	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 22:00:00.144676+00	2025-10-28 22:00:00.155063+00
1	1108	455987	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 21:00:00.034136+00	2025-10-28 21:00:00.050091+00
1	1103	454526	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 20:10:00.029833+00	2025-10-28 20:10:00.083959+00
1	1091	451032	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 18:10:00.060787+00	2025-10-28 18:10:00.187754+00
1	1096	452485	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 19:00:00.020413+00	2025-10-28 19:00:00.032072+00
1	1100	453650	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 19:40:00.023556+00	2025-10-28 19:40:00.164753+00
1	1106	455404	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 20:40:00.024169+00	2025-10-28 20:40:00.146948+00
1	1101	453945	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 19:50:00.019729+00	2025-10-28 19:50:00.031594+00
1	1104	454819	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 20:20:00.017393+00	2025-10-28 20:20:00.021353+00
1	1110	456572	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 21:20:00.029547+00	2025-10-28 21:20:00.078817+00
1	1109	456279	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 21:10:00.021726+00	2025-10-28 21:10:00.135855+00
1	1107	455694	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 20:50:00.086546+00	2025-10-28 20:50:00.200308+00
1	1115	458107	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 22:10:00.127407+00	2025-10-28 22:10:00.133092+00
1	1113	457490	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 21:50:00.057755+00	2025-10-28 21:50:00.074684+00
1	1112	457157	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 21:40:00.017998+00	2025-10-28 21:40:00.027028+00
1	1116	458411	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 22:20:00.13069+00	2025-10-28 22:20:00.139712+00
1	1117	458714	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 22:30:00.146295+00	2025-10-28 22:30:00.157453+00
1	1118	459012	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 22:40:00.143797+00	2025-10-28 22:40:00.156278+00
1	1119	459318	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 22:50:00.16122+00	2025-10-28 22:50:00.240611+00
1	1120	459630	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 23:00:00.145495+00	2025-10-28 23:00:00.151672+00
1	1121	459929	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 23:10:00.168517+00	2025-10-28 23:10:00.217238+00
1	1156	470927	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-29 05:00:00.020304+00	2025-10-29 05:00:00.030998+00
1	1143	467102	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-29 02:50:00.024933+00	2025-10-29 02:50:00.028398+00
1	1122	460252	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 23:20:00.160585+00	2025-10-28 23:20:00.172635+00
1	1134	463957	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-29 01:20:00.140895+00	2025-10-29 01:20:00.148211+00
1	1123	460567	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 23:30:00.137113+00	2025-10-28 23:30:00.147574+00
1	1151	469473	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-29 04:10:00.092722+00	2025-10-29 04:10:00.160487+00
1	1135	464272	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-29 01:30:00.147333+00	2025-10-29 01:30:00.158665+00
1	1124	460858	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 23:40:00.142521+00	2025-10-28 23:40:00.163021+00
1	1144	467406	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-29 03:00:00.135731+00	2025-10-29 03:00:00.150081+00
1	1125	461148	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-28 23:50:00.040514+00	2025-10-28 23:50:00.1149+00
1	1136	464577	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-29 01:40:00.143876+00	2025-10-29 01:40:00.149628+00
1	1126	461443	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-29 00:00:00.047084+00	2025-10-29 00:00:00.142745+00
1	1170	475155	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-29 07:20:00.122226+00	2025-10-29 07:20:00.163633+00
1	1164	473291	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-29 06:20:00.047664+00	2025-10-29 06:20:00.061865+00
1	1145	467705	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-29 03:10:00.04985+00	2025-10-29 03:10:00.069286+00
1	1127	461761	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-29 00:10:00.029756+00	2025-10-29 00:10:00.034494+00
1	1137	464893	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-29 01:50:00.126336+00	2025-10-29 01:50:00.137634+00
1	1128	462059	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-29 00:20:00.106876+00	2025-10-29 00:20:00.14839+00
1	1157	471214	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-29 05:10:00.139735+00	2025-10-29 05:10:00.24724+00
1	1152	469767	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-29 04:20:00.02334+00	2025-10-29 04:20:00.033325+00
1	1138	465196	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-29 02:00:00.149318+00	2025-10-29 02:00:00.158542+00
1	1129	462361	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-29 00:30:00.111963+00	2025-10-29 00:30:00.160659+00
1	1146	468001	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-29 03:20:00.035501+00	2025-10-29 03:20:00.142729+00
1	1130	462720	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-29 00:40:00.137966+00	2025-10-29 00:40:00.148633+00
1	1139	465485	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-29 02:10:00.165015+00	2025-10-29 02:10:00.208053+00
1	1131	463024	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-29 00:50:00.166796+00	2025-10-29 00:50:00.179384+00
1	1161	472408	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-29 05:50:00.05171+00	2025-10-29 05:50:00.064864+00
1	1132	463352	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-29 01:00:00.142602+00	2025-10-29 01:00:00.153979+00
1	1140	465802	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-29 02:20:00.139865+00	2025-10-29 02:20:00.148277+00
1	1147	468312	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-29 03:30:00.168404+00	2025-10-29 03:30:00.229971+00
1	1133	463648	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-29 01:10:00.161152+00	2025-10-29 01:10:00.199321+00
1	1153	470055	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-29 04:30:00.037807+00	2025-10-29 04:30:00.142385+00
1	1141	466172	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-29 02:30:00.140023+00	2025-10-29 02:30:00.168841+00
1	1148	468603	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-29 03:40:00.036937+00	2025-10-29 03:40:00.060374+00
1	1142	466804	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-29 02:40:00.157877+00	2025-10-29 02:40:00.282227+00
1	1158	471510	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-29 05:20:00.017087+00	2025-10-29 05:20:00.021278+00
1	1154	470346	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-29 04:40:00.021051+00	2025-10-29 04:40:00.027841+00
1	1149	468899	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-29 03:50:00.110081+00	2025-10-29 03:50:00.215993+00
1	1173	476055	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-29 07:50:00.109794+00	2025-10-29 07:50:00.126722+00
1	1162	472706	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-29 06:00:00.161116+00	2025-10-29 06:00:00.171045+00
1	1150	469186	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-29 04:00:00.024875+00	2025-10-29 04:00:00.033234+00
1	1155	470638	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-29 04:50:00.135722+00	2025-10-29 04:50:00.258105+00
1	1159	471804	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-29 05:30:00.032558+00	2025-10-29 05:30:00.117047+00
1	1167	474283	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-29 06:50:00.131698+00	2025-10-29 06:50:00.146331+00
1	1165	473585	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-29 06:30:00.04039+00	2025-10-29 06:30:00.182037+00
1	1160	472106	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-29 05:40:00.126275+00	2025-10-29 05:40:00.135993+00
1	1163	473002	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-29 06:10:00.060541+00	2025-10-29 06:10:00.091511+00
1	1169	474863	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-29 07:10:00.121379+00	2025-10-29 07:10:00.225469+00
1	1166	473877	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-29 06:40:00.040071+00	2025-10-29 06:40:00.04683+00
1	1168	474573	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-29 07:00:00.031229+00	2025-10-29 07:00:00.056484+00
1	1174	476354	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-29 08:00:00.134565+00	2025-10-29 08:00:00.152125+00
1	1172	475760	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-29 07:40:00.147888+00	2025-10-29 07:40:00.209451+00
1	1171	475463	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-29 07:30:00.113896+00	2025-10-29 07:30:00.118514+00
1	1175	476648	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-29 08:10:00.157974+00	2025-10-29 08:10:00.283881+00
1	1176	476941	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-29 08:20:00.017969+00	2025-10-29 08:20:00.022903+00
1	1177	477233	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-29 08:30:00.166953+00	2025-10-29 08:30:00.210495+00
1	1178	477524	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-29 08:40:00.116021+00	2025-10-29 08:40:00.144579+00
1	1179	477825	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-29 08:50:00.020451+00	2025-10-29 08:50:00.040602+00
1	1180	478137	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-29 09:00:00.155556+00	2025-10-29 09:00:00.169246+00
1	1202	484703	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-29 12:40:00.019512+00	2025-10-29 12:40:00.035159+00
1	1181	478464	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-29 09:10:00.151367+00	2025-10-29 09:10:00.155996+00
1	1193	482073	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-29 11:10:00.042957+00	2025-10-29 11:10:00.172029+00
1	1182	478768	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-29 09:20:00.154692+00	2025-10-29 09:20:00.216364+00
1	1194	482370	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-29 11:20:00.033248+00	2025-10-29 11:20:00.039102+00
1	1183	479066	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-29 09:30:00.140526+00	2025-10-29 09:30:00.185011+00
1	1203	485021	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-29 12:50:00.057384+00	2025-10-29 12:50:00.063787+00
1	1184	479373	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-29 09:40:00.10993+00	2025-10-29 09:40:00.116319+00
1	1195	482661	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-29 11:30:00.139751+00	2025-10-29 11:30:00.315979+00
1	1185	479668	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-29 09:50:00.142816+00	2025-10-29 09:50:00.182375+00
1	1204	485332	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-29 13:00:00.169431+00	2025-10-29 13:00:00.198061+00
1	1186	479962	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-29 10:00:00.142217+00	2025-10-29 10:00:00.215754+00
1	1196	482946	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-29 11:40:00.02264+00	2025-10-29 11:40:00.073778+00
1	1187	480280	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-29 10:10:00.016737+00	2025-10-29 10:10:00.023435+00
1	1197	483240	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-29 11:50:00.022633+00	2025-10-29 11:50:00.037315+00
1	1188	480605	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-29 10:20:00.125816+00	2025-10-29 10:20:00.135271+00
1	1205	485643	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-29 13:10:00.153234+00	2025-10-29 13:10:00.165735+00
1	1189	480902	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-29 10:30:00.129601+00	2025-10-29 10:30:00.177748+00
1	1198	483523	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-29 12:00:00.048589+00	2025-10-29 12:00:00.200147+00
1	1190	481207	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-29 10:40:00.019448+00	2025-10-29 10:40:00.023805+00
1	1191	481498	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-29 10:50:00.048349+00	2025-10-29 10:50:00.070212+00
1	1199	483811	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-29 12:10:00.024823+00	2025-10-29 12:10:00.110674+00
1	1192	481789	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-29 11:00:00.154896+00	2025-10-29 11:00:00.294794+00
1	1200	484104	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-29 12:20:00.067585+00	2025-10-29 12:20:00.173236+00
1	1201	484396	postgres	postgres	SELECT close_expired_chat_rooms()	succeeded	1 row	2025-10-29 12:30:00.025581+00	2025-10-29 12:30:00.137888+00
\.


--
-- Data for Name: attestations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.attestations (id, username, wallet_address, tx_hash, attestation_uid, created_at, updated_at, is_demo, fid) FROM stdin;
651c311f-5eb5-49b1-b432-3ee939632a5d	emirulu	0x39fa26142ec357a421d49c9a4cf022e8fb6bbf04	0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890	0x37bde26b5d4048535c943c629d79833ac15d7956a4450a91de9980f31530162d	2025-10-23 21:06:30.82448+00	2025-10-24 02:06:23.22176+00	f	\N
8f6f62a0-9108-47f2-a3fb-b705ab973c9a	@cengizhaneu	0x39fa26142ec357a421d49c9a4cf022e8fb6bbf04	0x95e6050b3d5c5d98f55b7e5b3e75da8839621dc17d7ea2c4d3ff46ca406ffb39	0xa2ef52e7350d80ee2db0436b270009f8b609e233d3b1c0f7de065e7e92efcb27	2025-10-23 21:15:45.524448+00	2025-10-24 02:06:23.383251+00	f	\N
415c0ff9-ce0c-4cfb-aa10-f8cdbb007d9a	@cengizhaneu	0x39fa26142ec357a421d49c9a4cf022e8fb6bbf04	0xb652cd284c867c6f5c47660329c4066e106f0dbc0c0ab254fecd29d32f141a83	0xf15df2f558d17adb47519e0541974868044152e9199b457e5581d90438ddbf4e	2025-10-24 00:27:18.528907+00	2025-10-24 02:06:23.478555+00	f	\N
92aca8ac-5afb-41cf-9aa3-d6f5d1cc3e92	@cengizhaneu	0x39fa26142ec357a421d49c9a4cf022e8fb6bbf04	0xc22cd115e615731bc6526f8bf0fbbdd9bd775c39877150ea28e81916e3169534	0x743f63f767ce227dadc983946e1852c00e638f71e78171e9a882156d0e24f051	2025-10-24 00:28:33.735246+00	2025-10-24 02:06:23.573516+00	f	\N
18997e82-16b3-4465-ad21-f7ce9e0fb45a	@demo_alice	0x1111111111111111111111111111111111111111	0xaaa...111	0xdemoUID1	2025-10-22 03:10:39.052648+00	2025-10-24 03:10:39.052648+00	t	\N
3b7044fa-d18e-4740-aa43-ad78e11cf1cc	@demo_bob	0x2222222222222222222222222222222222222222	0xbbb...222	0xdemoUID2	2025-10-23 03:10:39.052648+00	2025-10-24 03:10:39.052648+00	t	\N
cc970594-038a-48f8-b51c-84729b8d0db4	@demo_cem	0x3333333333333333333333333333333333333333	0xccc...333	0xdemoUID3	2025-10-24 03:10:39.052648+00	2025-10-24 03:10:39.052648+00	t	\N
5f2cbf09-1138-4b00-b4d8-85c447854b9b	aysu16	0x39fa26142ec357a421d49c9a4cf022e8fb6bbf04	0x23c694e50a10d193002932d071a8a899f75ed277dc455b67639f051b2654968d	0xe610fbb3fac68e4922ab815e58f8f4de485f1800e10dcddb1c7fa2c5393b8ed2	2025-10-24 05:49:37.544125+00	2025-10-24 05:49:37.544125+00	f	1394398
\.


--
-- Data for Name: auto_match_runs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.auto_match_runs (id, started_at, completed_at, users_processed, matches_created, status, error_message) FROM stdin;
67de242b-24f9-41c7-8a4f-018133b8053d	2025-10-19 20:24:56.073+00	2025-10-19 20:24:58.014+00	2	1	completed	\N
496dac14-643b-48bb-8f52-0f21a045f678	2025-10-20 02:20:56.728+00	2025-10-20 02:20:57.306+00	2	0	completed	\N
799765aa-778f-4360-b30a-d9a78f8ab807	2025-10-20 02:27:06.712+00	2025-10-20 02:27:07.156+00	2	0	completed	\N
a7a19504-3d1c-4a01-a82d-2f7eb0230715	2025-10-20 05:52:32.402+00	2025-10-20 05:52:34.538+00	2	1	completed	\N
30e32aaf-6531-4a64-83c8-43afc039f661	2025-10-22 00:54:09.314+00	2025-10-22 00:54:16.591+00	5	1	completed	\N
2a90b3f7-893b-41ee-b0a0-f2076881c7ef	2025-10-23 00:23:26.033+00	2025-10-23 00:23:31.992+00	5	0	completed	\N
9c887d2d-636c-4254-912c-2601cd1b24b7	2025-10-24 00:41:29.477+00	2025-10-24 00:41:39.455+00	5	1	completed	\N
50c7545a-3e29-4909-bb48-191e08ff08e9	2025-10-25 00:51:32.732+00	2025-10-25 00:51:39.638+00	5	1	completed	\N
ca19cb3d-f5c9-4feb-bfee-0d212fa49c2c	2025-10-26 00:45:26.662+00	2025-10-26 00:45:34.812+00	5	0	completed	\N
0b8d504a-0b6f-4590-aa61-5b07e41b2772	2025-10-27 00:45:26.298+00	2025-10-27 00:45:33.907+00	5	1	completed	\N
eb1ffc4c-54ad-40b7-bedd-fa8b5ada8d14	2025-10-28 00:49:55.691+00	2025-10-28 00:50:06.213+00	6	1	completed	\N
1dd5b9d3-3261-4b10-87c7-011f4ff260f0	2025-10-29 00:42:55.222+00	2025-10-29 00:43:05.363+00	6	0	completed	\N
\.


--
-- Data for Name: chat_messages; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.chat_messages (id, room_id, sender_fid, body, created_at) FROM stdin;
9c005e63-3c1a-498d-a632-a70e7a2f5034	83b1b829-394e-4e43-a9e6-bb8d02bea1f7	543581	kardeşim	2025-10-22 03:35:29.501756+00
b9c6c255-9f13-41df-949f-2dfa591cafe8	83b1b829-394e-4e43-a9e6-bb8d02bea1f7	543581	ıuyıouyıyuıoyooıuyoıuıou	2025-10-22 03:35:54.891897+00
eba1497b-ea54-4571-8cd3-9b55086b82ea	83b1b829-394e-4e43-a9e6-bb8d02bea1f7	543581	ORADA MISIN	2025-10-22 03:36:51.701782+00
46a12056-a5f1-4c16-94ad-abab7233fc02	713eacac-aa72-4a5c-9c93-8f9c15d39e2c	517833	sa	2025-10-22 03:42:29.800882+00
7942c6aa-3dfd-4a76-9bc6-92068de8b1f3	713eacac-aa72-4a5c-9c93-8f9c15d39e2c	517833	selam	2025-10-22 03:42:40.999414+00
33773eed-cd63-4074-af10-99ef66471d03	713eacac-aa72-4a5c-9c93-8f9c15d39e2c	517833	sadsad	2025-10-22 03:42:44.073127+00
\.


--
-- Data for Name: chat_participants; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.chat_participants (room_id, fid, joined_at, completed_at, created_at, updated_at) FROM stdin;
83b1b829-394e-4e43-a9e6-bb8d02bea1f7	1396322	2025-10-22 03:35:15.609782+00	\N	2025-10-22 03:35:15.609782+00	2025-10-22 03:35:15.609782+00
83b1b829-394e-4e43-a9e6-bb8d02bea1f7	543581	2025-10-22 03:35:15.609782+00	2025-10-22 03:36:01.841+00	2025-10-22 03:35:15.609782+00	2025-10-22 03:36:02.068418+00
713eacac-aa72-4a5c-9c93-8f9c15d39e2c	543581	2025-10-22 03:42:10.498285+00	\N	2025-10-22 03:42:10.498285+00	2025-10-22 03:42:10.498285+00
713eacac-aa72-4a5c-9c93-8f9c15d39e2c	517833	2025-10-22 03:42:10.498285+00	\N	2025-10-22 03:42:10.498285+00	2025-10-22 03:42:10.498285+00
dcbd1ec9-36ab-44fb-98a8-741ba61983b3	543581	2025-10-28 02:39:43.373097+00	\N	2025-10-28 02:39:43.373097+00	2025-10-28 02:39:43.373097+00
dcbd1ec9-36ab-44fb-98a8-741ba61983b3	1401992	2025-10-28 02:39:43.373097+00	\N	2025-10-28 02:39:43.373097+00	2025-10-28 02:39:43.373097+00
3008f116-59e7-4c99-ae9b-02a74bce2521	1394398	2025-10-29 09:07:58.728093+00	\N	2025-10-29 09:07:58.728093+00	2025-10-29 09:07:58.728093+00
3008f116-59e7-4c99-ae9b-02a74bce2521	1423060	2025-10-29 09:07:58.728093+00	\N	2025-10-29 09:07:58.728093+00	2025-10-29 09:07:58.728093+00
\.


--
-- Data for Name: chat_rooms; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.chat_rooms (id, match_id, opened_at, first_join_at, closed_at, ttl_seconds, is_closed, created_at, updated_at) FROM stdin;
83b1b829-394e-4e43-a9e6-bb8d02bea1f7	ee4929a5-6c41-4183-adcf-e12f9b387890	2025-10-22 03:35:15.289+00	2025-10-22 03:35:19.724+00	2025-10-22 05:40:00.133641+00	7200	t	2025-10-22 03:35:15.494132+00	2025-10-22 05:40:00.133641+00
713eacac-aa72-4a5c-9c93-8f9c15d39e2c	d5970e84-1a31-42ed-b426-b62c8d573668	2025-10-22 03:42:10.269+00	2025-10-22 03:42:24.572+00	2025-10-22 05:50:00.147995+00	7200	t	2025-10-22 03:42:10.336025+00	2025-10-22 05:50:00.147995+00
dcbd1ec9-36ab-44fb-98a8-741ba61983b3	12922ebb-bf6b-4802-95ff-916023188c28	2025-10-28 02:39:43.058+00	\N	\N	7200	f	2025-10-28 02:39:43.276749+00	2025-10-28 02:39:43.276749+00
3008f116-59e7-4c99-ae9b-02a74bce2521	0ab915e1-eef5-4bb9-919a-aac098d8c183	2025-10-29 09:07:58.516+00	\N	\N	7200	f	2025-10-29 09:07:58.587205+00	2025-10-29 09:07:58.587205+00
\.


--
-- Data for Name: match_cooldowns; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.match_cooldowns (id, user_a_fid, user_b_fid, declined_at, cooldown_until, updated_at) FROM stdin;
b71bfc28-fd36-4911-a85e-534cba1cb5d1	22222	543581	2025-10-23 04:17:40.820746+00	2025-10-30 04:17:40.820746+00	2025-10-23 04:17:40.820746+00
43792494-6c53-4dd1-b8ea-22b6928949db	11111	543581	2025-10-23 04:20:42.020239+00	2025-10-30 04:20:42.020239+00	2025-10-23 04:20:42.020239+00
ef5575b7-b7b4-4f95-8c05-db66bc9db570	543581	1396322	2025-10-23 04:38:32.768704+00	2025-10-30 04:38:32.768704+00	2025-10-23 04:38:32.768704+00
4efc6db6-7642-4a63-bae0-aa15fa614440	543581	1394398	2025-10-27 05:14:39.270891+00	2025-11-03 05:14:39.270891+00	2025-10-27 05:14:39.270891+00
0aa4e944-442e-4824-9222-7070749f3c44	543581	1401992	2025-10-28 02:43:56.923893+00	2025-11-04 02:43:56.923893+00	2025-10-28 02:43:56.923893+00
75dc3662-2198-472a-ad11-476830f53d06	1401992	1423060	2025-10-29 00:55:10.652743+00	2025-11-05 00:55:10.652743+00	2025-10-29 00:55:10.652743+00
48e3c252-f57f-41c7-a46a-d880efb8e62c	1394398	1401992	2025-10-29 00:55:16.055521+00	2025-11-05 00:55:16.055521+00	2025-10-29 00:55:16.055521+00
d9933842-268d-48e8-aa53-95bce4dc25a6	1394398	1423060	2025-10-29 01:42:20.000773+00	2025-11-05 01:42:20.000773+00	2025-10-29 01:42:20.000773+00
b0fbd59d-df39-499d-ad4e-7ed6d4f7c499	543581	1423060	2025-10-29 09:06:54.023436+00	2025-11-05 09:06:54.023436+00	2025-10-29 09:06:54.023436+00
\.


--
-- Data for Name: match_suggestion_cooldowns; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.match_suggestion_cooldowns (id, user_a_fid, user_b_fid, cooldown_until, declined_suggestion_id, created_at) FROM stdin;
\.


--
-- Data for Name: match_suggestions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.match_suggestions (id, created_by_fid, user_a_fid, user_b_fid, message, status, a_accepted, b_accepted, chat_room_id, created_at, updated_at, rationale) FROM stdin;
30f5add3-db02-406e-803d-9300619c7f90	543581	11111	22222	sdafasdfasdfasdfasdfasdfa	proposed	f	f	\N	2025-10-21 18:08:19.270649+00	2025-10-21 18:08:19.270649+00	\N
9c8bd587-9562-4de8-b82d-5b108cf0f543	543581	1401992	1394398	as.dLgfkaişsldfkaişlfdkaşsildkaisdf	proposed	f	f	\N	2025-10-27 05:11:00.646667+00	2025-10-27 05:11:00.646667+00	\N
709a54bc-874d-495d-8f45-67fb9335dae2	543581	1394398	55555	asldşfjasğdjfasdşfjasşdjfasf	proposed	f	f	\N	2025-10-27 05:11:57.536378+00	2025-10-27 05:11:57.536378+00	\N
850bf829-cde5-4ba3-b24a-8b65be6c4413	1401992	1394398	543581	pğgkdfokgsdkfgsdfgsdfgsdfg	accepted_by_a	t	f	\N	2025-10-27 05:28:58.851809+00	2025-10-27 05:29:18.779022+00	\N
b0200a6f-94ce-4858-abbc-1941e936f991	1394398	1423504	1423060	işsldjfasidşlfDSAFkadfasdfmas	pending_external	f	f	\N	2025-10-29 02:46:53.128819+00	2025-10-29 02:46:53.128819+00	{"reason": "işsldjfasidşlfDSAFkadfasdfmas", "userAData": {"bio": "", "fid": 1423504, "username": "muhammet9816", "avatar_url": "https://imagedelivery.net/BXluQx4ige9GuW0Ia56BHw/be8deecf-57c0-45e4-0124-f4f136e1a700/original", "display_name": "muhammet9816"}, "userBData": {"bio": "", "fid": 1423060, "username": "shortshipper", "avatar_url": "https://imagedelivery.net/BXluQx4ige9GuW0Ia56BHw/5567fc3e-c6a7-4b6d-b410-a5c46554ab00/original", "display_name": "shortshipper"}, "isExternalSuggestion": true}
c6168be2-23c3-46ca-b1c7-15c8f39c63bc	1394398	1423060	1423504	ıjıojojııopjoıjoıpjoj	pending_external	f	f	\N	2025-10-29 02:58:13.973424+00	2025-10-29 02:58:13.973424+00	{"reason": "ıjıojojııopjoıjoıpjoj", "userAData": {"bio": "", "fid": 1423060, "username": "shortshipper", "avatar_url": "https://imagedelivery.net/BXluQx4ige9GuW0Ia56BHw/5567fc3e-c6a7-4b6d-b410-a5c46554ab00/original", "display_name": "shortshipper"}, "userBData": {"bio": "", "fid": 1423504, "username": "muhammet9816", "avatar_url": "https://imagedelivery.net/BXluQx4ige9GuW0Ia56BHw/be8deecf-57c0-45e4-0124-f4f136e1a700/original", "display_name": "muhammet9816"}, "isExternalSuggestion": true}
7ff07151-0373-4c9d-93f7-a653788b2001	1394398	1423504	1423060	alsdfiaşsfdmsaşfikasfasdfasd	pending_external	f	f	\N	2025-10-29 03:21:40.209167+00	2025-10-29 03:21:40.209167+00	{"reason": "alsdfiaşsfdmsaşfikasfasdfasd", "userAData": {"bio": "", "fid": 1423504, "username": "muhammet9816", "avatar_url": "https://imagedelivery.net/BXluQx4ige9GuW0Ia56BHw/be8deecf-57c0-45e4-0124-f4f136e1a700/original", "display_name": "muhammet9816"}, "userBData": {"bio": "", "fid": 1423060, "username": "shortshipper", "avatar_url": "https://imagedelivery.net/BXluQx4ige9GuW0Ia56BHw/5567fc3e-c6a7-4b6d-b410-a5c46554ab00/original", "display_name": "shortshipper"}, "isExternalSuggestion": true}
94598a16-5348-492a-8f0d-4280d6790319	517833	1423060	1111	hey bro hows going you there	proposed	f	f	\N	2025-10-29 05:55:37.056264+00	2025-10-29 05:55:37.056264+00	\N
425e17f3-5ed2-4473-8007-d2e9847b03a8	1	1423504	1423060	Production test — MeetShipper.com	pending_external	f	f	\N	2025-10-29 07:45:12.361726+00	2025-10-29 07:45:12.361726+00	{"reason": "Production test — MeetShipper.com", "userAData": {"bio": "", "fid": 1423504, "username": "muhammet9816", "avatar_url": "https://imagedelivery.net/BXluQx4ige9GuW0Ia56BHw/be8deecf-57c0-45e4-0124-f4f136e1a700/original", "display_name": "muhammet9816"}, "userBData": {"bio": "", "fid": 1423060, "username": "shortshipper", "avatar_url": "https://imagedelivery.net/BXluQx4ige9GuW0Ia56BHw/5567fc3e-c6a7-4b6d-b410-a5c46554ab00/original", "display_name": "shortshipper"}, "isExternalSuggestion": true}
9440fa22-c4a7-4e40-b338-54a61de08d88	1	1423504	1423060	Production link test — MeetShipper.com	pending_external	f	f	\N	2025-10-29 08:02:06.926254+00	2025-10-29 08:02:06.926254+00	{"reason": "Production link test — MeetShipper.com", "userAData": {"bio": "", "fid": 1423504, "username": "muhammet9816", "avatar_url": "https://imagedelivery.net/BXluQx4ige9GuW0Ia56BHw/be8deecf-57c0-45e4-0124-f4f136e1a700/original", "display_name": "muhammet9816"}, "userBData": {"bio": "", "fid": 1423060, "username": "shortshipper", "avatar_url": "https://imagedelivery.net/BXluQx4ige9GuW0Ia56BHw/5567fc3e-c6a7-4b6d-b410-a5c46554ab00/original", "display_name": "shortshipper"}, "isExternalSuggestion": true}
\.


--
-- Data for Name: matches; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.matches (id, user_a_fid, user_b_fid, created_by_fid, status, message, a_accepted, b_accepted, created_at, updated_at, created_by, rationale, meeting_link, scheduled_at, completed_at, a_completed, b_completed, meeting_started_at, meeting_expires_at, meeting_closed_at, meeting_state) FROM stdin;
acb28422-7a69-4f48-a358-53265d963ea3	543581	1394398	543581	accepted	hadiia asdlfkalsidfkasdlfasdfasfsdaf	t	f	2025-10-21 05:08:17.357038+00	2025-10-21 05:12:21.322813+00	user	{"score": 0, "manualMatch": true, "requestedBy": 543581, "introductionMessage": "hadiia asdlfkalsidfkasdlfasdfasfsdaf"}	\N	\N	\N	f	f	\N	\N	\N	scheduled
691d6c6f-8985-4d5c-8f28-99837b73bff8	543581	1111	543581	accepted	sadfasdflasfasşlfkasdfasdfas	t	f	2025-10-21 05:11:50.124157+00	2025-10-21 05:12:21.322813+00	user	{"score": 0, "manualMatch": true, "requestedBy": 543581, "introductionMessage": "sadfasdflasfasşlfkasdfasdfas"}	\N	\N	\N	f	f	\N	\N	\N	scheduled
fc38fe9d-a5a1-46d8-9378-4aea7fe609bf	11111	22222	11111	accepted	\N	t	t	2025-10-20 05:52:34.38215+00	2025-10-20 05:57:43.341604+00	system	{"score": 0.6, "bioKeywords": [], "traitOverlap": ["Trader", "DeFi-explorer", "Data-driven", "Airdropper", "Risk-manager"], "bioSimilarity": 0, "traitSimilarity": 1}	\N	\N	\N	f	f	\N	\N	\N	scheduled
281a8391-b4de-40fc-9ee6-c67662fcfe8a	11111	22222	11111	accepted	\N	t	t	2025-10-19 20:24:57.526956+00	2025-10-20 06:04:19.58459+00	system	{"score": 0.782, "bioKeywords": ["crypto", "defi", "builder", "investor", "trading"], "traitOverlap": ["Trader", "Investor", "Builder", "Thinker", "Analyst", "Visionary"], "bioSimilarity": 0.45454545454545453, "traitSimilarity": 1}	https://meet.google.com/ezf-cgxa-ouv	2025-10-21 06:04:19.58459+00	\N	f	f	\N	\N	\N	scheduled
df698cdd-cf15-473e-b0e1-632c0a824b71	11111	22222	11111	cancelled	Auto-created test match	f	f	2025-10-20 02:20:11.232671+00	2025-10-20 02:24:55.948282+00	system	\N	\N	\N	\N	f	f	\N	\N	\N	scheduled
0cf44a49-7f5c-4c6b-a821-73b57f187bf8	1394398	543581	1394398	accepted	Merhaba, ben eşin trader olmak istiyorum en kısa zamanda görüşelim	t	t	2025-10-20 10:18:26.389951+00	2025-10-20 15:57:45.786555+00	user	{"score": 0, "manualMatch": true, "requestedBy": 1394398, "introductionMessage": "Merhaba, ben eşin trader olmak istiyorum en kısa zamanda görüşelim"}	\N	\N	\N	f	f	\N	\N	\N	scheduled
459711c9-14d9-4aef-8185-35b893a8540e	11111	22222	11111	proposed	\N	f	f	2025-10-22 00:54:15.199619+00	2025-10-22 00:54:15.199619+00	system	{"score": 0.6, "bioKeywords": [], "traitOverlap": ["Trader", "DeFi-explorer", "Data-driven", "Airdropper", "Risk-manager"], "bioSimilarity": 0, "traitSimilarity": 1}	\N	\N	\N	f	f	\N	\N	\N	scheduled
1cdebf76-db49-4476-9f09-2c899ae9607d	543581	22222	543581	declined	asşdjfkakşsjdfşasdjfkşasdjfasd	f	f	2025-10-23 03:48:54.679323+00	2025-10-23 04:17:40.820746+00	user	{"score": 0, "manualMatch": true, "requestedBy": 543581, "introductionMessage": "asşdjfkakşsjdfşasdjfkşasdjfasd"}	\N	\N	\N	f	f	\N	\N	\N	scheduled
ee4929a5-6c41-4183-adcf-e12f9b387890	1396322	543581	1396322	accepted	Bc I want 1 million dollar	t	t	2025-10-21 19:08:53.226208+00	2025-10-22 05:40:00.133641+00	user	{"score": 0, "manualMatch": true, "requestedBy": 1396322, "introductionMessage": "Bc I want 1 million dollar"}	\N	\N	2025-10-22 05:40:00.133641+00	f	f	\N	\N	\N	scheduled
d5970e84-1a31-42ed-b426-b62c8d573668	543581	517833	543581	accepted	Hey birader gel bi senin aklına alayım	t	t	2025-10-22 03:39:54.782006+00	2025-10-22 05:50:00.147995+00	user	{"score": 0, "manualMatch": true, "requestedBy": 543581, "introductionMessage": "Hey birader gel bi senin aklına alayım"}	\N	\N	2025-10-22 05:50:00.147995+00	f	f	\N	\N	\N	scheduled
35cf47c6-5a93-4467-833f-552ada4d88e8	543581	11111	543581	declined	asdfasdfasfdasfasdfasdfas	f	f	2025-10-21 18:09:49.527733+00	2025-10-23 04:20:42.020239+00	user	{"score": 0, "manualMatch": true, "requestedBy": 543581, "introductionMessage": "asdfasdfasfdasfasdfasdfas"}	\N	\N	\N	f	f	\N	\N	\N	scheduled
9b27cca6-fbe2-45f0-bd27-9f673095e5e4	543581	1396322	543581	declined	werfasfasdasdfdsafasfdsadf	f	f	2025-10-23 04:38:27.337721+00	2025-10-23 04:38:32.768704+00	user	{"score": 0, "manualMatch": true, "requestedBy": 543581, "introductionMessage": "werfasfasdasdfdsafasfdsadf"}	\N	\N	\N	f	f	\N	\N	\N	scheduled
7c57a23e-3c9c-4b77-b184-4c941a98ed70	11111	22222	11111	proposed	\N	f	f	2025-10-24 00:41:36.93996+00	2025-10-24 00:41:36.93996+00	system	{"score": 0.6, "bioKeywords": [], "traitOverlap": ["Trader", "DeFi-explorer", "Data-driven", "Airdropper", "Risk-manager"], "bioSimilarity": 0, "traitSimilarity": 1}	\N	\N	\N	f	f	\N	\N	\N	scheduled
fb077b0d-db62-4a51-ad3e-48adb1a2740f	11111	22222	11111	proposed	\N	f	f	2025-10-25 00:51:38.483093+00	2025-10-25 00:51:38.483093+00	system	{"score": 0.6, "bioKeywords": [], "traitOverlap": ["Trader", "DeFi-explorer", "Data-driven", "Airdropper", "Risk-manager"], "bioSimilarity": 0, "traitSimilarity": 1}	\N	\N	\N	f	f	\N	\N	\N	scheduled
e0d5b410-48ef-4610-a53b-7c06d7648b2c	11111	22222	11111	proposed	\N	f	f	2025-10-27 00:45:32.37938+00	2025-10-27 00:45:32.37938+00	system	{"score": 0.6, "bioKeywords": [], "traitOverlap": ["Trader", "DeFi-explorer", "Data-driven", "Airdropper", "Risk-manager"], "bioSimilarity": 0, "traitSimilarity": 1}	\N	\N	\N	f	f	\N	\N	\N	scheduled
f8ea4f7f-ed56-4e36-8bd2-111c0e3898e2	543581	1394398	543581	completed	asdsaafsadfsadfasdfasdfasdfasdf	t	t	2025-10-20 16:03:30.09143+00	2025-10-20 22:57:42.01918+00	user	{"score": 0, "manualMatch": true, "requestedBy": 543581, "introductionMessage": "asdsaafsadfsadfasdfasdfasdfasdf"}	https://meetshipper.whereby.com/meetshipper-da31ded2-f384-47b7-952b-2e498a98ac7d	2025-10-20 16:05:32.042+00	2025-10-20 22:57:42.01918+00	t	t	\N	\N	2025-10-20 22:57:42.01918+00	closed
203a60be-d289-45c8-bac0-c103d30b1d64	1394398	543581	1394398	completed	ASDLFJASDFASDFAİSDFKSLFŞKLSFDŞKŞADFA	t	t	2025-10-20 16:51:46.418829+00	2025-10-20 22:57:42.01918+00	user	{"score": 0, "manualMatch": true, "requestedBy": 1394398, "introductionMessage": "ASDLFJASDFASDFAİSDFKSLFŞKLSFDŞKŞADFA"}	https://meetshipper.whereby.com/meetshipper-e412bc33-4705-472e-b227-3e6f9ee60a32	2025-10-20 16:53:04.69+00	2025-10-20 22:57:42.01918+00	t	t	\N	\N	2025-10-20 22:57:42.01918+00	closed
2f1b98f0-5b0e-46d9-aeb9-a2faa20392b3	543581	1394398	543581	completed	dsafgdfshgfhfdjfdkjghjfghjfghj	t	t	2025-10-20 20:38:00.817459+00	2025-10-20 22:57:42.01918+00	user	{"score": 0, "manualMatch": true, "requestedBy": 543581, "introductionMessage": "dsafgdfshgfhfdjfdkjghjfghjfghj"}	https://meetshipper.whereby.com/meetshipper-2188caf0-54de-4a76-be63-e82a665158bd	2025-10-20 22:11:45.185+00	2025-10-20 22:57:42.01918+00	t	t	\N	\N	2025-10-20 22:57:42.01918+00	closed
93c49d73-fcec-466c-8749-df77793e8ebc	543581	1394398	543581	completed	llldsafşaslidfmasşdfmasldmfas	t	t	2025-10-20 22:19:41.009403+00	2025-10-20 23:00:15.814749+00	user	{"score": 0, "manualMatch": true, "requestedBy": 543581, "introductionMessage": "llldsafşaslidfmasşdfmasldmfas"}	https://meetshipper.whereby.com/meetshipper-1d4a8120-6366-47b2-89db-1d64616e00d9	2025-10-20 22:59:11.049+00	2025-10-20 23:00:15.814749+00	t	t	\N	\N	2025-10-20 23:00:15.618+00	closed
2d3fff29-3eea-4367-95c8-1dc4db3c28c8	1111	543581	1111	accepted	Sizinle tanışmak istiyorum proje hakkında konuşmak istiyorum zaman ayırırsanız bugün görüşelim	f	t	2025-10-20 09:43:44.009969+00	2025-10-21 05:07:07.349585+00	user	{"score": 0, "manualMatch": true, "requestedBy": 1111, "introductionMessage": "Sizinle tanışmak istiyorum proje hakkında konuşmak istiyorum zaman ayırırsanız bugün görüşelim"}	\N	\N	\N	f	f	\N	\N	\N	scheduled
865d99b2-8616-44ad-b885-92854ff57a3e	543581	22222	543581	accepted	fgjddfgsdfgsdfgsdfgsdfgsdfg	t	f	2025-10-20 20:51:23.32395+00	2025-10-21 05:07:07.349585+00	user	{"score": 0, "manualMatch": true, "requestedBy": 543581, "introductionMessage": "fgjddfgsdfgsdfgsdfgsdfgsdfg"}	\N	\N	\N	f	f	\N	\N	\N	scheduled
981d8ae7-b3f6-4f33-b019-9da325ffade1	543581	11111	543581	accepted	dşlfgjkdsfjgsşdfjglksdfkjlsdjg	t	f	2025-10-20 23:22:53.178138+00	2025-10-21 05:07:07.349585+00	user	{"score": 0, "manualMatch": true, "requestedBy": 543581, "introductionMessage": "dşlfgjkdsfjgsşdfjglksdfkjlsdjg"}	\N	\N	\N	f	f	\N	\N	\N	scheduled
bd477f2d-dc40-43ff-a919-299445da9fa6	543581	1394398	543581	declined	İşfdaisdfkawoğfkasdfasdlfas322323	f	f	2025-10-27 05:09:20.401614+00	2025-10-27 05:14:39.270891+00	user	{"score": 0, "manualMatch": true, "requestedBy": 543581, "introductionMessage": "İşfdaisdfkawoğfkasdfasdlfas322323"}	\N	\N	\N	f	f	\N	\N	\N	scheduled
cc6f06b0-212f-4a36-a076-ec26a7eb7b17	11111	22222	11111	proposed	\N	f	f	2025-10-28 00:50:04.6375+00	2025-10-28 00:50:04.6375+00	system	{"score": 0.6, "bioKeywords": [], "traitOverlap": ["Trader", "DeFi-explorer", "Data-driven", "Airdropper", "Risk-manager"], "bioSimilarity": 0, "traitSimilarity": 1}	\N	\N	\N	f	f	\N	\N	\N	scheduled
12922ebb-bf6b-4802-95ff-916023188c28	543581	1401992	543581	accepted	Eşleşmek istiyorum deneyimleyelim burayı	t	t	2025-10-28 02:28:59.375828+00	2025-10-28 02:39:43.059384+00	user	{"score": 0, "manualMatch": true, "requestedBy": 543581, "isExternalUser": false, "introductionMessage": "Eşleşmek istiyorum deneyimleyelim burayı"}	\N	\N	\N	f	f	\N	\N	\N	scheduled
effc3baf-02ed-43e8-b066-2e066937c77f	1401992	543581	1401992	declined	lşjhlhjkşjşlkjkşljşlkjlşkjljşjşlkjklşjlşj	f	f	2025-10-28 02:40:40.011553+00	2025-10-28 02:43:56.923893+00	user	{"score": 0, "manualMatch": true, "requestedBy": 1401992, "isExternalUser": false, "introductionMessage": "lşjhlhjkşjşlkjkşljşlkjlşkjljşjşlkjklşjlşj"}	\N	\N	\N	f	f	\N	\N	\N	scheduled
b4b5a8c6-0f24-4e48-965b-a7fb959d7f71	543581	10259	543581	pending_external	Alexxxxxxxxxxxxxxxxxxx	f	f	2025-10-28 22:37:46.571579+00	2025-10-28 22:37:46.571579+00	user	{"score": 0, "manualMatch": true, "requestedBy": 543581, "isExternalUser": true, "externalUserData": {"bio": "likes building things • working on v0.dev at Vercel • https://alexgrover.me", "fid": 10259, "username": "alexgrover", "avatar_url": "https://imagedelivery.net/BXluQx4ige9GuW0Ia56BHw/c93f613c-597c-455a-73fe-65f5e1610f00/original", "display_name": "alex"}, "introductionMessage": "Alexxxxxxxxxxxxxxxxxxx"}	\N	\N	\N	f	f	\N	\N	\N	scheduled
a068abdb-02dd-4ebb-ae29-ffcd38a09198	543581	18559	543581	pending_external	Terece xdxopğhlşpor1452	f	f	2025-10-28 22:42:06.741999+00	2025-10-28 22:42:06.741999+00	user	{"score": 0, "manualMatch": true, "requestedBy": 543581, "isExternalUser": true, "externalUserData": {"bio": "Ethereum\\nhttps://terencecha.in/", "fid": 18559, "username": "terencechain", "avatar_url": "https://i.imgur.com/fmFhor4.jpg", "display_name": "terence"}, "introductionMessage": "Terece xdxopğhlşpor1452"}	\N	\N	\N	f	f	\N	\N	\N	scheduled
82427b50-9dda-4a84-ae8e-b153025dd16f	1401992	1423060	1401992	declined	ksdajkajsdfkjsalkfjasldfş	f	f	2025-10-29 00:09:50.692852+00	2025-10-29 00:55:10.652743+00	user	{"score": 0, "manualMatch": true, "requestedBy": 1401992, "isExternalUser": false, "introductionMessage": "ksdajkajsdfkjsalkfjasldfş"}	\N	\N	\N	f	f	\N	\N	\N	scheduled
66f3134e-d020-4ef1-8446-3d1ca6ffdef5	1401992	1394398	1401992	declined	çöasdhşfasnflşasfdlsda	f	f	2025-10-28 02:44:20.448108+00	2025-10-29 00:55:16.055521+00	user	{"score": 0, "manualMatch": true, "requestedBy": 1401992, "isExternalUser": false, "introductionMessage": "çöasdhşfasnflşasfdlsda"}	\N	\N	\N	f	f	\N	\N	\N	scheduled
caaf5141-3a53-40a7-ae16-df38f912ec2a	1394398	1423060	1394398	declined	lksdjfşlkajdasjdfasdf	f	f	2025-10-29 00:59:31.09874+00	2025-10-29 01:42:20.000773+00	user	{"score": 0, "manualMatch": true, "requestedBy": 1394398, "isExternalUser": true, "externalUserData": {"bio": "", "fid": 1423060, "username": "shortshipper", "avatar_url": "https://imagedelivery.net/BXluQx4ige9GuW0Ia56BHw/5567fc3e-c6a7-4b6d-b410-a5c46554ab00/original", "display_name": "shortshipper"}, "introductionMessage": "lksdjfşlkajdasjdfasdf"}	\N	\N	\N	f	f	\N	\N	\N	scheduled
080aefa1-5fe3-4a8a-8174-a25e590f8892	1394398	1423060	1394398	accepted_by_a	qrerafsdfsdafasdfsadfasd	t	f	2025-10-29 01:16:36.09132+00	2025-10-29 01:42:26.553574+00	user	{"score": 0, "manualMatch": true, "requestedBy": 1394398, "isExternalUser": true, "externalUserData": {"bio": "", "fid": 1423060, "username": "shortshipper", "avatar_url": "https://imagedelivery.net/BXluQx4ige9GuW0Ia56BHw/5567fc3e-c6a7-4b6d-b410-a5c46554ab00/original", "display_name": "shortshipper"}, "introductionMessage": "qrerafsdfsdafasdfsadfasd"}	\N	\N	\N	f	f	\N	\N	\N	scheduled
8464254e-dc77-417c-a9d9-3ccc97f5e216	543581	517833	543581	accepted_by_b	adfasdfasdfasfasdfasdfasdfasdf	f	t	2025-10-28 02:34:04.95484+00	2025-10-29 05:51:07.894638+00	user	{"score": 0, "manualMatch": true, "requestedBy": 543581, "isExternalUser": false, "introductionMessage": "adfasdfasdfasfasdfasdfasdfasdf"}	\N	\N	\N	f	f	\N	\N	\N	scheduled
f7e1e361-3115-492b-978d-9fe855cbe408	517833	55555	517833	proposed	hi momomomomomomomomo	f	f	2025-10-29 05:52:19.623357+00	2025-10-29 05:52:19.623357+00	user	{"score": 0, "manualMatch": true, "requestedBy": 517833, "isExternalUser": false, "introductionMessage": "hi momomomomomomomomo"}	\N	\N	\N	f	f	\N	\N	\N	scheduled
360b5956-974d-45c7-91cc-21345a2b9565	1423060	1424386	1423060	proposed	sdlfşgaijsşlgkşlgsasgs	f	f	2025-10-29 09:05:30.334639+00	2025-10-29 09:05:30.334639+00	user	{"score": 0, "manualMatch": true, "requestedBy": 1423060, "isExternalUser": false, "introductionMessage": "sdlfşgaijsşlgkşlgsasgs"}	\N	\N	\N	f	f	\N	\N	\N	scheduled
5cfa971e-a87d-4328-a10f-a6cb0345d701	543581	1423060	543581	declined	Hadi hadi go go hadi bebekkk	f	f	2025-10-28 22:59:10.667467+00	2025-10-29 09:06:54.023436+00	user	{"score": 0, "manualMatch": true, "requestedBy": 543581, "isExternalUser": true, "externalUserData": {"bio": "", "fid": 1423060, "username": "shortshipper", "avatar_url": "https://imagedelivery.net/BXluQx4ige9GuW0Ia56BHw/5567fc3e-c6a7-4b6d-b410-a5c46554ab00/original", "display_name": "shortshipper"}, "introductionMessage": "Hadi hadi go go hadi bebekkk"}	\N	\N	\N	f	f	\N	\N	\N	scheduled
80830400-cebf-4b80-b44c-0f759976b2e6	1423060	1424386	1423060	accepted_by_a	şlsdafgşlkajdfgiafdgşdfjsgls	t	f	2025-10-29 08:54:22.073054+00	2025-10-29 09:07:30.017773+00	user	{"score": 0, "manualMatch": true, "requestedBy": 1423060, "isExternalUser": true, "externalUserData": {"bio": "", "fid": 1424386, "username": "yancar", "avatar_url": "https://imagedelivery.net/BXluQx4ige9GuW0Ia56BHw/5a2717bd-8a5e-4596-12ba-67e920d4f600/original", "display_name": "yancar"}, "introductionMessage": "şlsdafgşlkajdfgiafdgşdfjsgls"}	\N	\N	\N	f	f	\N	\N	\N	scheduled
0ab915e1-eef5-4bb9-919a-aac098d8c183	1394398	1423060	1394398	accepted	adsfasdfasfasfasdfasdfas	t	t	2025-10-29 01:26:49.631435+00	2025-10-29 09:07:58.323291+00	user	{"score": 0, "manualMatch": true, "requestedBy": 1394398, "isExternalUser": true, "externalUserData": {"bio": "", "fid": 1423060, "username": "shortshipper", "avatar_url": "https://imagedelivery.net/BXluQx4ige9GuW0Ia56BHw/5567fc3e-c6a7-4b6d-b410-a5c46554ab00/original", "display_name": "shortshipper"}, "introductionMessage": "adsfasdfasfasfasdfasdfas"}	\N	\N	\N	f	f	\N	\N	\N	scheduled
9d70e248-f0d5-4156-93e4-543eacb86797	1401992	1423504	1401992	accepted_by_a	joogbnşljlklşkjşlkjkşl	t	f	2025-10-29 09:10:13.840929+00	2025-10-29 12:44:27.486885+00	user	{"score": 0, "manualMatch": true, "requestedBy": 1401992, "isExternalUser": true, "externalUserData": {"bio": "", "fid": 1423504, "username": "muhammet9816", "avatar_url": "https://imagedelivery.net/BXluQx4ige9GuW0Ia56BHw/be8deecf-57c0-45e4-0124-f4f136e1a700/original", "display_name": "muhammet9816"}, "introductionMessage": "joogbnşljlklşkjşlkjkşl"}	\N	\N	\N	f	f	\N	\N	\N	scheduled
ad8bfae4-cd98-45a9-84c3-52f6eacdc2fd	1401992	517833	1401992	accepted_by_a	I believe we share some common interests, and I’d like to get to know you and have a conversation.	t	f	2025-10-29 12:47:47.009014+00	2025-10-29 12:47:55.357674+00	user	{"score": 0, "manualMatch": true, "requestedBy": 1401992, "isExternalUser": false, "introductionMessage": "I believe we share some common interests, and I’d like to get to know you and have a conversation."}	\N	\N	\N	f	f	\N	\N	\N	scheduled
98d5c36b-25c1-40ff-8b23-9f4f516b7de3	1401992	1416480	1401992	accepted_by_a	I believe we share some common interests, and I’d like to get to know you and have a conversation.	t	f	2025-10-29 12:50:26.60177+00	2025-10-29 12:50:36.019044+00	user	{"score": 0, "manualMatch": true, "requestedBy": 1401992, "isExternalUser": true, "externalUserData": {"bio": "Automated Farcaster notifier for Meet Shipper match requests.", "fid": 1416480, "username": "meetshipperapp", "avatar_url": "https://imgur.com/u6c0DoG.png", "display_name": "Meet Shipper Notifier"}, "introductionMessage": "I believe we share some common interests, and I’d like to get to know you and have a conversation."}	\N	\N	\N	f	f	\N	\N	\N	scheduled
\.


--
-- Data for Name: messages; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.messages (id, match_id, sender_fid, content, is_system_message, created_at) FROM stdin;
bb4aea7c-8997-4eab-b182-9e0f89b2ed91	281a8391-b4de-40fc-9ee6-c67662fcfe8a	11111	Match created! alpha_test has introduced you both.	t	2025-10-19 20:24:57.526956+00
f6bf1b6c-66fb-44b0-ad25-af1b4ac71df6	df698cdd-cf15-473e-b0e1-632c0a824b71	11111	Match created! alice has introduced you both. Message: Auto-created test match	t	2025-10-20 02:20:11.232671+00
2ae6d67a-fc75-447c-834f-3572bdc252a9	fc38fe9d-a5a1-46d8-9378-4aea7fe609bf	11111	Match created! alice has introduced you both.	t	2025-10-20 05:52:34.38215+00
661f508b-b81c-45df-b2e5-34713ae776a5	2d3fff29-3eea-4367-95c8-1dc4db3c28c8	1111	Match created! alice has introduced you both. Message: Sizinle tanışmak istiyorum proje hakkında konuşmak istiyorum zaman ayırırsanız bugün görüşelim	t	2025-10-20 09:43:44.009969+00
1c0115d3-2693-4c9b-b7dd-13224f13258d	2d3fff29-3eea-4367-95c8-1dc4db3c28c8	1111	Match request: "Sizinle tanışmak istiyorum proje hakkında konuşmak istiyorum zaman ayırırsanız bugün görüşelim"	t	2025-10-20 09:43:44.009969+00
4255f241-b5d7-4579-917e-1a753a271bf3	2d3fff29-3eea-4367-95c8-1dc4db3c28c8	543581	cengizhaneu accepted the match! Waiting for your response.	t	2025-10-20 09:54:29.085293+00
e5ee4d67-edf5-4b6e-8af9-226720b5e3ee	0cf44a49-7f5c-4c6b-a821-73b57f187bf8	1394398	Match created! aysu16 has introduced you both. Message: Merhaba, ben eşin trader olmak istiyorum en kısa zamanda görüşelim	t	2025-10-20 10:18:26.389951+00
52d486d6-2014-4b17-aa56-a8081749152b	0cf44a49-7f5c-4c6b-a821-73b57f187bf8	1394398	Match request: "Merhaba, ben eşin trader olmak istiyorum en kısa zamanda görüşelim"	t	2025-10-20 10:18:26.529454+00
39e0e408-ed01-4a65-86a7-915ae65bbb36	0cf44a49-7f5c-4c6b-a821-73b57f187bf8	1394398	aysu16 accepted the match! Waiting for your response.	t	2025-10-20 10:18:35.808017+00
abd35e52-19dd-4dfd-84f1-9a0f9d8e6091	0cf44a49-7f5c-4c6b-a821-73b57f187bf8	1394398	Meeting scheduled! Join here: http://localhost:3000/mini/meeting/56a91381f7918c341aae3b966c543cf7	t	2025-10-20 15:12:37.497429+00
13c145e3-7c81-42dd-b1d5-ea1d07b76348	0cf44a49-7f5c-4c6b-a821-73b57f187bf8	1394398	🎉 Match accepted! Both parties agreed to meet. Your meeting link: http://localhost:3000/mini/meeting/56a91381f7918c341aae3b966c543cf7	t	2025-10-20 15:12:37.633326+00
9d541613-b714-413a-95bc-5869da5caf98	0cf44a49-7f5c-4c6b-a821-73b57f187bf8	543581	🎉 Match accepted! Both parties agreed to meet. Your meeting link: http://localhost:3000/mini/meeting/56a91381f7918c341aae3b966c543cf7	t	2025-10-20 15:12:37.746451+00
cb4d136a-dd56-49fe-9a1d-804ba7768092	f8ea4f7f-ed56-4e36-8bd2-111c0e3898e2	543581	Match created! cengizhaneu has introduced you both. Message: asdsaafsadfsadfasdfasdfasdfasdf	t	2025-10-20 16:03:30.09143+00
796bdfe0-2123-4dba-8b60-2728658018af	f8ea4f7f-ed56-4e36-8bd2-111c0e3898e2	543581	Match request: "asdsaafsadfsadfasdfasdfasdfasdf"	t	2025-10-20 16:03:30.325273+00
584f42d2-0a55-4310-bd0f-ec2235594d98	f8ea4f7f-ed56-4e36-8bd2-111c0e3898e2	543581	cengizhaneu accepted the match! Waiting for your response.	t	2025-10-20 16:03:37.708899+00
d08e9008-5da3-4656-b0a1-23ef35b96896	f8ea4f7f-ed56-4e36-8bd2-111c0e3898e2	543581	Meeting scheduled! Join here: https://meetshipper.whereby.com/meetshipper-da31ded2-f384-47b7-952b-2e498a98ac7d	t	2025-10-20 16:05:32.233061+00
6509d48b-9c87-48ad-8298-89239ee2bf0f	f8ea4f7f-ed56-4e36-8bd2-111c0e3898e2	543581	🎉 Match accepted! Both parties agreed to meet. Your meeting link: https://meetshipper.whereby.com/meetshipper-da31ded2-f384-47b7-952b-2e498a98ac7d	t	2025-10-20 16:05:32.327784+00
e0853345-bccd-419a-aa48-3490c17f2acd	f8ea4f7f-ed56-4e36-8bd2-111c0e3898e2	1394398	🎉 Match accepted! Both parties agreed to meet. Your meeting link: https://meetshipper.whereby.com/meetshipper-da31ded2-f384-47b7-952b-2e498a98ac7d	t	2025-10-20 16:05:32.43442+00
5982aec8-eea0-4e31-b0a1-d600eff1e96a	203a60be-d289-45c8-bac0-c103d30b1d64	1394398	Match created! aysu16 has introduced you both. Message: ASDLFJASDFASDFAİSDFKSLFŞKLSFDŞKŞADFA	t	2025-10-20 16:51:46.418829+00
ca821ee5-469c-4d07-a1ab-1490c919c4ed	203a60be-d289-45c8-bac0-c103d30b1d64	1394398	Match request: "ASDLFJASDFASDFAİSDFKSLFŞKLSFDŞKŞADFA"	t	2025-10-20 16:51:46.56398+00
512cf9e8-b51d-475f-a0cd-fc1a63ce5c95	203a60be-d289-45c8-bac0-c103d30b1d64	1394398	aysu16 accepted the match! Waiting for your response.	t	2025-10-20 16:51:52.634114+00
67372ae9-c390-4f8c-8162-e704850915ae	203a60be-d289-45c8-bac0-c103d30b1d64	1394398	Meeting scheduled! Join here: https://meetshipper.whereby.com/meetshipper-e412bc33-4705-472e-b227-3e6f9ee60a32	t	2025-10-20 16:53:04.942117+00
09f69378-4bc8-4b19-8285-e73fed1c8570	203a60be-d289-45c8-bac0-c103d30b1d64	1394398	🎉 Match accepted! Both parties agreed to meet. Your meeting link: https://meetshipper.whereby.com/meetshipper-e412bc33-4705-472e-b227-3e6f9ee60a32	t	2025-10-20 16:53:05.035667+00
efdea7fc-47c5-4bf3-a931-9db96d6c1b75	203a60be-d289-45c8-bac0-c103d30b1d64	543581	🎉 Match accepted! Both parties agreed to meet. Your meeting link: https://meetshipper.whereby.com/meetshipper-e412bc33-4705-472e-b227-3e6f9ee60a32	t	2025-10-20 16:53:05.137081+00
bd77c026-0f97-443e-8230-86e4eb0f57f9	203a60be-d289-45c8-bac0-c103d30b1d64	543581	cengizhaneu marked the meeting as completed. Waiting for the other party to confirm.	t	2025-10-20 16:53:34.24761+00
f05b3614-1f2e-4808-b15d-af4e28558538	203a60be-d289-45c8-bac0-c103d30b1d64	1394398	✅ Meeting completed! Both parties confirmed the meeting took place.	t	2025-10-20 16:53:59.588921+00
cf80f436-d25d-4417-a95d-0a987180fea6	203a60be-d289-45c8-bac0-c103d30b1d64	543581	✅ Meeting completed! Both parties confirmed the meeting took place.	t	2025-10-20 16:53:59.588921+00
a59ce15a-ce4d-4b19-a466-f3ced65a7186	2f1b98f0-5b0e-46d9-aeb9-a2faa20392b3	543581	Match created! cengizhaneu has introduced you both. Message: dsafgdfshgfhfdjfdkjghjfghjfghj	t	2025-10-20 20:38:00.817459+00
f16898d0-3956-4e82-94dd-b0a277a4a2e4	2f1b98f0-5b0e-46d9-aeb9-a2faa20392b3	543581	Match request: "dsafgdfshgfhfdjfdkjghjfghjfghj"	t	2025-10-20 20:38:01.144319+00
fa30a99e-5767-4060-90e5-06b8c77b4291	2f1b98f0-5b0e-46d9-aeb9-a2faa20392b3	543581	cengizhaneu accepted the match! Waiting for your response.	t	2025-10-20 20:38:08.02839+00
2f3435b1-082c-40b0-970f-6361d7de1f0f	865d99b2-8616-44ad-b885-92854ff57a3e	543581	Match created! cengizhaneu has introduced you both. Message: fgjddfgsdfgsdfgsdfgsdfgsdfg	t	2025-10-20 20:51:23.32395+00
f4443ab1-69b6-4013-bea5-e6837ed307d6	865d99b2-8616-44ad-b885-92854ff57a3e	543581	Match request: "fgjddfgsdfgsdfgsdfgsdfgsdfg"	t	2025-10-20 20:51:23.475475+00
65dc97ee-6c67-4a52-b2c5-a4256345d5d9	865d99b2-8616-44ad-b885-92854ff57a3e	543581	cengizhaneu accepted the match! Waiting for your response.	t	2025-10-20 20:51:30.240649+00
c730dc6a-2e51-4dc7-8c89-5b1fdb7c6d31	2f1b98f0-5b0e-46d9-aeb9-a2faa20392b3	543581	Meeting scheduled! Join here: https://meetshipper.whereby.com/meetshipper-2188caf0-54de-4a76-be63-e82a665158bd	t	2025-10-20 22:11:45.432733+00
789e0e2a-2387-4ae3-b00c-02de90fdd691	2f1b98f0-5b0e-46d9-aeb9-a2faa20392b3	543581	🎉 Match accepted! Both parties agreed to meet. Your meeting link: https://meetshipper.whereby.com/meetshipper-2188caf0-54de-4a76-be63-e82a665158bd	t	2025-10-20 22:11:45.540443+00
2b9374bd-03db-4779-bd6f-888a8f1890fd	2f1b98f0-5b0e-46d9-aeb9-a2faa20392b3	1394398	🎉 Match accepted! Both parties agreed to meet. Your meeting link: https://meetshipper.whereby.com/meetshipper-2188caf0-54de-4a76-be63-e82a665158bd	t	2025-10-20 22:11:45.647256+00
97882794-7117-423c-8be7-3c85167ff24b	2f1b98f0-5b0e-46d9-aeb9-a2faa20392b3	1394398	aysu16 marked the meeting as completed. Waiting for the other party to confirm.	t	2025-10-20 22:12:17.964647+00
88a873cb-8fe6-4bf5-8df8-6fab8bdd1270	2f1b98f0-5b0e-46d9-aeb9-a2faa20392b3	543581	✅ Meeting completed! Both parties confirmed the meeting took place.	t	2025-10-20 22:19:01.707845+00
48d7ca94-2947-45c6-9d2a-737ae64a6639	2f1b98f0-5b0e-46d9-aeb9-a2faa20392b3	1394398	✅ Meeting completed! Both parties confirmed the meeting took place.	t	2025-10-20 22:19:01.707845+00
f54488c4-ae81-4086-bbfe-6863f7af3da6	93c49d73-fcec-466c-8749-df77793e8ebc	543581	Match created! cengizhaneu has introduced you both. Message: llldsafşaslidfmasşdfmasldmfas	t	2025-10-20 22:19:41.009403+00
ef553f08-71ba-4b6d-8655-a745c73122b7	93c49d73-fcec-466c-8749-df77793e8ebc	543581	Match request: "llldsafşaslidfmasşdfmasldmfas"	t	2025-10-20 22:19:41.141992+00
f55f6989-add8-4893-b1c2-eea260cc177f	93c49d73-fcec-466c-8749-df77793e8ebc	543581	cengizhaneu accepted the match! Waiting for your response.	t	2025-10-20 22:19:47.0696+00
43e0fa17-1b34-49c2-9bf3-37bbc6c4f7d5	93c49d73-fcec-466c-8749-df77793e8ebc	543581	Meeting scheduled! Join here: https://meetshipper.whereby.com/meetshipper-1d4a8120-6366-47b2-89db-1d64616e00d9	t	2025-10-20 22:59:11.370948+00
3b2d41a2-a3a3-492d-820f-ca179691dae8	93c49d73-fcec-466c-8749-df77793e8ebc	543581	🎉 Match accepted! Both parties agreed to meet. Your meeting link: https://meetshipper.whereby.com/meetshipper-1d4a8120-6366-47b2-89db-1d64616e00d9	t	2025-10-20 22:59:11.477224+00
d5448cfe-f158-4b80-a14b-3725d97ff346	93c49d73-fcec-466c-8749-df77793e8ebc	1394398	aysu16 marked the meeting as completed. Waiting for the other party to confirm.	t	2025-10-20 22:59:40.751849+00
393f82a9-a5e3-4b98-ba0b-30e4e95b288c	93c49d73-fcec-466c-8749-df77793e8ebc	1394398	🎉 Match accepted! Both parties agreed to meet. Your meeting link: https://meetshipper.whereby.com/meetshipper-1d4a8120-6366-47b2-89db-1d64616e00d9	t	2025-10-20 22:59:11.572421+00
bd527ead-9b7f-4ae6-89bb-acf1914452a1	93c49d73-fcec-466c-8749-df77793e8ebc	543581	✅ Meeting completed! Both parties confirmed the meeting took place.	t	2025-10-20 23:00:14.986344+00
ea0a1b26-b5a0-4e88-b5d0-11f708b9e199	93c49d73-fcec-466c-8749-df77793e8ebc	1394398	✅ Meeting completed! Both parties confirmed the meeting took place.	t	2025-10-20 23:00:14.986344+00
af94932d-c2d1-492f-9883-1728e9a7cc1e	981d8ae7-b3f6-4f33-b019-9da325ffade1	543581	Match created! cengizhaneu has introduced you both. Message: dşlfgjkdsfjgsşdfjglksdfkjlsdjg	t	2025-10-20 23:22:53.178138+00
191ce152-1a85-4b87-95d6-1ee3553cd719	981d8ae7-b3f6-4f33-b019-9da325ffade1	543581	Match request: "dşlfgjkdsfjgsşdfjglksdfkjlsdjg"	t	2025-10-20 23:22:53.350107+00
fcb01f30-4b83-4974-8bf1-543c1bf9b4e7	981d8ae7-b3f6-4f33-b019-9da325ffade1	543581	cengizhaneu accepted the match! Waiting for your response.	t	2025-10-20 23:23:34.758397+00
2fb68fbd-c628-4b7a-aee7-d7dd3e62004b	acb28422-7a69-4f48-a358-53265d963ea3	543581	Match created! cengizhaneu has introduced you both. Message: hadiia asdlfkalsidfkasdlfasdfasfsdaf	t	2025-10-21 05:08:17.357038+00
d8c7a437-c57f-461a-a769-1a1c419c48dc	acb28422-7a69-4f48-a358-53265d963ea3	543581	Match request: "hadiia asdlfkalsidfkasdlfasdfasfsdaf"	t	2025-10-21 05:08:17.501943+00
6cc008c5-9bfa-4a1e-85b1-37ef80ab9a9c	acb28422-7a69-4f48-a358-53265d963ea3	543581	cengizhaneu accepted the match! Waiting for your response.	t	2025-10-21 05:08:22.710176+00
772de5bd-4ec7-42a9-b64b-ac9b8aae41f2	691d6c6f-8985-4d5c-8f28-99837b73bff8	543581	Match created! cengizhaneu has introduced you both. Message: sadfasdflasfasşlfkasdfasdfas	t	2025-10-21 05:11:50.124157+00
12ec062e-daf7-480f-96c0-9449298e8953	691d6c6f-8985-4d5c-8f28-99837b73bff8	543581	Match request: "sadfasdflasfasşlfkasdfasdfas"	t	2025-10-21 05:11:50.247301+00
0bdde544-8bc2-4073-9014-d86c8060f760	691d6c6f-8985-4d5c-8f28-99837b73bff8	543581	cengizhaneu accepted the match! Waiting for your response.	t	2025-10-21 05:11:55.414376+00
489b5674-1723-4988-bbe8-c1e3d31ff9c7	35cf47c6-5a93-4467-833f-552ada4d88e8	543581	Match created! cengizhaneu has introduced you both. Message: asdfasdfasfdasfasdfasdfas	t	2025-10-21 18:09:49.527733+00
44972fef-ca7f-4ee4-9124-bd43434de5ef	35cf47c6-5a93-4467-833f-552ada4d88e8	543581	Match request: "asdfasdfasfdasfasdfasdfas"	t	2025-10-21 18:09:49.762747+00
cd2f14fe-80c4-47d8-99ec-c2e87c8c35d8	ee4929a5-6c41-4183-adcf-e12f9b387890	1396322	Match created! recepaslan has introduced you both. Message: Bc I want 1 million dollar	t	2025-10-21 19:08:53.226208+00
46796d60-dfd2-4261-9b44-a1a6e2c5833e	ee4929a5-6c41-4183-adcf-e12f9b387890	1396322	Match request: "Bc I want 1 million dollar"	t	2025-10-21 19:08:53.88258+00
7864ebcb-1604-48df-b664-208b81b88e63	ee4929a5-6c41-4183-adcf-e12f9b387890	1396322	recepaslan accepted the match! Waiting for your response.	t	2025-10-21 19:09:32.062516+00
ef5fad3a-d9a8-46a4-94d8-51ddd1b8d26f	459711c9-14d9-4aef-8185-35b893a8540e	11111	Match created! alice has introduced you both.	t	2025-10-22 00:54:15.199619+00
1a43e0b8-281d-463b-9f4f-1ffb9ed9b1ee	ee4929a5-6c41-4183-adcf-e12f9b387890	1396322	🎉 Match accepted! Both parties agreed to meet. Your chat room is ready. Click "Open Chat" to start your conversation. Note: Chat room will auto-close 2 hours after first entry.	t	2025-10-22 03:35:15.748046+00
5f71b8bb-788a-44e8-b57e-1310b6cdd559	ee4929a5-6c41-4183-adcf-e12f9b387890	543581	🎉 Match accepted! Both parties agreed to meet. Your chat room is ready. Click "Open Chat" to start your conversation. Note: Chat room will auto-close 2 hours after first entry.	t	2025-10-22 03:35:15.851577+00
2269cb1c-39bc-4596-9bc7-1054f23b67ee	d5970e84-1a31-42ed-b426-b62c8d573668	543581	Match created! cengizhaneu has introduced you both. Message: Hey birader gel bi senin aklına alayım	t	2025-10-22 03:39:54.782006+00
895215c1-8e66-4cf0-8f87-dead60346e8a	d5970e84-1a31-42ed-b426-b62c8d573668	543581	Match request: "Hey birader gel bi senin aklına alayım"	t	2025-10-22 03:39:54.93118+00
c46a6d12-d9b0-4a0c-862a-180df51bc696	d5970e84-1a31-42ed-b426-b62c8d573668	543581	cengizhaneu accepted the match! Waiting for your response.	t	2025-10-22 03:40:01.040951+00
fd3199da-458b-405b-8fb7-fa8cfeabebbc	d5970e84-1a31-42ed-b426-b62c8d573668	543581	🎉 Match accepted! Both parties agreed to meet. Your chat room is ready. Click "Open Chat" to start your conversation. Note: Chat room will auto-close 2 hours after first entry.	t	2025-10-22 03:42:10.676753+00
16708e06-959b-491a-bd34-472d3a931c68	d5970e84-1a31-42ed-b426-b62c8d573668	517833	🎉 Match accepted! Both parties agreed to meet. Your chat room is ready. Click "Open Chat" to start your conversation. Note: Chat room will auto-close 2 hours after first entry.	t	2025-10-22 03:42:10.849383+00
56346269-c166-4416-9b77-d4bad5ab834c	1cdebf76-db49-4476-9f09-2c899ae9607d	543581	Match created! cengizhaneu has introduced you both. Message: asşdjfkakşsjdfşasdjfkşasdjfasd	t	2025-10-23 03:48:54.679323+00
241bee4f-c07e-4156-b661-3347931a48bd	1cdebf76-db49-4476-9f09-2c899ae9607d	543581	Match request: "asşdjfkakşsjdfşasdjfkşasdjfasd"	t	2025-10-23 03:48:54.813988+00
8b34b814-2782-4c1c-abab-caa95eddafa3	1cdebf76-db49-4476-9f09-2c899ae9607d	543581	Match declined by cengizhaneu. This match is now closed for both participants.	t	2025-10-23 04:17:40.920625+00
865b6dae-6a26-46ca-afa6-592c20a748a2	35cf47c6-5a93-4467-833f-552ada4d88e8	543581	Match declined by cengizhaneu. This match is now closed for both participants.	t	2025-10-23 04:20:42.11096+00
bf3852f9-db93-4217-83fd-a040df062853	9b27cca6-fbe2-45f0-bd27-9f673095e5e4	543581	Match created! cengizhaneu has introduced you both. Message: werfasfasdasdfdsafasfdsadf	t	2025-10-23 04:38:27.337721+00
8e30fbe1-5c7b-4d7c-a821-b709ccecad9b	9b27cca6-fbe2-45f0-bd27-9f673095e5e4	543581	Match request: "werfasfasdasdfdsafasfdsadf"	t	2025-10-23 04:38:27.474322+00
f29d83eb-5422-4487-a86b-d3be847f8a67	9b27cca6-fbe2-45f0-bd27-9f673095e5e4	543581	Match declined by cengizhaneu. This match is now closed for both participants.	t	2025-10-23 04:38:32.867562+00
26d333f3-a2f9-4f37-873b-0a67a1e83d53	7c57a23e-3c9c-4b77-b184-4c941a98ed70	11111	Match created! alice has introduced you both.	t	2025-10-24 00:41:36.93996+00
ce947063-d3ba-457c-ae69-b7d49c9d5baf	fb077b0d-db62-4a51-ad3e-48adb1a2740f	11111	Match created! alice has introduced you both.	t	2025-10-25 00:51:38.483093+00
7a981aab-c006-4bad-84c2-2cd1c649bebc	e0d5b410-48ef-4610-a53b-7c06d7648b2c	11111	Match created! alice has introduced you both.	t	2025-10-27 00:45:32.37938+00
17ff07b7-78c7-4c57-b41f-5b312d6e83f6	bd477f2d-dc40-43ff-a919-299445da9fa6	543581	Match created! cengizhaneu has introduced you both. Message: İşfdaisdfkawoğfkasdfasdlfas322323	t	2025-10-27 05:09:20.401614+00
bd4b0adc-dd69-44c1-9cb0-8048d368d5cb	bd477f2d-dc40-43ff-a919-299445da9fa6	543581	Match request: "İşfdaisdfkawoğfkasdfasdlfas322323"	t	2025-10-27 05:09:20.579639+00
f0b9499a-725d-4a91-8b4a-b36333f90833	bd477f2d-dc40-43ff-a919-299445da9fa6	543581	cengizhaneu accepted the match! Waiting for your response.	t	2025-10-27 05:09:30.280933+00
18f11fb6-67d4-4adb-b78a-2c1087168b06	bd477f2d-dc40-43ff-a919-299445da9fa6	1394398	Match declined by aysu16. This match is now closed for both participants.	t	2025-10-27 05:14:39.512508+00
c89bd33d-9df6-4850-a3fc-ef5079bf0723	cc6f06b0-212f-4a36-a076-ec26a7eb7b17	11111	Match created! alice has introduced you both.	t	2025-10-28 00:50:04.6375+00
ac585412-c8e1-4e9a-84e3-3dfb447769a0	12922ebb-bf6b-4802-95ff-916023188c28	543581	Match created! cengizhaneu has introduced you both. Message: Eşleşmek istiyorum deneyimleyelim burayı	t	2025-10-28 02:28:59.375828+00
c9cd3ba8-2570-4f67-84e1-a784107e421d	12922ebb-bf6b-4802-95ff-916023188c28	543581	Match request: "Eşleşmek istiyorum deneyimleyelim burayı"	t	2025-10-28 02:28:59.527772+00
5f0ed379-7853-4338-89fc-37ddced2e272	12922ebb-bf6b-4802-95ff-916023188c28	543581	cengizhaneu accepted the match! Waiting for your response.	t	2025-10-28 02:32:24.409376+00
9cee9eff-a8d9-4530-be7d-06d01e9f2a93	8464254e-dc77-417c-a9d9-3ccc97f5e216	543581	Match created! cengizhaneu has introduced you both. Message: adfasdfasdfasfasdfasdfasdfasdf	t	2025-10-28 02:34:04.95484+00
5c18a496-258a-421d-93c2-7f96b0b77b4c	8464254e-dc77-417c-a9d9-3ccc97f5e216	543581	Match request: "adfasdfasdfasfasdfasdfasdfasdf"	t	2025-10-28 02:34:05.099722+00
3d14ce2b-f790-4624-af36-9cff3ee02551	12922ebb-bf6b-4802-95ff-916023188c28	543581	🎉 Match accepted! Both parties agreed to meet. Your chat room is ready. Click "Open Chat" to start your conversation. Note: Chat room will auto-close 2 hours after first entry.	t	2025-10-28 02:39:43.498642+00
d1429ab5-0f3a-4231-8fee-dda5ccccf404	12922ebb-bf6b-4802-95ff-916023188c28	1401992	🎉 Match accepted! Both parties agreed to meet. Your chat room is ready. Click "Open Chat" to start your conversation. Note: Chat room will auto-close 2 hours after first entry.	t	2025-10-28 02:39:43.592038+00
6f2b0ece-d75f-45ac-88fe-6ace457f408c	effc3baf-02ed-43e8-b066-2e066937c77f	1401992	Match created! meetshipper has introduced you both. Message: lşjhlhjkşjşlkjkşljşlkjlşkjljşjşlkjklşjlşj	t	2025-10-28 02:40:40.011553+00
f43334a1-89b5-4b9d-a0f4-afe09b0fd734	effc3baf-02ed-43e8-b066-2e066937c77f	1401992	Match request: "lşjhlhjkşjşlkjkşljşlkjlşkjljşjşlkjklşjlşj"	t	2025-10-28 02:40:40.13369+00
b757e13c-abb4-430c-95d0-ba40a6c39c39	effc3baf-02ed-43e8-b066-2e066937c77f	1401992	Match declined by meetshipper. This match is now closed for both participants.	t	2025-10-28 02:43:57.044185+00
5b049813-2de3-40af-b77e-ec22228870e6	66f3134e-d020-4ef1-8446-3d1ca6ffdef5	1401992	Match created! meetshipper has introduced you both. Message: çöasdhşfasnflşasfdlsda	t	2025-10-28 02:44:20.448108+00
e1927031-4330-4630-b40c-8bc5490b391e	66f3134e-d020-4ef1-8446-3d1ca6ffdef5	1401992	Match request: "çöasdhşfasnflşasfdlsda"	t	2025-10-28 02:44:20.571528+00
4f9add29-332c-40a3-95ca-cf1a4d3f299c	b4b5a8c6-0f24-4e48-965b-a7fb959d7f71	543581	Match created! cengizhaneu has introduced you both. Message: Alexxxxxxxxxxxxxxxxxxx	t	2025-10-28 22:37:46.571579+00
eb5d80a4-1e18-4f18-8ce9-e279cc61686f	b4b5a8c6-0f24-4e48-965b-a7fb959d7f71	543581	Match request: "Alexxxxxxxxxxxxxxxxxxx"	t	2025-10-28 22:37:46.735907+00
1749c8f0-9bfc-421f-a884-ecff6c266515	a068abdb-02dd-4ebb-ae29-ffcd38a09198	543581	Match created! cengizhaneu has introduced you both. Message: Terece xdxopğhlşpor1452	t	2025-10-28 22:42:06.741999+00
41cbb89b-628e-48e1-b307-c4b57bcd135f	a068abdb-02dd-4ebb-ae29-ffcd38a09198	543581	Match request: "Terece xdxopğhlşpor1452"	t	2025-10-28 22:42:06.853851+00
80ddbde7-ece7-4336-b5fd-7ec41e02b157	5cfa971e-a87d-4328-a10f-a6cb0345d701	543581	Match created! cengizhaneu has introduced you both. Message: Hadi hadi go go hadi bebekkk	t	2025-10-28 22:59:10.667467+00
e16d1cd1-11b6-4d91-a6d8-60784adbc572	5cfa971e-a87d-4328-a10f-a6cb0345d701	543581	Match request: "Hadi hadi go go hadi bebekkk"	t	2025-10-28 22:59:10.792646+00
77b3b5f1-8e76-4da8-baca-d6b5251b73d7	82427b50-9dda-4a84-ae8e-b153025dd16f	1401992	Match created! meetshipper has introduced you both. Message: ksdajkajsdfkjsalkfjasldfş	t	2025-10-29 00:09:50.692852+00
2e5d9f1b-6049-447d-bb14-aaf41a12e667	82427b50-9dda-4a84-ae8e-b153025dd16f	1401992	Match request: "ksdajkajsdfkjsalkfjasldfş"	t	2025-10-29 00:09:50.977615+00
e1c0687e-def3-42c3-915f-a28abc7d8fab	82427b50-9dda-4a84-ae8e-b153025dd16f	1401992	Match declined by meetshipper. This match is now closed for both participants.	t	2025-10-29 00:55:10.829926+00
26f5bb4c-4553-464e-bdca-22877a74c745	66f3134e-d020-4ef1-8446-3d1ca6ffdef5	1401992	Match declined by meetshipper. This match is now closed for both participants.	t	2025-10-29 00:55:16.152683+00
401e97cf-0e72-4d27-a04a-ab3153aeab4c	caaf5141-3a53-40a7-ae16-df38f912ec2a	1394398	Match created! aysu16 has introduced you both. Message: lksdjfşlkajdasjdfasdf	t	2025-10-29 00:59:31.09874+00
f4c2e737-40fe-47b0-a8a8-07aae8698b14	caaf5141-3a53-40a7-ae16-df38f912ec2a	1394398	Match request: "lksdjfşlkajdasjdfasdf"	t	2025-10-29 00:59:31.236585+00
1baead95-68ec-4158-81c8-27d2234e2a2b	080aefa1-5fe3-4a8a-8174-a25e590f8892	1394398	Match created! aysu16 has introduced you both. Message: qrerafsdfsdafasdfsadfasd	t	2025-10-29 01:16:36.09132+00
eabbcabb-eacb-43ff-9a46-3a88aa3decb1	080aefa1-5fe3-4a8a-8174-a25e590f8892	1394398	Match request: "qrerafsdfsdafasdfsadfasd"	t	2025-10-29 01:16:36.242749+00
57472cc2-22df-422c-9542-c74baea0ade2	0ab915e1-eef5-4bb9-919a-aac098d8c183	1394398	Match created! aysu16 has introduced you both. Message: adsfasdfasfasfasdfasdfas	t	2025-10-29 01:26:49.631435+00
4bcdb271-716b-4e3a-bef9-c23fd9e97b27	0ab915e1-eef5-4bb9-919a-aac098d8c183	1394398	Match request: "adsfasdfasfasfasdfasdfas"	t	2025-10-29 01:26:49.786294+00
a6498ccf-d0fd-42bb-86c0-d71b8208551f	caaf5141-3a53-40a7-ae16-df38f912ec2a	1394398	Match declined by aysu16. This match is now closed for both participants.	t	2025-10-29 01:42:20.31746+00
bf0bd1d4-1b90-4637-bb99-a62affb308ea	080aefa1-5fe3-4a8a-8174-a25e590f8892	1394398	aysu16 accepted the match! Waiting for your response.	t	2025-10-29 01:42:26.658615+00
6f43792d-210b-4b59-b1ea-c94ea7c09cdd	0ab915e1-eef5-4bb9-919a-aac098d8c183	1394398	aysu16 accepted the match! Waiting for your response.	t	2025-10-29 01:42:32.705787+00
7859e6a7-411b-4f7e-80a3-384a55b54d9b	8464254e-dc77-417c-a9d9-3ccc97f5e216	517833	cainwell accepted the match! Waiting for your response.	t	2025-10-29 05:51:08.144346+00
203cbdb8-bf65-42fe-8db9-009f4d62ee7c	f7e1e361-3115-492b-978d-9fe855cbe408	517833	Match created! cainwell has introduced you both. Message: hi momomomomomomomomo	t	2025-10-29 05:52:19.623357+00
3a86e0f9-691a-4006-89d3-44b95ca039f3	f7e1e361-3115-492b-978d-9fe855cbe408	517833	Match request: "hi momomomomomomomomo"	t	2025-10-29 05:52:19.763752+00
79cee794-30ed-456a-b249-a37c47c13960	80830400-cebf-4b80-b44c-0f759976b2e6	1423060	Match created! shortshipper has introduced you both. Message: şlsdafgşlkajdfgiafdgşdfjsgls	t	2025-10-29 08:54:22.073054+00
9fac0858-3756-4c3b-9389-1e390ce4d892	80830400-cebf-4b80-b44c-0f759976b2e6	1423060	Match request: "şlsdafgşlkajdfgiafdgşdfjsgls"	t	2025-10-29 08:54:22.250704+00
4b631831-2e02-4ede-99fc-2cfc7bf48e95	360b5956-974d-45c7-91cc-21345a2b9565	1423060	Match created! shortshipper has introduced you both. Message: sdlfşgaijsşlgkşlgsasgs	t	2025-10-29 09:05:30.334639+00
a6ceef76-3e86-4ebd-9119-6962f3ea3580	360b5956-974d-45c7-91cc-21345a2b9565	1423060	Match request: "sdlfşgaijsşlgkşlgsasgs"	t	2025-10-29 09:05:30.504477+00
bf9ec28a-148a-42b5-a0b8-861db214ab22	5cfa971e-a87d-4328-a10f-a6cb0345d701	1423060	Match declined by shortshipper. This match is now closed for both participants.	t	2025-10-29 09:06:54.184751+00
a2e9bbff-7bcd-425b-ad81-015b70c0515f	80830400-cebf-4b80-b44c-0f759976b2e6	1423060	shortshipper accepted the match! Waiting for your response.	t	2025-10-29 09:07:30.150874+00
3530814f-5546-4a8a-8521-50080c60c076	0ab915e1-eef5-4bb9-919a-aac098d8c183	1394398	🎉 Match accepted! Both parties agreed to meet. Your chat room is ready. Click "Open Chat" to start your conversation. Note: Chat room will auto-close 2 hours after first entry.	t	2025-10-29 09:07:58.883292+00
b67d2745-7a6f-417c-b24e-fe7c95d66d4a	0ab915e1-eef5-4bb9-919a-aac098d8c183	1423060	🎉 Match accepted! Both parties agreed to meet. Your chat room is ready. Click "Open Chat" to start your conversation. Note: Chat room will auto-close 2 hours after first entry.	t	2025-10-29 09:07:59.016881+00
6624cdd2-acdc-4016-903a-7322785435f5	9d70e248-f0d5-4156-93e4-543eacb86797	1401992	Match created! meetshipper has introduced you both. Message: joogbnşljlklşkjşlkjkşl	t	2025-10-29 09:10:13.840929+00
414d552f-0047-47d7-a0e0-08bccad9239b	9d70e248-f0d5-4156-93e4-543eacb86797	1401992	Match request: "joogbnşljlklşkjşlkjkşl"	t	2025-10-29 09:10:13.982292+00
75a25038-3410-4477-95fd-34ddcb670b22	9d70e248-f0d5-4156-93e4-543eacb86797	1401992	meetshipper accepted the match! Waiting for your response.	t	2025-10-29 12:44:27.633603+00
873d6418-2569-43c5-9f33-5625f602e281	ad8bfae4-cd98-45a9-84c3-52f6eacdc2fd	1401992	Match created! meetshipper has introduced you both. Message: I believe we share some common interests, and I’d like to get to know you and have a conversation.	t	2025-10-29 12:47:47.009014+00
2b87e6c3-c8be-456b-933b-d7c61b8fc23b	ad8bfae4-cd98-45a9-84c3-52f6eacdc2fd	1401992	Match request: "I believe we share some common interests, and I’d like to get to know you and have a conversation."	t	2025-10-29 12:47:47.146808+00
9b40851b-1b5a-4a43-88bc-1a3fbb9537f2	ad8bfae4-cd98-45a9-84c3-52f6eacdc2fd	1401992	meetshipper accepted the match! Waiting for your response.	t	2025-10-29 12:47:55.493801+00
21ff9be1-5973-45ce-81da-b833826b7dc3	98d5c36b-25c1-40ff-8b23-9f4f516b7de3	1401992	Match created! meetshipper has introduced you both. Message: I believe we share some common interests, and I’d like to get to know you and have a conversation.	t	2025-10-29 12:50:26.60177+00
c5f95420-b270-4762-88aa-f69bb7fe7c6b	98d5c36b-25c1-40ff-8b23-9f4f516b7de3	1401992	Match request: "I believe we share some common interests, and I’d like to get to know you and have a conversation."	t	2025-10-29 12:50:26.724205+00
f82bedf9-db3b-43af-af8d-37dde72f352a	98d5c36b-25c1-40ff-8b23-9f4f516b7de3	1401992	meetshipper accepted the match! Waiting for your response.	t	2025-10-29 12:50:36.149653+00
\.


--
-- Data for Name: user_achievements; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_achievements (id, user_fid, code, points, awarded_at) FROM stdin;
f47a1513-af8a-452d-a2ed-8d1a512c95d6	543581	bio_done	50	2025-10-20 21:55:27.49525+00
e7036277-56b7-42d3-aae3-d9cfefc93990	543581	traits_done	50	2025-10-20 21:55:28.068201+00
ae60a014-e956-4db2-a083-ea10b32dca3d	1394398	traits_done	50	2025-10-20 22:11:17.456369+00
92092fb4-50c6-4e09-9740-6cdae1026ce1	1394398	bio_done	50	2025-10-20 22:11:32.592739+00
2644f8be-5145-44fc-b5cc-28f4f603eb00	1394398	joined_1	400	2025-10-20 22:19:02.021878+00
4b0a6ccb-19e8-4fd2-b9d1-ce09d444426b	543581	joined_1	400	2025-10-20 22:19:02.076586+00
14fa0367-616d-4e9d-a3d7-6a65fb209c6d	517833	bio_done	50	2025-10-21 02:36:50.995667+00
1ad5c92d-a298-4a29-bed7-ce15af148c22	517833	traits_done	50	2025-10-21 02:36:52.077558+00
04cece51-20aa-497b-b672-17592675c4be	543581	sent_5	100	2025-10-22 03:39:55.320893+00
434bc056-4de4-4f22-a27c-c114f7babcbb	1401992	bio_done	50	2025-10-27 02:49:26.744134+00
77bdb0fb-a552-4fcd-8c3f-a9d246aad398	1401992	traits_done	50	2025-10-27 02:49:27.825166+00
0177d057-5781-4ca7-9b5b-00f2c389d173	543581	sent_10	100	2025-10-28 22:59:11.296689+00
11d51de9-9434-4983-ba8e-52d612977167	1401992	sent_5	100	2025-10-29 12:47:47.571484+00
\.


--
-- Data for Name: user_friends; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_friends (user_fid, friend_fid, friend_username, friend_display_name, friend_avatar_url, cached_at) FROM stdin;
\.


--
-- Data for Name: user_levels; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_levels (user_fid, points_total, created_at, updated_at) FROM stdin;
1394398	500	2025-10-20 22:11:01.346619+00	2025-10-20 22:19:02.198573+00
517833	100	2025-10-21 02:35:46.529908+00	2025-10-21 02:36:52.342096+00
1396322	0	2025-10-21 19:06:37.757074+00	2025-10-21 19:06:37.757074+00
543581	700	2025-10-20 21:55:27.729256+00	2025-10-28 22:59:11.519634+00
1423060	0	2025-10-29 05:36:35.104183+00	2025-10-29 05:36:35.104183+00
1424386	0	2025-10-29 09:04:01.639757+00	2025-10-29 09:04:01.639757+00
1401992	200	2025-10-26 22:41:50.45326+00	2025-10-29 12:47:47.828491+00
\.


--
-- Data for Name: user_wallets; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_wallets (id, fid, wallet_address, chain_id, created_at, updated_at) FROM stdin;
8df556fc-dbe6-4c0d-bd3f-46d8e76f8a9e	543581	0x39fa26142ec357a421d49c9a4cf022e8fb6bbf04	84532	2025-10-23 06:40:53.876447+00	2025-10-23 06:40:53.572+00
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (fid, username, display_name, avatar_url, bio, created_at, updated_at, user_code, traits, has_joined_meetshipper) FROM stdin;
1396322	recepaslan	recepaslan	https://imagedelivery.net/BXluQx4ige9GuW0Ia56BHw/be8deecf-57c0-45e4-0124-f4f136e1a700/original	\N	2025-10-21 19:06:32.575558+00	2025-10-21 19:06:31.046+00	1489259086	[]	t
55555	user55555	User 55555	https://avatar.vercel.sh/55555		2025-10-21 02:29:58.177383+00	2025-10-21 02:29:58.177383+00	8421758525	[]	t
1401992	meetshipper	meetshipper	https://imagedelivery.net/BXluQx4ige9GuW0Ia56BHw/cfe77638-20f0-493a-1337-e9eeca7a4500/original	Meetshipper.com	2025-10-26 22:41:48.589507+00	2025-10-29 12:53:19.890122+00	6351083476	["Graph-reader", "Market-seer", "Visionary", "Speculator", "Analyst", "Signal-maker", "Data-driven", "Opportunist"]	t
1	farcaster	Farcaster	https://imagedelivery.net/BXluQx4ige9GuW0Ia56BHw/ef803ee0-a0de-4c34-c879-2a4888086e00/original	Discover. Trade. Create.	2025-10-29 07:45:11.411061+00	2025-10-29 08:02:06.102383+00	4422339476	[]	f
1423504	muhammet9816	muhammet9816	https://imagedelivery.net/BXluQx4ige9GuW0Ia56BHw/be8deecf-57c0-45e4-0124-f4f136e1a700/original		2025-10-29 02:46:52.693858+00	2025-10-29 08:02:06.424782+00	8391567482	[]	f
517833	cainwell	Dutchie.base.eth	https://res.cloudinary.com/base-app/image/upload/f_auto/v1760295845/image_uploads/c1110b34-a19a-4e03-acda-00ea031f6bbd.jpg	Love to be in powerful\n and determined community	2025-10-21 02:35:45.335653+00	2025-10-29 05:50:33.844355+00	8163181739	["Trader", "Visionary", "Analyst", "Chartist", "Airfarmer", "Trend-catcher", "Meme-king"]	t
11111	alice	Alice	https://picsum.photos/seed/a/80	DeFi & airdrop hunter	2025-10-19 16:59:25.850444+00	2025-10-20 02:17:03.383466+00	6287777951	["Trader", "DeFi-explorer", "Data-driven", "Airdropper", "Risk-manager"]	t
22222	bob	Bob	https://picsum.photos/seed/b/80	Trader & early L2 user	2025-10-19 16:59:25.850444+00	2025-10-20 02:17:03.383466+00	4881118121	["Trader", "DeFi-explorer", "Data-driven", "Airdropper", "Risk-manager"]	t
10259	alexgrover	alex	https://imagedelivery.net/BXluQx4ige9GuW0Ia56BHw/c93f613c-597c-455a-73fe-65f5e1610f00/original	likes building things • working on v0.dev at Vercel • https://alexgrover.me	2025-10-28 22:37:45.775394+00	2025-10-29 00:37:56.556344+00	2650334076	[]	f
18559	terencechain	terence	https://i.imgur.com/fmFhor4.jpg	Ethereum\nhttps://terencecha.in/	2025-10-28 22:42:06.304082+00	2025-10-29 00:37:56.556344+00	9903328663	[]	f
1394398	aysu16	aysu16	https://imagedelivery.net/BXluQx4ige9GuW0Ia56BHw/5567fc3e-c6a7-4b6d-b410-a5c46554ab00/original	Cengizhan'nın ki	2025-10-20 10:16:51.034176+00	2025-10-29 00:58:35.804756+00	0652219743	["Airdropper", "Visionary", "Chartist", "Staking-warrior", "Trend-catcher", "Earlybird"]	t
1111	alice	Alice	https://avatar.vercel.sh/alice	Test user for manual matching. Interested in web3, startups, and meeting new people.	2025-10-20 07:19:36.258665+00	2025-10-20 09:50:24.408655+00	0696378016	["Founder", "Web3", "Builder", "Open Source", "Community", "Design", "Product"]	t
1424386	yancar	yancar	https://imagedelivery.net/BXluQx4ige9GuW0Ia56BHw/5a2717bd-8a5e-4596-12ba-67e920d4f600/original	\N	2025-10-29 08:54:21.288893+00	2025-10-29 09:04:35.631455+00	6915223396	[]	t
1423060	shortshipper	shortshipper	https://imagedelivery.net/BXluQx4ige9GuW0Ia56BHw/5567fc3e-c6a7-4b6d-b410-a5c46554ab00/original	\N	2025-10-28 22:59:10.18544+00	2025-10-29 09:08:14.723854+00	5353645082	[]	t
543581	cengizhaneu	EmirCengizhanUlu	https://imagedelivery.net/BXluQx4ige9GuW0Ia56BHw/816eace1-a20d-494d-bd6f-f2e3b923e300/rectcrop3	\N	2025-10-19 17:25:04.185374+00	2025-10-29 07:27:09.930077+00	7189696562	["Drop-sniper", "Whale", "Beta-chaser", "Airfarmer", "Thinker", "Earlybird", "Token-seeker", "Adaptive-leader", "Visionary", "Chartist"]	t
5620	fun	welter	https://imagedelivery.net/BXluQx4ige9GuW0Ia56BHw/d793c077-f8fc-4bd6-3c4c-d5b03603a400/original	building reel.farm	2025-10-29 07:29:55.361313+00	2025-10-29 07:30:00.813022+00	1613003689	[]	f
1416480	meetshipperapp	Meet Shipper Notifier	https://imgur.com/u6c0DoG.png	Automated Farcaster notifier for Meet Shipper match requests.	2025-10-29 12:50:25.995107+00	2025-10-29 12:50:25.926+00	8654585544	[]	f
\.


--
-- Data for Name: messages_2025_10_26; Type: TABLE DATA; Schema: realtime; Owner: supabase_admin
--

COPY realtime.messages_2025_10_26 (topic, extension, payload, event, private, updated_at, inserted_at, id) FROM stdin;
\.


--
-- Data for Name: messages_2025_10_27; Type: TABLE DATA; Schema: realtime; Owner: supabase_admin
--

COPY realtime.messages_2025_10_27 (topic, extension, payload, event, private, updated_at, inserted_at, id) FROM stdin;
\.


--
-- Data for Name: messages_2025_10_28; Type: TABLE DATA; Schema: realtime; Owner: supabase_admin
--

COPY realtime.messages_2025_10_28 (topic, extension, payload, event, private, updated_at, inserted_at, id) FROM stdin;
\.


--
-- Data for Name: messages_2025_10_29; Type: TABLE DATA; Schema: realtime; Owner: supabase_admin
--

COPY realtime.messages_2025_10_29 (topic, extension, payload, event, private, updated_at, inserted_at, id) FROM stdin;
\.


--
-- Data for Name: messages_2025_10_30; Type: TABLE DATA; Schema: realtime; Owner: supabase_admin
--

COPY realtime.messages_2025_10_30 (topic, extension, payload, event, private, updated_at, inserted_at, id) FROM stdin;
\.


--
-- Data for Name: messages_2025_10_31; Type: TABLE DATA; Schema: realtime; Owner: supabase_admin
--

COPY realtime.messages_2025_10_31 (topic, extension, payload, event, private, updated_at, inserted_at, id) FROM stdin;
\.


--
-- Data for Name: messages_2025_11_01; Type: TABLE DATA; Schema: realtime; Owner: supabase_admin
--

COPY realtime.messages_2025_11_01 (topic, extension, payload, event, private, updated_at, inserted_at, id) FROM stdin;
\.


--
-- Data for Name: schema_migrations; Type: TABLE DATA; Schema: realtime; Owner: supabase_admin
--

COPY realtime.schema_migrations (version, inserted_at) FROM stdin;
20211116024918	2025-10-18 15:33:31
20211116045059	2025-10-18 15:33:34
20211116050929	2025-10-18 15:33:36
20211116051442	2025-10-18 15:33:38
20211116212300	2025-10-18 15:33:40
20211116213355	2025-10-18 15:33:42
20211116213934	2025-10-18 15:33:44
20211116214523	2025-10-18 15:33:46
20211122062447	2025-10-18 15:33:48
20211124070109	2025-10-18 15:33:50
20211202204204	2025-10-18 15:33:52
20211202204605	2025-10-18 15:33:53
20211210212804	2025-10-18 15:33:59
20211228014915	2025-10-18 15:34:01
20220107221237	2025-10-18 15:34:03
20220228202821	2025-10-18 15:34:05
20220312004840	2025-10-18 15:34:06
20220603231003	2025-10-18 15:34:09
20220603232444	2025-10-18 15:34:11
20220615214548	2025-10-18 15:34:13
20220712093339	2025-10-18 15:34:15
20220908172859	2025-10-18 15:34:17
20220916233421	2025-10-18 15:34:18
20230119133233	2025-10-18 15:34:20
20230128025114	2025-10-18 15:34:23
20230128025212	2025-10-18 15:34:25
20230227211149	2025-10-18 15:34:27
20230228184745	2025-10-18 15:34:28
20230308225145	2025-10-18 15:34:30
20230328144023	2025-10-18 15:34:32
20231018144023	2025-10-18 15:34:34
20231204144023	2025-10-18 15:34:37
20231204144024	2025-10-18 15:34:39
20231204144025	2025-10-18 15:34:41
20240108234812	2025-10-18 15:34:42
20240109165339	2025-10-18 15:34:44
20240227174441	2025-10-18 15:34:47
20240311171622	2025-10-18 15:34:50
20240321100241	2025-10-18 15:34:54
20240401105812	2025-10-18 15:34:59
20240418121054	2025-10-18 15:35:01
20240523004032	2025-10-18 15:35:07
20240618124746	2025-10-18 15:35:09
20240801235015	2025-10-18 15:35:11
20240805133720	2025-10-18 15:35:12
20240827160934	2025-10-18 15:35:14
20240919163303	2025-10-18 15:35:17
20240919163305	2025-10-18 15:35:18
20241019105805	2025-10-18 15:35:20
20241030150047	2025-10-18 15:35:27
20241108114728	2025-10-18 15:35:29
20241121104152	2025-10-18 15:35:31
20241130184212	2025-10-18 15:35:33
20241220035512	2025-10-18 15:35:35
20241220123912	2025-10-18 15:35:36
20241224161212	2025-10-18 15:35:38
20250107150512	2025-10-18 15:35:40
20250110162412	2025-10-18 15:35:41
20250123174212	2025-10-18 15:35:43
20250128220012	2025-10-18 15:35:45
20250506224012	2025-10-18 15:35:46
20250523164012	2025-10-18 15:35:48
20250714121412	2025-10-18 15:35:50
20250905041441	2025-10-18 15:35:51
\.


--
-- Data for Name: subscription; Type: TABLE DATA; Schema: realtime; Owner: supabase_admin
--

COPY realtime.subscription (id, subscription_id, entity, filters, claims, created_at) FROM stdin;
\.


--
-- Data for Name: buckets; Type: TABLE DATA; Schema: storage; Owner: supabase_storage_admin
--

COPY storage.buckets (id, name, owner, created_at, updated_at, public, avif_autodetection, file_size_limit, allowed_mime_types, owner_id, type) FROM stdin;
\.


--
-- Data for Name: buckets_analytics; Type: TABLE DATA; Schema: storage; Owner: supabase_storage_admin
--

COPY storage.buckets_analytics (id, type, format, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: migrations; Type: TABLE DATA; Schema: storage; Owner: supabase_storage_admin
--

COPY storage.migrations (id, name, hash, executed_at) FROM stdin;
0	create-migrations-table	e18db593bcde2aca2a408c4d1100f6abba2195df	2025-10-18 15:25:12.240461
1	initialmigration	6ab16121fbaa08bbd11b712d05f358f9b555d777	2025-10-18 15:25:12.282475
2	storage-schema	5c7968fd083fcea04050c1b7f6253c9771b99011	2025-10-18 15:25:12.291741
3	pathtoken-column	2cb1b0004b817b29d5b0a971af16bafeede4b70d	2025-10-18 15:25:12.400162
4	add-migrations-rls	427c5b63fe1c5937495d9c635c263ee7a5905058	2025-10-18 15:25:12.820924
5	add-size-functions	79e081a1455b63666c1294a440f8ad4b1e6a7f84	2025-10-18 15:25:12.861284
6	change-column-name-in-get-size	f93f62afdf6613ee5e7e815b30d02dc990201044	2025-10-18 15:25:12.886031
7	add-rls-to-buckets	e7e7f86adbc51049f341dfe8d30256c1abca17aa	2025-10-18 15:25:12.922773
8	add-public-to-buckets	fd670db39ed65f9d08b01db09d6202503ca2bab3	2025-10-18 15:25:12.949231
9	fix-search-function	3a0af29f42e35a4d101c259ed955b67e1bee6825	2025-10-18 15:25:12.973239
10	search-files-search-function	68dc14822daad0ffac3746a502234f486182ef6e	2025-10-18 15:25:12.997827
11	add-trigger-to-auto-update-updated_at-column	7425bdb14366d1739fa8a18c83100636d74dcaa2	2025-10-18 15:25:13.040807
12	add-automatic-avif-detection-flag	8e92e1266eb29518b6a4c5313ab8f29dd0d08df9	2025-10-18 15:25:13.071841
13	add-bucket-custom-limits	cce962054138135cd9a8c4bcd531598684b25e7d	2025-10-18 15:25:13.085452
14	use-bytes-for-max-size	941c41b346f9802b411f06f30e972ad4744dad27	2025-10-18 15:25:13.120368
15	add-can-insert-object-function	934146bc38ead475f4ef4b555c524ee5d66799e5	2025-10-18 15:25:13.397631
16	add-version	76debf38d3fd07dcfc747ca49096457d95b1221b	2025-10-18 15:25:13.403993
17	drop-owner-foreign-key	f1cbb288f1b7a4c1eb8c38504b80ae2a0153d101	2025-10-18 15:25:13.407974
18	add_owner_id_column_deprecate_owner	e7a511b379110b08e2f214be852c35414749fe66	2025-10-18 15:25:13.527671
19	alter-default-value-objects-id	02e5e22a78626187e00d173dc45f58fa66a4f043	2025-10-18 15:25:13.542464
20	list-objects-with-delimiter	cd694ae708e51ba82bf012bba00caf4f3b6393b7	2025-10-18 15:25:13.546578
21	s3-multipart-uploads	8c804d4a566c40cd1e4cc5b3725a664a9303657f	2025-10-18 15:25:13.553695
22	s3-multipart-uploads-big-ints	9737dc258d2397953c9953d9b86920b8be0cdb73	2025-10-18 15:25:13.592576
23	optimize-search-function	9d7e604cddc4b56a5422dc68c9313f4a1b6f132c	2025-10-18 15:25:13.615922
24	operation-function	8312e37c2bf9e76bbe841aa5fda889206d2bf8aa	2025-10-18 15:25:13.621366
25	custom-metadata	d974c6057c3db1c1f847afa0e291e6165693b990	2025-10-18 15:25:13.626218
26	objects-prefixes	ef3f7871121cdc47a65308e6702519e853422ae2	2025-10-18 15:25:13.635334
27	search-v2	33b8f2a7ae53105f028e13e9fcda9dc4f356b4a2	2025-10-18 15:25:13.682852
28	object-bucket-name-sorting	ba85ec41b62c6a30a3f136788227ee47f311c436	2025-10-18 15:25:15.348712
29	create-prefixes	a7b1a22c0dc3ab630e3055bfec7ce7d2045c5b7b	2025-10-18 15:25:15.383612
30	update-object-levels	6c6f6cc9430d570f26284a24cf7b210599032db7	2025-10-18 15:25:15.426578
31	objects-level-index	33f1fef7ec7fea08bb892222f4f0f5d79bab5eb8	2025-10-18 15:25:15.440808
32	backward-compatible-index-on-objects	2d51eeb437a96868b36fcdfb1ddefdf13bef1647	2025-10-18 15:25:15.450707
33	backward-compatible-index-on-prefixes	fe473390e1b8c407434c0e470655945b110507bf	2025-10-18 15:25:15.474233
34	optimize-search-function-v1	82b0e469a00e8ebce495e29bfa70a0797f7ebd2c	2025-10-18 15:25:15.476205
35	add-insert-trigger-prefixes	63bb9fd05deb3dc5e9fa66c83e82b152f0caf589	2025-10-18 15:25:15.488227
36	optimise-existing-functions	81cf92eb0c36612865a18016a38496c530443899	2025-10-18 15:25:15.492458
37	add-bucket-name-length-trigger	3944135b4e3e8b22d6d4cbb568fe3b0b51df15c1	2025-10-18 15:25:15.506021
38	iceberg-catalog-flag-on-buckets	19a8bd89d5dfa69af7f222a46c726b7c41e462c5	2025-10-18 15:25:15.515214
39	add-search-v2-sort-support	39cf7d1e6bf515f4b02e41237aba845a7b492853	2025-10-18 15:25:15.538407
40	fix-prefix-race-conditions-optimized	fd02297e1c67df25a9fc110bf8c8a9af7fb06d1f	2025-10-18 15:25:15.735332
41	add-object-level-update-trigger	44c22478bf01744b2129efc480cd2edc9a7d60e9	2025-10-18 15:25:15.749499
42	rollback-prefix-triggers	f2ab4f526ab7f979541082992593938c05ee4b47	2025-10-18 15:25:15.759452
43	fix-object-level	ab837ad8f1c7d00cc0b7310e989a23388ff29fc6	2025-10-18 15:25:15.775119
\.


--
-- Data for Name: objects; Type: TABLE DATA; Schema: storage; Owner: supabase_storage_admin
--

COPY storage.objects (id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata, version, owner_id, user_metadata, level) FROM stdin;
\.


--
-- Data for Name: prefixes; Type: TABLE DATA; Schema: storage; Owner: supabase_storage_admin
--

COPY storage.prefixes (bucket_id, name, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: s3_multipart_uploads; Type: TABLE DATA; Schema: storage; Owner: supabase_storage_admin
--

COPY storage.s3_multipart_uploads (id, in_progress_size, upload_signature, bucket_id, key, version, owner_id, created_at, user_metadata) FROM stdin;
\.


--
-- Data for Name: s3_multipart_uploads_parts; Type: TABLE DATA; Schema: storage; Owner: supabase_storage_admin
--

COPY storage.s3_multipart_uploads_parts (id, upload_id, size, part_number, bucket_id, key, etag, owner_id, version, created_at) FROM stdin;
\.


--
-- Data for Name: secrets; Type: TABLE DATA; Schema: vault; Owner: supabase_admin
--

COPY vault.secrets (id, name, description, secret, key_id, nonce, created_at, updated_at) FROM stdin;
\.


--
-- Name: refresh_tokens_id_seq; Type: SEQUENCE SET; Schema: auth; Owner: supabase_auth_admin
--

SELECT pg_catalog.setval('auth.refresh_tokens_id_seq', 1, false);


--
-- Name: jobid_seq; Type: SEQUENCE SET; Schema: cron; Owner: supabase_admin
--

SELECT pg_catalog.setval('cron.jobid_seq', 1, true);


--
-- Name: runid_seq; Type: SEQUENCE SET; Schema: cron; Owner: supabase_admin
--

SELECT pg_catalog.setval('cron.runid_seq', 1205, true);


--
-- Name: subscription_id_seq; Type: SEQUENCE SET; Schema: realtime; Owner: supabase_admin
--

SELECT pg_catalog.setval('realtime.subscription_id_seq', 3, true);


--
-- Name: mfa_amr_claims amr_id_pk; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.mfa_amr_claims
    ADD CONSTRAINT amr_id_pk PRIMARY KEY (id);


--
-- Name: audit_log_entries audit_log_entries_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.audit_log_entries
    ADD CONSTRAINT audit_log_entries_pkey PRIMARY KEY (id);


--
-- Name: flow_state flow_state_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.flow_state
    ADD CONSTRAINT flow_state_pkey PRIMARY KEY (id);


--
-- Name: identities identities_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.identities
    ADD CONSTRAINT identities_pkey PRIMARY KEY (id);


--
-- Name: identities identities_provider_id_provider_unique; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.identities
    ADD CONSTRAINT identities_provider_id_provider_unique UNIQUE (provider_id, provider);


--
-- Name: instances instances_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.instances
    ADD CONSTRAINT instances_pkey PRIMARY KEY (id);


--
-- Name: mfa_amr_claims mfa_amr_claims_session_id_authentication_method_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.mfa_amr_claims
    ADD CONSTRAINT mfa_amr_claims_session_id_authentication_method_pkey UNIQUE (session_id, authentication_method);


--
-- Name: mfa_challenges mfa_challenges_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.mfa_challenges
    ADD CONSTRAINT mfa_challenges_pkey PRIMARY KEY (id);


--
-- Name: mfa_factors mfa_factors_last_challenged_at_key; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.mfa_factors
    ADD CONSTRAINT mfa_factors_last_challenged_at_key UNIQUE (last_challenged_at);


--
-- Name: mfa_factors mfa_factors_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.mfa_factors
    ADD CONSTRAINT mfa_factors_pkey PRIMARY KEY (id);


--
-- Name: oauth_authorizations oauth_authorizations_authorization_code_key; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.oauth_authorizations
    ADD CONSTRAINT oauth_authorizations_authorization_code_key UNIQUE (authorization_code);


--
-- Name: oauth_authorizations oauth_authorizations_authorization_id_key; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.oauth_authorizations
    ADD CONSTRAINT oauth_authorizations_authorization_id_key UNIQUE (authorization_id);


--
-- Name: oauth_authorizations oauth_authorizations_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.oauth_authorizations
    ADD CONSTRAINT oauth_authorizations_pkey PRIMARY KEY (id);


--
-- Name: oauth_clients oauth_clients_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.oauth_clients
    ADD CONSTRAINT oauth_clients_pkey PRIMARY KEY (id);


--
-- Name: oauth_consents oauth_consents_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.oauth_consents
    ADD CONSTRAINT oauth_consents_pkey PRIMARY KEY (id);


--
-- Name: oauth_consents oauth_consents_user_client_unique; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.oauth_consents
    ADD CONSTRAINT oauth_consents_user_client_unique UNIQUE (user_id, client_id);


--
-- Name: one_time_tokens one_time_tokens_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.one_time_tokens
    ADD CONSTRAINT one_time_tokens_pkey PRIMARY KEY (id);


--
-- Name: refresh_tokens refresh_tokens_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.refresh_tokens
    ADD CONSTRAINT refresh_tokens_pkey PRIMARY KEY (id);


--
-- Name: refresh_tokens refresh_tokens_token_unique; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.refresh_tokens
    ADD CONSTRAINT refresh_tokens_token_unique UNIQUE (token);


--
-- Name: saml_providers saml_providers_entity_id_key; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.saml_providers
    ADD CONSTRAINT saml_providers_entity_id_key UNIQUE (entity_id);


--
-- Name: saml_providers saml_providers_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.saml_providers
    ADD CONSTRAINT saml_providers_pkey PRIMARY KEY (id);


--
-- Name: saml_relay_states saml_relay_states_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.saml_relay_states
    ADD CONSTRAINT saml_relay_states_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: sessions sessions_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- Name: sso_domains sso_domains_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.sso_domains
    ADD CONSTRAINT sso_domains_pkey PRIMARY KEY (id);


--
-- Name: sso_providers sso_providers_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.sso_providers
    ADD CONSTRAINT sso_providers_pkey PRIMARY KEY (id);


--
-- Name: users users_phone_key; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.users
    ADD CONSTRAINT users_phone_key UNIQUE (phone);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: attestations attestations_attestation_uid_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attestations
    ADD CONSTRAINT attestations_attestation_uid_key UNIQUE (attestation_uid);


--
-- Name: attestations attestations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attestations
    ADD CONSTRAINT attestations_pkey PRIMARY KEY (id);


--
-- Name: auto_match_runs auto_match_runs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auto_match_runs
    ADD CONSTRAINT auto_match_runs_pkey PRIMARY KEY (id);


--
-- Name: chat_messages chat_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_messages
    ADD CONSTRAINT chat_messages_pkey PRIMARY KEY (id);


--
-- Name: chat_participants chat_participants_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_participants
    ADD CONSTRAINT chat_participants_pkey PRIMARY KEY (room_id, fid);


--
-- Name: chat_rooms chat_rooms_match_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_rooms
    ADD CONSTRAINT chat_rooms_match_id_key UNIQUE (match_id);


--
-- Name: chat_rooms chat_rooms_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_rooms
    ADD CONSTRAINT chat_rooms_pkey PRIMARY KEY (id);


--
-- Name: match_cooldowns match_cooldowns_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.match_cooldowns
    ADD CONSTRAINT match_cooldowns_pkey PRIMARY KEY (id);


--
-- Name: match_suggestion_cooldowns match_suggestion_cooldowns_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.match_suggestion_cooldowns
    ADD CONSTRAINT match_suggestion_cooldowns_pkey PRIMARY KEY (id);


--
-- Name: match_suggestions match_suggestions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.match_suggestions
    ADD CONSTRAINT match_suggestions_pkey PRIMARY KEY (id);


--
-- Name: matches matches_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.matches
    ADD CONSTRAINT matches_pkey PRIMARY KEY (id);


--
-- Name: messages messages_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (id);


--
-- Name: match_cooldowns uniq_cooldown_pair; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.match_cooldowns
    ADD CONSTRAINT uniq_cooldown_pair UNIQUE (user_a_fid, user_b_fid);


--
-- Name: user_achievements user_achievements_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_achievements
    ADD CONSTRAINT user_achievements_pkey PRIMARY KEY (id);


--
-- Name: user_achievements user_achievements_user_fid_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_achievements
    ADD CONSTRAINT user_achievements_user_fid_code_key UNIQUE (user_fid, code);


--
-- Name: user_friends user_friends_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_friends
    ADD CONSTRAINT user_friends_pkey PRIMARY KEY (user_fid, friend_fid);


--
-- Name: user_levels user_levels_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_levels
    ADD CONSTRAINT user_levels_pkey PRIMARY KEY (user_fid);


--
-- Name: user_wallets user_wallets_fid_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_wallets
    ADD CONSTRAINT user_wallets_fid_key UNIQUE (fid);


--
-- Name: user_wallets user_wallets_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_wallets
    ADD CONSTRAINT user_wallets_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (fid);


--
-- Name: messages messages_pkey; Type: CONSTRAINT; Schema: realtime; Owner: supabase_realtime_admin
--

ALTER TABLE ONLY realtime.messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (id, inserted_at);


--
-- Name: messages_2025_10_26 messages_2025_10_26_pkey; Type: CONSTRAINT; Schema: realtime; Owner: supabase_admin
--

ALTER TABLE ONLY realtime.messages_2025_10_26
    ADD CONSTRAINT messages_2025_10_26_pkey PRIMARY KEY (id, inserted_at);


--
-- Name: messages_2025_10_27 messages_2025_10_27_pkey; Type: CONSTRAINT; Schema: realtime; Owner: supabase_admin
--

ALTER TABLE ONLY realtime.messages_2025_10_27
    ADD CONSTRAINT messages_2025_10_27_pkey PRIMARY KEY (id, inserted_at);


--
-- Name: messages_2025_10_28 messages_2025_10_28_pkey; Type: CONSTRAINT; Schema: realtime; Owner: supabase_admin
--

ALTER TABLE ONLY realtime.messages_2025_10_28
    ADD CONSTRAINT messages_2025_10_28_pkey PRIMARY KEY (id, inserted_at);


--
-- Name: messages_2025_10_29 messages_2025_10_29_pkey; Type: CONSTRAINT; Schema: realtime; Owner: supabase_admin
--

ALTER TABLE ONLY realtime.messages_2025_10_29
    ADD CONSTRAINT messages_2025_10_29_pkey PRIMARY KEY (id, inserted_at);


--
-- Name: messages_2025_10_30 messages_2025_10_30_pkey; Type: CONSTRAINT; Schema: realtime; Owner: supabase_admin
--

ALTER TABLE ONLY realtime.messages_2025_10_30
    ADD CONSTRAINT messages_2025_10_30_pkey PRIMARY KEY (id, inserted_at);


--
-- Name: messages_2025_10_31 messages_2025_10_31_pkey; Type: CONSTRAINT; Schema: realtime; Owner: supabase_admin
--

ALTER TABLE ONLY realtime.messages_2025_10_31
    ADD CONSTRAINT messages_2025_10_31_pkey PRIMARY KEY (id, inserted_at);


--
-- Name: messages_2025_11_01 messages_2025_11_01_pkey; Type: CONSTRAINT; Schema: realtime; Owner: supabase_admin
--

ALTER TABLE ONLY realtime.messages_2025_11_01
    ADD CONSTRAINT messages_2025_11_01_pkey PRIMARY KEY (id, inserted_at);


--
-- Name: subscription pk_subscription; Type: CONSTRAINT; Schema: realtime; Owner: supabase_admin
--

ALTER TABLE ONLY realtime.subscription
    ADD CONSTRAINT pk_subscription PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: realtime; Owner: supabase_admin
--

ALTER TABLE ONLY realtime.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: buckets_analytics buckets_analytics_pkey; Type: CONSTRAINT; Schema: storage; Owner: supabase_storage_admin
--

ALTER TABLE ONLY storage.buckets_analytics
    ADD CONSTRAINT buckets_analytics_pkey PRIMARY KEY (id);


--
-- Name: buckets buckets_pkey; Type: CONSTRAINT; Schema: storage; Owner: supabase_storage_admin
--

ALTER TABLE ONLY storage.buckets
    ADD CONSTRAINT buckets_pkey PRIMARY KEY (id);


--
-- Name: migrations migrations_name_key; Type: CONSTRAINT; Schema: storage; Owner: supabase_storage_admin
--

ALTER TABLE ONLY storage.migrations
    ADD CONSTRAINT migrations_name_key UNIQUE (name);


--
-- Name: migrations migrations_pkey; Type: CONSTRAINT; Schema: storage; Owner: supabase_storage_admin
--

ALTER TABLE ONLY storage.migrations
    ADD CONSTRAINT migrations_pkey PRIMARY KEY (id);


--
-- Name: objects objects_pkey; Type: CONSTRAINT; Schema: storage; Owner: supabase_storage_admin
--

ALTER TABLE ONLY storage.objects
    ADD CONSTRAINT objects_pkey PRIMARY KEY (id);


--
-- Name: prefixes prefixes_pkey; Type: CONSTRAINT; Schema: storage; Owner: supabase_storage_admin
--

ALTER TABLE ONLY storage.prefixes
    ADD CONSTRAINT prefixes_pkey PRIMARY KEY (bucket_id, level, name);


--
-- Name: s3_multipart_uploads_parts s3_multipart_uploads_parts_pkey; Type: CONSTRAINT; Schema: storage; Owner: supabase_storage_admin
--

ALTER TABLE ONLY storage.s3_multipart_uploads_parts
    ADD CONSTRAINT s3_multipart_uploads_parts_pkey PRIMARY KEY (id);


--
-- Name: s3_multipart_uploads s3_multipart_uploads_pkey; Type: CONSTRAINT; Schema: storage; Owner: supabase_storage_admin
--

ALTER TABLE ONLY storage.s3_multipart_uploads
    ADD CONSTRAINT s3_multipart_uploads_pkey PRIMARY KEY (id);


--
-- Name: audit_logs_instance_id_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX audit_logs_instance_id_idx ON auth.audit_log_entries USING btree (instance_id);


--
-- Name: confirmation_token_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE UNIQUE INDEX confirmation_token_idx ON auth.users USING btree (confirmation_token) WHERE ((confirmation_token)::text !~ '^[0-9 ]*$'::text);


--
-- Name: email_change_token_current_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE UNIQUE INDEX email_change_token_current_idx ON auth.users USING btree (email_change_token_current) WHERE ((email_change_token_current)::text !~ '^[0-9 ]*$'::text);


--
-- Name: email_change_token_new_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE UNIQUE INDEX email_change_token_new_idx ON auth.users USING btree (email_change_token_new) WHERE ((email_change_token_new)::text !~ '^[0-9 ]*$'::text);


--
-- Name: factor_id_created_at_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX factor_id_created_at_idx ON auth.mfa_factors USING btree (user_id, created_at);


--
-- Name: flow_state_created_at_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX flow_state_created_at_idx ON auth.flow_state USING btree (created_at DESC);


--
-- Name: identities_email_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX identities_email_idx ON auth.identities USING btree (email text_pattern_ops);


--
-- Name: INDEX identities_email_idx; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON INDEX auth.identities_email_idx IS 'Auth: Ensures indexed queries on the email column';


--
-- Name: identities_user_id_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX identities_user_id_idx ON auth.identities USING btree (user_id);


--
-- Name: idx_auth_code; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX idx_auth_code ON auth.flow_state USING btree (auth_code);


--
-- Name: idx_user_id_auth_method; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX idx_user_id_auth_method ON auth.flow_state USING btree (user_id, authentication_method);


--
-- Name: mfa_challenge_created_at_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX mfa_challenge_created_at_idx ON auth.mfa_challenges USING btree (created_at DESC);


--
-- Name: mfa_factors_user_friendly_name_unique; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE UNIQUE INDEX mfa_factors_user_friendly_name_unique ON auth.mfa_factors USING btree (friendly_name, user_id) WHERE (TRIM(BOTH FROM friendly_name) <> ''::text);


--
-- Name: mfa_factors_user_id_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX mfa_factors_user_id_idx ON auth.mfa_factors USING btree (user_id);


--
-- Name: oauth_auth_pending_exp_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX oauth_auth_pending_exp_idx ON auth.oauth_authorizations USING btree (expires_at) WHERE (status = 'pending'::auth.oauth_authorization_status);


--
-- Name: oauth_clients_deleted_at_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX oauth_clients_deleted_at_idx ON auth.oauth_clients USING btree (deleted_at);


--
-- Name: oauth_consents_active_client_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX oauth_consents_active_client_idx ON auth.oauth_consents USING btree (client_id) WHERE (revoked_at IS NULL);


--
-- Name: oauth_consents_active_user_client_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX oauth_consents_active_user_client_idx ON auth.oauth_consents USING btree (user_id, client_id) WHERE (revoked_at IS NULL);


--
-- Name: oauth_consents_user_order_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX oauth_consents_user_order_idx ON auth.oauth_consents USING btree (user_id, granted_at DESC);


--
-- Name: one_time_tokens_relates_to_hash_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX one_time_tokens_relates_to_hash_idx ON auth.one_time_tokens USING hash (relates_to);


--
-- Name: one_time_tokens_token_hash_hash_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX one_time_tokens_token_hash_hash_idx ON auth.one_time_tokens USING hash (token_hash);


--
-- Name: one_time_tokens_user_id_token_type_key; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE UNIQUE INDEX one_time_tokens_user_id_token_type_key ON auth.one_time_tokens USING btree (user_id, token_type);


--
-- Name: reauthentication_token_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE UNIQUE INDEX reauthentication_token_idx ON auth.users USING btree (reauthentication_token) WHERE ((reauthentication_token)::text !~ '^[0-9 ]*$'::text);


--
-- Name: recovery_token_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE UNIQUE INDEX recovery_token_idx ON auth.users USING btree (recovery_token) WHERE ((recovery_token)::text !~ '^[0-9 ]*$'::text);


--
-- Name: refresh_tokens_instance_id_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX refresh_tokens_instance_id_idx ON auth.refresh_tokens USING btree (instance_id);


--
-- Name: refresh_tokens_instance_id_user_id_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX refresh_tokens_instance_id_user_id_idx ON auth.refresh_tokens USING btree (instance_id, user_id);


--
-- Name: refresh_tokens_parent_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX refresh_tokens_parent_idx ON auth.refresh_tokens USING btree (parent);


--
-- Name: refresh_tokens_session_id_revoked_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX refresh_tokens_session_id_revoked_idx ON auth.refresh_tokens USING btree (session_id, revoked);


--
-- Name: refresh_tokens_updated_at_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX refresh_tokens_updated_at_idx ON auth.refresh_tokens USING btree (updated_at DESC);


--
-- Name: saml_providers_sso_provider_id_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX saml_providers_sso_provider_id_idx ON auth.saml_providers USING btree (sso_provider_id);


--
-- Name: saml_relay_states_created_at_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX saml_relay_states_created_at_idx ON auth.saml_relay_states USING btree (created_at DESC);


--
-- Name: saml_relay_states_for_email_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX saml_relay_states_for_email_idx ON auth.saml_relay_states USING btree (for_email);


--
-- Name: saml_relay_states_sso_provider_id_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX saml_relay_states_sso_provider_id_idx ON auth.saml_relay_states USING btree (sso_provider_id);


--
-- Name: sessions_not_after_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX sessions_not_after_idx ON auth.sessions USING btree (not_after DESC);


--
-- Name: sessions_oauth_client_id_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX sessions_oauth_client_id_idx ON auth.sessions USING btree (oauth_client_id);


--
-- Name: sessions_user_id_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX sessions_user_id_idx ON auth.sessions USING btree (user_id);


--
-- Name: sso_domains_domain_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE UNIQUE INDEX sso_domains_domain_idx ON auth.sso_domains USING btree (lower(domain));


--
-- Name: sso_domains_sso_provider_id_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX sso_domains_sso_provider_id_idx ON auth.sso_domains USING btree (sso_provider_id);


--
-- Name: sso_providers_resource_id_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE UNIQUE INDEX sso_providers_resource_id_idx ON auth.sso_providers USING btree (lower(resource_id));


--
-- Name: sso_providers_resource_id_pattern_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX sso_providers_resource_id_pattern_idx ON auth.sso_providers USING btree (resource_id text_pattern_ops);


--
-- Name: unique_phone_factor_per_user; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE UNIQUE INDEX unique_phone_factor_per_user ON auth.mfa_factors USING btree (user_id, phone);


--
-- Name: user_id_created_at_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX user_id_created_at_idx ON auth.sessions USING btree (user_id, created_at);


--
-- Name: users_email_partial_key; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE UNIQUE INDEX users_email_partial_key ON auth.users USING btree (email) WHERE (is_sso_user = false);


--
-- Name: INDEX users_email_partial_key; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON INDEX auth.users_email_partial_key IS 'Auth: A partial unique index that applies only when is_sso_user is false';


--
-- Name: users_instance_id_email_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX users_instance_id_email_idx ON auth.users USING btree (instance_id, lower((email)::text));


--
-- Name: users_instance_id_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX users_instance_id_idx ON auth.users USING btree (instance_id);


--
-- Name: users_is_anonymous_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX users_is_anonymous_idx ON auth.users USING btree (is_anonymous);


--
-- Name: idx_attestations_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_attestations_created_at ON public.attestations USING btree (created_at DESC);


--
-- Name: idx_attestations_fid; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_attestations_fid ON public.attestations USING btree (fid);


--
-- Name: idx_attestations_uid; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_attestations_uid ON public.attestations USING btree (attestation_uid);


--
-- Name: idx_attestations_username; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_attestations_username ON public.attestations USING btree (username);


--
-- Name: idx_attestations_wallet_address; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_attestations_wallet_address ON public.attestations USING btree (wallet_address);


--
-- Name: idx_chat_messages_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_chat_messages_created_at ON public.chat_messages USING btree (room_id, created_at DESC);


--
-- Name: idx_chat_messages_room_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_chat_messages_room_id ON public.chat_messages USING btree (room_id);


--
-- Name: idx_chat_participants_fid; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_chat_participants_fid ON public.chat_participants USING btree (fid);


--
-- Name: idx_chat_rooms_first_join_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_chat_rooms_first_join_at ON public.chat_rooms USING btree (first_join_at);


--
-- Name: idx_chat_rooms_is_closed; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_chat_rooms_is_closed ON public.chat_rooms USING btree (is_closed);


--
-- Name: idx_chat_rooms_match_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_chat_rooms_match_id ON public.chat_rooms USING btree (match_id);


--
-- Name: idx_cooldowns_until; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_cooldowns_until ON public.match_cooldowns USING btree (cooldown_until);


--
-- Name: idx_cooldowns_users; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_cooldowns_users ON public.match_cooldowns USING btree (user_a_fid, user_b_fid);


--
-- Name: idx_match_cooldowns_pair; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_match_cooldowns_pair ON public.match_suggestion_cooldowns USING btree (LEAST(user_a_fid, user_b_fid), GREATEST(user_a_fid, user_b_fid), cooldown_until);


--
-- Name: idx_match_suggestions_chat_room; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_match_suggestions_chat_room ON public.match_suggestions USING btree (chat_room_id);


--
-- Name: idx_match_suggestions_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_match_suggestions_created_at ON public.match_suggestions USING btree (created_at DESC);


--
-- Name: idx_match_suggestions_creator; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_match_suggestions_creator ON public.match_suggestions USING btree (created_by_fid);


--
-- Name: idx_match_suggestions_pair_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_match_suggestions_pair_status ON public.match_suggestions USING btree (LEAST(user_a_fid, user_b_fid), GREATEST(user_a_fid, user_b_fid), status) WHERE (status <> ALL (ARRAY['declined'::text, 'cancelled'::text]));


--
-- Name: idx_match_suggestions_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_match_suggestions_status ON public.match_suggestions USING btree (status);


--
-- Name: idx_match_suggestions_unique_pending_pair; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX idx_match_suggestions_unique_pending_pair ON public.match_suggestions USING btree (LEAST(user_a_fid, user_b_fid), GREATEST(user_a_fid, user_b_fid)) WHERE (status = ANY (ARRAY['proposed'::text, 'accepted_by_a'::text, 'accepted_by_b'::text]));


--
-- Name: idx_match_suggestions_user_a; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_match_suggestions_user_a ON public.match_suggestions USING btree (user_a_fid);


--
-- Name: idx_match_suggestions_user_b; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_match_suggestions_user_b ON public.match_suggestions USING btree (user_b_fid);


--
-- Name: idx_matches_a_completed; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_matches_a_completed ON public.matches USING btree (a_completed);


--
-- Name: idx_matches_auto_close_check; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_matches_auto_close_check ON public.matches USING btree (meeting_state, meeting_expires_at) WHERE ((meeting_state = ANY (ARRAY['scheduled'::text, 'in_progress'::text])) AND (meeting_expires_at IS NOT NULL));


--
-- Name: idx_matches_b_completed; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_matches_b_completed ON public.matches USING btree (b_completed);


--
-- Name: idx_matches_completed; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_matches_completed ON public.matches USING btree (status) WHERE (status = 'completed'::text);


--
-- Name: idx_matches_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_matches_created_at ON public.matches USING btree (created_at DESC);


--
-- Name: idx_matches_created_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_matches_created_by ON public.matches USING btree (created_by);


--
-- Name: idx_matches_creator; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_matches_creator ON public.matches USING btree (created_by_fid);


--
-- Name: idx_matches_meeting_expires_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_matches_meeting_expires_at ON public.matches USING btree (meeting_expires_at) WHERE (meeting_state <> 'closed'::text);


--
-- Name: idx_matches_meeting_state; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_matches_meeting_state ON public.matches USING btree (meeting_state);


--
-- Name: idx_matches_rationale; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_matches_rationale ON public.matches USING gin (rationale);


--
-- Name: idx_matches_scheduled_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_matches_scheduled_at ON public.matches USING btree (scheduled_at) WHERE (scheduled_at IS NOT NULL);


--
-- Name: idx_matches_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_matches_status ON public.matches USING btree (status);


--
-- Name: idx_matches_user_a; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_matches_user_a ON public.matches USING btree (user_a_fid);


--
-- Name: idx_matches_user_b; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_matches_user_b ON public.matches USING btree (user_b_fid);


--
-- Name: idx_messages_match_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_messages_match_id ON public.messages USING btree (match_id, created_at DESC);


--
-- Name: idx_messages_sender; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_messages_sender ON public.messages USING btree (sender_fid);


--
-- Name: idx_user_achievements_awarded; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_user_achievements_awarded ON public.user_achievements USING btree (awarded_at DESC);


--
-- Name: idx_user_achievements_code; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_user_achievements_code ON public.user_achievements USING btree (code);


--
-- Name: idx_user_achievements_fid; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_user_achievements_fid ON public.user_achievements USING btree (user_fid);


--
-- Name: idx_user_friends_cached_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_user_friends_cached_at ON public.user_friends USING btree (cached_at);


--
-- Name: idx_user_friends_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_user_friends_user ON public.user_friends USING btree (user_fid);


--
-- Name: idx_user_levels_fid; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_user_levels_fid ON public.user_levels USING btree (user_fid);


--
-- Name: idx_user_levels_points; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_user_levels_points ON public.user_levels USING btree (points_total DESC);


--
-- Name: idx_user_wallets_address; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_user_wallets_address ON public.user_wallets USING btree (wallet_address);


--
-- Name: idx_user_wallets_fid; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_user_wallets_fid ON public.user_wallets USING btree (fid);


--
-- Name: idx_users_bio; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_bio ON public.users USING gin (to_tsvector('english'::regconfig, bio)) WHERE (bio IS NOT NULL);


--
-- Name: idx_users_has_joined; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_has_joined ON public.users USING btree (has_joined_meetshipper);


--
-- Name: idx_users_traits; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_traits ON public.users USING gin (traits);


--
-- Name: idx_users_traits_gin; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_traits_gin ON public.users USING gin (traits);


--
-- Name: idx_users_username; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_username ON public.users USING btree (username);


--
-- Name: users_user_code_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX users_user_code_key ON public.users USING btree (user_code);


--
-- Name: ix_realtime_subscription_entity; Type: INDEX; Schema: realtime; Owner: supabase_admin
--

CREATE INDEX ix_realtime_subscription_entity ON realtime.subscription USING btree (entity);


--
-- Name: messages_inserted_at_topic_index; Type: INDEX; Schema: realtime; Owner: supabase_realtime_admin
--

CREATE INDEX messages_inserted_at_topic_index ON ONLY realtime.messages USING btree (inserted_at DESC, topic) WHERE ((extension = 'broadcast'::text) AND (private IS TRUE));


--
-- Name: messages_2025_10_26_inserted_at_topic_idx; Type: INDEX; Schema: realtime; Owner: supabase_admin
--

CREATE INDEX messages_2025_10_26_inserted_at_topic_idx ON realtime.messages_2025_10_26 USING btree (inserted_at DESC, topic) WHERE ((extension = 'broadcast'::text) AND (private IS TRUE));


--
-- Name: messages_2025_10_27_inserted_at_topic_idx; Type: INDEX; Schema: realtime; Owner: supabase_admin
--

CREATE INDEX messages_2025_10_27_inserted_at_topic_idx ON realtime.messages_2025_10_27 USING btree (inserted_at DESC, topic) WHERE ((extension = 'broadcast'::text) AND (private IS TRUE));


--
-- Name: messages_2025_10_28_inserted_at_topic_idx; Type: INDEX; Schema: realtime; Owner: supabase_admin
--

CREATE INDEX messages_2025_10_28_inserted_at_topic_idx ON realtime.messages_2025_10_28 USING btree (inserted_at DESC, topic) WHERE ((extension = 'broadcast'::text) AND (private IS TRUE));


--
-- Name: messages_2025_10_29_inserted_at_topic_idx; Type: INDEX; Schema: realtime; Owner: supabase_admin
--

CREATE INDEX messages_2025_10_29_inserted_at_topic_idx ON realtime.messages_2025_10_29 USING btree (inserted_at DESC, topic) WHERE ((extension = 'broadcast'::text) AND (private IS TRUE));


--
-- Name: messages_2025_10_30_inserted_at_topic_idx; Type: INDEX; Schema: realtime; Owner: supabase_admin
--

CREATE INDEX messages_2025_10_30_inserted_at_topic_idx ON realtime.messages_2025_10_30 USING btree (inserted_at DESC, topic) WHERE ((extension = 'broadcast'::text) AND (private IS TRUE));


--
-- Name: messages_2025_10_31_inserted_at_topic_idx; Type: INDEX; Schema: realtime; Owner: supabase_admin
--

CREATE INDEX messages_2025_10_31_inserted_at_topic_idx ON realtime.messages_2025_10_31 USING btree (inserted_at DESC, topic) WHERE ((extension = 'broadcast'::text) AND (private IS TRUE));


--
-- Name: messages_2025_11_01_inserted_at_topic_idx; Type: INDEX; Schema: realtime; Owner: supabase_admin
--

CREATE INDEX messages_2025_11_01_inserted_at_topic_idx ON realtime.messages_2025_11_01 USING btree (inserted_at DESC, topic) WHERE ((extension = 'broadcast'::text) AND (private IS TRUE));


--
-- Name: subscription_subscription_id_entity_filters_key; Type: INDEX; Schema: realtime; Owner: supabase_admin
--

CREATE UNIQUE INDEX subscription_subscription_id_entity_filters_key ON realtime.subscription USING btree (subscription_id, entity, filters);


--
-- Name: bname; Type: INDEX; Schema: storage; Owner: supabase_storage_admin
--

CREATE UNIQUE INDEX bname ON storage.buckets USING btree (name);


--
-- Name: bucketid_objname; Type: INDEX; Schema: storage; Owner: supabase_storage_admin
--

CREATE UNIQUE INDEX bucketid_objname ON storage.objects USING btree (bucket_id, name);


--
-- Name: idx_multipart_uploads_list; Type: INDEX; Schema: storage; Owner: supabase_storage_admin
--

CREATE INDEX idx_multipart_uploads_list ON storage.s3_multipart_uploads USING btree (bucket_id, key, created_at);


--
-- Name: idx_name_bucket_level_unique; Type: INDEX; Schema: storage; Owner: supabase_storage_admin
--

CREATE UNIQUE INDEX idx_name_bucket_level_unique ON storage.objects USING btree (name COLLATE "C", bucket_id, level);


--
-- Name: idx_objects_bucket_id_name; Type: INDEX; Schema: storage; Owner: supabase_storage_admin
--

CREATE INDEX idx_objects_bucket_id_name ON storage.objects USING btree (bucket_id, name COLLATE "C");


--
-- Name: idx_objects_lower_name; Type: INDEX; Schema: storage; Owner: supabase_storage_admin
--

CREATE INDEX idx_objects_lower_name ON storage.objects USING btree ((path_tokens[level]), lower(name) text_pattern_ops, bucket_id, level);


--
-- Name: idx_prefixes_lower_name; Type: INDEX; Schema: storage; Owner: supabase_storage_admin
--

CREATE INDEX idx_prefixes_lower_name ON storage.prefixes USING btree (bucket_id, level, ((string_to_array(name, '/'::text))[level]), lower(name) text_pattern_ops);


--
-- Name: name_prefix_search; Type: INDEX; Schema: storage; Owner: supabase_storage_admin
--

CREATE INDEX name_prefix_search ON storage.objects USING btree (name text_pattern_ops);


--
-- Name: objects_bucket_id_level_idx; Type: INDEX; Schema: storage; Owner: supabase_storage_admin
--

CREATE UNIQUE INDEX objects_bucket_id_level_idx ON storage.objects USING btree (bucket_id, level, name COLLATE "C");


--
-- Name: messages_2025_10_26_inserted_at_topic_idx; Type: INDEX ATTACH; Schema: realtime; Owner: supabase_realtime_admin
--

ALTER INDEX realtime.messages_inserted_at_topic_index ATTACH PARTITION realtime.messages_2025_10_26_inserted_at_topic_idx;


--
-- Name: messages_2025_10_26_pkey; Type: INDEX ATTACH; Schema: realtime; Owner: supabase_realtime_admin
--

ALTER INDEX realtime.messages_pkey ATTACH PARTITION realtime.messages_2025_10_26_pkey;


--
-- Name: messages_2025_10_27_inserted_at_topic_idx; Type: INDEX ATTACH; Schema: realtime; Owner: supabase_realtime_admin
--

ALTER INDEX realtime.messages_inserted_at_topic_index ATTACH PARTITION realtime.messages_2025_10_27_inserted_at_topic_idx;


--
-- Name: messages_2025_10_27_pkey; Type: INDEX ATTACH; Schema: realtime; Owner: supabase_realtime_admin
--

ALTER INDEX realtime.messages_pkey ATTACH PARTITION realtime.messages_2025_10_27_pkey;


--
-- Name: messages_2025_10_28_inserted_at_topic_idx; Type: INDEX ATTACH; Schema: realtime; Owner: supabase_realtime_admin
--

ALTER INDEX realtime.messages_inserted_at_topic_index ATTACH PARTITION realtime.messages_2025_10_28_inserted_at_topic_idx;


--
-- Name: messages_2025_10_28_pkey; Type: INDEX ATTACH; Schema: realtime; Owner: supabase_realtime_admin
--

ALTER INDEX realtime.messages_pkey ATTACH PARTITION realtime.messages_2025_10_28_pkey;


--
-- Name: messages_2025_10_29_inserted_at_topic_idx; Type: INDEX ATTACH; Schema: realtime; Owner: supabase_realtime_admin
--

ALTER INDEX realtime.messages_inserted_at_topic_index ATTACH PARTITION realtime.messages_2025_10_29_inserted_at_topic_idx;


--
-- Name: messages_2025_10_29_pkey; Type: INDEX ATTACH; Schema: realtime; Owner: supabase_realtime_admin
--

ALTER INDEX realtime.messages_pkey ATTACH PARTITION realtime.messages_2025_10_29_pkey;


--
-- Name: messages_2025_10_30_inserted_at_topic_idx; Type: INDEX ATTACH; Schema: realtime; Owner: supabase_realtime_admin
--

ALTER INDEX realtime.messages_inserted_at_topic_index ATTACH PARTITION realtime.messages_2025_10_30_inserted_at_topic_idx;


--
-- Name: messages_2025_10_30_pkey; Type: INDEX ATTACH; Schema: realtime; Owner: supabase_realtime_admin
--

ALTER INDEX realtime.messages_pkey ATTACH PARTITION realtime.messages_2025_10_30_pkey;


--
-- Name: messages_2025_10_31_inserted_at_topic_idx; Type: INDEX ATTACH; Schema: realtime; Owner: supabase_realtime_admin
--

ALTER INDEX realtime.messages_inserted_at_topic_index ATTACH PARTITION realtime.messages_2025_10_31_inserted_at_topic_idx;


--
-- Name: messages_2025_10_31_pkey; Type: INDEX ATTACH; Schema: realtime; Owner: supabase_realtime_admin
--

ALTER INDEX realtime.messages_pkey ATTACH PARTITION realtime.messages_2025_10_31_pkey;


--
-- Name: messages_2025_11_01_inserted_at_topic_idx; Type: INDEX ATTACH; Schema: realtime; Owner: supabase_realtime_admin
--

ALTER INDEX realtime.messages_inserted_at_topic_index ATTACH PARTITION realtime.messages_2025_11_01_inserted_at_topic_idx;


--
-- Name: messages_2025_11_01_pkey; Type: INDEX ATTACH; Schema: realtime; Owner: supabase_realtime_admin
--

ALTER INDEX realtime.messages_pkey ATTACH PARTITION realtime.messages_2025_11_01_pkey;


--
-- Name: matches check_match_acceptance; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER check_match_acceptance BEFORE UPDATE ON public.matches FOR EACH ROW EXECUTE FUNCTION public.update_match_status();


--
-- Name: matches check_match_completion; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER check_match_completion BEFORE UPDATE ON public.matches FOR EACH ROW EXECUTE FUNCTION public.update_match_completion();


--
-- Name: matches create_match_notification; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER create_match_notification AFTER INSERT ON public.matches FOR EACH ROW EXECUTE FUNCTION public.create_initial_match_message();


--
-- Name: matches match_declined_cooldown; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER match_declined_cooldown AFTER UPDATE ON public.matches FOR EACH ROW WHEN ((new.status = 'declined'::text)) EXECUTE FUNCTION public.trg_match_declined_cooldown();


--
-- Name: attestations set_attestations_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_attestations_updated_at BEFORE UPDATE ON public.attestations FOR EACH ROW EXECUTE FUNCTION public.update_attestations_updated_at();


--
-- Name: matches trg_match_cancel; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_match_cancel AFTER UPDATE ON public.matches FOR EACH ROW EXECUTE FUNCTION public.add_cooldown_on_cancel();


--
-- Name: users trg_set_user_code; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_set_user_code BEFORE INSERT ON public.users FOR EACH ROW EXECUTE FUNCTION public.set_user_code_before_insert();


--
-- Name: match_suggestions trigger_create_suggestion_cooldown; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_create_suggestion_cooldown AFTER UPDATE ON public.match_suggestions FOR EACH ROW EXECUTE FUNCTION public.create_suggestion_cooldown();


--
-- Name: match_suggestions trigger_update_suggestion_status; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_update_suggestion_status BEFORE UPDATE ON public.match_suggestions FOR EACH ROW WHEN (((old.a_accepted IS DISTINCT FROM new.a_accepted) OR (old.b_accepted IS DISTINCT FROM new.b_accepted))) EXECUTE FUNCTION public.update_suggestion_status();


--
-- Name: user_levels trigger_update_user_levels_timestamp; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_update_user_levels_timestamp BEFORE UPDATE ON public.user_levels FOR EACH ROW EXECUTE FUNCTION public.update_user_levels_timestamp();


--
-- Name: chat_participants update_chat_participants_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_chat_participants_updated_at BEFORE UPDATE ON public.chat_participants FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: chat_rooms update_chat_rooms_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_chat_rooms_updated_at BEFORE UPDATE ON public.chat_rooms FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: match_suggestions update_match_suggestions_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_match_suggestions_updated_at BEFORE UPDATE ON public.match_suggestions FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: matches update_matches_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_matches_updated_at BEFORE UPDATE ON public.matches FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: users update_users_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: subscription tr_check_filters; Type: TRIGGER; Schema: realtime; Owner: supabase_admin
--

CREATE TRIGGER tr_check_filters BEFORE INSERT OR UPDATE ON realtime.subscription FOR EACH ROW EXECUTE FUNCTION realtime.subscription_check_filters();


--
-- Name: buckets enforce_bucket_name_length_trigger; Type: TRIGGER; Schema: storage; Owner: supabase_storage_admin
--

CREATE TRIGGER enforce_bucket_name_length_trigger BEFORE INSERT OR UPDATE OF name ON storage.buckets FOR EACH ROW EXECUTE FUNCTION storage.enforce_bucket_name_length();


--
-- Name: objects objects_delete_delete_prefix; Type: TRIGGER; Schema: storage; Owner: supabase_storage_admin
--

CREATE TRIGGER objects_delete_delete_prefix AFTER DELETE ON storage.objects FOR EACH ROW EXECUTE FUNCTION storage.delete_prefix_hierarchy_trigger();


--
-- Name: objects objects_insert_create_prefix; Type: TRIGGER; Schema: storage; Owner: supabase_storage_admin
--

CREATE TRIGGER objects_insert_create_prefix BEFORE INSERT ON storage.objects FOR EACH ROW EXECUTE FUNCTION storage.objects_insert_prefix_trigger();


--
-- Name: objects objects_update_create_prefix; Type: TRIGGER; Schema: storage; Owner: supabase_storage_admin
--

CREATE TRIGGER objects_update_create_prefix BEFORE UPDATE ON storage.objects FOR EACH ROW WHEN (((new.name <> old.name) OR (new.bucket_id <> old.bucket_id))) EXECUTE FUNCTION storage.objects_update_prefix_trigger();


--
-- Name: prefixes prefixes_create_hierarchy; Type: TRIGGER; Schema: storage; Owner: supabase_storage_admin
--

CREATE TRIGGER prefixes_create_hierarchy BEFORE INSERT ON storage.prefixes FOR EACH ROW WHEN ((pg_trigger_depth() < 1)) EXECUTE FUNCTION storage.prefixes_insert_trigger();


--
-- Name: prefixes prefixes_delete_hierarchy; Type: TRIGGER; Schema: storage; Owner: supabase_storage_admin
--

CREATE TRIGGER prefixes_delete_hierarchy AFTER DELETE ON storage.prefixes FOR EACH ROW EXECUTE FUNCTION storage.delete_prefix_hierarchy_trigger();


--
-- Name: objects update_objects_updated_at; Type: TRIGGER; Schema: storage; Owner: supabase_storage_admin
--

CREATE TRIGGER update_objects_updated_at BEFORE UPDATE ON storage.objects FOR EACH ROW EXECUTE FUNCTION storage.update_updated_at_column();


--
-- Name: identities identities_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.identities
    ADD CONSTRAINT identities_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: mfa_amr_claims mfa_amr_claims_session_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.mfa_amr_claims
    ADD CONSTRAINT mfa_amr_claims_session_id_fkey FOREIGN KEY (session_id) REFERENCES auth.sessions(id) ON DELETE CASCADE;


--
-- Name: mfa_challenges mfa_challenges_auth_factor_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.mfa_challenges
    ADD CONSTRAINT mfa_challenges_auth_factor_id_fkey FOREIGN KEY (factor_id) REFERENCES auth.mfa_factors(id) ON DELETE CASCADE;


--
-- Name: mfa_factors mfa_factors_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.mfa_factors
    ADD CONSTRAINT mfa_factors_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: oauth_authorizations oauth_authorizations_client_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.oauth_authorizations
    ADD CONSTRAINT oauth_authorizations_client_id_fkey FOREIGN KEY (client_id) REFERENCES auth.oauth_clients(id) ON DELETE CASCADE;


--
-- Name: oauth_authorizations oauth_authorizations_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.oauth_authorizations
    ADD CONSTRAINT oauth_authorizations_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: oauth_consents oauth_consents_client_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.oauth_consents
    ADD CONSTRAINT oauth_consents_client_id_fkey FOREIGN KEY (client_id) REFERENCES auth.oauth_clients(id) ON DELETE CASCADE;


--
-- Name: oauth_consents oauth_consents_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.oauth_consents
    ADD CONSTRAINT oauth_consents_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: one_time_tokens one_time_tokens_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.one_time_tokens
    ADD CONSTRAINT one_time_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: refresh_tokens refresh_tokens_session_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.refresh_tokens
    ADD CONSTRAINT refresh_tokens_session_id_fkey FOREIGN KEY (session_id) REFERENCES auth.sessions(id) ON DELETE CASCADE;


--
-- Name: saml_providers saml_providers_sso_provider_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.saml_providers
    ADD CONSTRAINT saml_providers_sso_provider_id_fkey FOREIGN KEY (sso_provider_id) REFERENCES auth.sso_providers(id) ON DELETE CASCADE;


--
-- Name: saml_relay_states saml_relay_states_flow_state_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.saml_relay_states
    ADD CONSTRAINT saml_relay_states_flow_state_id_fkey FOREIGN KEY (flow_state_id) REFERENCES auth.flow_state(id) ON DELETE CASCADE;


--
-- Name: saml_relay_states saml_relay_states_sso_provider_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.saml_relay_states
    ADD CONSTRAINT saml_relay_states_sso_provider_id_fkey FOREIGN KEY (sso_provider_id) REFERENCES auth.sso_providers(id) ON DELETE CASCADE;


--
-- Name: sessions sessions_oauth_client_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.sessions
    ADD CONSTRAINT sessions_oauth_client_id_fkey FOREIGN KEY (oauth_client_id) REFERENCES auth.oauth_clients(id) ON DELETE CASCADE;


--
-- Name: sessions sessions_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.sessions
    ADD CONSTRAINT sessions_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: sso_domains sso_domains_sso_provider_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.sso_domains
    ADD CONSTRAINT sso_domains_sso_provider_id_fkey FOREIGN KEY (sso_provider_id) REFERENCES auth.sso_providers(id) ON DELETE CASCADE;


--
-- Name: attestations attestations_fid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attestations
    ADD CONSTRAINT attestations_fid_fkey FOREIGN KEY (fid) REFERENCES public.users(fid) ON DELETE CASCADE;


--
-- Name: chat_messages chat_messages_room_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_messages
    ADD CONSTRAINT chat_messages_room_id_fkey FOREIGN KEY (room_id) REFERENCES public.chat_rooms(id) ON DELETE CASCADE;


--
-- Name: chat_messages chat_messages_sender_fid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_messages
    ADD CONSTRAINT chat_messages_sender_fid_fkey FOREIGN KEY (sender_fid) REFERENCES public.users(fid) ON DELETE CASCADE;


--
-- Name: chat_participants chat_participants_fid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_participants
    ADD CONSTRAINT chat_participants_fid_fkey FOREIGN KEY (fid) REFERENCES public.users(fid) ON DELETE CASCADE;


--
-- Name: chat_participants chat_participants_room_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_participants
    ADD CONSTRAINT chat_participants_room_id_fkey FOREIGN KEY (room_id) REFERENCES public.chat_rooms(id) ON DELETE CASCADE;


--
-- Name: chat_rooms chat_rooms_match_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_rooms
    ADD CONSTRAINT chat_rooms_match_id_fkey FOREIGN KEY (match_id) REFERENCES public.matches(id) ON DELETE CASCADE;


--
-- Name: user_wallets fk_user_wallets_fid; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_wallets
    ADD CONSTRAINT fk_user_wallets_fid FOREIGN KEY (fid) REFERENCES public.users(fid) ON DELETE CASCADE;


--
-- Name: match_cooldowns match_cooldowns_user_a_fid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.match_cooldowns
    ADD CONSTRAINT match_cooldowns_user_a_fid_fkey FOREIGN KEY (user_a_fid) REFERENCES public.users(fid) ON DELETE CASCADE;


--
-- Name: match_cooldowns match_cooldowns_user_b_fid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.match_cooldowns
    ADD CONSTRAINT match_cooldowns_user_b_fid_fkey FOREIGN KEY (user_b_fid) REFERENCES public.users(fid) ON DELETE CASCADE;


--
-- Name: match_suggestion_cooldowns match_suggestion_cooldowns_declined_suggestion_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.match_suggestion_cooldowns
    ADD CONSTRAINT match_suggestion_cooldowns_declined_suggestion_id_fkey FOREIGN KEY (declined_suggestion_id) REFERENCES public.match_suggestions(id) ON DELETE SET NULL;


--
-- Name: match_suggestion_cooldowns match_suggestion_cooldowns_user_a_fid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.match_suggestion_cooldowns
    ADD CONSTRAINT match_suggestion_cooldowns_user_a_fid_fkey FOREIGN KEY (user_a_fid) REFERENCES public.users(fid) ON DELETE CASCADE;


--
-- Name: match_suggestion_cooldowns match_suggestion_cooldowns_user_b_fid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.match_suggestion_cooldowns
    ADD CONSTRAINT match_suggestion_cooldowns_user_b_fid_fkey FOREIGN KEY (user_b_fid) REFERENCES public.users(fid) ON DELETE CASCADE;


--
-- Name: match_suggestions match_suggestions_chat_room_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.match_suggestions
    ADD CONSTRAINT match_suggestions_chat_room_id_fkey FOREIGN KEY (chat_room_id) REFERENCES public.chat_rooms(id) ON DELETE SET NULL;


--
-- Name: match_suggestions match_suggestions_created_by_fid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.match_suggestions
    ADD CONSTRAINT match_suggestions_created_by_fid_fkey FOREIGN KEY (created_by_fid) REFERENCES public.users(fid) ON DELETE CASCADE;


--
-- Name: match_suggestions match_suggestions_user_a_fid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.match_suggestions
    ADD CONSTRAINT match_suggestions_user_a_fid_fkey FOREIGN KEY (user_a_fid) REFERENCES public.users(fid) ON DELETE CASCADE;


--
-- Name: match_suggestions match_suggestions_user_b_fid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.match_suggestions
    ADD CONSTRAINT match_suggestions_user_b_fid_fkey FOREIGN KEY (user_b_fid) REFERENCES public.users(fid) ON DELETE CASCADE;


--
-- Name: matches matches_created_by_fid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.matches
    ADD CONSTRAINT matches_created_by_fid_fkey FOREIGN KEY (created_by_fid) REFERENCES public.users(fid) ON DELETE CASCADE;


--
-- Name: matches matches_user_a_fid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.matches
    ADD CONSTRAINT matches_user_a_fid_fkey FOREIGN KEY (user_a_fid) REFERENCES public.users(fid) ON DELETE CASCADE;


--
-- Name: matches matches_user_b_fid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.matches
    ADD CONSTRAINT matches_user_b_fid_fkey FOREIGN KEY (user_b_fid) REFERENCES public.users(fid) ON DELETE CASCADE;


--
-- Name: messages messages_match_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_match_id_fkey FOREIGN KEY (match_id) REFERENCES public.matches(id) ON DELETE CASCADE;


--
-- Name: messages messages_sender_fid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_sender_fid_fkey FOREIGN KEY (sender_fid) REFERENCES public.users(fid) ON DELETE CASCADE;


--
-- Name: user_achievements user_achievements_user_fid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_achievements
    ADD CONSTRAINT user_achievements_user_fid_fkey FOREIGN KEY (user_fid) REFERENCES public.users(fid) ON DELETE CASCADE;


--
-- Name: user_friends user_friends_user_fid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_friends
    ADD CONSTRAINT user_friends_user_fid_fkey FOREIGN KEY (user_fid) REFERENCES public.users(fid) ON DELETE CASCADE;


--
-- Name: user_levels user_levels_user_fid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_levels
    ADD CONSTRAINT user_levels_user_fid_fkey FOREIGN KEY (user_fid) REFERENCES public.users(fid) ON DELETE CASCADE;


--
-- Name: objects objects_bucketId_fkey; Type: FK CONSTRAINT; Schema: storage; Owner: supabase_storage_admin
--

ALTER TABLE ONLY storage.objects
    ADD CONSTRAINT "objects_bucketId_fkey" FOREIGN KEY (bucket_id) REFERENCES storage.buckets(id);


--
-- Name: prefixes prefixes_bucketId_fkey; Type: FK CONSTRAINT; Schema: storage; Owner: supabase_storage_admin
--

ALTER TABLE ONLY storage.prefixes
    ADD CONSTRAINT "prefixes_bucketId_fkey" FOREIGN KEY (bucket_id) REFERENCES storage.buckets(id);


--
-- Name: s3_multipart_uploads s3_multipart_uploads_bucket_id_fkey; Type: FK CONSTRAINT; Schema: storage; Owner: supabase_storage_admin
--

ALTER TABLE ONLY storage.s3_multipart_uploads
    ADD CONSTRAINT s3_multipart_uploads_bucket_id_fkey FOREIGN KEY (bucket_id) REFERENCES storage.buckets(id);


--
-- Name: s3_multipart_uploads_parts s3_multipart_uploads_parts_bucket_id_fkey; Type: FK CONSTRAINT; Schema: storage; Owner: supabase_storage_admin
--

ALTER TABLE ONLY storage.s3_multipart_uploads_parts
    ADD CONSTRAINT s3_multipart_uploads_parts_bucket_id_fkey FOREIGN KEY (bucket_id) REFERENCES storage.buckets(id);


--
-- Name: s3_multipart_uploads_parts s3_multipart_uploads_parts_upload_id_fkey; Type: FK CONSTRAINT; Schema: storage; Owner: supabase_storage_admin
--

ALTER TABLE ONLY storage.s3_multipart_uploads_parts
    ADD CONSTRAINT s3_multipart_uploads_parts_upload_id_fkey FOREIGN KEY (upload_id) REFERENCES storage.s3_multipart_uploads(id) ON DELETE CASCADE;


--
-- Name: audit_log_entries; Type: ROW SECURITY; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE auth.audit_log_entries ENABLE ROW LEVEL SECURITY;

--
-- Name: flow_state; Type: ROW SECURITY; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE auth.flow_state ENABLE ROW LEVEL SECURITY;

--
-- Name: identities; Type: ROW SECURITY; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE auth.identities ENABLE ROW LEVEL SECURITY;

--
-- Name: instances; Type: ROW SECURITY; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE auth.instances ENABLE ROW LEVEL SECURITY;

--
-- Name: mfa_amr_claims; Type: ROW SECURITY; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE auth.mfa_amr_claims ENABLE ROW LEVEL SECURITY;

--
-- Name: mfa_challenges; Type: ROW SECURITY; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE auth.mfa_challenges ENABLE ROW LEVEL SECURITY;

--
-- Name: mfa_factors; Type: ROW SECURITY; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE auth.mfa_factors ENABLE ROW LEVEL SECURITY;

--
-- Name: one_time_tokens; Type: ROW SECURITY; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE auth.one_time_tokens ENABLE ROW LEVEL SECURITY;

--
-- Name: refresh_tokens; Type: ROW SECURITY; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE auth.refresh_tokens ENABLE ROW LEVEL SECURITY;

--
-- Name: saml_providers; Type: ROW SECURITY; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE auth.saml_providers ENABLE ROW LEVEL SECURITY;

--
-- Name: saml_relay_states; Type: ROW SECURITY; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE auth.saml_relay_states ENABLE ROW LEVEL SECURITY;

--
-- Name: schema_migrations; Type: ROW SECURITY; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE auth.schema_migrations ENABLE ROW LEVEL SECURITY;

--
-- Name: sessions; Type: ROW SECURITY; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE auth.sessions ENABLE ROW LEVEL SECURITY;

--
-- Name: sso_domains; Type: ROW SECURITY; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE auth.sso_domains ENABLE ROW LEVEL SECURITY;

--
-- Name: sso_providers; Type: ROW SECURITY; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE auth.sso_providers ENABLE ROW LEVEL SECURITY;

--
-- Name: users; Type: ROW SECURITY; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE auth.users ENABLE ROW LEVEL SECURITY;

--
-- Name: match_suggestions Participants can accept/decline suggestions; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Participants can accept/decline suggestions" ON public.match_suggestions FOR UPDATE USING (((user_a_fid = (((current_setting('request.jwt.claims'::text, true))::json ->> 'fid'::text))::bigint) OR (user_b_fid = (((current_setting('request.jwt.claims'::text, true))::json ->> 'fid'::text))::bigint))) WITH CHECK (((user_a_fid = (((current_setting('request.jwt.claims'::text, true))::json ->> 'fid'::text))::bigint) OR (user_b_fid = (((current_setting('request.jwt.claims'::text, true))::json ->> 'fid'::text))::bigint)));


--
-- Name: match_suggestions Participants can view their suggestions; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Participants can view their suggestions" ON public.match_suggestions FOR SELECT USING (((user_a_fid = (((current_setting('request.jwt.claims'::text, true))::json ->> 'fid'::text))::bigint) OR (user_b_fid = (((current_setting('request.jwt.claims'::text, true))::json ->> 'fid'::text))::bigint)));


--
-- Name: user_wallets Service can insert wallets; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Service can insert wallets" ON public.user_wallets FOR INSERT WITH CHECK (true);


--
-- Name: user_wallets Service can update wallets; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Service can update wallets" ON public.user_wallets FOR UPDATE USING (true);


--
-- Name: chat_rooms Service role can manage chat rooms; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Service role can manage chat rooms" ON public.chat_rooms USING ((((current_setting('request.jwt.claims'::text, true))::json ->> 'role'::text) = 'service_role'::text)) WITH CHECK ((((current_setting('request.jwt.claims'::text, true))::json ->> 'role'::text) = 'service_role'::text));


--
-- Name: chat_messages Service role can manage messages; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Service role can manage messages" ON public.chat_messages USING ((((current_setting('request.jwt.claims'::text, true))::json ->> 'role'::text) = 'service_role'::text)) WITH CHECK ((((current_setting('request.jwt.claims'::text, true))::json ->> 'role'::text) = 'service_role'::text));


--
-- Name: chat_participants Service role can manage participants; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Service role can manage participants" ON public.chat_participants USING ((((current_setting('request.jwt.claims'::text, true))::json ->> 'role'::text) = 'service_role'::text)) WITH CHECK ((((current_setting('request.jwt.claims'::text, true))::json ->> 'role'::text) = 'service_role'::text));


--
-- Name: match_suggestions Users can create match suggestions; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can create match suggestions" ON public.match_suggestions FOR INSERT WITH CHECK (((created_by_fid = (((current_setting('request.jwt.claims'::text, true))::json ->> 'fid'::text))::bigint) AND (user_a_fid <> created_by_fid) AND (user_b_fid <> created_by_fid) AND (user_a_fid <> user_b_fid)));


--
-- Name: matches Users can create matches; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can create matches" ON public.matches FOR INSERT TO authenticated WITH CHECK ((created_by_fid = (((current_setting('request.jwt.claims'::text, true))::json ->> 'fid'::text))::bigint));


--
-- Name: attestations Users can create own attestations; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can create own attestations" ON public.attestations FOR INSERT WITH CHECK ((fid IN ( SELECT users.fid
   FROM public.users
  WHERE (users.fid = (current_setting('app.current_user_fid'::text, true))::bigint))));


--
-- Name: attestations Users can delete own attestations; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can delete own attestations" ON public.attestations FOR DELETE USING ((fid IN ( SELECT users.fid
   FROM public.users
  WHERE (users.fid = (current_setting('app.current_user_fid'::text, true))::bigint))));


--
-- Name: users Users can read all profiles; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can read all profiles" ON public.users FOR SELECT USING (true);


--
-- Name: attestations Users can read own attestations; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can read own attestations" ON public.attestations FOR SELECT USING ((fid IN ( SELECT users.fid
   FROM public.users
  WHERE (users.fid = (current_setting('app.current_user_fid'::text, true))::bigint))));


--
-- Name: chat_messages Users can send messages in open rooms; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can send messages in open rooms" ON public.chat_messages FOR INSERT WITH CHECK (((sender_fid = (((current_setting('request.jwt.claims'::text, true))::json ->> 'fid'::text))::bigint) AND (EXISTS ( SELECT 1
   FROM public.chat_participants
  WHERE ((chat_participants.room_id = chat_messages.room_id) AND (chat_participants.fid = (((current_setting('request.jwt.claims'::text, true))::json ->> 'fid'::text))::bigint)))) AND (EXISTS ( SELECT 1
   FROM public.chat_rooms
  WHERE ((chat_rooms.id = chat_messages.room_id) AND (chat_rooms.is_closed = false) AND ((chat_rooms.first_join_at IS NULL) OR (now() <= (chat_rooms.first_join_at + ((chat_rooms.ttl_seconds || ' seconds'::text))::interval))))))));


--
-- Name: attestations Users can update own attestations; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can update own attestations" ON public.attestations FOR UPDATE USING ((fid IN ( SELECT users.fid
   FROM public.users
  WHERE (users.fid = (current_setting('app.current_user_fid'::text, true))::bigint))));


--
-- Name: matches Users can update their matches; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can update their matches" ON public.matches FOR UPDATE TO authenticated USING (((user_a_fid = (((current_setting('request.jwt.claims'::text, true))::json ->> 'fid'::text))::bigint) OR (user_b_fid = (((current_setting('request.jwt.claims'::text, true))::json ->> 'fid'::text))::bigint)));


--
-- Name: chat_messages Users can view messages in their rooms; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can view messages in their rooms" ON public.chat_messages FOR SELECT USING ((EXISTS ( SELECT 1
   FROM public.chat_participants
  WHERE ((chat_participants.room_id = chat_messages.room_id) AND (chat_participants.fid = (((current_setting('request.jwt.claims'::text, true))::json ->> 'fid'::text))::bigint)))));


--
-- Name: chat_participants Users can view participants in their rooms; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can view participants in their rooms" ON public.chat_participants FOR SELECT USING (((fid = (((current_setting('request.jwt.claims'::text, true))::json ->> 'fid'::text))::bigint) OR (EXISTS ( SELECT 1
   FROM public.chat_participants cp
  WHERE ((cp.room_id = chat_participants.room_id) AND (cp.fid = (((current_setting('request.jwt.claims'::text, true))::json ->> 'fid'::text))::bigint))))));


--
-- Name: match_suggestion_cooldowns Users can view relevant cooldowns; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can view relevant cooldowns" ON public.match_suggestion_cooldowns FOR SELECT USING (((user_a_fid = (((current_setting('request.jwt.claims'::text, true))::json ->> 'fid'::text))::bigint) OR (user_b_fid = (((current_setting('request.jwt.claims'::text, true))::json ->> 'fid'::text))::bigint)));


--
-- Name: chat_rooms Users can view their chat rooms; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can view their chat rooms" ON public.chat_rooms FOR SELECT USING ((EXISTS ( SELECT 1
   FROM public.chat_participants
  WHERE ((chat_participants.room_id = chat_rooms.id) AND (chat_participants.fid = (((current_setting('request.jwt.claims'::text, true))::json ->> 'fid'::text))::bigint)))));


--
-- Name: matches Users can view their matches; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can view their matches" ON public.matches FOR SELECT TO authenticated USING (((user_a_fid = (((current_setting('request.jwt.claims'::text, true))::json ->> 'fid'::text))::bigint) OR (user_b_fid = (((current_setting('request.jwt.claims'::text, true))::json ->> 'fid'::text))::bigint) OR (created_by_fid = (((current_setting('request.jwt.claims'::text, true))::json ->> 'fid'::text))::bigint)));


--
-- Name: user_wallets Users can view wallets; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can view wallets" ON public.user_wallets FOR SELECT USING (true);


--
-- Name: attestations; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.attestations ENABLE ROW LEVEL SECURITY;

--
-- Name: chat_messages; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;

--
-- Name: chat_participants; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.chat_participants ENABLE ROW LEVEL SECURITY;

--
-- Name: chat_rooms; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.chat_rooms ENABLE ROW LEVEL SECURITY;

--
-- Name: users insert users via service role; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "insert users via service role" ON public.users FOR INSERT TO authenticated, anon WITH CHECK ((auth.role() = 'service_role'::text));


--
-- Name: match_suggestion_cooldowns; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.match_suggestion_cooldowns ENABLE ROW LEVEL SECURITY;

--
-- Name: match_suggestions; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.match_suggestions ENABLE ROW LEVEL SECURITY;

--
-- Name: users public read users; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "public read users" ON public.users FOR SELECT TO authenticated, anon USING (true);


--
-- Name: users self read users; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "self read users" ON public.users FOR SELECT TO authenticated USING ((fid = (((current_setting('request.jwt.claims'::text, true))::json ->> 'fid'::text))::bigint));


--
-- Name: user_achievements; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.user_achievements ENABLE ROW LEVEL SECURITY;

--
-- Name: user_achievements user_achievements_select_own; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY user_achievements_select_own ON public.user_achievements FOR SELECT USING ((user_fid = (((current_setting('request.jwt.claims'::text, true))::json ->> 'fid'::text))::bigint));


--
-- Name: user_achievements user_achievements_service_all; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY user_achievements_service_all ON public.user_achievements USING (true) WITH CHECK (true);


--
-- Name: user_levels; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.user_levels ENABLE ROW LEVEL SECURITY;

--
-- Name: user_levels user_levels_select_own; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY user_levels_select_own ON public.user_levels FOR SELECT USING ((user_fid = (((current_setting('request.jwt.claims'::text, true))::json ->> 'fid'::text))::bigint));


--
-- Name: user_levels user_levels_service_all; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY user_levels_service_all ON public.user_levels USING (true) WITH CHECK (true);


--
-- Name: user_wallets; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.user_wallets ENABLE ROW LEVEL SECURITY;

--
-- Name: users; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

--
-- Name: messages; Type: ROW SECURITY; Schema: realtime; Owner: supabase_realtime_admin
--

ALTER TABLE realtime.messages ENABLE ROW LEVEL SECURITY;

--
-- Name: buckets; Type: ROW SECURITY; Schema: storage; Owner: supabase_storage_admin
--

ALTER TABLE storage.buckets ENABLE ROW LEVEL SECURITY;

--
-- Name: buckets_analytics; Type: ROW SECURITY; Schema: storage; Owner: supabase_storage_admin
--

ALTER TABLE storage.buckets_analytics ENABLE ROW LEVEL SECURITY;

--
-- Name: migrations; Type: ROW SECURITY; Schema: storage; Owner: supabase_storage_admin
--

ALTER TABLE storage.migrations ENABLE ROW LEVEL SECURITY;

--
-- Name: objects; Type: ROW SECURITY; Schema: storage; Owner: supabase_storage_admin
--

ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

--
-- Name: prefixes; Type: ROW SECURITY; Schema: storage; Owner: supabase_storage_admin
--

ALTER TABLE storage.prefixes ENABLE ROW LEVEL SECURITY;

--
-- Name: s3_multipart_uploads; Type: ROW SECURITY; Schema: storage; Owner: supabase_storage_admin
--

ALTER TABLE storage.s3_multipart_uploads ENABLE ROW LEVEL SECURITY;

--
-- Name: s3_multipart_uploads_parts; Type: ROW SECURITY; Schema: storage; Owner: supabase_storage_admin
--

ALTER TABLE storage.s3_multipart_uploads_parts ENABLE ROW LEVEL SECURITY;

--
-- Name: supabase_realtime; Type: PUBLICATION; Schema: -; Owner: postgres
--

CREATE PUBLICATION supabase_realtime WITH (publish = 'insert, update, delete, truncate');


ALTER PUBLICATION supabase_realtime OWNER TO postgres;

--
-- Name: supabase_realtime_messages_publication; Type: PUBLICATION; Schema: -; Owner: supabase_admin
--

CREATE PUBLICATION supabase_realtime_messages_publication WITH (publish = 'insert, update, delete, truncate');


ALTER PUBLICATION supabase_realtime_messages_publication OWNER TO supabase_admin;

--
-- Name: supabase_realtime chat_messages; Type: PUBLICATION TABLE; Schema: public; Owner: postgres
--

ALTER PUBLICATION supabase_realtime ADD TABLE ONLY public.chat_messages;


--
-- Name: supabase_realtime_messages_publication messages; Type: PUBLICATION TABLE; Schema: realtime; Owner: supabase_admin
--

ALTER PUBLICATION supabase_realtime_messages_publication ADD TABLE ONLY realtime.messages;


--
-- Name: SCHEMA auth; Type: ACL; Schema: -; Owner: supabase_admin
--

GRANT USAGE ON SCHEMA auth TO anon;
GRANT USAGE ON SCHEMA auth TO authenticated;
GRANT USAGE ON SCHEMA auth TO service_role;
GRANT ALL ON SCHEMA auth TO supabase_auth_admin;
GRANT ALL ON SCHEMA auth TO dashboard_user;
GRANT USAGE ON SCHEMA auth TO postgres;


--
-- Name: SCHEMA cron; Type: ACL; Schema: -; Owner: supabase_admin
--

GRANT USAGE ON SCHEMA cron TO postgres WITH GRANT OPTION;


--
-- Name: SCHEMA extensions; Type: ACL; Schema: -; Owner: postgres
--

GRANT USAGE ON SCHEMA extensions TO anon;
GRANT USAGE ON SCHEMA extensions TO authenticated;
GRANT USAGE ON SCHEMA extensions TO service_role;
GRANT ALL ON SCHEMA extensions TO dashboard_user;


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: pg_database_owner
--

GRANT USAGE ON SCHEMA public TO postgres;
GRANT USAGE ON SCHEMA public TO anon;
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT USAGE ON SCHEMA public TO service_role;


--
-- Name: SCHEMA realtime; Type: ACL; Schema: -; Owner: supabase_admin
--

GRANT USAGE ON SCHEMA realtime TO postgres;
GRANT USAGE ON SCHEMA realtime TO anon;
GRANT USAGE ON SCHEMA realtime TO authenticated;
GRANT USAGE ON SCHEMA realtime TO service_role;
GRANT ALL ON SCHEMA realtime TO supabase_realtime_admin;


--
-- Name: SCHEMA storage; Type: ACL; Schema: -; Owner: supabase_admin
--

GRANT USAGE ON SCHEMA storage TO postgres WITH GRANT OPTION;
GRANT USAGE ON SCHEMA storage TO anon;
GRANT USAGE ON SCHEMA storage TO authenticated;
GRANT USAGE ON SCHEMA storage TO service_role;
GRANT ALL ON SCHEMA storage TO supabase_storage_admin;
GRANT ALL ON SCHEMA storage TO dashboard_user;


--
-- Name: SCHEMA vault; Type: ACL; Schema: -; Owner: supabase_admin
--

GRANT USAGE ON SCHEMA vault TO postgres WITH GRANT OPTION;
GRANT USAGE ON SCHEMA vault TO service_role;


--
-- Name: FUNCTION gtrgm_in(cstring); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.gtrgm_in(cstring) TO postgres;
GRANT ALL ON FUNCTION public.gtrgm_in(cstring) TO anon;
GRANT ALL ON FUNCTION public.gtrgm_in(cstring) TO authenticated;
GRANT ALL ON FUNCTION public.gtrgm_in(cstring) TO service_role;


--
-- Name: FUNCTION gtrgm_out(public.gtrgm); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.gtrgm_out(public.gtrgm) TO postgres;
GRANT ALL ON FUNCTION public.gtrgm_out(public.gtrgm) TO anon;
GRANT ALL ON FUNCTION public.gtrgm_out(public.gtrgm) TO authenticated;
GRANT ALL ON FUNCTION public.gtrgm_out(public.gtrgm) TO service_role;


--
-- Name: FUNCTION email(); Type: ACL; Schema: auth; Owner: supabase_auth_admin
--

GRANT ALL ON FUNCTION auth.email() TO dashboard_user;


--
-- Name: FUNCTION jwt(); Type: ACL; Schema: auth; Owner: supabase_auth_admin
--

GRANT ALL ON FUNCTION auth.jwt() TO postgres;
GRANT ALL ON FUNCTION auth.jwt() TO dashboard_user;


--
-- Name: FUNCTION role(); Type: ACL; Schema: auth; Owner: supabase_auth_admin
--

GRANT ALL ON FUNCTION auth.role() TO dashboard_user;


--
-- Name: FUNCTION uid(); Type: ACL; Schema: auth; Owner: supabase_auth_admin
--

GRANT ALL ON FUNCTION auth.uid() TO dashboard_user;


--
-- Name: FUNCTION alter_job(job_id bigint, schedule text, command text, database text, username text, active boolean); Type: ACL; Schema: cron; Owner: supabase_admin
--

GRANT ALL ON FUNCTION cron.alter_job(job_id bigint, schedule text, command text, database text, username text, active boolean) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION job_cache_invalidate(); Type: ACL; Schema: cron; Owner: supabase_admin
--

GRANT ALL ON FUNCTION cron.job_cache_invalidate() TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION schedule(schedule text, command text); Type: ACL; Schema: cron; Owner: supabase_admin
--

GRANT ALL ON FUNCTION cron.schedule(schedule text, command text) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION schedule(job_name text, schedule text, command text); Type: ACL; Schema: cron; Owner: supabase_admin
--

GRANT ALL ON FUNCTION cron.schedule(job_name text, schedule text, command text) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION schedule_in_database(job_name text, schedule text, command text, database text, username text, active boolean); Type: ACL; Schema: cron; Owner: supabase_admin
--

GRANT ALL ON FUNCTION cron.schedule_in_database(job_name text, schedule text, command text, database text, username text, active boolean) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION unschedule(job_id bigint); Type: ACL; Schema: cron; Owner: supabase_admin
--

GRANT ALL ON FUNCTION cron.unschedule(job_id bigint) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION unschedule(job_name text); Type: ACL; Schema: cron; Owner: supabase_admin
--

GRANT ALL ON FUNCTION cron.unschedule(job_name text) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION armor(bytea); Type: ACL; Schema: extensions; Owner: postgres
--

REVOKE ALL ON FUNCTION extensions.armor(bytea) FROM postgres;
GRANT ALL ON FUNCTION extensions.armor(bytea) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.armor(bytea) TO dashboard_user;


--
-- Name: FUNCTION armor(bytea, text[], text[]); Type: ACL; Schema: extensions; Owner: postgres
--

REVOKE ALL ON FUNCTION extensions.armor(bytea, text[], text[]) FROM postgres;
GRANT ALL ON FUNCTION extensions.armor(bytea, text[], text[]) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.armor(bytea, text[], text[]) TO dashboard_user;


--
-- Name: FUNCTION crypt(text, text); Type: ACL; Schema: extensions; Owner: postgres
--

REVOKE ALL ON FUNCTION extensions.crypt(text, text) FROM postgres;
GRANT ALL ON FUNCTION extensions.crypt(text, text) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.crypt(text, text) TO dashboard_user;


--
-- Name: FUNCTION dearmor(text); Type: ACL; Schema: extensions; Owner: postgres
--

REVOKE ALL ON FUNCTION extensions.dearmor(text) FROM postgres;
GRANT ALL ON FUNCTION extensions.dearmor(text) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.dearmor(text) TO dashboard_user;


--
-- Name: FUNCTION decrypt(bytea, bytea, text); Type: ACL; Schema: extensions; Owner: postgres
--

REVOKE ALL ON FUNCTION extensions.decrypt(bytea, bytea, text) FROM postgres;
GRANT ALL ON FUNCTION extensions.decrypt(bytea, bytea, text) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.decrypt(bytea, bytea, text) TO dashboard_user;


--
-- Name: FUNCTION decrypt_iv(bytea, bytea, bytea, text); Type: ACL; Schema: extensions; Owner: postgres
--

REVOKE ALL ON FUNCTION extensions.decrypt_iv(bytea, bytea, bytea, text) FROM postgres;
GRANT ALL ON FUNCTION extensions.decrypt_iv(bytea, bytea, bytea, text) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.decrypt_iv(bytea, bytea, bytea, text) TO dashboard_user;


--
-- Name: FUNCTION digest(bytea, text); Type: ACL; Schema: extensions; Owner: postgres
--

REVOKE ALL ON FUNCTION extensions.digest(bytea, text) FROM postgres;
GRANT ALL ON FUNCTION extensions.digest(bytea, text) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.digest(bytea, text) TO dashboard_user;


--
-- Name: FUNCTION digest(text, text); Type: ACL; Schema: extensions; Owner: postgres
--

REVOKE ALL ON FUNCTION extensions.digest(text, text) FROM postgres;
GRANT ALL ON FUNCTION extensions.digest(text, text) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.digest(text, text) TO dashboard_user;


--
-- Name: FUNCTION encrypt(bytea, bytea, text); Type: ACL; Schema: extensions; Owner: postgres
--

REVOKE ALL ON FUNCTION extensions.encrypt(bytea, bytea, text) FROM postgres;
GRANT ALL ON FUNCTION extensions.encrypt(bytea, bytea, text) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.encrypt(bytea, bytea, text) TO dashboard_user;


--
-- Name: FUNCTION encrypt_iv(bytea, bytea, bytea, text); Type: ACL; Schema: extensions; Owner: postgres
--

REVOKE ALL ON FUNCTION extensions.encrypt_iv(bytea, bytea, bytea, text) FROM postgres;
GRANT ALL ON FUNCTION extensions.encrypt_iv(bytea, bytea, bytea, text) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.encrypt_iv(bytea, bytea, bytea, text) TO dashboard_user;


--
-- Name: FUNCTION gen_random_bytes(integer); Type: ACL; Schema: extensions; Owner: postgres
--

REVOKE ALL ON FUNCTION extensions.gen_random_bytes(integer) FROM postgres;
GRANT ALL ON FUNCTION extensions.gen_random_bytes(integer) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.gen_random_bytes(integer) TO dashboard_user;


--
-- Name: FUNCTION gen_random_uuid(); Type: ACL; Schema: extensions; Owner: postgres
--

REVOKE ALL ON FUNCTION extensions.gen_random_uuid() FROM postgres;
GRANT ALL ON FUNCTION extensions.gen_random_uuid() TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.gen_random_uuid() TO dashboard_user;


--
-- Name: FUNCTION gen_salt(text); Type: ACL; Schema: extensions; Owner: postgres
--

REVOKE ALL ON FUNCTION extensions.gen_salt(text) FROM postgres;
GRANT ALL ON FUNCTION extensions.gen_salt(text) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.gen_salt(text) TO dashboard_user;


--
-- Name: FUNCTION gen_salt(text, integer); Type: ACL; Schema: extensions; Owner: postgres
--

REVOKE ALL ON FUNCTION extensions.gen_salt(text, integer) FROM postgres;
GRANT ALL ON FUNCTION extensions.gen_salt(text, integer) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.gen_salt(text, integer) TO dashboard_user;


--
-- Name: FUNCTION grant_pg_cron_access(); Type: ACL; Schema: extensions; Owner: supabase_admin
--

REVOKE ALL ON FUNCTION extensions.grant_pg_cron_access() FROM supabase_admin;
GRANT ALL ON FUNCTION extensions.grant_pg_cron_access() TO supabase_admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.grant_pg_cron_access() TO dashboard_user;


--
-- Name: FUNCTION grant_pg_graphql_access(); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.grant_pg_graphql_access() TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION grant_pg_net_access(); Type: ACL; Schema: extensions; Owner: supabase_admin
--

REVOKE ALL ON FUNCTION extensions.grant_pg_net_access() FROM supabase_admin;
GRANT ALL ON FUNCTION extensions.grant_pg_net_access() TO supabase_admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.grant_pg_net_access() TO dashboard_user;


--
-- Name: FUNCTION hmac(bytea, bytea, text); Type: ACL; Schema: extensions; Owner: postgres
--

REVOKE ALL ON FUNCTION extensions.hmac(bytea, bytea, text) FROM postgres;
GRANT ALL ON FUNCTION extensions.hmac(bytea, bytea, text) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.hmac(bytea, bytea, text) TO dashboard_user;


--
-- Name: FUNCTION hmac(text, text, text); Type: ACL; Schema: extensions; Owner: postgres
--

REVOKE ALL ON FUNCTION extensions.hmac(text, text, text) FROM postgres;
GRANT ALL ON FUNCTION extensions.hmac(text, text, text) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.hmac(text, text, text) TO dashboard_user;


--
-- Name: FUNCTION pg_stat_statements(showtext boolean, OUT userid oid, OUT dbid oid, OUT toplevel boolean, OUT queryid bigint, OUT query text, OUT plans bigint, OUT total_plan_time double precision, OUT min_plan_time double precision, OUT max_plan_time double precision, OUT mean_plan_time double precision, OUT stddev_plan_time double precision, OUT calls bigint, OUT total_exec_time double precision, OUT min_exec_time double precision, OUT max_exec_time double precision, OUT mean_exec_time double precision, OUT stddev_exec_time double precision, OUT rows bigint, OUT shared_blks_hit bigint, OUT shared_blks_read bigint, OUT shared_blks_dirtied bigint, OUT shared_blks_written bigint, OUT local_blks_hit bigint, OUT local_blks_read bigint, OUT local_blks_dirtied bigint, OUT local_blks_written bigint, OUT temp_blks_read bigint, OUT temp_blks_written bigint, OUT shared_blk_read_time double precision, OUT shared_blk_write_time double precision, OUT local_blk_read_time double precision, OUT local_blk_write_time double precision, OUT temp_blk_read_time double precision, OUT temp_blk_write_time double precision, OUT wal_records bigint, OUT wal_fpi bigint, OUT wal_bytes numeric, OUT jit_functions bigint, OUT jit_generation_time double precision, OUT jit_inlining_count bigint, OUT jit_inlining_time double precision, OUT jit_optimization_count bigint, OUT jit_optimization_time double precision, OUT jit_emission_count bigint, OUT jit_emission_time double precision, OUT jit_deform_count bigint, OUT jit_deform_time double precision, OUT stats_since timestamp with time zone, OUT minmax_stats_since timestamp with time zone); Type: ACL; Schema: extensions; Owner: postgres
--

REVOKE ALL ON FUNCTION extensions.pg_stat_statements(showtext boolean, OUT userid oid, OUT dbid oid, OUT toplevel boolean, OUT queryid bigint, OUT query text, OUT plans bigint, OUT total_plan_time double precision, OUT min_plan_time double precision, OUT max_plan_time double precision, OUT mean_plan_time double precision, OUT stddev_plan_time double precision, OUT calls bigint, OUT total_exec_time double precision, OUT min_exec_time double precision, OUT max_exec_time double precision, OUT mean_exec_time double precision, OUT stddev_exec_time double precision, OUT rows bigint, OUT shared_blks_hit bigint, OUT shared_blks_read bigint, OUT shared_blks_dirtied bigint, OUT shared_blks_written bigint, OUT local_blks_hit bigint, OUT local_blks_read bigint, OUT local_blks_dirtied bigint, OUT local_blks_written bigint, OUT temp_blks_read bigint, OUT temp_blks_written bigint, OUT shared_blk_read_time double precision, OUT shared_blk_write_time double precision, OUT local_blk_read_time double precision, OUT local_blk_write_time double precision, OUT temp_blk_read_time double precision, OUT temp_blk_write_time double precision, OUT wal_records bigint, OUT wal_fpi bigint, OUT wal_bytes numeric, OUT jit_functions bigint, OUT jit_generation_time double precision, OUT jit_inlining_count bigint, OUT jit_inlining_time double precision, OUT jit_optimization_count bigint, OUT jit_optimization_time double precision, OUT jit_emission_count bigint, OUT jit_emission_time double precision, OUT jit_deform_count bigint, OUT jit_deform_time double precision, OUT stats_since timestamp with time zone, OUT minmax_stats_since timestamp with time zone) FROM postgres;
GRANT ALL ON FUNCTION extensions.pg_stat_statements(showtext boolean, OUT userid oid, OUT dbid oid, OUT toplevel boolean, OUT queryid bigint, OUT query text, OUT plans bigint, OUT total_plan_time double precision, OUT min_plan_time double precision, OUT max_plan_time double precision, OUT mean_plan_time double precision, OUT stddev_plan_time double precision, OUT calls bigint, OUT total_exec_time double precision, OUT min_exec_time double precision, OUT max_exec_time double precision, OUT mean_exec_time double precision, OUT stddev_exec_time double precision, OUT rows bigint, OUT shared_blks_hit bigint, OUT shared_blks_read bigint, OUT shared_blks_dirtied bigint, OUT shared_blks_written bigint, OUT local_blks_hit bigint, OUT local_blks_read bigint, OUT local_blks_dirtied bigint, OUT local_blks_written bigint, OUT temp_blks_read bigint, OUT temp_blks_written bigint, OUT shared_blk_read_time double precision, OUT shared_blk_write_time double precision, OUT local_blk_read_time double precision, OUT local_blk_write_time double precision, OUT temp_blk_read_time double precision, OUT temp_blk_write_time double precision, OUT wal_records bigint, OUT wal_fpi bigint, OUT wal_bytes numeric, OUT jit_functions bigint, OUT jit_generation_time double precision, OUT jit_inlining_count bigint, OUT jit_inlining_time double precision, OUT jit_optimization_count bigint, OUT jit_optimization_time double precision, OUT jit_emission_count bigint, OUT jit_emission_time double precision, OUT jit_deform_count bigint, OUT jit_deform_time double precision, OUT stats_since timestamp with time zone, OUT minmax_stats_since timestamp with time zone) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.pg_stat_statements(showtext boolean, OUT userid oid, OUT dbid oid, OUT toplevel boolean, OUT queryid bigint, OUT query text, OUT plans bigint, OUT total_plan_time double precision, OUT min_plan_time double precision, OUT max_plan_time double precision, OUT mean_plan_time double precision, OUT stddev_plan_time double precision, OUT calls bigint, OUT total_exec_time double precision, OUT min_exec_time double precision, OUT max_exec_time double precision, OUT mean_exec_time double precision, OUT stddev_exec_time double precision, OUT rows bigint, OUT shared_blks_hit bigint, OUT shared_blks_read bigint, OUT shared_blks_dirtied bigint, OUT shared_blks_written bigint, OUT local_blks_hit bigint, OUT local_blks_read bigint, OUT local_blks_dirtied bigint, OUT local_blks_written bigint, OUT temp_blks_read bigint, OUT temp_blks_written bigint, OUT shared_blk_read_time double precision, OUT shared_blk_write_time double precision, OUT local_blk_read_time double precision, OUT local_blk_write_time double precision, OUT temp_blk_read_time double precision, OUT temp_blk_write_time double precision, OUT wal_records bigint, OUT wal_fpi bigint, OUT wal_bytes numeric, OUT jit_functions bigint, OUT jit_generation_time double precision, OUT jit_inlining_count bigint, OUT jit_inlining_time double precision, OUT jit_optimization_count bigint, OUT jit_optimization_time double precision, OUT jit_emission_count bigint, OUT jit_emission_time double precision, OUT jit_deform_count bigint, OUT jit_deform_time double precision, OUT stats_since timestamp with time zone, OUT minmax_stats_since timestamp with time zone) TO dashboard_user;


--
-- Name: FUNCTION pg_stat_statements_info(OUT dealloc bigint, OUT stats_reset timestamp with time zone); Type: ACL; Schema: extensions; Owner: postgres
--

REVOKE ALL ON FUNCTION extensions.pg_stat_statements_info(OUT dealloc bigint, OUT stats_reset timestamp with time zone) FROM postgres;
GRANT ALL ON FUNCTION extensions.pg_stat_statements_info(OUT dealloc bigint, OUT stats_reset timestamp with time zone) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.pg_stat_statements_info(OUT dealloc bigint, OUT stats_reset timestamp with time zone) TO dashboard_user;


--
-- Name: FUNCTION pg_stat_statements_reset(userid oid, dbid oid, queryid bigint, minmax_only boolean); Type: ACL; Schema: extensions; Owner: postgres
--

REVOKE ALL ON FUNCTION extensions.pg_stat_statements_reset(userid oid, dbid oid, queryid bigint, minmax_only boolean) FROM postgres;
GRANT ALL ON FUNCTION extensions.pg_stat_statements_reset(userid oid, dbid oid, queryid bigint, minmax_only boolean) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.pg_stat_statements_reset(userid oid, dbid oid, queryid bigint, minmax_only boolean) TO dashboard_user;


--
-- Name: FUNCTION pgp_armor_headers(text, OUT key text, OUT value text); Type: ACL; Schema: extensions; Owner: postgres
--

REVOKE ALL ON FUNCTION extensions.pgp_armor_headers(text, OUT key text, OUT value text) FROM postgres;
GRANT ALL ON FUNCTION extensions.pgp_armor_headers(text, OUT key text, OUT value text) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.pgp_armor_headers(text, OUT key text, OUT value text) TO dashboard_user;


--
-- Name: FUNCTION pgp_key_id(bytea); Type: ACL; Schema: extensions; Owner: postgres
--

REVOKE ALL ON FUNCTION extensions.pgp_key_id(bytea) FROM postgres;
GRANT ALL ON FUNCTION extensions.pgp_key_id(bytea) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.pgp_key_id(bytea) TO dashboard_user;


--
-- Name: FUNCTION pgp_pub_decrypt(bytea, bytea); Type: ACL; Schema: extensions; Owner: postgres
--

REVOKE ALL ON FUNCTION extensions.pgp_pub_decrypt(bytea, bytea) FROM postgres;
GRANT ALL ON FUNCTION extensions.pgp_pub_decrypt(bytea, bytea) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.pgp_pub_decrypt(bytea, bytea) TO dashboard_user;


--
-- Name: FUNCTION pgp_pub_decrypt(bytea, bytea, text); Type: ACL; Schema: extensions; Owner: postgres
--

REVOKE ALL ON FUNCTION extensions.pgp_pub_decrypt(bytea, bytea, text) FROM postgres;
GRANT ALL ON FUNCTION extensions.pgp_pub_decrypt(bytea, bytea, text) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.pgp_pub_decrypt(bytea, bytea, text) TO dashboard_user;


--
-- Name: FUNCTION pgp_pub_decrypt(bytea, bytea, text, text); Type: ACL; Schema: extensions; Owner: postgres
--

REVOKE ALL ON FUNCTION extensions.pgp_pub_decrypt(bytea, bytea, text, text) FROM postgres;
GRANT ALL ON FUNCTION extensions.pgp_pub_decrypt(bytea, bytea, text, text) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.pgp_pub_decrypt(bytea, bytea, text, text) TO dashboard_user;


--
-- Name: FUNCTION pgp_pub_decrypt_bytea(bytea, bytea); Type: ACL; Schema: extensions; Owner: postgres
--

REVOKE ALL ON FUNCTION extensions.pgp_pub_decrypt_bytea(bytea, bytea) FROM postgres;
GRANT ALL ON FUNCTION extensions.pgp_pub_decrypt_bytea(bytea, bytea) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.pgp_pub_decrypt_bytea(bytea, bytea) TO dashboard_user;


--
-- Name: FUNCTION pgp_pub_decrypt_bytea(bytea, bytea, text); Type: ACL; Schema: extensions; Owner: postgres
--

REVOKE ALL ON FUNCTION extensions.pgp_pub_decrypt_bytea(bytea, bytea, text) FROM postgres;
GRANT ALL ON FUNCTION extensions.pgp_pub_decrypt_bytea(bytea, bytea, text) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.pgp_pub_decrypt_bytea(bytea, bytea, text) TO dashboard_user;


--
-- Name: FUNCTION pgp_pub_decrypt_bytea(bytea, bytea, text, text); Type: ACL; Schema: extensions; Owner: postgres
--

REVOKE ALL ON FUNCTION extensions.pgp_pub_decrypt_bytea(bytea, bytea, text, text) FROM postgres;
GRANT ALL ON FUNCTION extensions.pgp_pub_decrypt_bytea(bytea, bytea, text, text) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.pgp_pub_decrypt_bytea(bytea, bytea, text, text) TO dashboard_user;


--
-- Name: FUNCTION pgp_pub_encrypt(text, bytea); Type: ACL; Schema: extensions; Owner: postgres
--

REVOKE ALL ON FUNCTION extensions.pgp_pub_encrypt(text, bytea) FROM postgres;
GRANT ALL ON FUNCTION extensions.pgp_pub_encrypt(text, bytea) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.pgp_pub_encrypt(text, bytea) TO dashboard_user;


--
-- Name: FUNCTION pgp_pub_encrypt(text, bytea, text); Type: ACL; Schema: extensions; Owner: postgres
--

REVOKE ALL ON FUNCTION extensions.pgp_pub_encrypt(text, bytea, text) FROM postgres;
GRANT ALL ON FUNCTION extensions.pgp_pub_encrypt(text, bytea, text) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.pgp_pub_encrypt(text, bytea, text) TO dashboard_user;


--
-- Name: FUNCTION pgp_pub_encrypt_bytea(bytea, bytea); Type: ACL; Schema: extensions; Owner: postgres
--

REVOKE ALL ON FUNCTION extensions.pgp_pub_encrypt_bytea(bytea, bytea) FROM postgres;
GRANT ALL ON FUNCTION extensions.pgp_pub_encrypt_bytea(bytea, bytea) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.pgp_pub_encrypt_bytea(bytea, bytea) TO dashboard_user;


--
-- Name: FUNCTION pgp_pub_encrypt_bytea(bytea, bytea, text); Type: ACL; Schema: extensions; Owner: postgres
--

REVOKE ALL ON FUNCTION extensions.pgp_pub_encrypt_bytea(bytea, bytea, text) FROM postgres;
GRANT ALL ON FUNCTION extensions.pgp_pub_encrypt_bytea(bytea, bytea, text) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.pgp_pub_encrypt_bytea(bytea, bytea, text) TO dashboard_user;


--
-- Name: FUNCTION pgp_sym_decrypt(bytea, text); Type: ACL; Schema: extensions; Owner: postgres
--

REVOKE ALL ON FUNCTION extensions.pgp_sym_decrypt(bytea, text) FROM postgres;
GRANT ALL ON FUNCTION extensions.pgp_sym_decrypt(bytea, text) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.pgp_sym_decrypt(bytea, text) TO dashboard_user;


--
-- Name: FUNCTION pgp_sym_decrypt(bytea, text, text); Type: ACL; Schema: extensions; Owner: postgres
--

REVOKE ALL ON FUNCTION extensions.pgp_sym_decrypt(bytea, text, text) FROM postgres;
GRANT ALL ON FUNCTION extensions.pgp_sym_decrypt(bytea, text, text) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.pgp_sym_decrypt(bytea, text, text) TO dashboard_user;


--
-- Name: FUNCTION pgp_sym_decrypt_bytea(bytea, text); Type: ACL; Schema: extensions; Owner: postgres
--

REVOKE ALL ON FUNCTION extensions.pgp_sym_decrypt_bytea(bytea, text) FROM postgres;
GRANT ALL ON FUNCTION extensions.pgp_sym_decrypt_bytea(bytea, text) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.pgp_sym_decrypt_bytea(bytea, text) TO dashboard_user;


--
-- Name: FUNCTION pgp_sym_decrypt_bytea(bytea, text, text); Type: ACL; Schema: extensions; Owner: postgres
--

REVOKE ALL ON FUNCTION extensions.pgp_sym_decrypt_bytea(bytea, text, text) FROM postgres;
GRANT ALL ON FUNCTION extensions.pgp_sym_decrypt_bytea(bytea, text, text) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.pgp_sym_decrypt_bytea(bytea, text, text) TO dashboard_user;


--
-- Name: FUNCTION pgp_sym_encrypt(text, text); Type: ACL; Schema: extensions; Owner: postgres
--

REVOKE ALL ON FUNCTION extensions.pgp_sym_encrypt(text, text) FROM postgres;
GRANT ALL ON FUNCTION extensions.pgp_sym_encrypt(text, text) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.pgp_sym_encrypt(text, text) TO dashboard_user;


--
-- Name: FUNCTION pgp_sym_encrypt(text, text, text); Type: ACL; Schema: extensions; Owner: postgres
--

REVOKE ALL ON FUNCTION extensions.pgp_sym_encrypt(text, text, text) FROM postgres;
GRANT ALL ON FUNCTION extensions.pgp_sym_encrypt(text, text, text) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.pgp_sym_encrypt(text, text, text) TO dashboard_user;


--
-- Name: FUNCTION pgp_sym_encrypt_bytea(bytea, text); Type: ACL; Schema: extensions; Owner: postgres
--

REVOKE ALL ON FUNCTION extensions.pgp_sym_encrypt_bytea(bytea, text) FROM postgres;
GRANT ALL ON FUNCTION extensions.pgp_sym_encrypt_bytea(bytea, text) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.pgp_sym_encrypt_bytea(bytea, text) TO dashboard_user;


--
-- Name: FUNCTION pgp_sym_encrypt_bytea(bytea, text, text); Type: ACL; Schema: extensions; Owner: postgres
--

REVOKE ALL ON FUNCTION extensions.pgp_sym_encrypt_bytea(bytea, text, text) FROM postgres;
GRANT ALL ON FUNCTION extensions.pgp_sym_encrypt_bytea(bytea, text, text) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.pgp_sym_encrypt_bytea(bytea, text, text) TO dashboard_user;


--
-- Name: FUNCTION pgrst_ddl_watch(); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.pgrst_ddl_watch() TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION pgrst_drop_watch(); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.pgrst_drop_watch() TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION set_graphql_placeholder(); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.set_graphql_placeholder() TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION uuid_generate_v1(); Type: ACL; Schema: extensions; Owner: postgres
--

REVOKE ALL ON FUNCTION extensions.uuid_generate_v1() FROM postgres;
GRANT ALL ON FUNCTION extensions.uuid_generate_v1() TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.uuid_generate_v1() TO dashboard_user;


--
-- Name: FUNCTION uuid_generate_v1mc(); Type: ACL; Schema: extensions; Owner: postgres
--

REVOKE ALL ON FUNCTION extensions.uuid_generate_v1mc() FROM postgres;
GRANT ALL ON FUNCTION extensions.uuid_generate_v1mc() TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.uuid_generate_v1mc() TO dashboard_user;


--
-- Name: FUNCTION uuid_generate_v3(namespace uuid, name text); Type: ACL; Schema: extensions; Owner: postgres
--

REVOKE ALL ON FUNCTION extensions.uuid_generate_v3(namespace uuid, name text) FROM postgres;
GRANT ALL ON FUNCTION extensions.uuid_generate_v3(namespace uuid, name text) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.uuid_generate_v3(namespace uuid, name text) TO dashboard_user;


--
-- Name: FUNCTION uuid_generate_v4(); Type: ACL; Schema: extensions; Owner: postgres
--

REVOKE ALL ON FUNCTION extensions.uuid_generate_v4() FROM postgres;
GRANT ALL ON FUNCTION extensions.uuid_generate_v4() TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.uuid_generate_v4() TO dashboard_user;


--
-- Name: FUNCTION uuid_generate_v5(namespace uuid, name text); Type: ACL; Schema: extensions; Owner: postgres
--

REVOKE ALL ON FUNCTION extensions.uuid_generate_v5(namespace uuid, name text) FROM postgres;
GRANT ALL ON FUNCTION extensions.uuid_generate_v5(namespace uuid, name text) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.uuid_generate_v5(namespace uuid, name text) TO dashboard_user;


--
-- Name: FUNCTION uuid_nil(); Type: ACL; Schema: extensions; Owner: postgres
--

REVOKE ALL ON FUNCTION extensions.uuid_nil() FROM postgres;
GRANT ALL ON FUNCTION extensions.uuid_nil() TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.uuid_nil() TO dashboard_user;


--
-- Name: FUNCTION uuid_ns_dns(); Type: ACL; Schema: extensions; Owner: postgres
--

REVOKE ALL ON FUNCTION extensions.uuid_ns_dns() FROM postgres;
GRANT ALL ON FUNCTION extensions.uuid_ns_dns() TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.uuid_ns_dns() TO dashboard_user;


--
-- Name: FUNCTION uuid_ns_oid(); Type: ACL; Schema: extensions; Owner: postgres
--

REVOKE ALL ON FUNCTION extensions.uuid_ns_oid() FROM postgres;
GRANT ALL ON FUNCTION extensions.uuid_ns_oid() TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.uuid_ns_oid() TO dashboard_user;


--
-- Name: FUNCTION uuid_ns_url(); Type: ACL; Schema: extensions; Owner: postgres
--

REVOKE ALL ON FUNCTION extensions.uuid_ns_url() FROM postgres;
GRANT ALL ON FUNCTION extensions.uuid_ns_url() TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.uuid_ns_url() TO dashboard_user;


--
-- Name: FUNCTION uuid_ns_x500(); Type: ACL; Schema: extensions; Owner: postgres
--

REVOKE ALL ON FUNCTION extensions.uuid_ns_x500() FROM postgres;
GRANT ALL ON FUNCTION extensions.uuid_ns_x500() TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.uuid_ns_x500() TO dashboard_user;


--
-- Name: FUNCTION graphql("operationName" text, query text, variables jsonb, extensions jsonb); Type: ACL; Schema: graphql_public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION graphql_public.graphql("operationName" text, query text, variables jsonb, extensions jsonb) TO postgres;
GRANT ALL ON FUNCTION graphql_public.graphql("operationName" text, query text, variables jsonb, extensions jsonb) TO anon;
GRANT ALL ON FUNCTION graphql_public.graphql("operationName" text, query text, variables jsonb, extensions jsonb) TO authenticated;
GRANT ALL ON FUNCTION graphql_public.graphql("operationName" text, query text, variables jsonb, extensions jsonb) TO service_role;


--
-- Name: FUNCTION get_auth(p_usename text); Type: ACL; Schema: pgbouncer; Owner: supabase_admin
--

REVOKE ALL ON FUNCTION pgbouncer.get_auth(p_usename text) FROM PUBLIC;
GRANT ALL ON FUNCTION pgbouncer.get_auth(p_usename text) TO pgbouncer;
GRANT ALL ON FUNCTION pgbouncer.get_auth(p_usename text) TO postgres;


--
-- Name: FUNCTION add_cooldown_on_cancel(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.add_cooldown_on_cancel() TO anon;
GRANT ALL ON FUNCTION public.add_cooldown_on_cancel() TO authenticated;
GRANT ALL ON FUNCTION public.add_cooldown_on_cancel() TO service_role;


--
-- Name: FUNCTION add_cooldown_on_status_change(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.add_cooldown_on_status_change() TO anon;
GRANT ALL ON FUNCTION public.add_cooldown_on_status_change() TO authenticated;
GRANT ALL ON FUNCTION public.add_cooldown_on_status_change() TO service_role;


--
-- Name: FUNCTION add_match_cooldown(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.add_match_cooldown() TO anon;
GRANT ALL ON FUNCTION public.add_match_cooldown() TO authenticated;
GRANT ALL ON FUNCTION public.add_match_cooldown() TO service_role;


--
-- Name: FUNCTION add_match_cooldown(a_fid bigint, b_fid bigint); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.add_match_cooldown(a_fid bigint, b_fid bigint) TO anon;
GRANT ALL ON FUNCTION public.add_match_cooldown(a_fid bigint, b_fid bigint) TO authenticated;
GRANT ALL ON FUNCTION public.add_match_cooldown(a_fid bigint, b_fid bigint) TO service_role;


--
-- Name: FUNCTION auto_close_expired_rooms(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.auto_close_expired_rooms() TO anon;
GRANT ALL ON FUNCTION public.auto_close_expired_rooms() TO authenticated;
GRANT ALL ON FUNCTION public.auto_close_expired_rooms() TO service_role;


--
-- Name: FUNCTION award_achievement(p_user_fid bigint, p_code text, p_points integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.award_achievement(p_user_fid bigint, p_code text, p_points integer) TO anon;
GRANT ALL ON FUNCTION public.award_achievement(p_user_fid bigint, p_code text, p_points integer) TO authenticated;
GRANT ALL ON FUNCTION public.award_achievement(p_user_fid bigint, p_code text, p_points integer) TO service_role;


--
-- Name: FUNCTION calculate_trait_similarity(traits_a jsonb, traits_b jsonb); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.calculate_trait_similarity(traits_a jsonb, traits_b jsonb) TO anon;
GRANT ALL ON FUNCTION public.calculate_trait_similarity(traits_a jsonb, traits_b jsonb) TO authenticated;
GRANT ALL ON FUNCTION public.calculate_trait_similarity(traits_a jsonb, traits_b jsonb) TO service_role;


--
-- Name: FUNCTION check_match_cooldown(fid_a bigint, fid_b bigint); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.check_match_cooldown(fid_a bigint, fid_b bigint) TO anon;
GRANT ALL ON FUNCTION public.check_match_cooldown(fid_a bigint, fid_b bigint) TO authenticated;
GRANT ALL ON FUNCTION public.check_match_cooldown(fid_a bigint, fid_b bigint) TO service_role;


--
-- Name: FUNCTION check_match_request_achievements(p_user_fid bigint); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.check_match_request_achievements(p_user_fid bigint) TO anon;
GRANT ALL ON FUNCTION public.check_match_request_achievements(p_user_fid bigint) TO authenticated;
GRANT ALL ON FUNCTION public.check_match_request_achievements(p_user_fid bigint) TO service_role;


--
-- Name: FUNCTION check_meeting_achievements(p_user_fid bigint); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.check_meeting_achievements(p_user_fid bigint) TO anon;
GRANT ALL ON FUNCTION public.check_meeting_achievements(p_user_fid bigint) TO authenticated;
GRANT ALL ON FUNCTION public.check_meeting_achievements(p_user_fid bigint) TO service_role;


--
-- Name: FUNCTION check_profile_achievements(p_user_fid bigint); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.check_profile_achievements(p_user_fid bigint) TO anon;
GRANT ALL ON FUNCTION public.check_profile_achievements(p_user_fid bigint) TO authenticated;
GRANT ALL ON FUNCTION public.check_profile_achievements(p_user_fid bigint) TO service_role;


--
-- Name: FUNCTION check_suggestion_cooldown(p_user_a_fid bigint, p_user_b_fid bigint); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.check_suggestion_cooldown(p_user_a_fid bigint, p_user_b_fid bigint) TO anon;
GRANT ALL ON FUNCTION public.check_suggestion_cooldown(p_user_a_fid bigint, p_user_b_fid bigint) TO authenticated;
GRANT ALL ON FUNCTION public.check_suggestion_cooldown(p_user_a_fid bigint, p_user_b_fid bigint) TO service_role;


--
-- Name: FUNCTION cleanup_expired_cooldowns(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.cleanup_expired_cooldowns() TO anon;
GRANT ALL ON FUNCTION public.cleanup_expired_cooldowns() TO authenticated;
GRANT ALL ON FUNCTION public.cleanup_expired_cooldowns() TO service_role;


--
-- Name: FUNCTION close_expired_chat_rooms(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.close_expired_chat_rooms() TO anon;
GRANT ALL ON FUNCTION public.close_expired_chat_rooms() TO authenticated;
GRANT ALL ON FUNCTION public.close_expired_chat_rooms() TO service_role;


--
-- Name: FUNCTION close_meeting_room(p_match_id uuid, p_reason text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.close_meeting_room(p_match_id uuid, p_reason text) TO anon;
GRANT ALL ON FUNCTION public.close_meeting_room(p_match_id uuid, p_reason text) TO authenticated;
GRANT ALL ON FUNCTION public.close_meeting_room(p_match_id uuid, p_reason text) TO service_role;


--
-- Name: FUNCTION count_pending_matches(user_fid bigint); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.count_pending_matches(user_fid bigint) TO anon;
GRANT ALL ON FUNCTION public.count_pending_matches(user_fid bigint) TO authenticated;
GRANT ALL ON FUNCTION public.count_pending_matches(user_fid bigint) TO service_role;


--
-- Name: FUNCTION create_initial_match_message(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.create_initial_match_message() TO anon;
GRANT ALL ON FUNCTION public.create_initial_match_message() TO authenticated;
GRANT ALL ON FUNCTION public.create_initial_match_message() TO service_role;


--
-- Name: FUNCTION create_suggestion_cooldown(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.create_suggestion_cooldown() TO anon;
GRANT ALL ON FUNCTION public.create_suggestion_cooldown() TO authenticated;
GRANT ALL ON FUNCTION public.create_suggestion_cooldown() TO service_role;


--
-- Name: FUNCTION gen_unique_user_code(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.gen_unique_user_code() TO anon;
GRANT ALL ON FUNCTION public.gen_unique_user_code() TO authenticated;
GRANT ALL ON FUNCTION public.gen_unique_user_code() TO service_role;


--
-- Name: FUNCTION get_expired_meeting_rooms(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.get_expired_meeting_rooms() TO anon;
GRANT ALL ON FUNCTION public.get_expired_meeting_rooms() TO authenticated;
GRANT ALL ON FUNCTION public.get_expired_meeting_rooms() TO service_role;


--
-- Name: FUNCTION get_match_cooldown_expiry(fid_a bigint, fid_b bigint); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.get_match_cooldown_expiry(fid_a bigint, fid_b bigint) TO anon;
GRANT ALL ON FUNCTION public.get_match_cooldown_expiry(fid_a bigint, fid_b bigint) TO authenticated;
GRANT ALL ON FUNCTION public.get_match_cooldown_expiry(fid_a bigint, fid_b bigint) TO service_role;


--
-- Name: FUNCTION get_matchable_users(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.get_matchable_users() TO anon;
GRANT ALL ON FUNCTION public.get_matchable_users() TO authenticated;
GRANT ALL ON FUNCTION public.get_matchable_users() TO service_role;


--
-- Name: FUNCTION get_user_achievements(p_user_fid bigint); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.get_user_achievements(p_user_fid bigint) TO anon;
GRANT ALL ON FUNCTION public.get_user_achievements(p_user_fid bigint) TO authenticated;
GRANT ALL ON FUNCTION public.get_user_achievements(p_user_fid bigint) TO service_role;


--
-- Name: FUNCTION get_user_level(p_user_fid bigint); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.get_user_level(p_user_fid bigint) TO anon;
GRANT ALL ON FUNCTION public.get_user_level(p_user_fid bigint) TO authenticated;
GRANT ALL ON FUNCTION public.get_user_level(p_user_fid bigint) TO service_role;


--
-- Name: FUNCTION gin_extract_query_trgm(text, internal, smallint, internal, internal, internal, internal); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.gin_extract_query_trgm(text, internal, smallint, internal, internal, internal, internal) TO postgres;
GRANT ALL ON FUNCTION public.gin_extract_query_trgm(text, internal, smallint, internal, internal, internal, internal) TO anon;
GRANT ALL ON FUNCTION public.gin_extract_query_trgm(text, internal, smallint, internal, internal, internal, internal) TO authenticated;
GRANT ALL ON FUNCTION public.gin_extract_query_trgm(text, internal, smallint, internal, internal, internal, internal) TO service_role;


--
-- Name: FUNCTION gin_extract_value_trgm(text, internal); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.gin_extract_value_trgm(text, internal) TO postgres;
GRANT ALL ON FUNCTION public.gin_extract_value_trgm(text, internal) TO anon;
GRANT ALL ON FUNCTION public.gin_extract_value_trgm(text, internal) TO authenticated;
GRANT ALL ON FUNCTION public.gin_extract_value_trgm(text, internal) TO service_role;


--
-- Name: FUNCTION gin_trgm_consistent(internal, smallint, text, integer, internal, internal, internal, internal); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.gin_trgm_consistent(internal, smallint, text, integer, internal, internal, internal, internal) TO postgres;
GRANT ALL ON FUNCTION public.gin_trgm_consistent(internal, smallint, text, integer, internal, internal, internal, internal) TO anon;
GRANT ALL ON FUNCTION public.gin_trgm_consistent(internal, smallint, text, integer, internal, internal, internal, internal) TO authenticated;
GRANT ALL ON FUNCTION public.gin_trgm_consistent(internal, smallint, text, integer, internal, internal, internal, internal) TO service_role;


--
-- Name: FUNCTION gin_trgm_triconsistent(internal, smallint, text, integer, internal, internal, internal); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.gin_trgm_triconsistent(internal, smallint, text, integer, internal, internal, internal) TO postgres;
GRANT ALL ON FUNCTION public.gin_trgm_triconsistent(internal, smallint, text, integer, internal, internal, internal) TO anon;
GRANT ALL ON FUNCTION public.gin_trgm_triconsistent(internal, smallint, text, integer, internal, internal, internal) TO authenticated;
GRANT ALL ON FUNCTION public.gin_trgm_triconsistent(internal, smallint, text, integer, internal, internal, internal) TO service_role;


--
-- Name: FUNCTION gtrgm_compress(internal); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.gtrgm_compress(internal) TO postgres;
GRANT ALL ON FUNCTION public.gtrgm_compress(internal) TO anon;
GRANT ALL ON FUNCTION public.gtrgm_compress(internal) TO authenticated;
GRANT ALL ON FUNCTION public.gtrgm_compress(internal) TO service_role;


--
-- Name: FUNCTION gtrgm_consistent(internal, text, smallint, oid, internal); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.gtrgm_consistent(internal, text, smallint, oid, internal) TO postgres;
GRANT ALL ON FUNCTION public.gtrgm_consistent(internal, text, smallint, oid, internal) TO anon;
GRANT ALL ON FUNCTION public.gtrgm_consistent(internal, text, smallint, oid, internal) TO authenticated;
GRANT ALL ON FUNCTION public.gtrgm_consistent(internal, text, smallint, oid, internal) TO service_role;


--
-- Name: FUNCTION gtrgm_decompress(internal); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.gtrgm_decompress(internal) TO postgres;
GRANT ALL ON FUNCTION public.gtrgm_decompress(internal) TO anon;
GRANT ALL ON FUNCTION public.gtrgm_decompress(internal) TO authenticated;
GRANT ALL ON FUNCTION public.gtrgm_decompress(internal) TO service_role;


--
-- Name: FUNCTION gtrgm_distance(internal, text, smallint, oid, internal); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.gtrgm_distance(internal, text, smallint, oid, internal) TO postgres;
GRANT ALL ON FUNCTION public.gtrgm_distance(internal, text, smallint, oid, internal) TO anon;
GRANT ALL ON FUNCTION public.gtrgm_distance(internal, text, smallint, oid, internal) TO authenticated;
GRANT ALL ON FUNCTION public.gtrgm_distance(internal, text, smallint, oid, internal) TO service_role;


--
-- Name: FUNCTION gtrgm_options(internal); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.gtrgm_options(internal) TO postgres;
GRANT ALL ON FUNCTION public.gtrgm_options(internal) TO anon;
GRANT ALL ON FUNCTION public.gtrgm_options(internal) TO authenticated;
GRANT ALL ON FUNCTION public.gtrgm_options(internal) TO service_role;


--
-- Name: FUNCTION gtrgm_penalty(internal, internal, internal); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.gtrgm_penalty(internal, internal, internal) TO postgres;
GRANT ALL ON FUNCTION public.gtrgm_penalty(internal, internal, internal) TO anon;
GRANT ALL ON FUNCTION public.gtrgm_penalty(internal, internal, internal) TO authenticated;
GRANT ALL ON FUNCTION public.gtrgm_penalty(internal, internal, internal) TO service_role;


--
-- Name: FUNCTION gtrgm_picksplit(internal, internal); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.gtrgm_picksplit(internal, internal) TO postgres;
GRANT ALL ON FUNCTION public.gtrgm_picksplit(internal, internal) TO anon;
GRANT ALL ON FUNCTION public.gtrgm_picksplit(internal, internal) TO authenticated;
GRANT ALL ON FUNCTION public.gtrgm_picksplit(internal, internal) TO service_role;


--
-- Name: FUNCTION gtrgm_same(public.gtrgm, public.gtrgm, internal); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.gtrgm_same(public.gtrgm, public.gtrgm, internal) TO postgres;
GRANT ALL ON FUNCTION public.gtrgm_same(public.gtrgm, public.gtrgm, internal) TO anon;
GRANT ALL ON FUNCTION public.gtrgm_same(public.gtrgm, public.gtrgm, internal) TO authenticated;
GRANT ALL ON FUNCTION public.gtrgm_same(public.gtrgm, public.gtrgm, internal) TO service_role;


--
-- Name: FUNCTION gtrgm_union(internal, internal); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.gtrgm_union(internal, internal) TO postgres;
GRANT ALL ON FUNCTION public.gtrgm_union(internal, internal) TO anon;
GRANT ALL ON FUNCTION public.gtrgm_union(internal, internal) TO authenticated;
GRANT ALL ON FUNCTION public.gtrgm_union(internal, internal) TO service_role;


--
-- Name: FUNCTION handle_decline_or_cancel(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.handle_decline_or_cancel() TO anon;
GRANT ALL ON FUNCTION public.handle_decline_or_cancel() TO authenticated;
GRANT ALL ON FUNCTION public.handle_decline_or_cancel() TO service_role;


--
-- Name: FUNCTION handle_match_decline(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.handle_match_decline() TO anon;
GRANT ALL ON FUNCTION public.handle_match_decline() TO authenticated;
GRANT ALL ON FUNCTION public.handle_match_decline() TO service_role;


--
-- Name: FUNCTION is_room_expired(room_id uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.is_room_expired(room_id uuid) TO anon;
GRANT ALL ON FUNCTION public.is_room_expired(room_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.is_room_expired(room_id uuid) TO service_role;


--
-- Name: FUNCTION reload_pgrst_schema(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.reload_pgrst_schema() TO anon;
GRANT ALL ON FUNCTION public.reload_pgrst_schema() TO authenticated;
GRANT ALL ON FUNCTION public.reload_pgrst_schema() TO service_role;


--
-- Name: FUNCTION set_limit(real); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.set_limit(real) TO postgres;
GRANT ALL ON FUNCTION public.set_limit(real) TO anon;
GRANT ALL ON FUNCTION public.set_limit(real) TO authenticated;
GRANT ALL ON FUNCTION public.set_limit(real) TO service_role;


--
-- Name: FUNCTION set_user_code_before_insert(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.set_user_code_before_insert() TO anon;
GRANT ALL ON FUNCTION public.set_user_code_before_insert() TO authenticated;
GRANT ALL ON FUNCTION public.set_user_code_before_insert() TO service_role;


--
-- Name: FUNCTION show_limit(); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.show_limit() TO postgres;
GRANT ALL ON FUNCTION public.show_limit() TO anon;
GRANT ALL ON FUNCTION public.show_limit() TO authenticated;
GRANT ALL ON FUNCTION public.show_limit() TO service_role;


--
-- Name: FUNCTION show_trgm(text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.show_trgm(text) TO postgres;
GRANT ALL ON FUNCTION public.show_trgm(text) TO anon;
GRANT ALL ON FUNCTION public.show_trgm(text) TO authenticated;
GRANT ALL ON FUNCTION public.show_trgm(text) TO service_role;


--
-- Name: FUNCTION similarity(text, text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.similarity(text, text) TO postgres;
GRANT ALL ON FUNCTION public.similarity(text, text) TO anon;
GRANT ALL ON FUNCTION public.similarity(text, text) TO authenticated;
GRANT ALL ON FUNCTION public.similarity(text, text) TO service_role;


--
-- Name: FUNCTION similarity_dist(text, text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.similarity_dist(text, text) TO postgres;
GRANT ALL ON FUNCTION public.similarity_dist(text, text) TO anon;
GRANT ALL ON FUNCTION public.similarity_dist(text, text) TO authenticated;
GRANT ALL ON FUNCTION public.similarity_dist(text, text) TO service_role;


--
-- Name: FUNCTION similarity_op(text, text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.similarity_op(text, text) TO postgres;
GRANT ALL ON FUNCTION public.similarity_op(text, text) TO anon;
GRANT ALL ON FUNCTION public.similarity_op(text, text) TO authenticated;
GRANT ALL ON FUNCTION public.similarity_op(text, text) TO service_role;


--
-- Name: FUNCTION start_meeting_timer(p_match_id uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.start_meeting_timer(p_match_id uuid) TO anon;
GRANT ALL ON FUNCTION public.start_meeting_timer(p_match_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.start_meeting_timer(p_match_id uuid) TO service_role;


--
-- Name: FUNCTION strict_word_similarity(text, text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.strict_word_similarity(text, text) TO postgres;
GRANT ALL ON FUNCTION public.strict_word_similarity(text, text) TO anon;
GRANT ALL ON FUNCTION public.strict_word_similarity(text, text) TO authenticated;
GRANT ALL ON FUNCTION public.strict_word_similarity(text, text) TO service_role;


--
-- Name: FUNCTION strict_word_similarity_commutator_op(text, text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.strict_word_similarity_commutator_op(text, text) TO postgres;
GRANT ALL ON FUNCTION public.strict_word_similarity_commutator_op(text, text) TO anon;
GRANT ALL ON FUNCTION public.strict_word_similarity_commutator_op(text, text) TO authenticated;
GRANT ALL ON FUNCTION public.strict_word_similarity_commutator_op(text, text) TO service_role;


--
-- Name: FUNCTION strict_word_similarity_dist_commutator_op(text, text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.strict_word_similarity_dist_commutator_op(text, text) TO postgres;
GRANT ALL ON FUNCTION public.strict_word_similarity_dist_commutator_op(text, text) TO anon;
GRANT ALL ON FUNCTION public.strict_word_similarity_dist_commutator_op(text, text) TO authenticated;
GRANT ALL ON FUNCTION public.strict_word_similarity_dist_commutator_op(text, text) TO service_role;


--
-- Name: FUNCTION strict_word_similarity_dist_op(text, text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.strict_word_similarity_dist_op(text, text) TO postgres;
GRANT ALL ON FUNCTION public.strict_word_similarity_dist_op(text, text) TO anon;
GRANT ALL ON FUNCTION public.strict_word_similarity_dist_op(text, text) TO authenticated;
GRANT ALL ON FUNCTION public.strict_word_similarity_dist_op(text, text) TO service_role;


--
-- Name: FUNCTION strict_word_similarity_op(text, text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.strict_word_similarity_op(text, text) TO postgres;
GRANT ALL ON FUNCTION public.strict_word_similarity_op(text, text) TO anon;
GRANT ALL ON FUNCTION public.strict_word_similarity_op(text, text) TO authenticated;
GRANT ALL ON FUNCTION public.strict_word_similarity_op(text, text) TO service_role;


--
-- Name: FUNCTION trg_match_declined_cooldown(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.trg_match_declined_cooldown() TO anon;
GRANT ALL ON FUNCTION public.trg_match_declined_cooldown() TO authenticated;
GRANT ALL ON FUNCTION public.trg_match_declined_cooldown() TO service_role;


--
-- Name: FUNCTION trg_set_cooldown_on_decline(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.trg_set_cooldown_on_decline() TO anon;
GRANT ALL ON FUNCTION public.trg_set_cooldown_on_decline() TO authenticated;
GRANT ALL ON FUNCTION public.trg_set_cooldown_on_decline() TO service_role;


--
-- Name: FUNCTION update_attestations_updated_at(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.update_attestations_updated_at() TO anon;
GRANT ALL ON FUNCTION public.update_attestations_updated_at() TO authenticated;
GRANT ALL ON FUNCTION public.update_attestations_updated_at() TO service_role;


--
-- Name: FUNCTION update_match_completion(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.update_match_completion() TO anon;
GRANT ALL ON FUNCTION public.update_match_completion() TO authenticated;
GRANT ALL ON FUNCTION public.update_match_completion() TO service_role;


--
-- Name: FUNCTION update_match_status(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.update_match_status() TO anon;
GRANT ALL ON FUNCTION public.update_match_status() TO authenticated;
GRANT ALL ON FUNCTION public.update_match_status() TO service_role;


--
-- Name: FUNCTION update_suggestion_status(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.update_suggestion_status() TO anon;
GRANT ALL ON FUNCTION public.update_suggestion_status() TO authenticated;
GRANT ALL ON FUNCTION public.update_suggestion_status() TO service_role;


--
-- Name: FUNCTION update_updated_at_column(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.update_updated_at_column() TO anon;
GRANT ALL ON FUNCTION public.update_updated_at_column() TO authenticated;
GRANT ALL ON FUNCTION public.update_updated_at_column() TO service_role;


--
-- Name: FUNCTION update_user_levels_timestamp(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.update_user_levels_timestamp() TO anon;
GRANT ALL ON FUNCTION public.update_user_levels_timestamp() TO authenticated;
GRANT ALL ON FUNCTION public.update_user_levels_timestamp() TO service_role;


--
-- Name: FUNCTION upsert_cooldown(a integer, b integer, ttl interval); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.upsert_cooldown(a integer, b integer, ttl interval) TO anon;
GRANT ALL ON FUNCTION public.upsert_cooldown(a integer, b integer, ttl interval) TO authenticated;
GRANT ALL ON FUNCTION public.upsert_cooldown(a integer, b integer, ttl interval) TO service_role;


--
-- Name: FUNCTION upsert_cooldown(a_fid bigint, b_fid bigint, ttl interval); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.upsert_cooldown(a_fid bigint, b_fid bigint, ttl interval) TO anon;
GRANT ALL ON FUNCTION public.upsert_cooldown(a_fid bigint, b_fid bigint, ttl interval) TO authenticated;
GRANT ALL ON FUNCTION public.upsert_cooldown(a_fid bigint, b_fid bigint, ttl interval) TO service_role;


--
-- Name: FUNCTION upsert_match_cooldown(a_fid bigint, b_fid bigint, ttl interval); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.upsert_match_cooldown(a_fid bigint, b_fid bigint, ttl interval) TO anon;
GRANT ALL ON FUNCTION public.upsert_match_cooldown(a_fid bigint, b_fid bigint, ttl interval) TO authenticated;
GRANT ALL ON FUNCTION public.upsert_match_cooldown(a_fid bigint, b_fid bigint, ttl interval) TO service_role;


--
-- Name: FUNCTION verify_trigger_fix(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.verify_trigger_fix() TO anon;
GRANT ALL ON FUNCTION public.verify_trigger_fix() TO authenticated;
GRANT ALL ON FUNCTION public.verify_trigger_fix() TO service_role;


--
-- Name: FUNCTION word_similarity(text, text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.word_similarity(text, text) TO postgres;
GRANT ALL ON FUNCTION public.word_similarity(text, text) TO anon;
GRANT ALL ON FUNCTION public.word_similarity(text, text) TO authenticated;
GRANT ALL ON FUNCTION public.word_similarity(text, text) TO service_role;


--
-- Name: FUNCTION word_similarity_commutator_op(text, text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.word_similarity_commutator_op(text, text) TO postgres;
GRANT ALL ON FUNCTION public.word_similarity_commutator_op(text, text) TO anon;
GRANT ALL ON FUNCTION public.word_similarity_commutator_op(text, text) TO authenticated;
GRANT ALL ON FUNCTION public.word_similarity_commutator_op(text, text) TO service_role;


--
-- Name: FUNCTION word_similarity_dist_commutator_op(text, text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.word_similarity_dist_commutator_op(text, text) TO postgres;
GRANT ALL ON FUNCTION public.word_similarity_dist_commutator_op(text, text) TO anon;
GRANT ALL ON FUNCTION public.word_similarity_dist_commutator_op(text, text) TO authenticated;
GRANT ALL ON FUNCTION public.word_similarity_dist_commutator_op(text, text) TO service_role;


--
-- Name: FUNCTION word_similarity_dist_op(text, text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.word_similarity_dist_op(text, text) TO postgres;
GRANT ALL ON FUNCTION public.word_similarity_dist_op(text, text) TO anon;
GRANT ALL ON FUNCTION public.word_similarity_dist_op(text, text) TO authenticated;
GRANT ALL ON FUNCTION public.word_similarity_dist_op(text, text) TO service_role;


--
-- Name: FUNCTION word_similarity_op(text, text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.word_similarity_op(text, text) TO postgres;
GRANT ALL ON FUNCTION public.word_similarity_op(text, text) TO anon;
GRANT ALL ON FUNCTION public.word_similarity_op(text, text) TO authenticated;
GRANT ALL ON FUNCTION public.word_similarity_op(text, text) TO service_role;


--
-- Name: FUNCTION apply_rls(wal jsonb, max_record_bytes integer); Type: ACL; Schema: realtime; Owner: supabase_admin
--

GRANT ALL ON FUNCTION realtime.apply_rls(wal jsonb, max_record_bytes integer) TO postgres;
GRANT ALL ON FUNCTION realtime.apply_rls(wal jsonb, max_record_bytes integer) TO dashboard_user;
GRANT ALL ON FUNCTION realtime.apply_rls(wal jsonb, max_record_bytes integer) TO anon;
GRANT ALL ON FUNCTION realtime.apply_rls(wal jsonb, max_record_bytes integer) TO authenticated;
GRANT ALL ON FUNCTION realtime.apply_rls(wal jsonb, max_record_bytes integer) TO service_role;
GRANT ALL ON FUNCTION realtime.apply_rls(wal jsonb, max_record_bytes integer) TO supabase_realtime_admin;


--
-- Name: FUNCTION broadcast_changes(topic_name text, event_name text, operation text, table_name text, table_schema text, new record, old record, level text); Type: ACL; Schema: realtime; Owner: supabase_admin
--

GRANT ALL ON FUNCTION realtime.broadcast_changes(topic_name text, event_name text, operation text, table_name text, table_schema text, new record, old record, level text) TO postgres;
GRANT ALL ON FUNCTION realtime.broadcast_changes(topic_name text, event_name text, operation text, table_name text, table_schema text, new record, old record, level text) TO dashboard_user;


--
-- Name: FUNCTION build_prepared_statement_sql(prepared_statement_name text, entity regclass, columns realtime.wal_column[]); Type: ACL; Schema: realtime; Owner: supabase_admin
--

GRANT ALL ON FUNCTION realtime.build_prepared_statement_sql(prepared_statement_name text, entity regclass, columns realtime.wal_column[]) TO postgres;
GRANT ALL ON FUNCTION realtime.build_prepared_statement_sql(prepared_statement_name text, entity regclass, columns realtime.wal_column[]) TO dashboard_user;
GRANT ALL ON FUNCTION realtime.build_prepared_statement_sql(prepared_statement_name text, entity regclass, columns realtime.wal_column[]) TO anon;
GRANT ALL ON FUNCTION realtime.build_prepared_statement_sql(prepared_statement_name text, entity regclass, columns realtime.wal_column[]) TO authenticated;
GRANT ALL ON FUNCTION realtime.build_prepared_statement_sql(prepared_statement_name text, entity regclass, columns realtime.wal_column[]) TO service_role;
GRANT ALL ON FUNCTION realtime.build_prepared_statement_sql(prepared_statement_name text, entity regclass, columns realtime.wal_column[]) TO supabase_realtime_admin;


--
-- Name: FUNCTION "cast"(val text, type_ regtype); Type: ACL; Schema: realtime; Owner: supabase_admin
--

GRANT ALL ON FUNCTION realtime."cast"(val text, type_ regtype) TO postgres;
GRANT ALL ON FUNCTION realtime."cast"(val text, type_ regtype) TO dashboard_user;
GRANT ALL ON FUNCTION realtime."cast"(val text, type_ regtype) TO anon;
GRANT ALL ON FUNCTION realtime."cast"(val text, type_ regtype) TO authenticated;
GRANT ALL ON FUNCTION realtime."cast"(val text, type_ regtype) TO service_role;
GRANT ALL ON FUNCTION realtime."cast"(val text, type_ regtype) TO supabase_realtime_admin;


--
-- Name: FUNCTION check_equality_op(op realtime.equality_op, type_ regtype, val_1 text, val_2 text); Type: ACL; Schema: realtime; Owner: supabase_admin
--

GRANT ALL ON FUNCTION realtime.check_equality_op(op realtime.equality_op, type_ regtype, val_1 text, val_2 text) TO postgres;
GRANT ALL ON FUNCTION realtime.check_equality_op(op realtime.equality_op, type_ regtype, val_1 text, val_2 text) TO dashboard_user;
GRANT ALL ON FUNCTION realtime.check_equality_op(op realtime.equality_op, type_ regtype, val_1 text, val_2 text) TO anon;
GRANT ALL ON FUNCTION realtime.check_equality_op(op realtime.equality_op, type_ regtype, val_1 text, val_2 text) TO authenticated;
GRANT ALL ON FUNCTION realtime.check_equality_op(op realtime.equality_op, type_ regtype, val_1 text, val_2 text) TO service_role;
GRANT ALL ON FUNCTION realtime.check_equality_op(op realtime.equality_op, type_ regtype, val_1 text, val_2 text) TO supabase_realtime_admin;


--
-- Name: FUNCTION is_visible_through_filters(columns realtime.wal_column[], filters realtime.user_defined_filter[]); Type: ACL; Schema: realtime; Owner: supabase_admin
--

GRANT ALL ON FUNCTION realtime.is_visible_through_filters(columns realtime.wal_column[], filters realtime.user_defined_filter[]) TO postgres;
GRANT ALL ON FUNCTION realtime.is_visible_through_filters(columns realtime.wal_column[], filters realtime.user_defined_filter[]) TO dashboard_user;
GRANT ALL ON FUNCTION realtime.is_visible_through_filters(columns realtime.wal_column[], filters realtime.user_defined_filter[]) TO anon;
GRANT ALL ON FUNCTION realtime.is_visible_through_filters(columns realtime.wal_column[], filters realtime.user_defined_filter[]) TO authenticated;
GRANT ALL ON FUNCTION realtime.is_visible_through_filters(columns realtime.wal_column[], filters realtime.user_defined_filter[]) TO service_role;
GRANT ALL ON FUNCTION realtime.is_visible_through_filters(columns realtime.wal_column[], filters realtime.user_defined_filter[]) TO supabase_realtime_admin;


--
-- Name: FUNCTION list_changes(publication name, slot_name name, max_changes integer, max_record_bytes integer); Type: ACL; Schema: realtime; Owner: supabase_admin
--

GRANT ALL ON FUNCTION realtime.list_changes(publication name, slot_name name, max_changes integer, max_record_bytes integer) TO postgres;
GRANT ALL ON FUNCTION realtime.list_changes(publication name, slot_name name, max_changes integer, max_record_bytes integer) TO dashboard_user;
GRANT ALL ON FUNCTION realtime.list_changes(publication name, slot_name name, max_changes integer, max_record_bytes integer) TO anon;
GRANT ALL ON FUNCTION realtime.list_changes(publication name, slot_name name, max_changes integer, max_record_bytes integer) TO authenticated;
GRANT ALL ON FUNCTION realtime.list_changes(publication name, slot_name name, max_changes integer, max_record_bytes integer) TO service_role;
GRANT ALL ON FUNCTION realtime.list_changes(publication name, slot_name name, max_changes integer, max_record_bytes integer) TO supabase_realtime_admin;


--
-- Name: FUNCTION quote_wal2json(entity regclass); Type: ACL; Schema: realtime; Owner: supabase_admin
--

GRANT ALL ON FUNCTION realtime.quote_wal2json(entity regclass) TO postgres;
GRANT ALL ON FUNCTION realtime.quote_wal2json(entity regclass) TO dashboard_user;
GRANT ALL ON FUNCTION realtime.quote_wal2json(entity regclass) TO anon;
GRANT ALL ON FUNCTION realtime.quote_wal2json(entity regclass) TO authenticated;
GRANT ALL ON FUNCTION realtime.quote_wal2json(entity regclass) TO service_role;
GRANT ALL ON FUNCTION realtime.quote_wal2json(entity regclass) TO supabase_realtime_admin;


--
-- Name: FUNCTION send(payload jsonb, event text, topic text, private boolean); Type: ACL; Schema: realtime; Owner: supabase_admin
--

GRANT ALL ON FUNCTION realtime.send(payload jsonb, event text, topic text, private boolean) TO postgres;
GRANT ALL ON FUNCTION realtime.send(payload jsonb, event text, topic text, private boolean) TO dashboard_user;


--
-- Name: FUNCTION subscription_check_filters(); Type: ACL; Schema: realtime; Owner: supabase_admin
--

GRANT ALL ON FUNCTION realtime.subscription_check_filters() TO postgres;
GRANT ALL ON FUNCTION realtime.subscription_check_filters() TO dashboard_user;
GRANT ALL ON FUNCTION realtime.subscription_check_filters() TO anon;
GRANT ALL ON FUNCTION realtime.subscription_check_filters() TO authenticated;
GRANT ALL ON FUNCTION realtime.subscription_check_filters() TO service_role;
GRANT ALL ON FUNCTION realtime.subscription_check_filters() TO supabase_realtime_admin;


--
-- Name: FUNCTION to_regrole(role_name text); Type: ACL; Schema: realtime; Owner: supabase_admin
--

GRANT ALL ON FUNCTION realtime.to_regrole(role_name text) TO postgres;
GRANT ALL ON FUNCTION realtime.to_regrole(role_name text) TO dashboard_user;
GRANT ALL ON FUNCTION realtime.to_regrole(role_name text) TO anon;
GRANT ALL ON FUNCTION realtime.to_regrole(role_name text) TO authenticated;
GRANT ALL ON FUNCTION realtime.to_regrole(role_name text) TO service_role;
GRANT ALL ON FUNCTION realtime.to_regrole(role_name text) TO supabase_realtime_admin;


--
-- Name: FUNCTION topic(); Type: ACL; Schema: realtime; Owner: supabase_realtime_admin
--

GRANT ALL ON FUNCTION realtime.topic() TO postgres;
GRANT ALL ON FUNCTION realtime.topic() TO dashboard_user;


--
-- Name: FUNCTION _crypto_aead_det_decrypt(message bytea, additional bytea, key_id bigint, context bytea, nonce bytea); Type: ACL; Schema: vault; Owner: supabase_admin
--

GRANT ALL ON FUNCTION vault._crypto_aead_det_decrypt(message bytea, additional bytea, key_id bigint, context bytea, nonce bytea) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION vault._crypto_aead_det_decrypt(message bytea, additional bytea, key_id bigint, context bytea, nonce bytea) TO service_role;


--
-- Name: FUNCTION create_secret(new_secret text, new_name text, new_description text, new_key_id uuid); Type: ACL; Schema: vault; Owner: supabase_admin
--

GRANT ALL ON FUNCTION vault.create_secret(new_secret text, new_name text, new_description text, new_key_id uuid) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION vault.create_secret(new_secret text, new_name text, new_description text, new_key_id uuid) TO service_role;


--
-- Name: FUNCTION update_secret(secret_id uuid, new_secret text, new_name text, new_description text, new_key_id uuid); Type: ACL; Schema: vault; Owner: supabase_admin
--

GRANT ALL ON FUNCTION vault.update_secret(secret_id uuid, new_secret text, new_name text, new_description text, new_key_id uuid) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION vault.update_secret(secret_id uuid, new_secret text, new_name text, new_description text, new_key_id uuid) TO service_role;


--
-- Name: TABLE audit_log_entries; Type: ACL; Schema: auth; Owner: supabase_auth_admin
--

GRANT ALL ON TABLE auth.audit_log_entries TO dashboard_user;
GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE auth.audit_log_entries TO postgres;
GRANT SELECT ON TABLE auth.audit_log_entries TO postgres WITH GRANT OPTION;


--
-- Name: TABLE flow_state; Type: ACL; Schema: auth; Owner: supabase_auth_admin
--

GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE auth.flow_state TO postgres;
GRANT SELECT ON TABLE auth.flow_state TO postgres WITH GRANT OPTION;
GRANT ALL ON TABLE auth.flow_state TO dashboard_user;


--
-- Name: TABLE identities; Type: ACL; Schema: auth; Owner: supabase_auth_admin
--

GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE auth.identities TO postgres;
GRANT SELECT ON TABLE auth.identities TO postgres WITH GRANT OPTION;
GRANT ALL ON TABLE auth.identities TO dashboard_user;


--
-- Name: TABLE instances; Type: ACL; Schema: auth; Owner: supabase_auth_admin
--

GRANT ALL ON TABLE auth.instances TO dashboard_user;
GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE auth.instances TO postgres;
GRANT SELECT ON TABLE auth.instances TO postgres WITH GRANT OPTION;


--
-- Name: TABLE mfa_amr_claims; Type: ACL; Schema: auth; Owner: supabase_auth_admin
--

GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE auth.mfa_amr_claims TO postgres;
GRANT SELECT ON TABLE auth.mfa_amr_claims TO postgres WITH GRANT OPTION;
GRANT ALL ON TABLE auth.mfa_amr_claims TO dashboard_user;


--
-- Name: TABLE mfa_challenges; Type: ACL; Schema: auth; Owner: supabase_auth_admin
--

GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE auth.mfa_challenges TO postgres;
GRANT SELECT ON TABLE auth.mfa_challenges TO postgres WITH GRANT OPTION;
GRANT ALL ON TABLE auth.mfa_challenges TO dashboard_user;


--
-- Name: TABLE mfa_factors; Type: ACL; Schema: auth; Owner: supabase_auth_admin
--

GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE auth.mfa_factors TO postgres;
GRANT SELECT ON TABLE auth.mfa_factors TO postgres WITH GRANT OPTION;
GRANT ALL ON TABLE auth.mfa_factors TO dashboard_user;


--
-- Name: TABLE oauth_authorizations; Type: ACL; Schema: auth; Owner: supabase_auth_admin
--

GRANT ALL ON TABLE auth.oauth_authorizations TO postgres;
GRANT ALL ON TABLE auth.oauth_authorizations TO dashboard_user;


--
-- Name: TABLE oauth_clients; Type: ACL; Schema: auth; Owner: supabase_auth_admin
--

GRANT ALL ON TABLE auth.oauth_clients TO postgres;
GRANT ALL ON TABLE auth.oauth_clients TO dashboard_user;


--
-- Name: TABLE oauth_consents; Type: ACL; Schema: auth; Owner: supabase_auth_admin
--

GRANT ALL ON TABLE auth.oauth_consents TO postgres;
GRANT ALL ON TABLE auth.oauth_consents TO dashboard_user;


--
-- Name: TABLE one_time_tokens; Type: ACL; Schema: auth; Owner: supabase_auth_admin
--

GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE auth.one_time_tokens TO postgres;
GRANT SELECT ON TABLE auth.one_time_tokens TO postgres WITH GRANT OPTION;
GRANT ALL ON TABLE auth.one_time_tokens TO dashboard_user;


--
-- Name: TABLE refresh_tokens; Type: ACL; Schema: auth; Owner: supabase_auth_admin
--

GRANT ALL ON TABLE auth.refresh_tokens TO dashboard_user;
GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE auth.refresh_tokens TO postgres;
GRANT SELECT ON TABLE auth.refresh_tokens TO postgres WITH GRANT OPTION;


--
-- Name: SEQUENCE refresh_tokens_id_seq; Type: ACL; Schema: auth; Owner: supabase_auth_admin
--

GRANT ALL ON SEQUENCE auth.refresh_tokens_id_seq TO dashboard_user;
GRANT ALL ON SEQUENCE auth.refresh_tokens_id_seq TO postgres;


--
-- Name: TABLE saml_providers; Type: ACL; Schema: auth; Owner: supabase_auth_admin
--

GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE auth.saml_providers TO postgres;
GRANT SELECT ON TABLE auth.saml_providers TO postgres WITH GRANT OPTION;
GRANT ALL ON TABLE auth.saml_providers TO dashboard_user;


--
-- Name: TABLE saml_relay_states; Type: ACL; Schema: auth; Owner: supabase_auth_admin
--

GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE auth.saml_relay_states TO postgres;
GRANT SELECT ON TABLE auth.saml_relay_states TO postgres WITH GRANT OPTION;
GRANT ALL ON TABLE auth.saml_relay_states TO dashboard_user;


--
-- Name: TABLE schema_migrations; Type: ACL; Schema: auth; Owner: supabase_auth_admin
--

GRANT SELECT ON TABLE auth.schema_migrations TO postgres WITH GRANT OPTION;


--
-- Name: TABLE sessions; Type: ACL; Schema: auth; Owner: supabase_auth_admin
--

GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE auth.sessions TO postgres;
GRANT SELECT ON TABLE auth.sessions TO postgres WITH GRANT OPTION;
GRANT ALL ON TABLE auth.sessions TO dashboard_user;


--
-- Name: TABLE sso_domains; Type: ACL; Schema: auth; Owner: supabase_auth_admin
--

GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE auth.sso_domains TO postgres;
GRANT SELECT ON TABLE auth.sso_domains TO postgres WITH GRANT OPTION;
GRANT ALL ON TABLE auth.sso_domains TO dashboard_user;


--
-- Name: TABLE sso_providers; Type: ACL; Schema: auth; Owner: supabase_auth_admin
--

GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE auth.sso_providers TO postgres;
GRANT SELECT ON TABLE auth.sso_providers TO postgres WITH GRANT OPTION;
GRANT ALL ON TABLE auth.sso_providers TO dashboard_user;


--
-- Name: TABLE users; Type: ACL; Schema: auth; Owner: supabase_auth_admin
--

GRANT ALL ON TABLE auth.users TO dashboard_user;
GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE auth.users TO postgres;
GRANT SELECT ON TABLE auth.users TO postgres WITH GRANT OPTION;


--
-- Name: TABLE job; Type: ACL; Schema: cron; Owner: supabase_admin
--

GRANT SELECT ON TABLE cron.job TO postgres WITH GRANT OPTION;


--
-- Name: TABLE job_run_details; Type: ACL; Schema: cron; Owner: supabase_admin
--

GRANT ALL ON TABLE cron.job_run_details TO postgres WITH GRANT OPTION;


--
-- Name: TABLE pg_stat_statements; Type: ACL; Schema: extensions; Owner: postgres
--

REVOKE ALL ON TABLE extensions.pg_stat_statements FROM postgres;
GRANT ALL ON TABLE extensions.pg_stat_statements TO postgres WITH GRANT OPTION;
GRANT ALL ON TABLE extensions.pg_stat_statements TO dashboard_user;


--
-- Name: TABLE pg_stat_statements_info; Type: ACL; Schema: extensions; Owner: postgres
--

REVOKE ALL ON TABLE extensions.pg_stat_statements_info FROM postgres;
GRANT ALL ON TABLE extensions.pg_stat_statements_info TO postgres WITH GRANT OPTION;
GRANT ALL ON TABLE extensions.pg_stat_statements_info TO dashboard_user;


--
-- Name: TABLE attestations; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.attestations TO anon;
GRANT ALL ON TABLE public.attestations TO authenticated;
GRANT ALL ON TABLE public.attestations TO service_role;


--
-- Name: TABLE auto_match_runs; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.auto_match_runs TO anon;
GRANT ALL ON TABLE public.auto_match_runs TO authenticated;
GRANT ALL ON TABLE public.auto_match_runs TO service_role;


--
-- Name: TABLE chat_messages; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.chat_messages TO anon;
GRANT ALL ON TABLE public.chat_messages TO authenticated;
GRANT ALL ON TABLE public.chat_messages TO service_role;


--
-- Name: TABLE chat_participants; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.chat_participants TO anon;
GRANT ALL ON TABLE public.chat_participants TO authenticated;
GRANT ALL ON TABLE public.chat_participants TO service_role;


--
-- Name: TABLE chat_rooms; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.chat_rooms TO anon;
GRANT ALL ON TABLE public.chat_rooms TO authenticated;
GRANT ALL ON TABLE public.chat_rooms TO service_role;


--
-- Name: TABLE match_cooldowns; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.match_cooldowns TO anon;
GRANT ALL ON TABLE public.match_cooldowns TO authenticated;
GRANT ALL ON TABLE public.match_cooldowns TO service_role;


--
-- Name: TABLE matches; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.matches TO anon;
GRANT ALL ON TABLE public.matches TO authenticated;
GRANT ALL ON TABLE public.matches TO service_role;


--
-- Name: TABLE users; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.users TO anon;
GRANT ALL ON TABLE public.users TO authenticated;
GRANT ALL ON TABLE public.users TO service_role;


--
-- Name: TABLE match_details; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.match_details TO anon;
GRANT ALL ON TABLE public.match_details TO authenticated;
GRANT ALL ON TABLE public.match_details TO service_role;


--
-- Name: TABLE match_suggestion_cooldowns; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.match_suggestion_cooldowns TO anon;
GRANT ALL ON TABLE public.match_suggestion_cooldowns TO authenticated;
GRANT ALL ON TABLE public.match_suggestion_cooldowns TO service_role;


--
-- Name: TABLE match_suggestions; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.match_suggestions TO anon;
GRANT ALL ON TABLE public.match_suggestions TO authenticated;
GRANT ALL ON TABLE public.match_suggestions TO service_role;


--
-- Name: TABLE match_suggestions_with_details; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.match_suggestions_with_details TO anon;
GRANT ALL ON TABLE public.match_suggestions_with_details TO authenticated;
GRANT ALL ON TABLE public.match_suggestions_with_details TO service_role;


--
-- Name: TABLE messages; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.messages TO anon;
GRANT ALL ON TABLE public.messages TO authenticated;
GRANT ALL ON TABLE public.messages TO service_role;


--
-- Name: TABLE message_details; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.message_details TO anon;
GRANT ALL ON TABLE public.message_details TO authenticated;
GRANT ALL ON TABLE public.message_details TO service_role;


--
-- Name: TABLE user_achievements; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.user_achievements TO anon;
GRANT ALL ON TABLE public.user_achievements TO authenticated;
GRANT ALL ON TABLE public.user_achievements TO service_role;


--
-- Name: TABLE user_friends; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.user_friends TO anon;
GRANT ALL ON TABLE public.user_friends TO authenticated;
GRANT ALL ON TABLE public.user_friends TO service_role;


--
-- Name: TABLE user_levels; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.user_levels TO anon;
GRANT ALL ON TABLE public.user_levels TO authenticated;
GRANT ALL ON TABLE public.user_levels TO service_role;


--
-- Name: TABLE user_wallets; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.user_wallets TO anon;
GRANT ALL ON TABLE public.user_wallets TO authenticated;
GRANT ALL ON TABLE public.user_wallets TO service_role;


--
-- Name: TABLE messages; Type: ACL; Schema: realtime; Owner: supabase_realtime_admin
--

GRANT ALL ON TABLE realtime.messages TO postgres;
GRANT ALL ON TABLE realtime.messages TO dashboard_user;
GRANT SELECT,INSERT,UPDATE ON TABLE realtime.messages TO anon;
GRANT SELECT,INSERT,UPDATE ON TABLE realtime.messages TO authenticated;
GRANT SELECT,INSERT,UPDATE ON TABLE realtime.messages TO service_role;


--
-- Name: TABLE messages_2025_10_26; Type: ACL; Schema: realtime; Owner: supabase_admin
--

GRANT ALL ON TABLE realtime.messages_2025_10_26 TO postgres;
GRANT ALL ON TABLE realtime.messages_2025_10_26 TO dashboard_user;


--
-- Name: TABLE messages_2025_10_27; Type: ACL; Schema: realtime; Owner: supabase_admin
--

GRANT ALL ON TABLE realtime.messages_2025_10_27 TO postgres;
GRANT ALL ON TABLE realtime.messages_2025_10_27 TO dashboard_user;


--
-- Name: TABLE messages_2025_10_28; Type: ACL; Schema: realtime; Owner: supabase_admin
--

GRANT ALL ON TABLE realtime.messages_2025_10_28 TO postgres;
GRANT ALL ON TABLE realtime.messages_2025_10_28 TO dashboard_user;


--
-- Name: TABLE messages_2025_10_29; Type: ACL; Schema: realtime; Owner: supabase_admin
--

GRANT ALL ON TABLE realtime.messages_2025_10_29 TO postgres;
GRANT ALL ON TABLE realtime.messages_2025_10_29 TO dashboard_user;


--
-- Name: TABLE messages_2025_10_30; Type: ACL; Schema: realtime; Owner: supabase_admin
--

GRANT ALL ON TABLE realtime.messages_2025_10_30 TO postgres;
GRANT ALL ON TABLE realtime.messages_2025_10_30 TO dashboard_user;


--
-- Name: TABLE messages_2025_10_31; Type: ACL; Schema: realtime; Owner: supabase_admin
--

GRANT ALL ON TABLE realtime.messages_2025_10_31 TO postgres;
GRANT ALL ON TABLE realtime.messages_2025_10_31 TO dashboard_user;


--
-- Name: TABLE messages_2025_11_01; Type: ACL; Schema: realtime; Owner: supabase_admin
--

GRANT ALL ON TABLE realtime.messages_2025_11_01 TO postgres;
GRANT ALL ON TABLE realtime.messages_2025_11_01 TO dashboard_user;


--
-- Name: TABLE schema_migrations; Type: ACL; Schema: realtime; Owner: supabase_admin
--

GRANT ALL ON TABLE realtime.schema_migrations TO postgres;
GRANT ALL ON TABLE realtime.schema_migrations TO dashboard_user;
GRANT SELECT ON TABLE realtime.schema_migrations TO anon;
GRANT SELECT ON TABLE realtime.schema_migrations TO authenticated;
GRANT SELECT ON TABLE realtime.schema_migrations TO service_role;
GRANT ALL ON TABLE realtime.schema_migrations TO supabase_realtime_admin;


--
-- Name: TABLE subscription; Type: ACL; Schema: realtime; Owner: supabase_admin
--

GRANT ALL ON TABLE realtime.subscription TO postgres;
GRANT ALL ON TABLE realtime.subscription TO dashboard_user;
GRANT SELECT ON TABLE realtime.subscription TO anon;
GRANT SELECT ON TABLE realtime.subscription TO authenticated;
GRANT SELECT ON TABLE realtime.subscription TO service_role;
GRANT ALL ON TABLE realtime.subscription TO supabase_realtime_admin;


--
-- Name: SEQUENCE subscription_id_seq; Type: ACL; Schema: realtime; Owner: supabase_admin
--

GRANT ALL ON SEQUENCE realtime.subscription_id_seq TO postgres;
GRANT ALL ON SEQUENCE realtime.subscription_id_seq TO dashboard_user;
GRANT USAGE ON SEQUENCE realtime.subscription_id_seq TO anon;
GRANT USAGE ON SEQUENCE realtime.subscription_id_seq TO authenticated;
GRANT USAGE ON SEQUENCE realtime.subscription_id_seq TO service_role;
GRANT ALL ON SEQUENCE realtime.subscription_id_seq TO supabase_realtime_admin;


--
-- Name: TABLE buckets; Type: ACL; Schema: storage; Owner: supabase_storage_admin
--

GRANT ALL ON TABLE storage.buckets TO anon;
GRANT ALL ON TABLE storage.buckets TO authenticated;
GRANT ALL ON TABLE storage.buckets TO service_role;
GRANT ALL ON TABLE storage.buckets TO postgres WITH GRANT OPTION;


--
-- Name: TABLE buckets_analytics; Type: ACL; Schema: storage; Owner: supabase_storage_admin
--

GRANT ALL ON TABLE storage.buckets_analytics TO service_role;
GRANT ALL ON TABLE storage.buckets_analytics TO authenticated;
GRANT ALL ON TABLE storage.buckets_analytics TO anon;


--
-- Name: TABLE objects; Type: ACL; Schema: storage; Owner: supabase_storage_admin
--

GRANT ALL ON TABLE storage.objects TO anon;
GRANT ALL ON TABLE storage.objects TO authenticated;
GRANT ALL ON TABLE storage.objects TO service_role;
GRANT ALL ON TABLE storage.objects TO postgres WITH GRANT OPTION;


--
-- Name: TABLE prefixes; Type: ACL; Schema: storage; Owner: supabase_storage_admin
--

GRANT ALL ON TABLE storage.prefixes TO service_role;
GRANT ALL ON TABLE storage.prefixes TO authenticated;
GRANT ALL ON TABLE storage.prefixes TO anon;


--
-- Name: TABLE s3_multipart_uploads; Type: ACL; Schema: storage; Owner: supabase_storage_admin
--

GRANT ALL ON TABLE storage.s3_multipart_uploads TO service_role;
GRANT SELECT ON TABLE storage.s3_multipart_uploads TO authenticated;
GRANT SELECT ON TABLE storage.s3_multipart_uploads TO anon;


--
-- Name: TABLE s3_multipart_uploads_parts; Type: ACL; Schema: storage; Owner: supabase_storage_admin
--

GRANT ALL ON TABLE storage.s3_multipart_uploads_parts TO service_role;
GRANT SELECT ON TABLE storage.s3_multipart_uploads_parts TO authenticated;
GRANT SELECT ON TABLE storage.s3_multipart_uploads_parts TO anon;


--
-- Name: TABLE secrets; Type: ACL; Schema: vault; Owner: supabase_admin
--

GRANT SELECT,REFERENCES,DELETE,TRUNCATE ON TABLE vault.secrets TO postgres WITH GRANT OPTION;
GRANT SELECT,DELETE ON TABLE vault.secrets TO service_role;


--
-- Name: TABLE decrypted_secrets; Type: ACL; Schema: vault; Owner: supabase_admin
--

GRANT SELECT,REFERENCES,DELETE,TRUNCATE ON TABLE vault.decrypted_secrets TO postgres WITH GRANT OPTION;
GRANT SELECT,DELETE ON TABLE vault.decrypted_secrets TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: auth; Owner: supabase_auth_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_auth_admin IN SCHEMA auth GRANT ALL ON SEQUENCES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_auth_admin IN SCHEMA auth GRANT ALL ON SEQUENCES TO dashboard_user;


--
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: auth; Owner: supabase_auth_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_auth_admin IN SCHEMA auth GRANT ALL ON FUNCTIONS TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_auth_admin IN SCHEMA auth GRANT ALL ON FUNCTIONS TO dashboard_user;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: auth; Owner: supabase_auth_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_auth_admin IN SCHEMA auth GRANT ALL ON TABLES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_auth_admin IN SCHEMA auth GRANT ALL ON TABLES TO dashboard_user;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: cron; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA cron GRANT ALL ON SEQUENCES TO postgres WITH GRANT OPTION;


--
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: cron; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA cron GRANT ALL ON FUNCTIONS TO postgres WITH GRANT OPTION;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: cron; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA cron GRANT ALL ON TABLES TO postgres WITH GRANT OPTION;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: extensions; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA extensions GRANT ALL ON SEQUENCES TO postgres WITH GRANT OPTION;


--
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: extensions; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA extensions GRANT ALL ON FUNCTIONS TO postgres WITH GRANT OPTION;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: extensions; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA extensions GRANT ALL ON TABLES TO postgres WITH GRANT OPTION;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: graphql; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql GRANT ALL ON SEQUENCES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql GRANT ALL ON SEQUENCES TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql GRANT ALL ON SEQUENCES TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql GRANT ALL ON SEQUENCES TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: graphql; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql GRANT ALL ON FUNCTIONS TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql GRANT ALL ON FUNCTIONS TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql GRANT ALL ON FUNCTIONS TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql GRANT ALL ON FUNCTIONS TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: graphql; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql GRANT ALL ON TABLES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql GRANT ALL ON TABLES TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql GRANT ALL ON TABLES TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql GRANT ALL ON TABLES TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: graphql_public; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql_public GRANT ALL ON SEQUENCES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql_public GRANT ALL ON SEQUENCES TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql_public GRANT ALL ON SEQUENCES TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql_public GRANT ALL ON SEQUENCES TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: graphql_public; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql_public GRANT ALL ON FUNCTIONS TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql_public GRANT ALL ON FUNCTIONS TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql_public GRANT ALL ON FUNCTIONS TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql_public GRANT ALL ON FUNCTIONS TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: graphql_public; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql_public GRANT ALL ON TABLES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql_public GRANT ALL ON TABLES TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql_public GRANT ALL ON TABLES TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql_public GRANT ALL ON TABLES TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: public; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON SEQUENCES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON SEQUENCES TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON SEQUENCES TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON SEQUENCES TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON FUNCTIONS TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON FUNCTIONS TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON FUNCTIONS TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON FUNCTIONS TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: public; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON FUNCTIONS TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON FUNCTIONS TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON FUNCTIONS TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON FUNCTIONS TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON TABLES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON TABLES TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON TABLES TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON TABLES TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: realtime; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA realtime GRANT ALL ON SEQUENCES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA realtime GRANT ALL ON SEQUENCES TO dashboard_user;


--
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: realtime; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA realtime GRANT ALL ON FUNCTIONS TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA realtime GRANT ALL ON FUNCTIONS TO dashboard_user;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: realtime; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA realtime GRANT ALL ON TABLES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA realtime GRANT ALL ON TABLES TO dashboard_user;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: storage; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA storage GRANT ALL ON SEQUENCES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA storage GRANT ALL ON SEQUENCES TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA storage GRANT ALL ON SEQUENCES TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA storage GRANT ALL ON SEQUENCES TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: storage; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA storage GRANT ALL ON FUNCTIONS TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA storage GRANT ALL ON FUNCTIONS TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA storage GRANT ALL ON FUNCTIONS TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA storage GRANT ALL ON FUNCTIONS TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: storage; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA storage GRANT ALL ON TABLES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA storage GRANT ALL ON TABLES TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA storage GRANT ALL ON TABLES TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA storage GRANT ALL ON TABLES TO service_role;


--
-- Name: issue_graphql_placeholder; Type: EVENT TRIGGER; Schema: -; Owner: supabase_admin
--

CREATE EVENT TRIGGER issue_graphql_placeholder ON sql_drop
         WHEN TAG IN ('DROP EXTENSION')
   EXECUTE FUNCTION extensions.set_graphql_placeholder();


ALTER EVENT TRIGGER issue_graphql_placeholder OWNER TO supabase_admin;

--
-- Name: issue_pg_cron_access; Type: EVENT TRIGGER; Schema: -; Owner: supabase_admin
--

CREATE EVENT TRIGGER issue_pg_cron_access ON ddl_command_end
         WHEN TAG IN ('CREATE EXTENSION')
   EXECUTE FUNCTION extensions.grant_pg_cron_access();


ALTER EVENT TRIGGER issue_pg_cron_access OWNER TO supabase_admin;

--
-- Name: issue_pg_graphql_access; Type: EVENT TRIGGER; Schema: -; Owner: supabase_admin
--

CREATE EVENT TRIGGER issue_pg_graphql_access ON ddl_command_end
         WHEN TAG IN ('CREATE FUNCTION')
   EXECUTE FUNCTION extensions.grant_pg_graphql_access();


ALTER EVENT TRIGGER issue_pg_graphql_access OWNER TO supabase_admin;

--
-- Name: issue_pg_net_access; Type: EVENT TRIGGER; Schema: -; Owner: supabase_admin
--

CREATE EVENT TRIGGER issue_pg_net_access ON ddl_command_end
         WHEN TAG IN ('CREATE EXTENSION')
   EXECUTE FUNCTION extensions.grant_pg_net_access();


ALTER EVENT TRIGGER issue_pg_net_access OWNER TO supabase_admin;

--
-- Name: pgrst_ddl_watch; Type: EVENT TRIGGER; Schema: -; Owner: supabase_admin
--

CREATE EVENT TRIGGER pgrst_ddl_watch ON ddl_command_end
   EXECUTE FUNCTION extensions.pgrst_ddl_watch();


ALTER EVENT TRIGGER pgrst_ddl_watch OWNER TO supabase_admin;

--
-- Name: pgrst_drop_watch; Type: EVENT TRIGGER; Schema: -; Owner: supabase_admin
--

CREATE EVENT TRIGGER pgrst_drop_watch ON sql_drop
   EXECUTE FUNCTION extensions.pgrst_drop_watch();


ALTER EVENT TRIGGER pgrst_drop_watch OWNER TO supabase_admin;

--
-- PostgreSQL database dump complete
--

\unrestrict jz6ynGDl1qoqflsR4URhcw6jUFZfIN2quecsfvw73aFybv1Y47haJH5J6CZ0RQk

