# frozen_string_literal: true

module ::WatermarkV2
  module UploadExtension
    def self.prepended(base)
      base.after_commit :watermark_v2_apply, on: :create
    end

    def watermark_v2_apply
      if SiteSetting.watermark_v2_enabled && original_filename =~ /\.(mp4|mov|avi|mkv)$/i
        Rails.logger.warn("🔥 WatermarkV2: applying watermark inline to #{original_filename}")
        ::WatermarkV2::Watermarker.apply(self)
      end
    end
  end
end
