# frozen_string_literal: true

module Jobs
  class VideoWatermarkJob < ::Jobs::Base
    def execute(args)
      upload_id = args[:upload_id]
      upload = Upload.find_by(id: upload_id)
      return unless upload

      ::WatermarkV2::Watermarker.apply(upload)
    end
  end
end