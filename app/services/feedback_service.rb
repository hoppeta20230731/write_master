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

    system_prompt = "あなたは優秀な文章レビューアシスタントです。以下の投稿内容について、建設的なフィードバックを提供してください。特に、文章の構成、表現の明確さ、改善点などを具体的に指摘してください。"
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
        max_tokens: 1024
      )

      feedback_text = response.content&.first&.text

      if feedback_text.present?
        post.update!(ai_feedback: feedback_text.strip)
        Rails.logger.info "Claude feedback generated successfully for Post ID: #{post.id}"
      else
        Rails.logger.warn "Claude feedback generation returned empty for Post ID: #{post.id}"
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