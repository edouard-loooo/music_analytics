{% macro normalize_artist_name(column_name) %}
    normalize_and_casefold(trim(
        regexp_replace(
            regexp_replace(
                {{ column_name }}, 
                r'\p{Pd}', '-'),
            r'[\x{2018}\x{2019}\x{02BC}\x{0060}\x{00B4}]', "'")
        ), NFKC)
{% endmacro %}