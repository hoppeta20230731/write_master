FactoryBot.define do
  factory :post do
    title { "テスト投稿" }
    content { "これはテスト投稿の内容です。" }
    word_count { 14 }
    draft_flag { true }
    association :user
  end
end
