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
end