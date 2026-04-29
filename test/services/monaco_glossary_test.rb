require "test_helper"

class MonacoGlossaryTest < ActiveSupport::TestCase
  test "ALL is the union of CORE, DISTRICTS, BUILDINGS, ADDRESSES with no duplicates" do
    expected = MonacoGlossary::CORE +
               MonacoGlossary::DISTRICTS +
               MonacoGlossary::BUILDINGS +
               MonacoGlossary::ADDRESSES
    assert_equal expected.uniq, MonacoGlossary::ALL
    assert_equal MonacoGlossary::ALL.size, MonacoGlossary::ALL.uniq.size
  end

  test "ALL is frozen" do
    assert MonacoGlossary::ALL.frozen?
  end

  test "ALL includes Monaco and Monte-Carlo" do
    assert_includes MonacoGlossary::ALL, "Monaco"
    assert_includes MonacoGlossary::ALL, "Monte-Carlo"
  end

  test "all sub-constants are frozen" do
    assert MonacoGlossary::CORE.frozen?, "CORE should be frozen"
    assert MonacoGlossary::DISTRICTS.frozen?, "DISTRICTS should be frozen"
    assert MonacoGlossary::BUILDINGS.frozen?, "BUILDINGS should be frozen"
    assert MonacoGlossary::ADDRESSES.frozen?, "ADDRESSES should be frozen"
  end
end
