require "test_helper"

class LegacyPeerImporterTest < ActiveSupport::TestCase
  CSV_CONTENT = <<~CSV.freeze
    "id","person","name","email","telephone","link_agency","link_agent"
    "7","SMITH John","Other Agency","John@Other.mc","+377 93 00 00 00","",""
  CSV

  test "imported peers get the peer category" do
    with_csv do |path|
      result = LegacyPeerImporter.new(path).call
      assert_equal 1, result.imported

      peer = Contact.find_by!(legacy_id: 7)
      assert_equal "peer", peer.category
      assert_equal "Other Agency", peer.company
      assert_equal "john@other.mc", peer.email
    end
  end

  test "re-running updates peers in place, even alongside an ordinary contact with the same legacy_id" do
    Contact.create!(last_name: "Ordinary", legacy_id: 7)

    with_csv do |path|
      LegacyPeerImporter.new(path).call
      rerun = LegacyPeerImporter.new(path).call

      assert_equal 0, rerun.imported
      assert_equal 1, rerun.updated
      assert_equal 1, Contact.peers.count
    end
  end

  private

  def with_csv(&block)
    Tempfile.create([ "legacy_peers", ".csv" ]) do |file|
      file.write(CSV_CONTENT)
      file.flush
      block.call(file.path)
    end
  end
end
