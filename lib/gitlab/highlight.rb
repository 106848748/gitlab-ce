module Gitlab
  class Highlight
    def self.highlight(blob_name, blob_content, repository: nil, nowrap: true, plain: false)
      new(blob_name, blob_content, nowrap: nowrap, repository: repository).
        highlight(blob_content, continue: false, plain: plain)
    end

    def self.highlight_lines(repository, ref, file_name)
      blob = repository.blob_at(ref, file_name)
      return [] unless blob

      blob.load_all_data!(repository)
      highlight(file_name, blob.data, repository: repository).lines.map!(&:html_safe)
    end

    attr_reader :lexer
    def initialize(blob_name, blob_content, repository: nil, nowrap: true)
      @blob_name = blob_name
      @blob_content = blob_content
      @repository = repository
      @formatter = rouge_formatter(nowrap: nowrap)

      @lexer = custom_language || begin
        Rouge::Lexer.guess(filename: blob_name, source: blob_content).new
      rescue Rouge::Lexer::AmbiguousGuess => e
        e.alternatives.sort_by(&:tag).first
      end
    end

    def highlight(text, continue: true, plain: false)
      highlighted_text = highlight_text(text, continue: continue, plain: plain)
      autolink_strings(highlighted_text)
    end

    private

    def custom_language
      language_name = @repository && @repository.gitattribute(@blob_name, 'gitlab-language')

      return nil unless language_name

      Rouge::Lexer.find_fancy(language_name)
    end

    def highlight_text(text, continue: true, plain: false)
      if plain
        highlight_plain(text)
      else
        highlight_rich(text, continue: continue)
      end
    end

    def highlight_plain(text)
      @formatter.format(Rouge::Lexers::PlainText.lex(text)).html_safe
    end

    def highlight_rich(text, continue: true)
      @formatter.format(@lexer.lex(text, continue: continue)).html_safe
    rescue
      highlight_plain(text)
    end

    def autolink_strings(highlighted_text)
      doc = Nokogiri::HTML::DocumentFragment.parse(highlighted_text)

      # Files without highlighting have all text in `span.line`.
      # Files with highlighting have strings and comments in `span`s with a
      # `class` starting with `c` or `s`.
      doc.xpath('.//span[@class="line" or starts-with(@class, "c") or starts-with(@class, "s")]/text()').each do |node|
        content = node.to_html
        html = Banzai.render(content, pipeline: :autolink, autolink_emails: true)

        next if html == content

        node.replace(html)
      end

      doc.to_html.html_safe
    end

    def rouge_formatter(options = {})
      options = options.reverse_merge(
        nowrap: true,
        cssclass: 'code highlight',
        lineanchors: true,
        lineanchorsid: 'LC'
      )

      Rouge::Formatters::HTMLGitlab.new(options)
    end
  end
end
