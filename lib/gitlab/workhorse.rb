require 'base64'
require 'json'
require 'securerandom'
require 'uri'

module Gitlab
  class Workhorse
    SEND_DATA_HEADER = 'Gitlab-Workhorse-Send-Data'.freeze
    VERSION_FILE = 'GITLAB_WORKHORSE_VERSION'.freeze
    INTERNAL_API_CONTENT_TYPE = 'application/vnd.gitlab-workhorse+json'.freeze
    INTERNAL_API_REQUEST_HEADER = 'Gitlab-Workhorse-Api-Request'.freeze
    NOTIFICATION_CHANNEL = 'workhorse:notifications'.freeze

    # Supposedly the effective key size for HMAC-SHA256 is 256 bits, i.e. 32
    # bytes https://tools.ietf.org/html/rfc4868#section-2.6
    SECRET_LENGTH = 32

    class << self
      def git_http_ok(repository, user)
        repo_path = repository.path_to_repo
        params = {
          GL_ID: Gitlab::GlId.gl_id(user),
          RepoPath: repo_path,
        }

        if Gitlab.config.gitaly.enabled
          storage = repository.project.repository_storage
          address = Gitlab::GitalyClient.get_address(storage)
          params[:GitalySocketPath] = URI(address).path
          # TODO: use GitalyClient code to assemble the Repository message
          params[:Repository] = Gitaly::Repository.new(
            path: repo_path,
            storage_name: storage,
            relative_path: Gitlab::RepoPath.strip_storage_path(repo_path),
          ).to_h
        end

        params
      end

      def lfs_upload_ok(oid, size)
        {
          StoreLFSPath: "#{Gitlab.config.lfs.storage_path}/tmp/upload",
          LfsOid: oid,
          LfsSize: size,
        }
      end

      def artifact_upload_ok
        { TempPath: ArtifactUploader.artifacts_upload_path }
      end

      def send_git_blob(repository, blob)
        params = {
          'RepoPath' => repository.path_to_repo,
          'BlobId' => blob.id,
        }

        [
          SEND_DATA_HEADER,
          "git-blob:#{encode(params)}"
        ]
      end

      def send_git_archive(repository, ref:, format:)
        format ||= 'tar.gz'
        format.downcase!
        params = repository.archive_metadata(ref, Gitlab.config.gitlab.repository_downloads_path, format)
        raise "Repository or ref not found" if params.empty?

        [
          SEND_DATA_HEADER,
          "git-archive:#{encode(params)}"
        ]
      end

      def send_git_diff(repository, diff_refs)
        params = {
          'RepoPath'  => repository.path_to_repo,
          'ShaFrom'   => diff_refs.base_sha,
          'ShaTo'     => diff_refs.head_sha
        }

        [
          SEND_DATA_HEADER,
          "git-diff:#{encode(params)}"
        ]
      end

      def send_git_patch(repository, diff_refs)
        params = {
          'RepoPath'  => repository.path_to_repo,
          'ShaFrom'   => diff_refs.base_sha,
          'ShaTo'     => diff_refs.head_sha
        }

        [
          SEND_DATA_HEADER,
          "git-format-patch:#{encode(params)}"
        ]
      end

      def send_artifacts_entry(build, entry)
        params = {
          'Archive' => build.artifacts_file.path,
          'Entry' => Base64.encode64(entry.path)
        }

        [
          SEND_DATA_HEADER,
          "artifacts-entry:#{encode(params)}"
        ]
      end

      def terminal_websocket(terminal)
        details = {
          'Terminal' => {
            'Subprotocols' => terminal[:subprotocols],
            'Url' => terminal[:url],
            'Header' => terminal[:headers],
            'MaxSessionTime' => terminal[:max_session_time],
          }
        }
        details['Terminal']['CAPem'] = terminal[:ca_pem] if terminal.has_key?(:ca_pem)

        details
      end

      def version
        path = Rails.root.join(VERSION_FILE)
        path.readable? ? path.read.chomp : 'unknown'
      end

      def secret
        @secret ||= begin
          bytes = Base64.strict_decode64(File.read(secret_path).chomp)
          raise "#{secret_path} does not contain #{SECRET_LENGTH} bytes" if bytes.length != SECRET_LENGTH
          bytes
        end
      end

      def write_secret
        bytes = SecureRandom.random_bytes(SECRET_LENGTH)
        File.open(secret_path, 'w:BINARY', 0600) do |f|
          f.chmod(0600) # If the file already existed, the '0600' passed to 'open' above was a no-op.
          f.write(Base64.strict_encode64(bytes))
        end
      end

      def verify_api_request!(request_headers)
        decode_jwt(request_headers[INTERNAL_API_REQUEST_HEADER])
      end

      def decode_jwt(encoded_message)
        JWT.decode(
          encoded_message,
          secret,
          true,
          { iss: 'gitlab-workhorse', verify_iss: true, algorithm: 'HS256' },
        )
      end

      def secret_path
        Rails.root.join('.gitlab_workhorse_secret')
      end

      def set_key_and_notify(key, value, expire: nil, overwrite: true)
        Gitlab::Redis.with do |redis|
          result = redis.set(key, value, ex: expire, nx: !overwrite)
          if result
            redis.publish(NOTIFICATION_CHANNEL, "#{key}=#{value}")
            value
          else
            redis.get(key)
          end
        end
      end

      protected

      def encode(hash)
        Base64.urlsafe_encode64(JSON.dump(hash))
      end
    end
  end
end
