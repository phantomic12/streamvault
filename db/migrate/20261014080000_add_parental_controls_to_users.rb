# frozen_string_literal: true

class AddParentalControlsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :child_account, :boolean, default: false, null: false
    add_column :users, :max_rating_age, :integer
    add_column :users, :child_lock_password_digest, :string
  end
end
