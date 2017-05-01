class SnippetBlob
  include Linguist::BlobHelper

  attr_reader :snippet

  def initialize(snippet)
    @snippet = snippet
  end

  delegate :id, to: :snippet

  def name
    snippet.file_name
  end

  alias_method :path, :name

  def size
    data.bytesize
  end

  def data
    snippet.content
  end

  def rendered_markup
    return unless Gitlab::MarkupHelper.gitlab_markdown?(name)

    Banzai.render_field(snippet, :content)
  end

  def mode
    nil
  end

  def binary?
    false
  end

  def load_all_data!(repository)
    # No-op
  end

  def truncated?
    false
  end

  def external_storage
    nil
  end
end
