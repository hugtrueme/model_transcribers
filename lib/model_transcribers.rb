# frozen_string_literal: true

require 'active_support/concern'

#:nodoc:
module ModelTranscribers
  extend ActiveSupport::Concern

  class_methods do
    attr_accessor :destination_model, :attr_mapping, :attr_assignment

    def sync(destination:)
      self.destination_model = destination
      self.attr_mapping = {}
      self.attr_assignment = {}

      yield

      sync_method = "sync_to_#{destination.name.underscore}".to_sym
      define_method(sync_method) do
        destination_id.present? ? update_destination : create_destination
      end

      after_save(sync_method)
    end

    def copy_attr(from:, to:, by: nil)
      attr_mapping[from] = ContentAdapter.new(to, by || from)
    end

    def assign_attr(to:, by:)
      attr_assignment[to] = ContentAdapter.new(to, by)
    end
  end

  included do
    def update_destination
      # Only update the changed attributes.
      attrubites = saved_changes.keys.each_with_object({}) do |changed_attr, attrs|
        adapter = self.class.attr_mapping[changed_attr.to_sym]
        attrs[adapter.destination] = adapter.content_from(self) unless adapter.nil?
      end

      return if attrubites.blank?

      self.class.destination_model.find(destination_id).update_columns(attrubites)
    end

    def create_destination
      # To create a new destination, we need fill up all attributes we have defined.
      all_adapters = self.class.attr_mapping.values +
                     self.class.attr_assignment.values

      attrubites = all_adapters.each_with_object({}) do |adapter, attrs|
        content = adapter.content_from(self)
        attrs[adapter.destination] = content if content.present?
      end

      table = destination_model.table_name
      created_at = created_at.strftime('%F %T')
      updated_at = updated_at.strftime('%F %T')

      sql = "INSERT INTO #{table} (destination_id, created_at, updated_at) "\
            "VALUES (#{id}, '#{created_at}', '#{updated_at}')"
      ActiveRecord::Base.connection.execute(sql)

      destination = self.class.destination_model.find_by(destination_id: id)
      destination.update_columns(attrubites)

      update_columns(destination_id: destination.id)
    end
  end

  #:nodoc:
  class ContentAdapter
    attr_accessor :destination, :content

    def initialize(destination, content)
      @destination = destination
      @content = content
    end

    def content_from(source)
      if @content.is_a?(Proc)
        source.instance_exec(&@content)
      elsif @content.is_a?(Symbol)
        source.send(@content)
      else
        raise "Can only handle Proc or Symbol. (Got #{@content.class})"
      end
    end
  end
end
