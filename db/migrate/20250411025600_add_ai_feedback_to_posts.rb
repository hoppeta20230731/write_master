class AddAiFeedbackToPosts < ActiveRecord::Migration[7.1]
  def change
    add_column :posts, :ai_feedback, :text
  end
end
