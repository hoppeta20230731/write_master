class PostsController < ApplicationController
  before_action :authenticate_user!, except: [:index]
  before_action :set_post, only: [:show, :edit, :update, :destroy, :generate_ai_feedback, :feedback_status]
  
def index
  if user_signed_in?
    base_scope = current_user.posts # 基本となるスコープ
    @calendar_events = base_scope.order(created_at: :asc)
    # ★★★ ここから日付フィルタリングロジック ★★★
    if params[:start_date]
      begin
        # パラメータから日付オブジェクトを生成
        @selected_date = Date.parse(params[:start_date])
        # created_at が selected_date の範囲内にある投稿を検索
        # .all_day はその日の 00:00:00 から 23:59:59 までの Range を返す
        @posts = base_scope.where(created_at: @selected_date.all_day).order(created_at: :desc)
        # ビューで使うタイトルを設定
        @index_title = "#{@selected_date.strftime('%Y年%m月%d日')}の投稿"
      rescue ArgumentError
        # 不正な日付パラメータの場合は通常の全件表示に戻す
        @posts = base_scope.order(created_at: :desc)
        @index_title = "投稿一覧"
        # エラーメッセージをフラッシュで表示
        flash.now[:alert] = "無効な日付形式です。"
      end
    else
      # 日付指定がない場合は通常の全件表示
      @posts = base_scope.order(created_at: :desc)
      @index_title = "投稿一覧"
    end
    # ★★★ ここまで日付フィルタリングロジック ★★★
  end
  # ログインしていない場合は @posts は nil のままなので、
  # ビュー側で @posts.present? や user_signed_in? を使って表示を分岐する想定
end
  
  def new
    @post = Post.new
  end
  
  def create
    # 作成時に自動的にユーザーIDを設定したいためbuildが適切
    @post = current_user.posts.build(post_params)
    @post.word_count = count_words(@post.content) if @post.content.present?
    
    if @post.save
      unless @post.draft?
        SlackService.post_message(@post, current_user)
      end
      redirect_to posts_path, notice: '投稿が作成されました'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @slack_replies = SlackService.fetch_replies(@post, current_user)
  end
  
  def edit
    if @post.posted_at.present?
      redirect_to @post, alert: '投稿済みの内容は編集できません'
    end
  end
  
  def update
    if @post.posted_at.present?
      redirect_to @post, alert: '投稿済みの内容は編集できません'
      return
    end
    
    if @post.update(post_params)
      @post.update(word_count: count_words(@post.content)) if @post.content.present?
      
      # 下書きから公開に変更された場合はSlackに投稿
      if !@post.draft? && @post.posted_at.blank?
        SlackService.post_message(@post, current_user)
      end 
      redirect_to @post, notice: '投稿が更新されました'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    # 投稿済みは削除できない
    if @post.posted_at.present?
      redirect_to @post, alert: 'Slackに投稿済みのため削除できません'
      return
    end

    @post.destroy
    redirect_to posts_path, notice: '投稿が削除されました'
  end

  def generate_ai_feedback
    # --- 投稿済み かつ 既にフィードバックがある場合は実行しない ---
    if @post.posted_at.present? && @post.ai_feedback.present?
      redirect_to post_path(@post), alert: "投稿済みの記事のAIフィードバックは一度だけ生成できます。"
      return
    end
      
    @post.update(ai_feedback_status: 'queued') if @post.has_attribute?(:ai_feedback_status)
    GenerateAiFeedbackJob.perform_later(@post.id)
    redirect_to post_path(@post), notice: "AIフィードバックを生成中です。しばらくお待ちください。"
  rescue => e
    Rails.logger.error "Error queuing AI feedback generation: #{e.message}"
    redirect_to post_path(@post), alert: "AIフィードバック生成の開始に失敗しました。"
  end

def feedback_status
  if @post.user != current_user
    return render json: { error: "権限がありません" }, status: :forbidden
  end
  
  render json: { 
    status: @post.ai_feedback_status || 'none',
    has_feedback: @post.ai_feedback.present?
  }
end

  private

  def set_post
    # データを取得してからアクセス権をチェック
    @post = Post.find(params[:id])
    # 他のユーザーの投稿を見れないようにする
    if @post.user != current_user
      redirect_to posts_path, alert: '権限がありません'
    end
  end
  
  def post_params
    params.require(:post).permit(:title, :content, :draft_flag)
  end
  
  def count_words(text)
    # テキストの文字数をカウント（空白を含まない）
    text.gsub(/\s+/, '').length
  end
end