ENV["RAILS_ENV"] ||= "test"

# テスト用 DB は、実行のたびに削除して `prisma db push` で作り直す (db/schema.rb は使わない)。
# CI では eager loading によって Rails が起動時にテーブルを読むため、Rails を読み込む前に作る。
# パスは config/database.yml の test の database と合わせている。
root = File.expand_path("..", __dir__)
test_db = "#{root}/storage/test.sqlite3"
File.delete(*Dir["#{test_db}*"])
system({ "DATABASE_URL" => "file:#{test_db}" },
  "pnpm", "exec", "prisma", "db", "push", chdir: root, out: File::NULL, exception: true)

require_relative "../config/environment"
require "rails/test_help"
require_relative "test_helpers/session_test_helper"

module ActiveSupport
  class TestCase
    # 並列テストは使わない。Rails は並列ワーカーごとの DB を db/schema.rb から作るが、
    # このアプリには db/schema.rb がないため。

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end

module ActionDispatch
  class IntegrationTest
    # アプリの ApplicationController#default_url_options と同じく、URL に言語 (/ja/...) を入れる。
    # 入れないと session_url などが、URL の先頭の :locale に別の値を当てはめてしまうことがある
    setup { self.default_url_options = { locale: I18n.default_locale } }
  end
end
