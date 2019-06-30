# frozen_string_literal: true

class CreateTranscripts < ActiveRecord::Migration[5.2]
  def change
    create_table :transcripts do |t|
      t.string :name
      t.integer :power
      t.string :job
      t.string :team, default: 'The Avengers'
      t.integer :progenitor_id

      t.timestamps
    end
  end
end
