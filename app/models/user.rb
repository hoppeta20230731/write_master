class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  
  # 関連付け - ユーザーは複数の投稿を持つ
  has_many :posts, dependent: :destroy

  # バリデーション
  validates :name, presence: true

  # アクセストークン暗号化
  encrypts :slack_access_token

  # ユーザーの投稿に関する統計情報（最高/平均/最低スコア）を取得
  def score_stats
    # ai_scoreがnilでない投稿を対象
    relevant_posts = self.posts.where.not(ai_score: nil)
    {
      max: relevant_posts.maximum(:ai_score),
      avg: relevant_posts.average(:ai_score)&.round(1),
      min: relevant_posts.minimum(:ai_score)
    }
  end

  # ユーザーの投稿のスコア分布データを取得
  def score_distribution_data
    relevant_posts = self.posts.where.not(ai_score: nil)
    {
      "がんばろう (0-50点)" => relevant_posts.where(ai_score: 0..50).count,
      "良い (51-70点)" => relevant_posts.where(ai_score: 51..70).count,
      "とても良い (71-85点)" => relevant_posts.where(ai_score: 71..85).count,
      "優秀 (86-100点)" => relevant_posts.where(ai_score: 86..100).count
    }
  end

  # ユーザーの投稿ごとのスコア推移データを取得 (オプションで件数制限)
  # limit: グラフに表示する最新の投稿数を指定 (nilなら全件)
  def post_score_trend_data(limit: 50)
    # ai_scoreがnilでなく、作成日時順に並べた投稿を取得
    query = self.posts.where.not(ai_score: nil).order(created_at: :asc)
    # limitが指定されていれば、最新のlimit件に絞る
    query = query.last(limit) if limit.present?
    # Chartkickが扱いやすい [ラベル, スコア] の配列形式に変換
    query.map.with_index(1) do |post, index|
      # label = "Post ##{post.id} (#{post.created_at.strftime('%m/%d %H:%M')})" 
      # label = index.to_s
      label = "No.#{index}"
      [label, post.ai_score]
    end
  end
  

end
