class SlackAuthenticationsController < ApplicationController
  before_action :authenticate_user!

  def create
    # OmniAuthが提供する認証情報を取得 (request.env['omniauth.auth'])
    auth_hash = request.env['omniauth.auth']

    # 認証情報とトークンが存在するか確認
    if auth_hash&.credentials&.token
      # ログイン中のユーザーを取得 (Deviseのヘルパー)
      user = current_user

      # 取得したアクセストークンをUserモデルに保存 (encrypts が自動で暗号化)
      if user.update(slack_access_token: auth_hash.credentials.token)
        # 保存成功時の処理: ルートパスにリダイレクトし、成功メッセージを表示
        redirect_to root_path, notice: 'Slackとの連携が完了しました。'
      else
        # 保存失敗時の処理 (可能性は低いが念のため)
        Rails.logger.error "Slackアクセストークンの保存に失敗しました。 User ID: #{user.id}, Errors: #{user.errors.full_messages.join(', ')}"
        redirect_to root_path, alert: 'Slack連携情報の保存に失敗しました。'
      end
    else
      # 認証情報やトークンが取得できなかった場合の処理
      Rails.logger.error "Slack OmniAuthコールバックエラー: 認証情報またはトークンが見つかりません。Auth Hash: #{auth_hash.inspect}"
      redirect_to root_path, alert: 'Slackとの連携に失敗しました。認証情報を取得できませんでした。'
    end
  end

  # GET /auth/failure に対応するアクション (任意)
  # OmniAuth.config.on_failure で設定した場合に使われる
  def failure
    # 認証失敗時の処理: ルートパスにリダイレクトし、エラーメッセージを表示
    error_message = params[:message] || "不明なエラー"
    Rails.logger.error "Slack OmniAuth 認証失敗: #{error_message}"
    redirect_to root_path, alert: "Slack認証に失敗しました: #{error_message}"
  end
end