# write_masterのER図

## usersテーブル

| Column              | Type       | Options                        |
| ------------------- | ---------- | ------------------------------ |
| name                | string     | null: false                    |
| email               | string     | null: false, unique: true      |
| encrypted_password  | string     | null: false                    |
| slack_access_token  | string     |                                |

### Association
- has_many :posts

## postsテーブル

| Column              | Type       | Options                        |
| ------------------- | ---------- | ------------------------------ |
| title               | string     | null: false                    |
| content             | text       | null: false                    |
| word_count          | integer    | null: true                     |
| draft_flag          | boolean    |                                |
| posted_at           | datetime   |                                |
| slack_channel_id    | string     |                                |
| slack_message_ts    | string     |                                |
| slack_replies_data  | text       |                                |
| ai_feedback         | text       |                                |
| user                | references | null: false, foreign_key: true |

### Association
- belongs_to :user
