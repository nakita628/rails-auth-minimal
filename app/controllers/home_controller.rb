# ログイン後のトップページ。
#
# ログインが必要なページの例。ApplicationController (Authentication) の before_action が
# 未ログインならログイン画面へ送るので、ここでは何も確かめなくてよい。
class HomeController < ApplicationController
  # ログイン中のユーザーと、そのユーザーのログイン履歴 (Session) を表示する。
  #
  # GET /
  def index
    @sessions = Current.user.sessions.recent
  end
end
