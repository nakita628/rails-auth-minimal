require "test_helper"

# 翻訳ファイル (config/locales/**/*.yml) のテスト。
#
# 画面で使う文言の抜けは、開発・テスト環境の raise_on_missing_translations が表示のたびに見つける。
# ここでは表示されない分岐も含めて、どの言語にも同じキーがそろっていることを確かめる。
class I18nTest < ActiveSupport::TestCase
  # I18n が count で選ぶ、単数・複数の形の名前
  PLURAL_KEYS = %w[zero one two few many other].freeze

  test "どの言語にも同じキーがある" do
    ja, en = I18n.available_locales.map { |locale| translations(locale) }

    assert_empty ja.keys - en.keys, "英語に訳のないキー"
    assert_empty en.keys - ja.keys, "日本語に訳のないキー"
  end

  test "同じキーでは、どの言語も同じ変数 (%{count} など) を使う" do
    ja, en = I18n.available_locales.map { |locale| translations(locale) }

    ja.each do |key, text|
      assert_equal variables(text), variables(en[key]), key if en.key?(key)
    end
  end

  private

  # このアプリの翻訳ファイルに書いた文言を、`todos.index.title` の形のキーで返す。
  # rails-i18n などの gem の分は含めない。単数・複数の形はまとめて 1 つのキーにする。
  #
  # @param locale [Symbol]
  # @return [Hash{String => String, Hash}]
  def translations(locale)
    Dir[Rails.root.join("config/locales/**/*.yml")]
      .map { |path| YAML.load_file(path).fetch(locale.to_s, {}) }
      .reduce({}, :deep_merge)
      .then { |tree| flatten(tree) }
  end

  # @param tree [Hash]
  # @param prefix [String, nil]
  # @return [Hash{String => String, Hash}]
  def flatten(tree, prefix = nil)
    tree.each_with_object({}) do |(key, value), flat|
      path = [ prefix, key ].compact.join(".")
      if value.is_a?(Hash) && !(value.keys - PLURAL_KEYS).empty?
        flat.merge!(flatten(value, path))
      else
        flat[path] = value
      end
    end
  end

  # 文言に出てくる変数の名前。単数・複数の形があるときは、すべての形の分を合わせる。
  #
  # @param text [String, Hash]
  # @return [Array<String>]
  def variables(text)
    Array(text.is_a?(Hash) ? text.values : text).flat_map { |t| t.scan(/%\{(\w+)\}/).flatten }.uniq.sort
  end
end
