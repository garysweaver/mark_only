require 'test/unit'
require 'active_record'
require File.expand_path(File.dirname(__FILE__) + "/../lib/mark_only")

DB_FILE = 'tmp/test_db'

# keep these in sync with the defaults in configuration. in both places so we can ensure what we are checking!
ACTIVE_MARK = 'active'
DELETED_MARK = 'deleted'

FileUtils.mkdir_p File.dirname(DB_FILE)
FileUtils.rm_f DB_FILE

ActiveRecord::Base.establish_connection :adapter => 'sqlite3', :database => DB_FILE
ActiveRecord::Base.connection.execute 'CREATE TABLE parent_models (id INTEGER NOT NULL PRIMARY KEY, some_marked_column VARCHAR(32))'
ActiveRecord::Base.connection.execute 'CREATE TABLE mark_only_models (id INTEGER NOT NULL PRIMARY KEY, parent_model_id INTEGER, some_marked_column VARCHAR(32))'
ActiveRecord::Base.connection.execute 'CREATE TABLE featureful_models (id INTEGER NOT NULL PRIMARY KEY, some_marked_column VARCHAR(32), name VARCHAR(32))'
ActiveRecord::Base.connection.execute 'CREATE TABLE plain_models (id INTEGER NOT NULL PRIMARY KEY, some_marked_column VARCHAR(32))'
ActiveRecord::Base.connection.execute 'CREATE TABLE callback_models (id INTEGER NOT NULL PRIMARY KEY, some_marked_column VARCHAR(32))'
ActiveRecord::Base.connection.execute 'CREATE TABLE related_models (id INTEGER NOT NULL PRIMARY KEY, parent_model_id INTEGER NOT NULL, some_marked_column VARCHAR(32))'
ActiveRecord::Base.connection.execute 'CREATE TABLE employers (id INTEGER NOT NULL PRIMARY KEY, some_marked_column VARCHAR(32))'
ActiveRecord::Base.connection.execute 'CREATE TABLE employees (id INTEGER NOT NULL PRIMARY KEY, some_marked_column VARCHAR(32))'
ActiveRecord::Base.connection.execute 'CREATE TABLE jobs (id INTEGER NOT NULL PRIMARY KEY, employer_id INTEGER NOT NULL, employee_id INTEGER NOT NULL, some_marked_column VARCHAR(32))'

class MarkOnlyTest < Test::Unit::TestCase
  def test_plain_model_class_is_not_mark_only
    assert_equal false, PlainModel.mark_only?
  end

  def test_mark_only_model_class_is_mark_only
    assert_equal true, MarkOnlyModel.mark_only?
  end

  def test_plain_models_are_not_mark_only
    assert_equal false, PlainModel.new.mark_only?
  end

  def test_mark_only_models_are_mark_only
    assert_equal true, MarkOnlyModel.new.mark_only?
  end

  def test_mark_only_models_to_param
    model = MarkOnlyModel.new
    model.save
    to_param = model.to_param

    model.destroy

    assert_not_equal nil, model.to_param
    assert_equal to_param, model.to_param
  end

  def test_destroy_behavior_for_plain_models
    model = PlainModel.new
    assert_equal 0, model.class.count
    model.save!
    assert_equal 1, model.class.count
    model.destroy

    assert_equal nil, model.some_marked_column

    assert_equal 0, model.class.count

  end

  def test_destroy_behavior_for_mark_only_models
    MarkOnlyModel.delete_all
    model = MarkOnlyModel.new
    assert_equal 0, model.class.count
    model.save!
    assert_equal 1, model.class.count
    model.destroy

    assert_equal DELETED_MARK, model.some_marked_column

    assert_equal 1, model.class.count
  end
  
  def test_scoping_behavior_for_mark_only_models
    MarkOnlyModel.delete_all
    parent1 = ParentModel.create
    parent2 = ParentModel.create
    p1 = MarkOnlyModel.create(:parent_model => parent1)
    p2 = MarkOnlyModel.create(:parent_model => parent2)
    p1.destroy
    p2.destroy
    assert_equal 1, parent1.mark_only_models.count
    p3 = MarkOnlyModel.create(:parent_model => parent1)
    assert_equal 2, parent1.mark_only_models.count
    assert_equal [p1,p3], parent1.mark_only_models
  end

  def test_destroy_behavior_for_featureful_mark_only_models
    model = get_featureful_model
    assert_equal 0, model.class.count
    model.save!
    assert_equal 1, model.class.count
    model.destroy

    assert_equal DELETED_MARK, model.some_marked_column

    assert_equal 1, model.class.count
  end

  def test_has_many_relationships
    parent = ParentModel.create
    assert_equal 0, parent.related_models.count

    child = parent.related_models.create
    assert_equal 1, parent.related_models.count

    child.destroy
    assert_equal DELETED_MARK, child.some_marked_column

    assert_equal 1, parent.related_models.count
  end

  def test_has_many_through_relationships
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

  def test_delete_behavior_for_callbacks
    model = CallbackModel.new
    model.save
    model.delete
    assert_equal nil, model.instance_variable_get(:@callback_called)
  end

  def test_destroy_behavior_for_callbacks
    model = CallbackModel.new
    model.save
    model.destroy
    assert model.instance_variable_get(:@callback_called)
  end

  def test_restore
    model = MarkOnlyModel.new
    model.save
    id = model.id
    model.destroy

    assert_equal DELETED_MARK, model.some_marked_column
    assert model.destroyed?

    model = MarkOnlyModel.find(id)
    model.restore!
    model.reload

    assert_equal ACTIVE_MARK, model.some_marked_column
    assert_equal false, model.destroyed?
  end

  def test_real_destroy
    model = MarkOnlyModel.new
    model.save
    model.destroy!

    assert_equal false, MarkOnlyModel.exists?(model.id)
  end

  def test_real_delete
    model = MarkOnlyModel.new
    model.save
    model.delete!

    assert_equal false, MarkOnlyModel.exists?(model.id)
  end

  private
  def get_featureful_model
    FeaturefulModel.new(:name => "not empty")
  end
end

# Helper classes

class ParentModel < ActiveRecord::Base
  has_many :mark_only_models
end

class MarkOnlyModel < ActiveRecord::Base
  belongs_to :parent_model
  mark_only :some_marked_column
end

class FeaturefulModel < ActiveRecord::Base
  mark_only :some_marked_column
  validates :name, :presence => true, :uniqueness => true
end

class PlainModel < ActiveRecord::Base
end

class CallbackModel < ActiveRecord::Base
  mark_only :some_marked_column
  before_destroy {|model| model.instance_variable_set :@callback_called, true }
end

class ParentModel < ActiveRecord::Base
  mark_only :some_marked_column
  has_many :related_models
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
