require_relative '02_searchable'
require 'active_support/inflector'

# Phase IIIa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    # ...
    @class_name.constantize
  end

  def table_name
    # ...
    @class_name.downcase + "s"
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    # ...
    hash = {
      :class_name => name.to_s.camelcase,
      :foreign_key => "#{name}_id".to_sym,
      :primary_key => :id
    }
    
    hash.keys.each do |key|
      self.send("#{key}=", options[key] || hash[key])
    end
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    # ...

    hash = {
      :foreign_key => "#{self_class_name.downcase}_id".to_sym,
      :class_name => name.to_s.singularize.camelcase,
      :primary_key => :id
      
    }
    hash.keys.each do |key|
      self.send("#{key}=", options[key] || hash[key])
    end
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    # ...
    options = BelongsToOptions.new(name, options)

    self.define_method(name) do
      foreign_key = self.send(options.foreign_key)
      target_model_class = options.model_class
      target_model_class.where(id: foreign_key).first
    end

  end

  def has_many(name, options = {})
    # ...
    options = HasManyOptions.new(name, self.name, options)

    self.define_method(name) do
      foreign_key = self.send(options.primary_key)
      target_model_class = options.model_class
      target_model_class.where(options.foreign_key =>foreign_key)
    end
  end

  def assoc_options
    # Wait to implement this in Phase IVa. Modify `belongs_to`, too.
  end
end

class SQLObject
  # Mixin Associatable here...
  extend Associatable
end
