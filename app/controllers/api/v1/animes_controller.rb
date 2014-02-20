class Api::V1::AnimesController < Api::V1::ApiController
  respond_to :json, :xml

  # DOC GENERATED AUTOMATICALLY: REMOVE THIS LINE TO PREVENT REGENARATING NEXT TIME
  api :GET, "/animes/:id", "Show an anime"
  def show
    respond_with Anime.find(params[:id]).decorate, serializer: AnimeProfileSerializer
  end

  # DOC GENERATED AUTOMATICALLY: REMOVE THIS LINE TO PREVENT REGENARATING NEXT TIME
  api :GET, "/animes", "List animes"
  def index
    limit = [[params[:limit].to_i, 1].max, 100].min
    page = [params[:page].to_i, 1].max

    @collection = Rails.cache.fetch cache_key do
      AniMangaQuery
        .new(Anime, params, current_user)
        .fetch(page, limit)
        .to_a
    end

    respond_with @collection, each_serializer: AnimeSerializer
  end

private
  def cache_key
    Digest::MD5.hexdigest "#{request.path}|#{params.to_json}|#{params[:mylist].present? ? current_user.try(:cache_key) : nil}"
  end
end
