require 'spec_helper'

describe Gitlab::Highlight, lib: true do
  include RepoHelpers

  let(:project) { create(:project) }
  let(:repository) { project.repository }
  let(:commit) { project.commit(sample_commit.id) }

  describe '.highlight_lines' do
    let(:lines) do
      described_class.highlight_lines(project.repository, commit.id, 'files/ruby/popen.rb')
    end

    it 'should properly highlight all the lines' do
      expect(lines[4]).to eq(%Q{<span id="LC5" class="line">  <span class="kp">extend</span> <span class="nb">self</span></span>\n})
      expect(lines[21]).to eq(%Q{<span id="LC22" class="line">    <span class="k">unless</span> <span class="no">File</span><span class="p">.</span><span class="nf">directory?</span><span class="p">(</span><span class="n">path</span><span class="p">)</span></span>\n})
      expect(lines[26]).to eq(%Q{<span id="LC27" class="line">    <span class="vi">@cmd_status</span> <span class="o">=</span> <span class="mi">0</span></span>\n})
    end
  end

  describe 'custom highlighting from .gitattributes' do
    let(:branch) { 'gitattributes' }
    let(:blob) { repository.blob_at_branch(branch, path) }

    let(:highlighter) do
      Gitlab::Highlight.new(blob.path, blob.data, repository: repository)
    end

    before { project.change_head('gitattributes') }

    describe 'basic language selection' do
      let(:path) { 'custom-highlighting/test.gitlab-custom' }
      it 'highlights as ruby' do
        expect(highlighter.lexer.tag).to eq 'ruby'
      end
    end

    describe 'cgi options' do
      let(:path) { 'custom-highlighting/test.gitlab-cgi' }

      it 'highlights as json with erb' do
        expect(highlighter.lexer.tag).to eq 'erb'
        expect(highlighter.lexer.parent.tag).to eq 'json'
      end
    end
  end

  describe '#highlight' do
    subject { described_class.highlight(file_name, file_content, nowrap: false) }

    context "plain text file" do
      let(:file_name) { "example.txt" }
      let(:file_content) do
        <<-CONTENT.strip_heredoc
          URL: http://www.google.com
          Email: hello@example.com
        CONTENT
      end

      it "links URLs" do
        expect(subject).to include(%{<a href="http://www.google.com" rel="nofollow noreferrer" target="_blank">http://www.google.com</a>})
      end

      it "links emails" do
        expect(subject).to include(%{<a href="mailto:hello@example.com">hello@example.com</a>})
      end
    end

    context "file with highlighting" do
      let(:file_name) { "example.rb" }
      let(:file_content) do
        <<-CONTENT.strip_heredoc
          # URL in comment: http://www.google.com
          # Email in comment: hello@example.com

          "URL in string: http://www.google.com"
          "Email in string: hello@example.com"
        CONTENT
      end

      context "in a comment" do
        it "links URLs" do
          expect(subject).to include(%{URL in comment: <a href="http://www.google.com" rel="nofollow noreferrer" target="_blank">http://www.google.com</a>})
        end

        it "links emails" do
          expect(subject).to include(%{Email in comment: <a href="mailto:hello@example.com">hello@example.com</a>})
        end
      end

      context "in a string" do
        it "links URLs" do
          expect(subject).to include(%{URL in string: <a href="http://www.google.com" rel="nofollow noreferrer" target="_blank">http://www.google.com</a>})
        end

        it "links emails" do
          expect(subject).to include(%{Email in string: <a href="mailto:hello@example.com">hello@example.com</a>})
        end
      end
    end

    it 'links dependencies via DependencyLinker' do
      expect(Gitlab::DependencyLinker).to receive(:link).
        with('file.name', 'Contents', anything).and_call_original

      described_class.highlight('file.name', 'Contents')
    end
  end
end
