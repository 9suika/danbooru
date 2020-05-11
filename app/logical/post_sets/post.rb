module PostSets
  class Post
    MAX_PER_PAGE = 200
    MAX_SIDEBAR_TAGS = 25

    attr_reader :page, :random, :post_count, :format, :tag_string, :query

    def initialize(tags, page = 1, per_page = nil, random: false, format: "html")
      @query = PostQueryBuilder.new(tags, CurrentUser.user, safe_mode: CurrentUser.safe_mode?, hide_deleted_posts: CurrentUser.hide_deleted_posts?)
      @tag_string = tags
      @page = page
      @per_page = per_page
      @random = random.to_s.truthy?
      @format = format.to_s
    end

    def humanized_tag_string
      query.split_query.map { |tag| tag.tr("_", " ").titleize }.to_sentence
    end

    def has_blank_wiki?
      tag.present? && !wiki_page.present?
    end

    def wiki_page
      return nil unless tag.present? && tag.wiki_page.present?
      return nil unless !tag.wiki_page.is_deleted?
      tag.wiki_page
    end

    def tag
      return nil unless query.has_single_tag?
      @tag ||= Tag.find_by(name: query.tags.first.name)
    end

    def artist
      return nil unless tag.present? && tag.category == Tag.categories.artist
      return nil unless tag.artist.present? && !tag.artist.is_deleted?
      tag.artist
    end

    def pool
      pool_names = query.select_metatags(:pool, :ordpool).map(&:value)
      name = pool_names.first
      return nil unless pool_names.size == 1

      @pool ||= Pool.find_by_name(name)
    end

    def favgroup
      favgroup_names = query.select_metatags(:favgroup, :ordfavgroup).map(&:value)
      name = favgroup_names.first
      return nil unless favgroup_names.size == 1

      @favgroup ||= FavoriteGroup.visible(CurrentUser.user).find_by_name_or_id(name, CurrentUser.user)
    end

    def has_explicit?
      posts.any? {|x| x.rating == "e"}
    end

    def hidden_posts
      posts.reject(&:visible?)
    end

    def banned_posts
      posts.select(&:banblocked?)
    end

    def censored_posts
      posts.select { |p| p.levelblocked? && !p.banblocked? }
    end

    def safe_posts
      posts.select { |p| p.safeblocked? && !p.levelblocked? && !p.banblocked? }
    end

    def per_page
      (@per_page || query.find_metatag(:limit) || CurrentUser.user.per_page).to_i.clamp(0, MAX_PER_PAGE)
    end

    def is_random?
      random || query.find_metatag(:order) == "random"
    end

    def get_post_count
      if %w(json atom xml).include?(format.downcase)
        # no need to get counts for formats that don't use a paginator
        nil
      else
        query.fast_count
      end
    end

    def get_random_posts
      per_page.times.inject([]) do |all, x|
        all << ::Post.user_tag_match(tag_string).random
      end.compact.uniq
    end

    def posts
      @posts ||= begin
        @post_count = get_post_count

        if is_random?
          temp = get_random_posts
        else
          temp = query.build.paginate(page, count: post_count, search_count: !post_count.nil?, limit: per_page)
        end
      end
    end

    def hide_from_crawler?
      return true if current_page > 1
      return false if query.is_empty_search? || query.is_simple_tag? || query.is_metatag?(:order, :rank)
      true
    end

    def current_page
      [page.to_i, 1].max
    end

    def best_post
      # be smarter about this in the future
      posts.reject(&:is_deleted).select(&:visible?).max_by(&:fav_count)
    end

    def pending_bulk_update_requests
      return BulkUpdateRequest.none unless tag.present?
      @pending_bulk_update_requests ||= BulkUpdateRequest.pending.where_array_includes_any(:tags, tag.name)
    end

    def post_previews_html(template, show_cropped: true, **options)
      html = ""
      if none_shown(options)
        return template.render("post_sets/blank")
      end

      posts.each do |post|
        html << PostPresenter.preview(post, options.merge(:tags => tag_string))
        html << "\n"
      end

      html.html_safe
    end

    def not_shown(post, options)
      !options[:show_deleted] && post.is_deleted? && tag_string !~ /status:(?:all|any|deleted|banned)/
    end

    def none_shown(options)
      posts.reject {|post| not_shown(post, options) }.empty?
    end

    concerning :TagListMethods do
      def related_tags
        if query.is_wildcard_search?
          wildcard_tags
        elsif query.is_metatag?(:search)
          saved_search_tags
        elsif query.is_empty_search? || query.is_metatag?(:order, :rank)
          popular_tags
        elsif query.is_single_term?
          similar_tags
        else
          frequent_tags
        end
      end

      def popular_tags
        if PopularSearchService.enabled?
          PopularSearchService.new(Date.today).tags
        else
          frequent_tags
        end
      end

      def similar_tags
        RelatedTagCalculator.cached_similar_tags_for_search(query, MAX_SIDEBAR_TAGS)
      end

      def frequent_tags
        RelatedTagCalculator.frequent_tags_for_post_array(posts).take(MAX_SIDEBAR_TAGS)
      end

      def wildcard_tags
        Tag.wildcard_matches(tag_string)
      end

      def saved_search_tags
        ["search:all"] + SavedSearch.labels_for(CurrentUser.user.id).map {|x| "search:#{x}"}
      end

      def tag_set_presenter
        @tag_set_presenter ||= TagSetPresenter.new(related_tags.take(MAX_SIDEBAR_TAGS))
      end

      def tag_list_html(**options)
        tag_set_presenter.tag_list_html(name_only: query.is_metatag?(:search), **options)
      end
    end
  end
end
