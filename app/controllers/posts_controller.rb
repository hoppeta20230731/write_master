class PostsController < ApplicationController
  before_action :authenticate_user!, except: [:index]
  before_action :set_post, only: [:show, :edit, :update, :destroy]
  
  def index
    if user_signed_in?
      @posts = current_user.posts.order(created_at: :desc)
    end
    # ログインしていない場合は@postsは設定せず、ビューでウェルカムページを表示
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