Rails.application.routes.draw do
  # 言語を URL の先頭に入れる (/ja/..., /en/...)。省略したときは既定の日本語になる。
  # 対応していない言語 (/fr など) はどのルートにも一致せず 404 になる。
  scope "(:locale)", locale: /ja|en/ do
    root "home#index"

    # ログイン (new, create) とログアウト (destroy)。/session/new, /session
    resource :session, only: %i[new create destroy]
    # アカウント登録。/registration/new, /registration
    resource :registration, only: %i[new create]
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check
end
