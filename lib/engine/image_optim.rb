require 'codeclimate_engine'
require 'image_optim'

require 'active_support'
require 'active_support/number_helper'

require 'engine/file_list'

module Engine
  class ImageOptim
    DEFAULT_MIN_THRESHOLD = 5
    DEFAULT_PATHS = [
      '**/*.gif',
      '**/*.jpeg',
      '**/*.jpg',
      '**/*.png',
      '**/*.svg'
    ]

    def initialize(root, engine_config, io)
      @root = root
      @engine_config = engine_config || {}
      @io = io
    end

    def run
      optimizer.optimize_images(images_to_inspect) do |image, optimized|
        if optimized && above_threshold?(optimized)
          @io.print(create_issue(image, optimized).render)
        end
      end
    end

    private

    def create_issue(path, optimized)
      path = path.sub("#{@root}/", '')

      CCEngine::Issue.new(
        check_name: 'Unoptimized Image',
        description: "Optimizing `#{path}` could save #{image_size_diff(optimized)} (#{percentage_diff(optimized)}).",
        categories: %w(Performance),
        location: CCEngine::Location::LineRange.new(path: path, line_range: 1..1)
      )
    end

    def above_threshold?(optimized)
      threshold = @engine_config.fetch('min_threshold') { DEFAULT_MIN_THRESHOLD }

      optimized_percentage(optimized) > threshold
    end

    def image_size_diff(optimized)
      original_size = optimized.original_size
      optimized_size = optimized.size

      number_to_human_size(original_size - optimized_size)
    end

    def percentage_diff(optimized)
      number_to_percentage(optimized_percentage(optimized), precision: 2)
    end

    def images_to_inspect
      list = FileList.new(root: @root, engine_config: @engine_config, default_paths: DEFAULT_PATHS)
      list.files
    end

    def optimizer
      @optimizer ||= ::ImageOptim.new(pngcrush: false)
    end

    def number_to_human_size(number, options = {})
      ActiveSupport::NumberHelper.number_to_human_size(number, options)
    end

    def optimized_percentage(optimized)
      original_size = optimized.original_size
      optimized_size = optimized.size

      100 - 100.0 * optimized_size / original_size
    end

    def number_to_percentage(number, options = {})
      ActiveSupport::NumberHelper.number_to_percentage(number, options)
    end
  end
end
