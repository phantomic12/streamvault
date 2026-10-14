# frozen_string_literal: true

module ParentalControls
  # Enforces a child account's rating limit.  Every surface that returns
  # catalog content (search, home rows, listings) filters through #filter,
  # and every surface that serves content by ID (content pages, playback)
  # checks #allowed? — so content above the configured max_rating_age is
  # neither listed nor playable even when the user bypasses search and
  # requests an item ID directly.
  class ContentPolicy
    FILTER_CONCURRENCY = 8

    def initialize(user, resolver: RatingResolver.new)
      @user = user
      @resolver = resolver
    end

    def child_account?
      @user.child_account?
    end

    def max_age
      @user.max_rating_age.to_i
    end

    # True unless this is a child account whose rating limit excludes the
    # title.  Titles without a resolvable rating are blocked (they resolve
    # to Rating::UNKNOWN_AGE).
    def allowed?(imdb_id)
      return true unless child_account?
      return false if imdb_id.blank?

      @resolver.min_age(imdb_id) <= max_age
    end

    # Returns only the items whose IMDb ID passes #allowed?.  For plain
    # (non-child) accounts the input is returned untouched with no rating
    # lookups at all.  +items+ is any enumerable whose entries either
    # respond to #imdb_id or are hashes with an :imdb_id key; a block can
    # be given to extract the IMDb ID from other shapes.  Rating lookups
    # are remote, so items are checked in small concurrent batches.
    def filter(items)
      list = items.to_a
      return list unless child_account?

      allowed = Array.new(list.size)
      queue = (0...list.size).to_a
      mutex = Mutex.new

      workers = Array.new([ list.size, FILTER_CONCURRENCY ].min) do
        Thread.new do
          while (index = mutex.synchronize { queue.shift })
            item = list[index]
            imdb_id = block_given? ? yield(item) : default_imdb_id(item)
            allowed[index] = allowed?(imdb_id)
          end
        end
      end
      workers.each(&:join)

      list.each_with_index.filter_map { |item, index| item if allowed[index] }
    end

    private

    def default_imdb_id(item)
      if item.respond_to?(:imdb_id)
        item.imdb_id
      elsif item.is_a?(Hash)
        item[:imdb_id] || item["imdb_id"]
      end
    end
  end
end
