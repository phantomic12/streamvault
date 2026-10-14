# frozen_string_literal: true

require "rails_helper"

RSpec.describe Streams::ReleaseParser do
  subject(:parser) { described_class.new }

  describe "language detection" do
    it "detects Finnish release tags" do
      expect(parser.analyze(title: "Movie.Name.2020.1080p.FINNISH.WEB-DL")[:languages]).to eq([ "FINNISH" ])
      expect(parser.analyze(title: "Movie.Name.2020.1080p.FIN.WEB-DL")[:languages]).to eq([ "FINNISH" ])
      expect(parser.analyze(title: "Movie.Name.2020.1080p.FI.WEB-DL")[:languages]).to eq([ "FINNISH" ])
    end

    it "detects Finnish alongside other languages" do
      expect(parser.analyze(title: "Movie.Name.2020.ENG.FINNISH.1080p")[:languages])
        .to contain_exactly("ENG", "FINNISH")
    end

    it "treats MULTI releases as all supported languages including Finnish" do
      expect(parser.analyze(title: "Movie.Name.2020.MULTI.1080p")[:languages])
        .to include("ENG", "FINNISH")
    end

    it "does not match words that merely contain the Finnish markers" do
      expect(parser.analyze(title: "Movie.Name.2020.FiNAL.CUT.1080p")[:languages]).to eq([])
      expect(parser.analyze(title: "Movie.Name.2020.FINANCE.Documentary")[:languages]).to eq([])
    end
  end
end
