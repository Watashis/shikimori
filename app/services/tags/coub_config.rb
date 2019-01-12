class Tags::CoubConfig
  CONFIG_PATH = 'config/app/coub_tags.yml'

  def ignored_tags
    config[:ignored_tags]
  end

  def ignored_auto_generated
    config[:ignored_auto_generated]
  end

private

  def config
    @config ||= YAML.load_file(Rails.root.join(CONFIG_PATH))
  end
end
