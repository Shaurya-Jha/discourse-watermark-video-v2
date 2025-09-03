# frozen_string_literal: true

module ::WatermarkV2
  class Watermarker
    # WATERMARK_PATH = Rails.root.join("plugins", "discourse-watermark-video-v2", "assets", "images", "watermark.png")
    # 
    # More robust way to prevent wrong watermark path is as below:
    plugin_root = Rails.root.join("plugins", WatermarkV2::PLUGIN_NAME)
    WATERMARK_PATH = File.join(plugin_root, "assets", "images", "watermark.png")

    def self.apply_tempfile(path)
      tmp_path = File.join(File.dirname(path), "wm_#{SecureRandom.hex(6)}.mp4")

      size_percent = SiteSetting.watermark_v2_size_percent.to_f / 100.0

      position = case SiteSetting.watermark_v2_position
                when "top-left"     then "10:10"
                when "top-right"    then "main_w-overlay_w-10:10"
                when "bottom-left"  then "10:main_h-overlay_h-10"
                when "bottom-right" then "main_w-overlay_w-10:main_h-overlay_h-10"
                else "10:10"
                end

      filter_complex = "[1:v][0:v]scale2ref=w=-1:h=ih*#{size_percent}[wm][base];[base][wm]overlay=#{position},format=yuv420p"

      ffmpeg_cmd = <<~CMD
        ffmpeg -y -i #{Shellwords.escape(path)} -i #{Shellwords.escape(WATERMARK_PATH.to_s)} \
        -filter_complex "#{filter_complex}" \
        -c:v libx264 -preset veryfast -crf 23 -c:a aac -b:a 128k \
        #{Shellwords.escape(tmp_path)}
      CMD

      Rails.logger.warn("🔥 WatermarkV2: running ffmpeg on temp file #{path}")

      success = system(ffmpeg_cmd)

      if success && File.exist?(tmp_path) && File.size(tmp_path) > 0
        FileUtils.mv(tmp_path, path, force: true)
        Rails.logger.warn("🔥 WatermarkV2: successfully watermarked temp file #{path}")
      else
        FileUtils.rm_f(tmp_path)
        Rails.logger.error("🔥 WatermarkV2: ffmpeg failed for temp file #{path}, keeping original")
      end
    end


    # def self.apply(upload)
    #   input_path = Discourse.store.path_for(upload)
    #   unless input_path && File.exist?(input_path)
    #     Rails.logger.error("🔥 WatermarkV2: input file missing for upload #{upload.id} → #{input_path}")
    #     return
    #   end

    #   tmp_path = File.join(File.dirname(input_path), "tmp_wm_#{SecureRandom.hex(6)}.mp4")

    #   size_percent = SiteSetting.watermark_v2_size_percent
    #   scale_filter = "scale=-1:main_h*#{size_percent}/100"

    #   position = case SiteSetting.watermark_v2_position
    #              when "top-left"     then "10:10"
    #              when "top-right"    then "main_w-overlay_w-10:10"
    #              when "bottom-left"  then "10:main_h-overlay_h-10"
    #              when "bottom-right" then "main_w-overlay_w-10:main_h-overlay_h-10"
    #              else "10:10"
    #              end

    #   filter_complex = "[1:v]#{scale_filter}[wm];[0:v][wm]overlay=#{position},format=yuv420p"

    #   ffmpeg_cmd = <<~CMD
    #     ffmpeg -y -i #{Shellwords.escape(input_path)} -i #{Shellwords.escape(WATERMARK_PATH.to_s)} \
    #     -filter_complex "#{filter_complex}" \
    #     -c:v libx264 -preset veryfast -crf 23 -c:a aac -b:a 128k \
    #     #{Shellwords.escape(tmp_path)}
    #   CMD

    #   Rails.logger.warn("🔥 WatermarkV2: running ffmpeg for upload #{upload.id}")

    #   success = system(ffmpeg_cmd)

    #   if success && File.exist?(tmp_path) && File.size(tmp_path) > 0
    #     FileUtils.mv(tmp_path, input_path, force: true)

    #     new_size = File.size(input_path)
    #     new_sha1 = Digest::SHA1.file(input_path).hexdigest
    #     upload.update!(filesize: new_size, sha1: new_sha1)

    #     Rails.logger.warn("🔥 WatermarkV2: replaced upload #{upload.id}, size=#{new_size}, sha1=#{new_sha1}")
    #   else
    #     FileUtils.rm_f(tmp_path)
    #     Rails.logger.error("🔥 WatermarkV2: ffmpeg failed for #{input_path}, keeping original file")
    #   end
    # end
  end
end
