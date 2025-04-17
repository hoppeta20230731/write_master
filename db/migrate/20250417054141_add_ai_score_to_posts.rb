class AddAiScoreToPosts < ActiveRecord::Migration[7.1]
  def change
    add_column :posts, :ai_score, :integer
  end
end
