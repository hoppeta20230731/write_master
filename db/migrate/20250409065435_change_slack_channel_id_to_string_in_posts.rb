class ChangeSlackChannelIdToStringInPosts < ActiveRecord::Migration[7.1]
  def change
    change_column :posts, :slack_channel_id, :string
  end
end
