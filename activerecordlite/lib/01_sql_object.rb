require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    # ...
    return @columns if @columns
    query = DBConnection.execute2(<<-SQL).first
      SELECT 
        * 
      FROM 
        #{self.table_name} 
      LIMIT 0
      SQL
    
    @columns = query.map(&:to_sym)
  end

  def self.finalize!
    self.columns.each do |name|

      define_method(name) do
        self.attributes[name]
      end

      define_method("#{name}=") do |x|
        self.attributes[name] = x
      end

    end
  end

  def self.table_name=(table_name)
    # ...
    @table_name = table_name
  end

  def self.table_name
    # ...
    @table_name ? @table_name : "#{self.to_s.tableize}"
  end

  def self.all
    # ...

    query = DBConnection.execute(<<-SQL)
    SELECT 
      *
    FROM 
      "#{self.table_name}"
    SQL

    self.parse_all(query)
  end

  def self.parse_all(results)
    # ...
    results.map do |result|
      self.new(result)
    end

  end

  def self.find(id)
    # ...

    query = DBConnection.execute(<<-SQL, id)
    SELECT
      *
    FROM
      #{table_name}
    WHERE
      #{table_name}.id = ?
    LIMIT 1
    SQL

    self.parse_all(query).first
  end

  def initialize(params = {})
    # ...
    params.each do |k, v|
      sym = k.to_sym
      if self.class.columns.include?(sym)
        self.send("#{sym}=", v)
      else
        raise "unknown attribute '#{sym}'"
      end
    end
  end

  def attributes
    # ...
    @attributes ||= {}
  end

  def attribute_values
    # ...
    self.class.columns.map{|attr| self.send(attr)}
  end

  def insert
    # ...
    col_names = self.class.columns.drop(1).map(&:to_s).join(",")
    question_marks = []
    
    self.attribute_values.drop(1).length.times do
      question_marks << "?"
    end

    question_marks = question_marks.join(", ")

    DBConnection.execute(<<-SQL, *self.attribute_values.drop(1))
    INSERT INTO
      #{self.class.table_name} (#{col_names})
    VALUES
      (#{question_marks})
    SQL

    self.id = DBConnection.last_insert_row_id
  end

  def update
    # ...
    set_line = self.class.columns.map{|attr| "#{attr} = ?"}.join(", ")

    DBConnection.execute(<<-SQL, *attribute_values, id)
    UPDATE
      #{self.class.table_name}
    SET
      #{set_line}
    WHERE
      #{self.class.table_name}.id = ?
    SQL
  end

  def save
    # ...
    id.nil? ? insert : update
  end
end
