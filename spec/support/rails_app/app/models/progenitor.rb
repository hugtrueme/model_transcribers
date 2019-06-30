# frozen_string_literal: true

class Progenitor < ApplicationRecord
  include ModelTranscribers

  sync transcript: Transcript do
    copy_attr from: :name, to: :name
    copy_attr from: :iq, to: :power, by: -> { iq.to_i * 10_000 }
    assign_attr to: :job, by: -> { 'Avenger' }
  end
end
