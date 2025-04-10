Rails.application.config.middleware.use OmniAuth::Builder do
  provider :oauth2,
           # Client ID (Credentialsから取得)
           Rails.application.credentials.dig(:slack, :client_id),
           # Client Secret (Credentialsから取得)
           Rails.application.credentials.dig(:slack, :client_secret),
           {
             # プロバイダー名を :slack と定義 (URLパスやコールバック処理で使うため)
             name: 'slack',
             # 要求する Bot Token Scope
             scope: 'chat:write,channels:history',
             # 要求する User Token Scope (今回は空)
             user_scope: '',
             # 認可リクエストに追加するパラメータ
             authorize_params: {
               # Bot Token Flow であることを示すために user_scope を空で指定
               user_scope: ''
             },
             # Slack APIのエンドポイントや設定
             client_options: {
               # 基本となるサイトURL
               site: 'https://slack.com',
               # 【重要】OAuth V2 の認可エンドポイントURL
               authorize_url: 'https://slack.com/oauth/v2/authorize',
               # 【重要】OAuth V2 のトークンエンドポイントURL
               token_url: 'https://slack.com/api/oauth.v2.access'
             }
           }
end