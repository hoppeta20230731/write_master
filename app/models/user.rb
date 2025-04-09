class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  
  # 関連付け - ユーザーは複数の投稿を持つ
  has_many :posts, dependent: :destroy

  # バリデーション
  validates :name, presence: true

  # Slack暗号化キー
  attr_encrypted :slack_access_token, key: Rails.application.credentials.dig(:slack, :encryption_key)
end
