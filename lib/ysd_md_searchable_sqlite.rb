module Model
  module Searchable
    module DbBuiltIn
      #
      # Sqlite full text search strategy
      #
      class SQLiteBuiltInStrategy

        def initialize(searchable)
          @searchable = searchable
        end

        #
        # Performs a search
        #
        def search(q, opts = {})
          opts[:index] ||= 'search' 
          finder = searchable.all(opts.select{|key, value| not [:index, :condition].include?key}.merge(:conditions => index_search_condition(opts[:index], q)))
          finder &= searchable.all(opts[:conditions]) if opts[:conditions]
          finder
        end

        #
        # auto migrate
        # 
        def auto_migrate_up!(repository_name)

          searchable.indexes.each do |name, columns|

            [
             create_virtual_table_sql(repository_name, name, columns),
             create_trigger_insert_sql(repository_name, name, columns),
             create_trigger_update_sql(repository_name, name, columns)
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
      
            next if searchable.repository(repository_name).adapter.storage_exists?("#{searchable.storage_name(repository_name)}_#{name}")
 
            [
             create_virtual_table_sql(repository_name, name, columns),
             create_trigger_insert_sql(repository_name, name, columns),
             create_trigger_update_sql(repository_name, name, columns)
            ].each do |sql|
              searchable.repository(repository_name).adapter.execute sql
            end

          end
        end

        private

        def searchable
      	  @searchable
        end

        def index_search_condition(index, search_text)

           ["exists (select * from #{searchable.storage_name(searchable.repository_name)}_#{index}_index where #{searchable.storage_name(searchable.repository_name)}_#{index}_index match ?)", search_text]

        end	

        def create_virtual_table_sql(repository_name, name, columns)
          <<-EOS
            CREATE VIRTUAL TABLE #{searchable.storage_name(repository_name)}_#{name}_index using fts3 (#{column_sql(columns)}); 
          EOS
        end

        def create_trigger_insert_sql(repository_name, name, columns)
          <<-EOS
            CREATE TRIGGER #{searchable.storage_name(repository_name)}_#{name}_insert_search_index 
              AFTER INSERT ON #{searchable.storage_name(repository_name)} FOR EACH ROW 
                BEGIN
                  INSERT INTO #{searchable.storage_name(repository_name)}_#{name}_index (#{column_sql(columns)}) VALUES (#{columns_insert_values(columns)});
                END;
          EOS
        end

        def create_trigger_update_sql(repository_name, name, columns)
          <<-EOS
            CREATE TRIGGER #{searchable.storage_name(repository_name)}_#{name}_update_search_index 
              AFTER UPDATE ON #{searchable.storage_name(repository_name)} FOR EACH ROW 
                BEGIN
                  UPDATE #{searchable.storage_name(repository_name)}_#{name}_index SET #{column_updates(columns)} WHERE #{key_conditions_for_update};
                END;
          EOS
        end
      
        #
        # Get all the sql columns (includying keys)
        #
        def column_sql(columns)
          searchable.key.map {|key_property| key_property.field}.concat(columns.map {|column| searchable.send(column).field }).join(", ")
        end
      
        #
        # Get all the insert values
        #
        def columns_insert_values(columns)
          searchable.key.map {|key_property| "new.#{key_property.field}" }.concat(columns.map {|column| "new.#{searchable.send(column).field}" }).join(", ") 
        end

        #
        # Get the key conditions
        #
        def key_conditions_for_update
          searchable.key.map {|key_property| "#{key_property.field} = new.#{key_property.field}" }.join(" AND ")
        end
      
        #
        # Get the column updates
        #
        def column_updates(columns)
          columns.map {|column| "#{searchable.send(column).field} = new.#{searchable.send(column).field}" }.join(", ")
        end
      end
    end
  end
end