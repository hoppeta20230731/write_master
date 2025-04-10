require 'slack-ruby-client'

class SlackService
  # postオブジェクトと、投稿したuserオブジェクトを受け取る
  def self.post_message(post, user)
    # --- アクセストークン取得 ---
    token = user.slack_access_token
    unless token.present?
      Rails.logger.error "Slack投稿エラー: ユーザー (ID: #{user.id}) のアクセストークンが見つかりません。Slack連携が解除されている可能性があります。"
      return false
    end

    # --- 投稿先チャンネルID設定 ---
    channel_id = Rails.application.credentials.dig(:slack, :post_channel_id)

    unless channel_id.present?
      Rails.logger.error "Slack投稿エラー: 投稿先のチャンネルID (SLACK_POST_CHANNEL_ID) が設定されていません。"
      # デフォルトチャンネルを設定しない場合は false を返す
      return false
      # # デフォルトとして #general を使う場合 (チャンネルIDを調べて書き換えてください)
      # channel_id = '#general'
      # Rails.logger.warn "SLACK_POST_CHANNEL_ID が未設定のため、'#{channel_id}' に投稿を試みます。"
    end
    # --- ここまで設定 ---

    # Slack API クライアント初期化
    client = Slack::Web::Client.new(token: token)

    # メッセージ内容構築
    message_blocks = build_message_blocks(post, user)

    begin
      # --- API呼び出し: chat.postMessage ---
      response = client.chat_postMessage(
        channel: channel_id,
        blocks: message_blocks,
        text: "#{user.name}さんが新しい投稿を作成しました: #{post.title}",
        unfurl_links: false,
        unfurl_media: false
      )

      # --- 応答処理 & DB更新 ---
      if response.ok?
        if post.update(slack_channel_id: response.channel, slack_message_ts: response.ts, posted_at: Time.current)
          Rails.logger.info "Slackへの投稿成功、Post ID: #{post.id}, Channel: #{response.channel}, TS: #{response.ts}"
          return true
        else
          Rails.logger.error "Slack投稿後のPostレコード更新に失敗。Post ID: #{post.id}, Errors: #{post.errors.full_messages.join(', ')}"
          return false
        end
      else
        Rails.logger.error "Slack投稿APIエラー: #{response.error}. Post ID: #{post.id}"
        return false
      end

    # --- 例外処理 ---
    rescue Slack::Web::Api::Errors::SlackError => e
      Rails.logger.error "Slack API例外: #{e.message}. Post ID: #{post.id}"
      # TODO: エラーに応じた処理 (例: invalid_auth なら再連携を促す)
      return false
    rescue => e
      Rails.logger.error "予期せぬSlack投稿エラー: #{e.message}. Post ID: #{post.id}"
      Rails.logger.error e.backtrace.join("\n")
      return false
    end
  end

  private # private メソッドに変更

  # メッセージブロックを構築するメソッド
  def self.build_message_blocks(post, user)
    # Block Kit Builder などを使ってカスタマイズ: https://app.slack.com/block-kit-builder/
    [
      {
        type: "header",
        text: {
          type: "plain_text",
          text: post.title.truncate(150), # 最大150文字
          emoji: true
        }
      },
      { type: "divider" },
      {
        type: "section",
        text: {
          type: "mrkdwn",
          text: post.content.truncate(2950) # textオブジェクトの最大長は3000文字
        }
      },
      { type: "divider" },
      {
        type: "context",
        elements: [
          {
            type: "mrkdwn",
            text: "投稿者: *#{user.name}* | 文字数: #{post.word_count || 'N/A'}文字"
          }
          # TODO: 必要なら投稿へのリンクなどを追加
        ]
      }
    ]
  end
end