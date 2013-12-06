require 'mark_only/version'

module MarkOnly
  class << self
    attr_accessor :debug, :deleted_value, :enabled
    def configure(&blk)
      class_eval(&blk)
    end
  end

  extend ActiveSupport::Concern

  module ClassMethods
    def mark_only?
      true
    end
    
    def delete(id_or_array)
      return super(id_or_array) unless !!::MarkOnly.enabled
      logger.debug("will not #{self}.delete #{id_or_array.inspect}", e) if MarkOnly.debug
      c = "#{quoted_table_name}.#{connection.quote_column_name self.mark_only_column}"
      self.
        where(primary_key => id_or_array).
        where("#{c} != ? OR #{c} IS NULL", MarkOnly.deleted_value).
        update_all({self.mark_only_column => MarkOnly.deleted_value})
    end
    
    def delete_all(conditions = nil)
      return super(conditions) unless !!::MarkOnly.enabled
      logger.debug("will not #{self}.delete_all", e) if MarkOnly.debug
      c = "#{quoted_table_name}.#{connection.quote_column_name self.mark_only_column}"
      (conditions ? self.where(conditions) : self).
        where("#{c} != ? OR #{c} IS NULL", MarkOnly.deleted_value).
        update_all({self.mark_only_column => MarkOnly.deleted_value})
    end
  end

  def destroy
    return super unless !!::MarkOnly.enabled
    logger.debug("will not delete #{self}", e) if MarkOnly.debug
    update_mark_only_attribute_or_column(self.mark_only_column, MarkOnly.deleted_value) if !deleted? && persisted?
    run_callbacks(:destroy) { delete }
  end
  
  def delete
    return super unless !!::MarkOnly.enabled
    logger.debug("will not delete #{self}", e) if MarkOnly.debug
    update_mark_only_attribute_or_column(self.mark_only_column, MarkOnly.deleted_value) if !deleted? && persisted?
  end

  def destroyed?
    return super unless !!::MarkOnly.enabled
    self.send(self.mark_only_column.to_sym) == MarkOnly.deleted_value
  end
  alias :deleted? :destroyed?

end

module MarkOnlyRails4Extensions
  extend ActiveSupport::Concern

  def destroy!
    return super unless !!::MarkOnly.enabled
    update_mark_only_attribute_or_column(self.mark_only_column, MarkOnly.deleted_value) if !deleted? && persisted?
    raise ActiveRecord::RecordNotDestroyed.new("#{self} is mark_only")
  end
end

MarkOnly.configure do
  self.debug = false
  self.deleted_value = 'deleted'
  self.enabled = true
end

class ActiveRecord::Relation
  # don't use generic naming to try to avoid conflicts, since this isn't model class specific
  alias_method :mark_only_orig_relation_delete_all, :delete_all
  def delete_all(*args, &block)
    return mark_only_orig_relation_delete_all(*args, &block) unless !!::MarkOnly.enabled
    if klass.respond_to?(:mark_only?) && klass.mark_only?
      logger.debug("will not #{self}.delete_all", e) if MarkOnly.debug
      if args.length > 0 && block_given?
        where(*args, &block)
      elsif args.length > 0 && !block_given?
        where(*args)
      elsif args.length == 0 && block_given?
        where(&block)
      end
      c = "#{quoted_table_name}.#{connection.quote_column_name self.mark_only_column}"
      where("#{c} != ? OR #{c} IS NULL", MarkOnly.deleted_value)
      update_all({self.mark_only_column => MarkOnly.deleted_value})
    else
      mark_only_orig_relation_delete_all(*args, &block)
    end
  end

  # don't use generic naming to try to avoid conflicts, since this isn't model class specific
  alias_method :mark_only_orig_relation_destroy_all, :destroy_all
  def destroy_all(*args, &block)
    return mark_only_orig_relation_destroy_all(*args, &block) unless !!::MarkOnly.enabled
    if klass.respond_to?(:mark_only?) && klass.mark_only?
      logger.debug("will not #{self}.destroy_all", e) if MarkOnly.debug
      if args.length > 0 && block_given?
        where(*args, &block)
      elsif args.length > 0 && !block_given?
        where(*args)
      elsif args.length == 0 && block_given?
        where(&block)
      end
      c = "#{quoted_table_name}.#{connection.quote_column_name self.mark_only_column}"
      where("#{c} != ? OR #{c} IS NULL", MarkOnly.deleted_value)
      update_all({self.mark_only_column => MarkOnly.deleted_value})
      #rel.to_a.each {|object| object.run_callbacks(:destroy) { delete }}.tap { reset }
    else
      mark_only_orig_relation_destroy_all(*args, &block)
    end
  end
end

class ActiveRecord::Base

  def self.mark_only(col_name)
    raise "#{self} must call mark_only with a column name!" unless col_name
    class_attribute :mark_only_column, instance_writer: true
    self.mark_only_column = col_name.to_sym
    class << self
      alias_method :mark_only_orig_class_delete, :delete
      alias_method :mark_only_orig_class_delete_all, :delete_all
    end
    alias_method :mark_only_orig_delete, :delete
    alias_method :mark_only_orig_destroy, :destroy
    alias_method :mark_only_orig_destroyed?, :destroyed?
    include MarkOnly
    if defined?(ActiveRecord::VERSION::MAJOR) && ActiveRecord::VERSION::MAJOR > 3
      alias_method :mark_only_orig_destroy!, :destroy!
      include MarkOnlyRails4Extensions
    end
  end

  def self.mark_only?
    false
  end

  def mark_only?
    self.class.mark_only?
  end

  def persisted?
    mark_only? ? !new_record? : super
  end

private

  # Rails 3.1 adds update_column. Rails > 3.2.6 deprecates update_attribute, gone in Rails 4.
  def update_mark_only_attribute_or_column(*args)
    respond_to?(:update_column) ? update_column(*args) : update_attribute(*args)
  end

end
