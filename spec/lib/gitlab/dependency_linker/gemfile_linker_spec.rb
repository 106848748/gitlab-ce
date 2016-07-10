require 'rails_helper'

describe Gitlab::DependencyLinker::GemfileLinker, lib: true do
  describe '.support?' do
    it 'supports Gemfile' do
      expect(described_class.support?('Gemfile')).to be_truthy
    end

    it 'supports gems.rb' do
      expect(described_class.support?('gems.rb')).to be_truthy
    end

    it 'does not support other files' do
      expect(described_class.support?('Gemfile.lock')).to be_falsey
    end
  end

  describe '#link' do
    let(:file_name) { "Gemfile" }

    let(:file_content) do
      <<-CONTENT.strip_heredoc
        source 'https://rubygems.org'

        gem "rails", '4.2.6', github: "rails/rails"
        gem 'rails-deprecated_sanitizer', '~> 1.0.3'

        # Responders respond_to and respond_with
        gem 'responders', '~> 2.0', :github => 'rails/responders'

        # Specify a sprockets version due to increased performance
        # See https://gitlab.com/gitlab-org/gitlab-ce/issues/6069
        gem 'sprockets', '~> 3.6.0'

        # Default values for AR models
        gem 'default_value_for', '~> 3.0.0'
      CONTENT
    end

    subject { Gitlab::Highlight.highlight(file_name, file_content, nowrap: false) }

    def link(name, url)
      %{<a href="#{url}" rel="nofollow noreferrer" target="_blank">#{name}</a>}
    end

    it "links dependencies" do
      expect(subject).to include(link("rails", "https://rubygems.org/gems/rails"))
      expect(subject).to include(link("rails-deprecated_sanitizer", "https://rubygems.org/gems/rails-deprecated_sanitizer"))
      expect(subject).to include(link("responders", "https://rubygems.org/gems/responders"))
      expect(subject).to include(link("sprockets", "https://rubygems.org/gems/sprockets"))
      expect(subject).to include(link("default_value_for", "https://rubygems.org/gems/default_value_for"))
    end

    it "links GitHub repos" do
      expect(subject).to include(link("rails/rails", "https://github.com/rails/rails"))
      expect(subject).to include(link("rails/responders", "https://github.com/rails/responders"))
    end
  end
end
