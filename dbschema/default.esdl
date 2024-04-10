module default {
  abstract type Named {
    required name: str {
      rewrite insert, update using (default::str_clean(.name));
    };

    index on (default::str_sortable(.name));

    index fts::index on (
      fts::with_options(
        .name,
        language := fts::Language.eng,
      )
    );
  }

  # Helper function to workaround native support for sort ignoring accents
  # https://stackoverflow.com/a/11007216
  # https://github.com/edgedb/edgedb/issues/386
  function str_sortable(value: str) -> str
  using (
    str_lower(
      re_replace('Ñ', 'N',
        str_trim(re_replace('[ [\\]|,\\-$]+', ' ', value, flags := 'g')),
        flags := 'g'
       )
    )
  );

  function str_clean(string: str) -> optional str
    using(
      with trimmed := str_trim(string, " \t\r\n")
      select if len(trimmed) > 0 then trimmed else <str>{}
    );

  abstract type Project extending Named {
    overloaded name {
      constraint exclusive;
    };
  }

  type TranslationProject extending Project {
    multi link engagements := .<project[is LanguageEngagement];
    multi link languages := .engagements.language;
  }

  type Language extending Named {
    projects := (
      select TranslationProject filter __source__ = .languages
    );
  }

  type LanguageEngagement {
    required project: TranslationProject;

    required language: Language {
      readonly := true;
    }
    constraint exclusive on ((.project, .language));
  }
}
