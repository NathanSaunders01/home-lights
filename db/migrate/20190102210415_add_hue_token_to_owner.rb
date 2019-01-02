class AddHueTokenToOwner < ActiveRecord::Migration[5.0]
  def change
    add_column :owners, :hue_token, :string
  end
end
