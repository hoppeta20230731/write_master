class AddSlackMessageTsToPosts < ActiveRecord::Migration[7.1]
  def change
    add_column :posts, :slack_message_ts, :string
  end
end
