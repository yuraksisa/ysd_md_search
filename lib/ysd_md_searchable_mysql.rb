module Model
  module Searchable
  	module DBBuiltIn
      #
      # Mysql full text search strategy
      #
      class MySQLBuiltInStrategy
        
        def initialize(searchable)
          @searchable = searchable
        end    	
      
        def search(q, opts={})
        end
      
        def auto_migrate_up!(repository_name)
        end
      
        def auto_upgrade!(repository_name)
        end

        private

        def searchable
      	  @searchable
        end

      end
    end
  end
end