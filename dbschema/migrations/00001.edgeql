CREATE MIGRATION m1n43cqm4jcp245dgjsjqem5zkpoxnl6entyt4f3iuuu7katdz5aiq
    ONTO initial
{
  CREATE FUNCTION default::str_clean(string: std::str) -> OPTIONAL std::str USING (WITH
      trimmed := 
          std::str_trim(string, ' \t\r\n')
  SELECT
      (IF (std::len(trimmed) > 0) THEN trimmed ELSE <std::str>{})
  );
  CREATE ABSTRACT TYPE default::Named {
      CREATE REQUIRED PROPERTY name: std::str {
          CREATE REWRITE
              INSERT 
              USING (default::str_clean(.name));
          CREATE REWRITE
              UPDATE 
              USING (default::str_clean(.name));
      };
      CREATE INDEX fts::index ON (fts::with_options(.name, language := fts::Language.eng));
  };
  CREATE FUNCTION default::str_sortable(value: std::str) ->  std::str USING (std::str_lower(std::re_replace('Ñ', 'N', std::str_trim(std::re_replace(r'[ [\]|,\-$]+', ' ', value, flags := 'g')), flags := 'g')));
  CREATE TYPE default::Language EXTENDING default::Named;
  ALTER TYPE default::Named {
      CREATE INDEX ON (default::str_sortable(.name));
  };
  CREATE ABSTRACT TYPE default::Project EXTENDING default::Named {
      ALTER PROPERTY name {
          SET OWNED;
          CREATE CONSTRAINT std::exclusive;
      };
  };
  CREATE TYPE default::TranslationProject EXTENDING default::Project;
  CREATE TYPE default::LanguageEngagement {
      CREATE REQUIRED LINK language: default::Language {
          SET readonly := true;
      };
      CREATE REQUIRED LINK project: default::TranslationProject;
      CREATE CONSTRAINT std::exclusive ON ((.project, .language));
  };
  ALTER TYPE default::TranslationProject {
      CREATE MULTI LINK engagements := (.<project[IS default::LanguageEngagement]);
      CREATE MULTI LINK languages := (.engagements.language);
  };
  ALTER TYPE default::Language {
      CREATE LINK projects := (SELECT
          default::TranslationProject
      FILTER
          (__source__ = .languages)
      );
  };
};
