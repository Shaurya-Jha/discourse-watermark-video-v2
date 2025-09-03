# frozen_string_literal: true

# name: discourse-watermark-video-v2
# about: Automatically watermarks uploaded videos with a custom image
# version: 0.0.1
# authors: Shaurya-Jha

enabled_site_setting :watermark_v2_enabled

module ::WatermarkV2
  PLUGIN_NAME = "discourse-watermark-video-v2"
end

# Load engine + settings before hooks
require_relative "lib/watermark_v2/engine"

after_initialize do
  module ::WatermarkV2
    module UploadCreatorExtension
      def create_for(user_id)
        if @filename =~ /\.(mp4|mov|avi|mkv)$/i && @file && File.exist?(@file.path)
          Rails.logger.warn("🔥 WatermarkV2: watermarking temp file #{@filename} before upload save")
          ::WatermarkV2::Watermarker.apply_tempfile(@file.path)
        end

        super
      end

      def sha1
        if @filename =~ /\.(mp4|mov|avi|mkv)$/i
          fake_sha1 = SecureRandom.hex(20)
          Rails.logger.warn("🔥 WatermarkV2: fake SHA1 for #{@filename} → #{fake_sha1}")
          fake_sha1
        else
          super
        end
      end

      def find_existing_upload
        if @filename =~ /\.(mp4|mov|avi|mkv)$/i
          Rails.logger.warn("🔥 WatermarkV2: skipping DB dedupe for #{@filename}")
          return nil
        end
        super
      end
    end
  end

  ::UploadCreator.prepend(::WatermarkV2::UploadCreatorExtension)

end
