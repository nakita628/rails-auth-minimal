# すべてのコントローラの基底クラス。
#
# Authentication を include しているので、既定ではすべてのアクションにログインが必要になる。
class ApplicationController < ActionController::Base
  include Authentication

  # webp、Web Push、import maps、CSS のネストや :has に対応した新しいブラウザだけを受け付ける。
  # それ以外のブラウザには public/406-unsupported-browser.html を返す。
  allow_browser versions: :modern

  # 言語の切り替えは、他のコールバックより先 (prepend) に動かす。Authentication の before_action が
  # 未ログインでリダイレクトするときも、その先の URL (new_session_path) を今の言語にするため。
  prepend_around_action :switch_locale

  # URL を作るときに、今の言語を `:locale` に入れる。
  # リンク・フォーム・リダイレクト先が同じ言語のまま (/en/... なら /en/...) になる。
  #
  # @return [Hash]
  def default_url_options
    { locale: I18n.locale }
  end

  private

  # URL の言語 (`/en/...` の `:locale`) に合わせて、画面とメッセージの言語を切り替える。
  #
  # URL に言語がないときは、既定の日本語にする。
  #
  # @yield アクション本体
  def switch_locale(&action)
    locale = params[:locale] || I18n.default_locale
    I18n.with_locale(locale, &action)
  end
end
