require "test_helper"

# The Russian translations kept "Monaco" in Latin script because the old prompt
# told the model to preserve glossary terms verbatim. Fixing that text is a
# mechanical substitution, but it must not touch occurrences that belong to a
# longer Latin proper noun ("Monaco Yacht Show", "Rallye de Monte-Carlo").
class CyrillicProperNounFixerTest < ActiveSupport::TestCase
  def fix(text)
    CyrillicProperNounFixer.new(text).call
  end

  test "transliterates Monaco in plain Russian prose" do
    assert_equal "жизни в Монако сегодня", fix("жизни в Monaco сегодня")
  end

  test "transliterates Monte-Carlo in plain Russian prose" do
    assert_equal "район Монте-Карло дорогой", fix("район Monte-Carlo дорогой")
  end

  test "transliterates at the end of a sentence" do
    assert_equal "обосноваться в Монако.", fix("обосноваться в Monaco.")
  end

  test "transliterates every occurrence in a paragraph" do
    assert_equal "Монако и Монако", fix("Monaco и Monaco")
  end

  test "leaves an already-transliterated name alone" do
    assert_equal "жизни в Монако", fix("жизни в Монако")
  end

  # Category 2: Monaco inside a longer Latin-script proper noun.
  test "preserves Monaco when followed by Latin words" do
    text = "мероприятия, такие как Monaco Yacht Show и Гран-при"
    assert_equal text, fix(text)
  end

  test "preserves Monaco when preceded by a Latin proper-noun phrase" do
    text = "- L'International School of Monaco предлагает"
    assert_equal text, fix(text)
  end

  test "preserves Monte-Carlo inside an event name" do
    text = "Гран-при Формулы 1, Rallye de Monte-Carlo, теннисный"
    assert_equal text, fix(text)
  end

  test "preserves Monte-Carlo inside an institution name" do
    text = "- L'Orchestre Philharmonique de Monte-Carlo"
    assert_equal text, fix(text)
  end

  test "preserves the museum name" do
    text = "- Le Musée océanographique de Monaco"
    assert_equal text, fix(text)
  end

  test "preserves Le Monte-Carlo Country Club" do
    text = "- Le Monte-Carlo Country Club располагает"
    assert_equal text, fix(text)
  end

  test "preserves Caisses Sociales de Monaco" do
    text = "финансирования Caisses Sociales de Monaco (CSM) являются"
    assert_equal text, fix(text)
  end

  # Category 3: hyphenated district name, a single token.
  test "transliterates Monaco-Ville as a district name" do
    assert_equal "от Монако-Вилль до", fix("от Monaco-Ville до")
  end

  test "transliterates a standalone district heading" do
    assert_equal "## 1. Монако-Вилль: историческая", fix("## 1. Monaco Ville: историческая")
  end

  # Street addresses stay Latin so a reader can match them to signage.
  test "preserves Avenue de Monte-Carlo as a street address" do
    text = "расположен на Avenue de Monte-Carlo рядом"
    assert_equal text, fix(text)
  end

  test "does not touch markdown link URLs" do
    text = "см. [гид](https://example.com/monaco/guide) здесь"
    assert_equal text, fix(text)
  end

  test "does not touch a URL containing Monte-Carlo" do
    text = "[x](https://example.com/Monte-Carlo-page)"
    assert_equal text, fix(text)
  end

  test "reports whether it changed anything" do
    assert CyrillicProperNounFixer.new("в Monaco").changed?
    assert_not CyrillicProperNounFixer.new("в Монако").changed?
  end

  test "handles nil and empty input" do
    assert_equal "", CyrillicProperNounFixer.new(nil).call
    assert_equal "", CyrillicProperNounFixer.new("").call
  end
end
