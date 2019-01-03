class AddTokenExpiryToOwners < ActiveRecord::Migration[5.0]
  def change
    add_column :owners, :hue_expiry, :datetime
    add_column :owners, :refresh_token, :string
    add_column :owners, :refresh_expiry, :datetime
  end
end
