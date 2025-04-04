class CreatePosts < ActiveRecord::Migration[7.1]
  def change
    create_table :posts do |t|
      t.string :title
      t.text :content
      t.integer :word_count
      t.boolean :draft_flag
      t.datetime :posted_at
      t.integer :slack_channel_id
      t.references :user, null: false, foreign_key: true
      t.timestamps
    end
  end
end
