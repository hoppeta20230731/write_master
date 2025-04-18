require 'slack-ruby-client'

class SlackService
  def self.fetch_channels(user)
    return [] unless user&.slack_access_token.present?
    
    begin
      token = user.slack_access_token
      client = Slack::Web::Client.new(token: token)
      
      # トークンの検証
      auth_test = client.auth_test
      unless auth_test.ok?
        Rails.logger.error "Slack認証エラー: #{auth_test.error}"
        return []
      end
      
      # パブリックチャンネルの取得
      response = client.conversations_list(
        types: "public_channel",
        exclude_archived: true,
        limit: 1000
      )
      
      if response.ok?
        # Botがメンバーのチャンネルのみをフィルタリング
        channels = response.channels
          .select { |channel| channel.is_member == true }
          .map { |channel| ["##{channel.name}", channel.id] }
        
        # 名前でソート
        channels.sort_by { |c| c[0].downcase }
      else
        Rails.logger.error "Slack conversations.list APIエラー: #{response.error}"
        []
      end
    rescue => e
      Rails.logger.error "Slack API例外 (チャンネル取得): #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      []
    end
  end

  # postオブジェクトと、投稿したuserオブジェクトを受け取る
  def self.post_message(post, user)
    # --- アクセストークン取得 ---
    token = user.slack_access_token
    unless token.present?
      Rails.logger.error "Slack投稿エラー: ユーザー (ID: #{user.id}) のアクセストークンが見つかりません。Slack連携が解除されている可能性があります。"
      return false
    end

    # --- 投稿先チャンネルID設定 ---
    # 投稿オブジェクトのチャンネルIDを優先的に使用し、なければデフォルト値
    channel_id = post.slack_channel_id.presence || 
                Rails.application.credentials.dig(:slack, :post_channel_id)

    unless channel_id.present?
      Rails.logger.error "Slack投稿エラー: 投稿先のチャンネルIDが設定されていません。"
      return false
    end

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

  # 特定の投稿に対するSlackスレッドの返信を取得するクラスメソッド
  def self.fetch_replies(post, user)
    # 必要な情報が揃っているかチェック
    unless post.slack_channel_id.present? && post.slack_message_ts.present? && user&.slack_access_token.present?
      Rails.logger.info "Slack返信取得スキップ: Slack情報不足または未連携。 Post ID: #{post.id}"
      return [] # 情報不足なら空の配列を返す
    end

    replies = [] # 返信結果を格納する配列
    user_info_cache = {} # Slackユーザー情報を一時的にキャッシュするハッシュ

    begin
      token = user.slack_access_token
      client = Slack::Web::Client.new(token: token)

      # スレッド返信を取得
      response = client.conversations_replies(
        channel: post.slack_channel_id,
        ts: post.slack_message_ts
      )

      if response.ok?
        raw_replies = response.messages.drop(1) # 親メッセージを除外

        # 返信からユニークなユーザーIDを抽出
        user_ids = raw_replies.map { |msg| msg.user }.uniq.compact

        # ユニークなIDごとにユーザー情報を取得 (API呼び出しは最小限に)
        user_ids.each do |user_id|
          unless user_info_cache[user_id]
            begin
              user_info_response = client.users_info(user: user_id) # users:read スコープが必要
              if user_info_response.ok?
                user_profile = user_info_response.user.profile
                user_info_cache[user_id] = user_profile.real_name_normalized.presence || user_profile.display_name_normalized.presence || user_info_response.user.name
              else
                Rails.logger.warn "Slackユーザー情報取得APIエラー: #{user_info_response.error}. User ID: #{user_id}"
                user_info_cache[user_id] = "Unknown User(#{user_id})"
              end
            rescue Slack::Web::Api::Errors::SlackError => e
              Rails.logger.error "Slack users_info API例外: #{e.message}. User ID: #{user_id}"
              user_info_cache[user_id] = "Unknown User(#{user_id})"
            end
          end
        end

        # 返信データを整形 (キャッシュしたユーザー名を使用)
        replies = raw_replies.map do |msg|
          {
            user_id: msg.user,
            user_name: user_info_cache[msg.user] || "Unknown User(#{msg.user})",
            text: msg.text,
            ts: msg.ts,
            time: Time.at(msg.ts.to_f).strftime("%Y-%m-%d %H:%M")
          }
        end
        Rails.logger.info "Slack返信取得成功: Post ID: #{post.id}, Replies fetched: #{replies.count}"
      else
        Rails.logger.error "Slack conversations.replies APIエラー: #{response.error}. Post ID: #{post.id}"
      end

    rescue Slack::Web::Api::Errors::SlackError => e
      Rails.logger.error "Slack API例外 (返信取得): #{e.message}. Post ID: #{post.id}"
    rescue => e
      Rails.logger.error "予期せぬSlack返信取得エラー: #{e.message}. Post ID: #{post.id}"
      Rails.logger.error e.backtrace.join("\n")
    end

    replies # 整形済みの返信配列を返す
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