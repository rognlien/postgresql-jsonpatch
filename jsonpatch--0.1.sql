-- This script should only be called by CREATE EXTENSION only
\echo Use "CREATE EXTENSION jsonpatch" to load this file. \quit

CREATE TYPE jsonb_patch_op AS ENUM ('add', 'replace', 'remove');

CREATE OR REPLACE FUNCTION jsonb_patch(target jsonb, operation jsonb_patch_op, path text[], value jsonb)
  RETURNS jsonb AS $$

  BEGIN
    CASE operation
      WHEN 'add' THEN
        RETURN jsonb_patch_add(target, path, value);
      WHEN 'replace' THEN
        RETURN jsonb_patch_replace(target, path);
      WHEN 'remove' THEN
        RETURN jsonb_patch_remove(target, path);
      ELSE
        RETURN NULL;
    END CASE;

  END;
$$ LANGUAGE plpgsql STRICT IMMUTABLE;



CREATE OR REPLACE FUNCTION jsonb_patch_add(target jsonb, path text[], value jsonb)
  RETURNS jsonb AS $$
  BEGIN
    IF target #> path IS NOT NULL THEN
      --RAISE NOTICE 'The path % exists', path;
    ELSE
      --RAISE NOTICE 'The path % does not exist', path;
      target := jsonb_set(target, path[1:1], '{}'::jsonb, true);
  END IF;

  RETURN jsonb_set(target, path, value, true);
END;
$$ LANGUAGE plpgsql STRICT IMMUTABLE;


CREATE OR REPLACE FUNCTION jsonb_patch_replace(target jsonb, path text[], value jsonb)
  RETURNS jsonb AS $$
BEGIN
  IF target #> path IS NOT NULL THEN
  --RAISE NOTICE 'The path % exists', path;
  ELSE
    --RAISE NOTICE 'The path % does not exist', path;
    target := jsonb_set(target, path[1:1], '{}'::jsonb, true);
  END IF;

  RETURN jsonb_set(target, path, value, true);
END;
$$ LANGUAGE plpgsql STRICT IMMUTABLE;


CREATE OR REPLACE FUNCTION jsonb_patch_remove(target jsonb, path text[])
  RETURNS jsonb AS $$
  BEGIN
    RAISE NOTICE 'Removing %', path;
    RETURN target #- path;
  END;
$$ LANGUAGE plpgsql STRICT IMMUTABLE;




CREATE AGGREGATE json_patch_agg(operation jsonb_patch_op, path text[], value jsonb) (
sfunc = jsonb_patch
  ,stype = jsonb
  ,initcond = '{}'
);