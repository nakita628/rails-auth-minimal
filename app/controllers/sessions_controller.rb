# ログインとログアウト。`bin/rails generate authentication` が作るものをもとにしている。
#
# ログイン 1 回が Session 1 件なので、resource :session (単数) にしている。
class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]

  # 総当たり対策。同じ IP から 3 分間に 10 回を超えてログインを試みると、ログイン画面に戻す。
  # 回数は Rails.cache に数えるので、テスト環境 (null_store) では効かない。
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_path, alert: t(".rate_limited") }

  # ログイン画面を表示する。
  #
  # GET /session/new
  def new
  end

  # メールアドレスとパスワードを確かめて、ログインする。
  #
  # User.authenticate_by は、メールアドレスが見つからなくてもパスワードの照合と同じ時間をかける
  # (どちらが間違っていたかを応答時間から推測されないようにするため)。
  # 失敗したときも、どちらが違うかは伝えない。
  #
  # POST /session
  def create
    if user = User.authenticate_by(params.permit(:email_address, :password))
      start_new_session_for user
      redirect_to after_authentication_url
    else
      redirect_to new_session_path, alert: t(".alert")
    end
  end

  # ログアウトする。
  #
  # DELETE 後のリダイレクトは 303 (See Other) にする。
  # 302 だとブラウザが DELETE のままリダイレクト先を読みに行くことがあるため。
  #
  # DELETE /session
  def destroy
    terminate_session
    redirect_to new_session_path, status: :see_other
  end
end
