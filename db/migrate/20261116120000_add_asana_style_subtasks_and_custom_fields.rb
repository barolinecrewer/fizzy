class AddAsanaStyleSubtasksAndCustomFields < ActiveRecord::Migration[8.2]
  def change
    add_column :steps, :parent_id, :uuid
    add_column :steps, :assignee_id, :uuid
    add_index :steps, :parent_id
    add_index :steps, :assignee_id

    create_table :step_templates, id: :uuid do |t|
      t.uuid :account_id, null: false
      t.string :name, null: false
      t.text :outline, null: false
      t.timestamps

      t.index :account_id
    end

    create_table :custom_fields, id: :uuid do |t|
      t.uuid :account_id, null: false
      t.uuid :board_id, null: false
      t.string :name, null: false
      t.string :kind, null: false, default: "text"
      t.string :options
      t.timestamps

      t.index :account_id
      t.index :board_id
    end

    create_table :custom_field_values, id: :uuid do |t|
      t.uuid :account_id, null: false
      t.uuid :card_id, null: false
      t.uuid :custom_field_id, null: false
      t.string :value, null: false
      t.timestamps

      t.index :account_id
      t.index :custom_field_id
      t.index [ :card_id, :custom_field_id ], unique: true
    end
  end
end
