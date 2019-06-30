# frozen_string_literal: true

class CreateProgenitors < ActiveRecord::Migration[5.2]
  def change
    create_table :progenitors do |t|
      t.string :name
      t.integer :iq

      t.timestamps
    end
  end
end
