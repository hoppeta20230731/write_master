class GenerateAiFeedbackJob < ApplicationJob
  queue_as :default

  def perform(post_id)
    # 投稿を取得
    post = Post.find(post_id)
    begin
      # 実行中ステータスを設定（オプション）
      post.update(ai_feedback_status: 'processing') if post.has_attribute?(:ai_feedback_status)
      
      # 既存のサービスを呼び出し
      FeedbackService.new(post).generate_feedback
      
      # 完了ステータスを設定（オプション）
      post.update(ai_feedback_status: 'completed') if post.has_attribute?(:ai_feedback_status)
      
      Rails.logger.info "AI feedback generated successfully for Post ID: #{post.id}"
    rescue => e
      # エラー時の処理
      post.update(ai_feedback_status: 'failed') if post.has_attribute?(:ai_feedback_status)
      Rails.logger.error "Failed to generate AI feedback for Post ID: #{post.id}: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
    end
  end
end