# frozen_string_literal: true

require 'active_support/concern'

#:nodoc:
module ModelTranscribers
  extend ActiveSupport::Concern

  class_methods do
    attr_accessor :transcript_model, :attr_mapping, :attr_assignment

    def sync(transcript:)
      # Reset variables
      self.transcript_model = transcript
      self.attr_mapping = {}
      self.attr_assignment = {}

      yield

      build_association
      set_after_save_callback
    end

    def copy_attr(from:, to:, by: nil)
      attr_mapping[from] = ContentAdapter.new(to, by || from)
    end

    def assign_attr(to:, by:)
      attr_assignment[to] = ContentAdapter.new(to, by)
    end
  end

  included do
    private_class_method :build_association, :set_after_save_callback
  end

  # Private class methods
  class_methods do
    # Build the association between transcript and progenitor.
    def build_association
      has_one :transcript, class_name: transcript_model.name,
                           foreign_key: 'progenitor_id'
      progenitor_model = self
      transcript_model.class_eval do
        belongs_to :progenitor, class_name: progenitor_model.name,
                                foreign_key: 'progenitor_id'
      end
    end

    # Set the "sync_to_xxxxx" method to after_save callback.
    def set_after_save_callback
      sync_method = "sync_to_#{transcript_model.name.underscore}".to_sym
      define_method(sync_method) do
        transcript.present? ? update_transcript : create_transcript
      end
      after_save(sync_method)
    end
  end

  private

  def update_transcript
    # Only update the changed attributes.
    attrs = saved_changes.keys.each_with_object({}) do |changed_attr, hash|
      adapter = self.class.attr_mapping[changed_attr.to_sym]
      hash[adapter.transcript] = adapter.content_from(self) unless adapter.nil?
    end

    return if attrs.blank?

    transcript.update_columns(attrs)
  end

  def create_transcript
    create_transcript_in_raw_sql

    attrubites = all_attrubites_to_be_updated
    transcript.update_columns(attrubites)
  end

  def create_transcript_in_raw_sql
    table = self.class.transcript_model.table_name
    created_at = self.created_at.strftime('%F %T')
    updated_at = self.updated_at.strftime('%F %T')

    sql = "INSERT INTO #{table} (progenitor_id, created_at, updated_at) "\
          "VALUES (#{id}, '#{created_at}', '#{updated_at}')"
    ActiveRecord::Base.connection.execute(sql)

    # Bacuse we create the transcript by raw sql, so we need to force
    # database read otherwise the 'self.transcript' would be nil.
    reload_transcript
  end

  def all_attrubites_to_be_updated
    # To create a new transcript, we need fill up all attributes we
    # have defined.
    all_adapters = self.class.attr_mapping.values +
                   self.class.attr_assignment.values

    all_adapters.each_with_object({}) do |adapter, attrubites|
      content = adapter.content_from(self)
      attrubites[adapter.transcript] = content if content.present?
    end
  end

  #:nodoc:
  class ContentAdapter
    attr_accessor :transcript, :content

    def initialize(transcript, content)
      @transcript = transcript
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
