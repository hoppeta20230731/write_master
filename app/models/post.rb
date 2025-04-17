class Post < ApplicationRecord
    # ユーザーとの関連付け
    belongs_to :user
  
    # バリデーション
    validates :title, presence: true
    validates :content, presence: true
    validates :word_count, numericality: { only_integer: true, allow_nil: true }
    
    # 下書きかどうかを判定するメソッド
    def draft?
      draft_flag == true
    end

    # ai_scoreのバリデーション
    validates :ai_score, numericality: { 
      only_integer: true, 
      greater_than_or_equal_to: 0,
      less_than_or_equal_to: 100,
      allow_nil: true 
    }
    
    # スコアに基づいた評価ラベルを返すメソッド
    def score_label
      case ai_score
      when 0..50 then "改善が必要"
      when 51..70 then "良い"
      when 71..85 then "とても良い"
      when 86..100 then "優秀"
      else "未評価"
      end
    end
    
    # スコアに基づいたBadgeのカラークラスを返すメソッド
    def score_color
      case ai_score
      when 0..50 then "bg-danger"
      when 51..70 then "bg-warning"
      when 71..85 then "bg-info"
      when 86..100 then "bg-success"
      else "bg-secondary"
      end
    end
end