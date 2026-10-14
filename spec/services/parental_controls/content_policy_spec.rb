# frozen_string_literal: true

require "rails_helper"

RSpec.describe ParentalControls::ContentPolicy do
  let(:resolver) { instance_double(ParentalControls::RatingResolver) }

  def policy_for(child:, max_age: 13)
    user = User.new(child_account: child, max_rating_age: max_age)
    described_class.new(user, resolver: resolver)
  end

  describe "#allowed?" do
    it "allows every title for regular accounts without rating lookups" do
      expect(resolver).not_to receive(:min_age)

      expect(policy_for(child: false).allowed?("tt1375666")).to eq(true)
      expect(policy_for(child: false).allowed?(nil)).to eq(true)
    end

    it "allows titles rated within the account's age limit" do
      allow(resolver).to receive(:min_age).with("tt1375666").and_return(13)

      expect(policy_for(child: true, max_age: 13).allowed?("tt1375666")).to eq(true)
    end

    it "blocks titles rated above the account's age limit" do
      allow(resolver).to receive(:min_age).with("tt0994312").and_return(17)

      expect(policy_for(child: true, max_age: 13).allowed?("tt0994312")).to eq(false)
    end

    it "blocks titles whose rating cannot be verified" do
      allow(resolver).to receive(:min_age).with("tt0000001").and_return(ParentalControls::Rating::UNKNOWN_AGE)

      expect(policy_for(child: true, max_age: 17).allowed?("tt0000001")).to eq(false)
      expect(policy_for(child: true, max_age: 18).allowed?("tt0000001")).to eq(true)
    end

    it "blocks blank IDs for child accounts" do
      expect(policy_for(child: true).allowed?(nil)).to eq(false)
      expect(policy_for(child: true).allowed?("")).to eq(false)
    end
  end

  describe "#filter" do
    it "returns the input untouched for regular accounts" do
      expect(resolver).not_to receive(:min_age)
      items = [ { imdb_id: "tt1375666" }, { imdb_id: "tt0994312" } ]

      expect(policy_for(child: false).filter(items)).to eq(items)
    end

    it "drops titles above the age limit and keeps order" do
      allow(resolver).to receive(:min_age).and_return(17)
      allow(resolver).to receive(:min_age).with("tt1375666").and_return(13)
      allow(resolver).to receive(:min_age).with("tt0088763").and_return(8)

      items = [
        { imdb_id: "tt0994312", title: "Adult" },
        { imdb_id: "tt1375666", title: "Inception" },
        { imdb_id: "tt0088763", title: "Family" }
      ]

      expect(policy_for(child: true, max_age: 13).filter(items)).to eq(items.values_at(1, 2))
    end

    it "filters larger batches with concurrent lookups" do
      allow(resolver).to receive(:min_age) { |imdb_id| imdb_id.end_with?("1") ? 17 : 0 }
      items = (1..40).map { |i| { imdb_id: format("tt%07d", i) } }

      filtered = policy_for(child: true, max_age: 13).filter(items)

      expect(filtered.size).to eq(36)
      expect(filtered.map { |item| item[:imdb_id] }).not_to include("tt0000001")
    end

    it "drops items without a resolvable IMDb ID" do
      items = [ { title: "No ID" }, { imdb_id: "tt1375666" } ]
      allow(resolver).to receive(:min_age).with("tt1375666").and_return(13)

      expect(policy_for(child: true, max_age: 13).filter(items).map { |item| item[:imdb_id] })
        .to eq([ "tt1375666" ])
    end

    it "understands ActiveRecord-style items and custom extractors" do
      allow(resolver).to receive(:min_age).with("tt1375666").and_return(13)
      allow(resolver).to receive(:min_age).with("tt0994312").and_return(17)

      entries = [ CollectionEntry.new(imdb_id: "tt1375666"), CollectionEntry.new(imdb_id: "tt0994312") ]
      expect(policy_for(child: true, max_age: 13).filter(entries)).to eq(entries.first(1))

      keyed = [ { "imdb_id" => "tt1375666" }, { "imdb_id" => "tt0994312" } ]
      expect(policy_for(child: true, max_age: 13).filter(keyed)).to eq(keyed.first(1))

      custom = [ "tt1375666", "tt0994312" ]
      expect(policy_for(child: true, max_age: 13).filter(custom) { |id| id }).to eq([ "tt1375666" ])
    end
  end

  describe "child account helpers" do
    it "exposes the child flag and age limit" do
      policy = policy_for(child: true, max_age: 8)

      expect(policy.child_account?).to eq(true)
      expect(policy.max_age).to eq(8)
    end
  end
end
