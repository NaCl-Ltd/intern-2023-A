class AddFixedToMicroposts < ActiveRecord::Migration[7.0]
  def change
    add_column :microposts, :fixed, :boolean
  end
end
