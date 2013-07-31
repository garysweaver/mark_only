require 'test/unit'
require 'active_record'
require File.expand_path(File.dirname(__FILE__) + "/../lib/mark_only")

DELETED_MARK = 'deleted'
DB_FILE = 'tmp/test_db'

FileUtils.mkdir_p File.dirname DB_FILE
FileUtils.rm_f DB_FILE

ActiveRecord::Base.establish_connection :adapter => 'sqlite3', :database => DB_FILE
ActiveRecord::Base.connection.execute 'CREATE TABLE parent_models (id INTEGER NOT NULL PRIMARY KEY, some_marked_column VARCHAR(32))'
ActiveRecord::Base.connection.execute 'CREATE TABLE mark_only_models (id INTEGER NOT NULL PRIMARY KEY, some_marked_column VARCHAR(32))'
ActiveRecord::Base.connection.execute 'CREATE TABLE featureful_models (id INTEGER NOT NULL PRIMARY KEY, name VARCHAR(32), some_marked_column VARCHAR(32))'
ActiveRecord::Base.connection.execute 'CREATE TABLE child_models (id INTEGER NOT NULL PRIMARY KEY, parent_model_id INTEGER, some_marked_column VARCHAR(32))'
ActiveRecord::Base.connection.execute 'CREATE TABLE plain_models (id INTEGER NOT NULL PRIMARY KEY)'
ActiveRecord::Base.connection.execute 'CREATE TABLE callback_models (id INTEGER NOT NULL PRIMARY KEY, some_marked_column VARCHAR(32))'
ActiveRecord::Base.connection.execute 'CREATE TABLE related_models (id INTEGER NOT NULL PRIMARY KEY, parent_model_id INTEGER NOT NULL, some_marked_column VARCHAR(32))'
ActiveRecord::Base.connection.execute 'CREATE TABLE employers (id INTEGER NOT NULL PRIMARY KEY, some_marked_column VARCHAR(32))'
ActiveRecord::Base.connection.execute 'CREATE TABLE employees (id INTEGER NOT NULL PRIMARY KEY, some_marked_column VARCHAR(32))'
ActiveRecord::Base.connection.execute 'CREATE TABLE jobs (id INTEGER NOT NULL PRIMARY KEY, employer_id INTEGER NOT NULL, employee_id INTEGER NOT NULL, some_marked_column VARCHAR(32))'

