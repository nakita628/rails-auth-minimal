# アカウント登録 (ユーザーの作成)。
#
# `bin/rails generate authentication` は登録画面を作らない (ユーザーは console などで作る想定) ので、
# ここで足している。登録できたらそのままログインする。
class RegistrationsController < ApplicationController
  allow_unauthenticated_access

  # 登録画面を表示する。
  #
  # GET /registration/new
  def new
    @user = User.new
  end

  # ユーザーを作ってログインする。
  #
  # 入力が正しくなければ、エラーを付けて登録画面を 422 で描き直す。
  #
  # POST /registration
  def create
    @user = User.new(user_params)

    if @user.save
      start_new_session_for @user
      redirect_to root_path
    else
      render :new, status: :unprocessable_content
    end
  end

  private

  # フォームから受け取ってよい項目だけを取り出す (Strong Parameters)。
  #
  # @return [ActionController::Parameters] `email_address`、`password`、`password_confirmation`
  def user_params
    params.expect(user: %i[email_address password password_confirmation])
  end
end
