module ShikimoriDomain
  RU_HOSTS = %w[shikimori.one shikimori.org] + (
    Rails.env.development? ? %w[shikimori.local ru.shikimori.local localhost] : []
  )
  EN_HOSTS = %w[] + (
    Rails.env.development? ? %w[en.shikimori.local] : []
  )
  CLEAN_HOSTS = %w[shikimori.one]

  HOSTS = RU_HOSTS + EN_HOSTS

  def self.matches? request
    !AnimeOnlineDomain.matches?(request)
  end
end