class MarkOnlyTest < Test::Unit::TestCase

  def setup
    ActiveRecord::Base.connection.execute 'DELETE FROM parent_models'
    ActiveRecord::Base.connection.execute 'DELETE FROM mark_only_models'
    ActiveRecord::Base.connection.execute 'DELETE FROM featureful_models'
    ActiveRecord::Base.connection.execute 'DELETE FROM child_models'
    ActiveRecord::Base.connection.execute 'DELETE FROM plain_models'
    ActiveRecord::Base.connection.execute 'DELETE FROM callback_models'
    ActiveRecord::Base.connection.execute 'DELETE FROM related_models'
    ActiveRecord::Base.connection.execute 'DELETE FROM employers'
    ActiveRecord::Base.connection.execute 'DELETE FROM employees'
    ActiveRecord::Base.connection.execute 'DELETE FROM jobs'
  end

  # plain/unaltered

  def test_plain_class_has_delete
    assert_equal true,  PlainModel.respond_to?(:delete)
  end

  def test_plain_class_has_delete_all
    assert_equal true,  PlainModel.respond_to?(:delete_all)
  end

  def test_plain_instance_has_delete
    assert_equal true,  PlainModel.new.respond_to?(:delete)
  end

  def test_plain_instance_has_destroy
    assert_equal true,  PlainModel.new.respond_to?(:destroy)
  end

  def test_plain_model_instance_is_not_marked_mark_only
    assert_equal false, PlainModel.new.mark_only?
  end

  def test_plain_model_class_is_not_marked_mark_only
    assert_equal false, PlainModel.mark_only?
  end

  # mark_only
  
  def test_mark_only_model_instance_is_marked_mark_only
    assert_equal true, MarkOnlyModel.new.mark_only?
  end

  def test_mark_only_model_class_is_marked_mark_only
    assert_equal true, MarkOnlyModel.mark_only?
  end

  def test_mark_only_instance_delete
    model = MarkOnlyModel.new
    assert_equal 0, model.class.count
    model.save
    assert_equal 1, model.class.count
    assert_equal nil, model.some_marked_column
    model.delete
    assert_equal 1, model.class.count
    # won't work unless you reload model: assert_equal DELETED_MARK, model.some_marked_column
    assert_equal DELETED_MARK, model.class.where(id: model.id).first.some_marked_column
    assert_equal 1, ActiveRecord::Base.connection.select_all("SELECT count(*) as c FROM #{model.class.table_name} WHERE id = '#{model.id}' AND some_marked_column = '#{DELETED_MARK}'").first['c']
  end

  def test_mark_only_instance_destroy
    model = MarkOnlyModel.new
    assert_equal 0, model.class.count
    model.save
    assert_equal 1, model.class.count
    assert_equal nil, model.some_marked_column
    model.destroy
    assert_equal 1, model.class.count
    # won't work unless you reload model: assert_equal DELETED_MARK, model.some_marked_column
    assert_equal DELETED_MARK, model.class.where(id: model.id).first.some_marked_column
    assert_equal 1, ActiveRecord::Base.connection.select_all("SELECT count(*) as c FROM #{model.class.table_name} WHERE id = '#{model.id}' AND some_marked_column = '#{DELETED_MARK}'").first['c']
  end

  def test_mark_only_instance_destroy_bang_if_supported
    # destroy! implemented in Rails 4
    unless MarkOnlyModel.new.respond_to?(:destroy!)
      # skipping because model.destroy! not implemented
      return
    end

    begin
      model = MarkOnlyModel.new
      assert_equal 0, model.class.count
      model.save
      assert_equal 1, model.class.count
      assert_equal nil, model.some_marked_column
      # Rails 4 raises ActiveRecord::RecordNotDestroyed
      model.destroy!
      fail "should raise ActiveRecord::RecordNotDestroyed. destroy! implemented in #{model.method(:destroy!)}"
    rescue ActiveRecord::RecordNotDestroyed
      assert_equal 1, model.class.count
      # won't work unless you reload model: assert_equal DELETED_MARK, model.some_marked_column
      assert_equal DELETED_MARK, model.class.where(id: model.id).first.some_marked_column
      assert_equal 1, ActiveRecord::Base.connection.select_all("SELECT count(*) as c FROM #{model.class.table_name} WHERE id = '#{model.id}' AND some_marked_column = '#{DELETED_MARK}'").first['c']
    end
  end

  def test_mark_only_class_delete
    model = MarkOnlyModel.new
    assert_equal 0, model.class.count
    model.save
    assert_equal 1, model.class.count
    assert_equal nil, model.some_marked_column
    assert_equal false, model.class.where(id: model.id).first.deleted?
    MarkOnlyModel.delete(model.id)
    assert_equal 1, model.class.count
    # won't work unless you reload model: assert_equal DELETED_MARK, model.some_marked_column    
    assert_equal DELETED_MARK, model.class.where(id: model.id).first.some_marked_column
    assert_equal true, model.class.where(id: model.id).first.deleted?
    assert_equal 1, ActiveRecord::Base.connection.select_all("SELECT count(*) as c FROM #{model.class.table_name} WHERE id = '#{model.id}' AND some_marked_column = '#{DELETED_MARK}'").first['c']
  end

  def test_mark_only_class_delete_all
    model = MarkOnlyModel.new
    assert_equal 0, model.class.count
    model.save
    assert_equal 1, model.class.count
    assert_equal nil, model.some_marked_column
    MarkOnlyModel.delete_all
    assert_equal 1, model.class.count
    # won't work unless you reload model: assert_equal DELETED_MARK, model.some_marked_column
    assert_equal DELETED_MARK, model.class.where(id: model.id).first.some_marked_column
    assert_equal 1, ActiveRecord::Base.connection.select_all("SELECT count(*) as c FROM #{model.class.table_name} WHERE id = '#{model.id}' AND some_marked_column = '#{DELETED_MARK}'").first['c']
  end

  def test_mark_only_to_param_destroy
    model = MarkOnlyModel.new
    assert_equal 0, model.class.count
    model.save
    to_param = model.to_param
    assert_equal 1, model.class.count
    model.destroy
    assert_not_equal nil, model.to_param
    assert_equal to_param, model.to_param
    # won't work unless you reload model: assert_equal DELETED_MARK, model.some_marked_column
    assert_equal DELETED_MARK, model.class.where(id: model.id).first.some_marked_column
    assert_equal 1, ActiveRecord::Base.connection.select_all("SELECT count(*) as c FROM #{model.class.table_name} WHERE id = '#{model.id}' AND some_marked_column = '#{DELETED_MARK}'").first['c']
  end

  def test_mark_only_scoping
    parent1 = ParentModel.create
    parent2 = ParentModel.create
    p1 = ChildModel.create(:parent_model => parent1)
    p2 = ChildModel.create(:parent_model => parent2)
    p1.destroy
    p2.destroy
    assert_equal 1, parent1.child_models.count
    p3 = ChildModel.create(:parent_model => parent1)
    assert_equal 2, parent1.child_models.count
    assert_equal [p1,p3], parent1.child_models
  end

  def test_mark_only_featureful_destroy
    model = FeaturefulModel.new(:name => "not empty")
    assert_equal 0, model.class.count
    model.save!
    assert_equal 1, model.class.count
    model.destroy
    assert_equal 1, model.class.count
  end

  def test_has_many_destroy
    parent = ParentModel.create
    assert_equal 0, parent.related_models.count
    child = parent.related_models.create
    assert_equal 1, parent.related_models.count
    child.destroy
    assert_equal 1, parent.related_models.count
  end

  def test_has_many_through_destroy
    employer = Employer.create
    employee = Employee.create
    assert_equal 0, employer.jobs.count
    assert_equal 0, employer.employees.count
    assert_equal 0, employee.jobs.count
    assert_equal 0, employee.employers.count
    job = Job.create :employer => employer, :employee => employee
    assert_equal 1, employer.jobs.count
    assert_equal 1, employer.employees.count
    assert_equal 1, employee.jobs.count
    assert_equal 1, employee.employers.count
    employee2 = Employee.create
    job2 = Job.create :employer => employer, :employee => employee2
    employee2.destroy
    assert_equal 2, employer.jobs.count
    assert_equal 2, employer.employees.count
    job.destroy
    assert_equal 2, employer.jobs.count
    assert_equal 2, employer.employees.count
  end

  def test_no_callback_on_instance_delete
    model = CallbackModel.new
    model.save
    model.delete
    assert_equal nil, model.instance_variable_get(:@callback_called)
  end

  def test_does_callback_on_instance_destroy
    model = CallbackModel.new
    model.save
    model.destroy
    assert model.instance_variable_get(:@callback_called)
  end

  # relational methods

  def test_mark_only_where_delete_id
    model = MarkOnlyModel.new
    model.save
    assert_equal 1, model.class.count
    assert_equal nil, model.some_marked_column
    MarkOnlyModel.where('').delete(model.id)
    assert_equal 1, model.class.count
    # won't work unless you reload model: assert_equal DELETED_MARK, model.some_marked_column
    assert_equal DELETED_MARK, model.class.where(id: model.id).first.some_marked_column
    assert_equal 1, ActiveRecord::Base.connection.select_all("SELECT count(*) as c FROM #{model.class.table_name} WHERE id = '#{model.id}' AND some_marked_column = '#{DELETED_MARK}'").first['c']
  end

  def test_mark_only_where_delete_ids
    model = MarkOnlyModel.new
    model.save
    assert_equal 1, model.class.count
    assert_equal nil, model.some_marked_column
    MarkOnlyModel.where('').delete([model.id])
    assert_equal 1, model.class.count
    # won't work unless you reload model: assert_equal DELETED_MARK, model.some_marked_column
    assert_equal DELETED_MARK, model.class.where(id: model.id).first.some_marked_column
    assert_equal 1, ActiveRecord::Base.connection.select_all("SELECT count(*) as c FROM #{model.class.table_name} WHERE id = '#{model.id}' AND some_marked_column = '#{DELETED_MARK}'").first['c']
  end

  def test_mark_only_where_delete_all
    model = MarkOnlyModel.new
    model.save
    assert_equal 1, model.class.count
    assert_equal nil, model.some_marked_column
    MarkOnlyModel.where('').delete_all
    assert_equal 1, model.class.count
    # won't work unless you reload model: assert_equal DELETED_MARK, model.some_marked_column
    assert_equal DELETED_MARK, model.class.where(id: model.id).first.some_marked_column
    assert_equal 1, ActiveRecord::Base.connection.select_all("SELECT count(*) as c FROM #{model.class.table_name} WHERE id = '#{model.id}' AND some_marked_column = '#{DELETED_MARK}'").first['c']
  end

  def test_mark_only_where_destroy_id
    model = MarkOnlyModel.new
    model.save
    assert_equal 1, model.class.count
    assert_equal nil, model.some_marked_column
    MarkOnlyModel.where('').destroy(model.id)
    assert_equal 1, model.class.count
    # won't work unless you reload model: assert_equal DELETED_MARK, model.some_marked_column
    assert_equal DELETED_MARK, model.class.where(id: model.id).first.some_marked_column
    assert_equal 1, ActiveRecord::Base.connection.select_all("SELECT count(*) as c FROM #{model.class.table_name} WHERE id = '#{model.id}' AND some_marked_column = '#{DELETED_MARK}'").first['c']
  end

  def test_mark_only_where_destroy_all
    model = MarkOnlyModel.new
    model.save
    assert_equal 1, model.class.count
    assert_equal nil, model.some_marked_column
    MarkOnlyModel.where('').destroy_all
    assert_equal 1, model.class.count
    # won't work unless you reload model: assert_equal DELETED_MARK, model.some_marked_column
    assert_equal DELETED_MARK, model.class.where(id: model.id).first.some_marked_column
    assert_equal 1, ActiveRecord::Base.connection.select_all("SELECT count(*) as c FROM #{model.class.table_name} WHERE id = '#{model.id}' AND some_marked_column = '#{DELETED_MARK}'").first['c']
  end

end

# Helper classes

class PlainModel < ActiveRecord::Base
end

class ParentModel < ActiveRecord::Base
  mark_only :some_marked_column
  has_many :related_models
  has_many :child_models
end

class ChildModel < ActiveRecord::Base
  belongs_to :parent_model
  mark_only :some_marked_column
end

class RelatedModel < ActiveRecord::Base
  mark_only :some_marked_column
  belongs_to :parent_model
end

class Employer < ActiveRecord::Base
  mark_only :some_marked_column
  has_many :jobs
  has_many :employees, :through => :jobs
end

class Employee < ActiveRecord::Base
  mark_only :some_marked_column
  has_many :jobs
  has_many :employers, :through => :jobs
end

class Job < ActiveRecord::Base
  mark_only :some_marked_column
  belongs_to :employer
  belongs_to :employee
end

class MarkOnlyModel < ActiveRecord::Base
  mark_only :some_marked_column
end

class FeaturefulModel < ActiveRecord::Base
  mark_only :some_marked_column
  validates :name, :presence => true, :uniqueness => true
end

class CallbackModel < ActiveRecord::Base
  mark_only :some_marked_column
  before_destroy {|model| model.instance_variable_set :@callback_called, true }
end

