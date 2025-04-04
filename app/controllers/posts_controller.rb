class PostsController < ApplicationController
  before_action :authenticate_user!, except: [:index]
  
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
    @post = current_user.posts.build(post_params)
    @post.word_count = count_words(@post.content) if @post.content.present?
    
    if @post.save
      redirect_to posts_path, notice: '投稿が作成されました'
    else
      render :new
    end
  end
  
  private
  
  def post_params
    params.require(:post).permit(:title, :content, :draft_flag)
  end
  
  def count_words(text)
    # テキストの文字数をカウント（空白を含まない）
    text.gsub(/\s+/, '').length
  end
end