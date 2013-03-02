# https://gist.github.com/865099
# Mix this module into a DataMapper::Resource to get fast, indexed full
# text searching.
# 
#   class Post
#     include DataMapper::Resource
#     include Searchable
# 
#     property :title, String
#     property :body,  Text
# 
#     searchable [:title, :body]
#     searchable [:title], :index => :title_only
#   end
# 
#   Post.search("hello")
#   Post.search("hello", :index => :title_only)
#
# This code could potentially be extracted to a gem
module Model
  module Searchable
    
    def self.included(model)
    
      model.extend ClassMethods
      configure_search_strategy(model)

    end
    
    #
    # Set up the configuration
    #
    def self.configure(opts={})
      self.configuration.replace(opts)
    end
    
    #
    # Get the searchable configuration
    #
    def self.configuration
      @configuration ||= {:language => :es, :default_strategy => :db_built_in}
    end

    module ClassMethods

      #
      # Define the searchable (indexable) columns
      #      
      def searchable(columns, opts = {})
        opts[:index] ||= 'search'
        indexes[opts[:index]] = columns
      end
      
      #
      # Get all defined indexes
      #
      # @return [Hash]
      def indexes
        @__indexes ||= {}
      end

    end
          
    private

    #
    #
    #
    def self.configure_search_strategy(klass)
      
      strategy_class = configuration[:default_strategy].to_s.split("_").map{|item|item.capitalize}.join("")

      if self.const_defined?(strategy_class)
        klass.extend (self.const_get(strategy_class.to_sym))
      else
        klass.extend (self.const_get("db_built_in".split("_").map{|item|item.capitalize}.join("")))
      end 
      
    end

  end # Searchable
end # Model