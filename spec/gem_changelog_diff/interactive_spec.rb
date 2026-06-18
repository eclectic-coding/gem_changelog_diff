# frozen_string_literal: true

require "tty-prompt"

RSpec.describe GemChangelogDiff::Interactive do
  let(:rails_gem) do
    GemChangelogDiff::OutdatedGem.new(name: "rails", current_version: "7.0.8", newest_version: "7.1.3")
  end

  let(:sidekiq_gem) do
    GemChangelogDiff::OutdatedGem.new(name: "sidekiq", current_version: "7.1.0", newest_version: "7.2.0")
  end

  let(:prompt) { instance_double(TTY::Prompt) }
  let(:menu) { double("menu") }

  before do
    allow(TTY::Prompt).to receive(:new).and_return(prompt)
  end

  describe "#select" do
    it "presents gems as multi-select choices" do
      allow(prompt).to receive(:multi_select).and_yield(menu).and_return([rails_gem])
      allow(menu).to receive(:choice)

      interactive = described_class.new(gems: [rails_gem, sidekiq_gem])
      interactive.select

      expect(prompt).to have_received(:multi_select)
        .with("Select gems to check:", per_page: 15, help: "(Space to select, Enter to confirm)")
    end

    it "builds choice labels with name and versions" do
      allow(prompt).to receive(:multi_select).and_yield(menu).and_return([rails_gem])
      allow(menu).to receive(:choice)

      described_class.new(gems: [rails_gem, sidekiq_gem]).select

      expect(menu).to have_received(:choice).with("rails (7.0.8 → 7.1.3)", rails_gem)
      expect(menu).to have_received(:choice).with("sidekiq (7.1.0 → 7.2.0)", sidekiq_gem)
    end

    it "returns selected gems" do
      allow(prompt).to receive(:multi_select).and_yield(menu).and_return([rails_gem])
      allow(menu).to receive(:choice)

      interactive = described_class.new(gems: [rails_gem, sidekiq_gem])
      result = interactive.select

      expect(result).to eq([rails_gem])
    end

    it "returns empty array when nothing selected" do
      allow(prompt).to receive(:multi_select).and_yield(menu).and_return([])
      allow(menu).to receive(:choice)

      interactive = described_class.new(gems: [rails_gem])
      result = interactive.select

      expect(result).to eq([])
    end
  end
end
