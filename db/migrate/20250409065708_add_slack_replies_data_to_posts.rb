class AddSlackRepliesDataToPosts < ActiveRecord::Migration[7.1]
  def change
    add_column :posts, :slack_replies_data, :text
  end
end
