require 'pathname'

module Engine
  class FileList
    def initialize(root:, engine_config:, default_paths:)
      @root = root
      @engine_config = engine_config
      @default_paths = default_paths
    end

    def files
      Array(matching_files) & Array(included_files)
    end

    private

    attr_reader :engine_config, :default_paths, :root

    def matching_files
      paths.map do |glob|
        Dir.glob("#{root}/#{glob}").reject do |path|
          File.directory?(path)
        end
      end.flatten
    end

    def paths
      default_paths
    end

    def included_files
      include_paths.
        map { |path| expand_path(path) }.
        map { |path| collect_files(path) }.flatten.compact
    end

    def collect_files(path)
      if File.directory?(path)
        Dir.entries(path).map do |new_path|
          next if [".", ".."].include?(new_path)
          collect_files File.join(path, new_path)
        end
      else
        path
      end
    end

    def expand_path(path)
      File.join(root, path)
    end

    def include_paths
      engine_config.fetch('include_paths', [])
    end
  end
end
