module Model
  module Searchable
  	module DbBuiltIn
      #
      # Postgres full text search strategy
      #
      class PostgresBuiltInStrategy

        def initialize(searchable)
          @searchable = searchable
        end

        #
        # Performs a search
        #
        def search(q, opts = {})
          opts[:index] ||= 'search'
          finder = searchable.all(opts.select{|key, value| not [:index, :condition].include?key}.merge(:conditions => ["#{opts[:index]}_vector @@ plainto_tsquery('#{postgres_dictionary}', ?)", q]))
          finder &= searchable.all(opts[:conditions]) if opts[:conditions]
          finder
        end

        #
        # auto migrate
        # 
        def auto_migrate_up!(repository_name)

          searchable.indexes.each do |name, columns|
            [
              create_alter_table_sql(repository_name, name),
              create_index_sql(repository_name, name),
              create_trigger_sql(repository_name, name, columns)
            ].each do |sql|
              searchable.repository(repository_name).adapter.execute sql
            end
          end
        end

        #
        # auto upgrade
        # 
        def auto_upgrade!(repository_name)

          searchable.indexes.each do |name, columns|
      
            next if searchable.repository(repository_name).adapter.field_exists?(
              searchable.storage_name(repository_name),
              "#{name}_vector"
            )

            [
              create_alter_table_sql(repository_name, name),
              create_index_sql(repository_name, name),
              create_trigger_sql(repository_name, name, columns)
            ].each do |sql|
              searchable.repository(repository_name).adapter.execute sql
            end
          end
        end

        private

        def searchable
          @searchable
        end

        def postgres_dictionary

          dictionary = case Model::Searchable.configuration[:language].to_s
            when 'es'
              'spanish'
            when 'en'
              'english'
            else
              'english'
          end

          return dictionary

        end

        def create_alter_table_sql(repository_name, name)
          <<-EOS
            ALTER TABLE #{searchable.storage_name(repository_name)} 
              ADD COLUMN #{name}_vector tsvector NOT NULL default to_tsvector('')
          EOS
        end

        def create_index_sql(repository_name, name)
          <<-EOS
            CREATE INDEX #{searchable.storage_name(repository_name)}_#{name}_vector_idx
              ON #{searchable.storage_name(repository_name)} USING gin(#{name}_vector)
          EOS
        end

        def create_trigger_sql(repository_name, name, columns)
          <<-EOS
            CREATE TRIGGER #{searchable.storage_name(repository_name)}_#{name}_vector_refresh 
              BEFORE INSERT OR UPDATE ON #{searchable.storage_name(repository_name)} 
               FOR EACH ROW EXECUTE PROCEDURE
                 tsvector_update_trigger(#{name}_vector, 'pg_catalog.#{postgres_dictionary}', #{column_sql(columns)});
          EOS
        end

        def column_sql(columns)
          columns.map {|column| searchable.send(column).field }.join(", ")
        end

      end
    end
  end
end