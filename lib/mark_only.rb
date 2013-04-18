require 'mark_only/version'

module MarkOnly
  class << self
    [:deleted_value, :active_value].each{|o|attr_accessor o}
    def configure(&blk); class_eval(&blk); end
  end

  def self.included(klazz)
    klazz.extend Query
  end

  module Query
    def mark_only? ; true ; end
  end

  def destroy
    run_callbacks(:destroy) { delete }
  end

  def delete
    update_attribute_or_column(self.mark_only_column, MarkOnly.deleted_value) if !deleted? && persisted?
  rescue => e
    logger.error("failed to set #{self.mark_only_column} to #{MarkOnly.deleted_value} in #{self}", e)
    raise e
  end

  def restore!
    update_attribute_or_column self.mark_only_column, MarkOnly.active_value
  rescue => e
    logger.error("failed to set #{self.mark_only_column} to #{MarkOnly.active_value} in #{self}", e)
    raise e
  end

  def destroyed?
    self.send(self.mark_only_column.to_sym) == MarkOnly.deleted_value
  end
  alias :deleted? :destroyed?

  private

  # Rails 3.1 adds update_column. Rails > 3.2.6 deprecates update_attribute, gone in Rails 4.
  def update_attribute_or_column(*args)
    respond_to?(:update_column) ? update_column(*args) : update_attribute(*args)
  end
end

MarkOnly.configure do
  self.active_value = 'active'
  self.deleted_value = 'deleted'
end

class ActiveRecord::Base
  def self.mark_only(col_name)
    raise "#{self} must call mark_only with a column name!" unless col_name
    class_attribute :mark_only_column, instance_writer: true
    self.mark_only_column = col_name.to_sym
    alias :destroy! :destroy
    alias :delete!  :delete
    include MarkOnly
  end

  def self.mark_only? ; false ; end
  def mark_only? ; self.class.mark_only? ; end

  # Override the persisted method to allow for the paranoia gem.
  # If a mark_only record is selected, then we only want to check
  # if it's a new record, not if it is "destroyed".
  def persisted?
    mark_only? ? !new_record? : super
  end
end
