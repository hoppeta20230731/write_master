require 'anthropic'

class FeedbackService
  attr_reader :post
  class ClaudeApiError < StandardError; end

  def initialize(post)
    @post = post
  end

  def generate_feedback
    api_key = Rails.application.credentials.dig(:anthropic, :api_key)
    unless api_key
      Rails.logger.error "Anthropic API key is not configured."
      raise ClaudeApiError, "APIキーが設定されていません。"
    end

    client = Anthropic::Client.new(api_key: api_key)

    # JSONフォーマットのレスポンスを要求するシステムプロンプト
    system_prompt = <<~PROMPT
      あなたは優秀な文章レビューアシスタントです。以下の投稿内容について分析し、以下のJSONフォーマットで結果を返してください：
      {
        "feedback": "具体的なフィードバック内容をここに記述。改善点や良い点を含めて詳細に。",
        "score": 0〜100の整数値（文章の質を総合的に評価）
      }
      
      評価基準：
      - 明確さ: 文章が明確で理解しやすいか
      - 構成: 論理的な流れがあるか
      - 簡潔さ: 余分な言葉がないか
      - 説得力: 主張や説明に説得力があるか
      - 文法: 文法的に正しいか
    PROMPT

    user_message_content = <<~CONTENT
      # 投稿タイトル:
      #{post.title}

      # 投稿内容:
      #{post.content}
    CONTENT

    begin
      response = client.messages.create(
        model: "claude-3-5-haiku-20241022",
        system: system_prompt,
        messages: [
          { role: "user", content: user_message_content }
        ],
        max_tokens: 1024,
        temperature: 0.3
      )

      # レスポンステキストを取得
      response_text = response.content&.first&.text

      if response_text.present?
        begin
          # JSONとしてパース
          parsed_response = JSON.parse(response_text)
          
          # feedbackとscoreを抽出
          feedback = parsed_response["feedback"]
          score = parsed_response["score"].to_i
          
          # スコアの範囲を確認
          score = 0 if score < 0
          score = 100 if score > 100
          
          # postを更新
          post.update!(
            ai_feedback: feedback,
            ai_score: score
          )
          
          Rails.logger.info "AI feedback and score generated successfully for Post ID: #{post.id}, Score: #{score}"
        rescue JSON::ParserError => e
          # JSON解析エラー時はテキスト全体をフィードバックとして保存
          Rails.logger.error "JSON parsing error for Post ID: #{post.id}: #{e.message}"
          post.update!(
            ai_feedback: "フィードバック形式エラー。以下が生成されたテキストです：\n\n#{response_text}",
            ai_score: nil
          )
        end
      else
        Rails.logger.warn "Empty response received for Post ID: #{post.id}"
      end

    rescue Anthropic::Errors::APIError => e
      Rails.logger.error "Anthropic API error for Post ID: #{post.id}: Status=#{e.status}, Response=#{e.response_body}, Message=#{e.message}"
      raise ClaudeApiError, "Claude APIとの通信に失敗しました: #{e.message} (Status: #{e.status})"
    rescue StandardError => e
      Rails.logger.error "Unexpected error during feedback generation for Post ID: #{post.id}: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      raise ClaudeApiError, "予期せぬエラーが発生しました: #{e.message}"
    end
  end
end