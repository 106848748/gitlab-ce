module Ci
  class ArtifactBlob
    include Linguist::BlobHelper

    attr_reader :entry

    def initialize(entry)
      @entry = entry
    end

    def id
      Digest::SHA1.hexdigest(@entry.path)
    end

    def name
      entry.name
    end

    def path
      entry.path
    end

    def size
      @entry.metadata[:size]
    end

    def data
      "Build artifact #{path}"
    end

    def mode
      @entry.metadata[:mode]
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
      :build_artifact
    end

    alias_method :external_size, :size
  end
end
