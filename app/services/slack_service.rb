class SlackService
  def self.post_message(post, user)
    webhook_url = ENV['SLACK_WEBHOOK_URL']
    return false unless webhook_url.present?
    
    message = {
      text: "#{user.name}さんが新しい投稿を作成しました",
      blocks: [
        {
          type: "header",
          text: {
            type: "plain_text",
            text: post.title
          }
        },
        {
          type: "section",
          text: {
            type: "mrkdwn",
            text: post.content.truncate(1000)
          }
        },
        {
          type: "context",
          elements: [
            {
              type: "mrkdwn",
              text: "投稿者: *#{user.name}* | 文字数: #{post.word_count}文字"
            }
          ]
        }
      ]
    }
    
    begin
      response = HTTParty.post(
        webhook_url,
        body: message.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
      return response.code == 200
    rescue => e
      Rails.logger.error "Slack投稿エラー: #{e.message}"
      return false
    end
  end
end