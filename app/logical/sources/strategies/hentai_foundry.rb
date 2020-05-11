# Image URLs
#
# * https://pictures.hentai-foundry.com/a/Afrobull/795025/Afrobull-795025-kuroeda.png
#
# Page URLs
#
# * https://www.hentai-foundry.com/pictures/user/Afrobull/795025/kuroeda
# * https://www.hentai-foundry.com/pictures/user/Afrobull/795025o
#
# Preview URLs
#
# * https://thumbs.hentai-foundry.com/thumb.php?pid=795025&size=350
#
# Profile URLs
#
# * https://www.hentai-foundry.com/user/kajinman/profile
# * https://www.hentai-foundry.com/pictures/user/kajinman
# * https://www.hentai-foundry.com/pictures/user/kajinman/scraps
# * https://www.hentai-foundry.com/user/J-likes-to-draw/profile

module Sources
  module Strategies
    class HentaiFoundry < Base
      BASE_URL =    %r!\Ahttps?://(?:www\.)?hentai-foundry\.com!i
      PAGE_URL =    %r!#{BASE_URL}/pictures/user/(?<artist_name>[\w-]+)/(?<illust_id>\d+)(?:/[\w-]*)?(\?[\w=]*)?\z!i
      PROFILE_URL = %r!#{BASE_URL}/(?:pictures/)?user/(?<artist_name>[\w-]+)(?:/[a-z]*)?\z!i
      IMAGE_URL =   %r!\Ahttps?://pictures\.hentai-foundry\.com/\w/(?<artist_name>[\w-]+)/(?<illust_id>\d+)/[\w-]+\.\w+\z!i

      def domains
        ["hentai-foundry.com"]
      end

      def site_name
        "Hentai Foundry"
      end

      def image_urls
        image = page&.search("#picBox img")

        return [] unless image

        image.to_a.map { |img| URI.join(page_url, img["src"]).to_s }
      end

      def preview_urls
        image_urls.map do
          "https://thumbs.hentai-foundry.com/thumb.php?pid=#{illust_id}&size=250"
        end
      end

      def page_url
        return nil if illust_id.blank? || artist_name.blank?
        "https://www.hentai-foundry.com/pictures/user/#{artist_name}/#{illust_id}"
      end

      def page
        return nil if page_url.blank?

        doc = Cache.get("hentai-foundry:#{page_url}", 1.minute) do
          HTTParty.get("#{page_url}?enterAgree=1").body
        end

        Nokogiri::HTML(doc)
      end

      def tags
        tags = page&.search(".boxbody [rel='tag']") || []

        tags.map do |tag|
          [tag.text, URI.join(page_url, tag.attr("href")).to_s]
        end
      end

      def artist_name
        urls.map { |url| url[PROFILE_URL, :artist_name] || url[PAGE_URL, :artist_name] || url[IMAGE_URL, :artist_name] }.compact.first
      end

      def canonical_url
        image_url
      end

      def profile_url
        return nil if artist_name.blank?
        "https://www.hentai-foundry.com/user/#{artist_name}"
      end

      def artist_commentary_title
        page&.search("#picBox .imageTitle")&.text
      end

      def artist_commentary_desc
        page&.search("#descriptionBox .picDescript")&.to_html
      end

      def dtext_artist_commentary_desc
        DText.from_html(artist_commentary_desc).gsub(/\A[[:space:]]+|[[:space:]]+\z/, "").gsub(/\n+/, "\n")
      end

      def normalizable_for_artist_finder?
        artist_name.present?
      end

      def normalized_for_artist_finder?
        url =~ PROFILE_URL
      end

      def illust_id
        url[PAGE_URL, :illust_id] || url[IMAGE_URL, :illust_id]
      end
    end
  end
end
