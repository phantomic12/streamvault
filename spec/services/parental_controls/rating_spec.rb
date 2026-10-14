# frozen_string_literal: true

require "rails_helper"

RSpec.describe ParentalControls::Rating do
  describe ".min_age_for" do
    {
      "G" => 0, "TV-G" => 0, "TV-Y" => 0, "U" => 0,
      "TV-Y7" => 7, "TV-Y7-FV" => 7,
      "PG" => 8, "GP" => 8, "TV-PG" => 8,
      "PG-13" => 13, "M" => 13,
      "TV-14" => 14,
      "R" => 17, "TV-MA" => 17, "MA" => 17,
      "NC-17" => 18, "X" => 18, "AO" => 18
    }.each do |certification, age|
      it "maps #{certification.inspect} to minimum age #{age}" do
        expect(described_class.min_age_for(certification)).to eq(age)
      end
    end

    it "normalizes case and whitespace" do
      expect(described_class.min_age_for("  pg-13 ")).to eq(13)
      expect(described_class.min_age_for(" tv-ma ")).to eq(17)
    end

    it "treats unrecognized certifications as adult-only" do
      expect(described_class.min_age_for("SOMETHING-ELSE")).to eq(described_class::UNKNOWN_AGE)
    end

    it "treats blank and unrated markers as adult-only (fail closed)" do
      expect(described_class.min_age_for(nil)).to eq(described_class::UNKNOWN_AGE)
      expect(described_class.min_age_for("")).to eq(described_class::UNKNOWN_AGE)
      expect(described_class.min_age_for("N/A")).to eq(described_class::UNKNOWN_AGE)
      expect(described_class.min_age_for("NOT RATED")).to eq(described_class::UNKNOWN_AGE)
      expect(described_class.min_age_for("UNRATED")).to eq(described_class::UNKNOWN_AGE)
    end

    it "treats Production Code censorship seals as adult-only (regression: Dracula 1931)" do
      # "Passed"/"Approved" are pre-1968 censorship seals, not age
      # ratings — tt0021814 (Dracula, OMDB "Passed") must not appear
      # below the 18+ limit.
      expect(described_class.min_age_for("Passed")).to eq(described_class::UNKNOWN_AGE)
      expect(described_class.min_age_for("Approved")).to eq(described_class::UNKNOWN_AGE)
      expect(described_class.min_age_for("GP")).to eq(8)
    end
  end
end
