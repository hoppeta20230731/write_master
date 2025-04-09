Rails.application.config.middleware.use OmniAuth::Builder do
  provider :slack,
           # ↓ CredentialsからClient IDを取得
           Rails.application.credentials.dig(:slack, :client_id),
           # ↓ CredentialsからClient Secretを取得
           Rails.application.credentials.dig(:slack, :client_secret),
           # ↓ アプリが要求する権限（スコープ）を指定
           scope: 'chat:write,channels:history,groups:history'
           # user_scope: '' # User Tokenが必要な場合は指定 (今回は空)
end