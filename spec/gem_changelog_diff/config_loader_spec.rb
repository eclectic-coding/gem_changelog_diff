# frozen_string_literal: true

RSpec.describe GemChangelogDiff::ConfigLoader do
  let(:tmpdir) { Dir.mktmpdir }

  after { FileUtils.remove_entry(tmpdir) }

  describe "#load" do
    it "returns empty hash when no config files exist" do
      loader = described_class.new(project_dir: tmpdir)

      expect(loader.load).to eq({})
    end

    it "loads project config file" do
      File.write(File.join(tmpdir, ".gem_changelog_diff.yml"), "concurrency: 8\n")
      loader = described_class.new(project_dir: tmpdir)

      config = loader.load

      expect(config[:concurrency]).to eq(8)
    end

    it "loads user config file" do
      user_config_dir = File.join(tmpdir, "user_config")
      FileUtils.mkdir_p(user_config_dir)
      File.write(File.join(user_config_dir, "config.yml"), "default_format: json\n")

      stub_const("GemChangelogDiff::ConfigLoader::USER_CONFIG_PATH",
                 File.join(user_config_dir, "config.yml"))

      loader = described_class.new(project_dir: tmpdir)
      config = loader.load

      expect(config[:default_format]).to eq("json")
    end

    it "project config overrides user config" do
      user_config_dir = File.join(tmpdir, "user_config")
      FileUtils.mkdir_p(user_config_dir)
      File.write(File.join(user_config_dir, "config.yml"), "concurrency: 2\ndefault_format: json\n")
      File.write(File.join(tmpdir, ".gem_changelog_diff.yml"), "concurrency: 8\n")

      stub_const("GemChangelogDiff::ConfigLoader::USER_CONFIG_PATH",
                 File.join(user_config_dir, "config.yml"))

      loader = described_class.new(project_dir: tmpdir)
      config = loader.load

      expect(config[:concurrency]).to eq(8)
      expect(config[:default_format]).to eq("json")
    end

    it "handles corrupt YAML gracefully" do
      File.write(File.join(tmpdir, ".gem_changelog_diff.yml"), "{{invalid yaml")
      loader = described_class.new(project_dir: tmpdir)

      expect(loader.load).to eq({})
    end

    it "handles non-hash YAML content" do
      File.write(File.join(tmpdir, ".gem_changelog_diff.yml"), "- just\n- a\n- list\n")
      loader = described_class.new(project_dir: tmpdir)

      expect(loader.load).to eq({})
    end
  end
end
