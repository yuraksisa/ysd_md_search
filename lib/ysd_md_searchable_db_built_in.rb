module Model
  module Searchable	
    #
    #
    #
    module DbBuiltIn

      def search(q, options={})
        search_db_built_in_strategy.search(q, options)
      end

      def auto_migrate_up!(repository_name)
        super
        search_db_built_in_strategy.auto_migrate_up!(repository_name)
      end

      def auto_upgrade!(repository_name)
        super
        search_db_built_in_strategy.auto_upgrade!(repository_name)
      end

      private 
    
      #
      # Get the strategy
      #
      def search_db_built_in_strategy
     
        @search_built_in_strategy ||= if DataMapper::Adapters.const_defined?(:PostgresAdapter) and repository.adapter.is_a?DataMapper::Adapters::PostgresAdapter
                                      PostgresBuiltInStrategy.new(self)
                                    else
                                      if DataMapper::Adapters.const_defined?(:MysqlAdapter) and repository.adapter.is_a?DataMapper::Adapters::MysqlAdapter
                                        MysqlBuiltInStrategy.new(self)
                                      else
                                        if DataMapper::Adapters.const_defined?(:SqliteAdapter) and repository.adapter.is_a?DataMapper::Adapters::SqliteAdapter
                                          SQLiteBuiltInStrategy.new(self)
                                        end
                                      end
                                    end

      end
    end

  end
end