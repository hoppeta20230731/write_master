class AddAiFeedbackStatusToPosts < ActiveRecord::Migration[7.1]
  def change
    add_column :posts, :ai_feedback_status, :string
  end
end
