module Gitlab
  module Database
    module RenameReservedPathsMigration
      module Namespaces
        include Gitlab::ShellAdapter

        def rename_namespaces(paths, type:)
          namespaces_for_paths(paths, type: type).each do |namespace|
            rename_namespace(namespace)
          end
        end

        def namespaces_for_paths(paths, type:)
          namespaces = if type == :wildcard
                         MigrationClasses::Namespace.where.not(parent_id: nil)
                       elsif type == :top_level
                         MigrationClasses::Namespace.where(parent_id: nil)
                       end
          namespaces.where(path: paths.map(&:downcase))
        end

        def rename_namespace(namespace)
          old_path = namespace.path
          old_full_path = namespace.full_path
          # Only remove the last occurrence of the path name to get the parent namespace path
          namespace_path = remove_last_occurrence(old_full_path, old_path)
          new_path = rename_path(namespace_path, old_path)
          new_full_path = if namespace_path.present?
                            File.join(namespace_path, new_path)
                          else
                            new_path
                          end

          # skips callbacks & validations
          MigrationClasses::Namespace.where(id: namespace).
            update_all(path: new_path)

          replace_statement = replace_sql(Route.arel_table[:path],
                                          old_full_path,
                                          new_full_path)

          update_column_in_batches(:routes, :path, replace_statement)  do |table, query|
            query.where(MigrationClasses::Route.arel_table[:path].matches("#{old_full_path}%"))
          end

          move_repositories(namespace, old_full_path, new_full_path)
          move_namespace_folders(uploads_dir, old_full_path, new_full_path) if file_storage?
          move_namespace_folders(pages_dir, old_full_path, new_full_path)
        end

        def move_namespace_folders(directory, old_relative_path, new_relative_path)
          old_path = File.join(directory, old_relative_path)
          return unless File.directory?(old_path)

          new_path = File.join(directory, new_relative_path)
          FileUtils.mv(old_path, new_path)
        end

        def move_repositories(namespace, old_full_path, new_full_path)
          repo_paths_for_namespace(namespace).each do |repository_storage_path|
            # Ensure old directory exists before moving it
            gitlab_shell.add_namespace(repository_storage_path, old_full_path)

            unless gitlab_shell.mv_namespace(repository_storage_path, old_full_path, new_full_path)
              message = "Exception moving path #{repository_storage_path} \
                           from #{old_full_path} to #{new_full_path}"
              Rails.logger.error message
            end
          end
        end

        def repo_paths_for_namespace(namespace)
          projects_for_namespace(namespace).
            select('distinct(repository_storage)').map(&:repository_storage_path)
        end

        def projects_for_namespace(namespace)
          namespace_ids = child_ids_for_parent(namespace, ids: [namespace.id])
          namespace_or_children = MigrationClasses::Project.
                                    arel_table[:namespace_id].
                                    in(namespace_ids)
          MigrationClasses::Project.unscoped.where(namespace_or_children)
        end

        # This won't scale to huge trees, but it should do for a handful of
        # namespaces called `system`.
        def child_ids_for_parent(namespace, ids: [])
          namespace.children.each do |child|
            ids << child.id
            child_ids_for_parent(child, ids: ids) if child.children.any?
          end
          ids
        end

        def remove_last_occurrence(string, pattern)
          string.reverse.sub(pattern.reverse, "").reverse
        end

        def file_storage?
          CarrierWave::Uploader::Base.storage == CarrierWave::Storage::File
        end

        def uploads_dir
          File.join(CarrierWave.root, "uploads")
        end

        def pages_dir
          Settings.pages.path
        end
      end
    end
  end
end