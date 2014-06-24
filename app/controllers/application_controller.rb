class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  layout :set_layout
  before_action :fix_googlebot
  before_action :touch_last_online unless Rails.env.test?
  before_action :mailer_set_url_options
  before_action :force_vary_accept

  helper_method :resource_class
  helper_method :remote_addr
  helper_method :json?
  helper_method :domain_folder
  helper_method :adaptivity_class
  helper_method :shikimori?
  helper_method :anime_online?
  helper_method :manga_online?

  unless Rails.env.test?
    rescue_from AbstractController::ActionNotFound, AbstractController::Error, ActionController::InvalidAuthenticityToken,
      ActionController::RoutingError, ActionView::MissingTemplate, ActionView::Template::Error, Exception, PG::Error,
      NoMethodError, StandardError, SyntaxError, CanCan::AccessDenied, with: :runtime_error
  else
    rescue_from StatusCodeError, with: :runtime_error
  end

  I18n.exception_handler = -> (exception, locale, key, options) {
    raise I18n::MissingTranslationData, "#{locale} #{key}"
  }

  def runtime_error e
    ExceptionNotifier.notify_exception(e, env: request.env, data: { nickname: user_signed_in? ? current_user.nickname : nil })
    raise e if remote_addr == '127.0.0.1'

    if [ActionController::RoutingError, ActiveRecord::RecordNotFound, AbstractController::ActionNotFound, ActionController::UnknownFormat, NotFound].include?(e.class)
      @page_title = "Страница не найдена"
      @sub_layout = nil
      render 'pages/page404.html', layout: set_layout, status: 404

    elsif e.is_a?(Forbidden) || e.is_a?(CanCan::AccessDenied)
      render text: e.message, status: 403

    elsif e.is_a?(StatusCodeError)
      render json: {}, status: e.status

    else
      @page_title = "Ошибка"
      render 'pages/page503.html', layout: set_layout, status: 503
    end
  end

  # находимся ли сейчас на домене шикимори?
  def shikimori?
    ShikimoriDomain::HOSTS.include? request.host
  end

  # находимся ли сейчас на домене аниме?
  def anime_online?
    AnimeOnlineDomain::HOSTS.include? request.host
  end

  # находимся ли сейчас на домене манги?
  def manga_online?
    MangaOnlineDomain::HOSTS.include? request.host
  end

  def current_user
    @decorated_current_user ||= super.try :decorate
  end

  # каталог текущего домена
  def domain_folder
    if shikimori?
      'shikimori'
    elsif anime_online?
      'anime_online'
    elsif manga_online?
      'manga_online'
    else
      raise ArgumentError, 'unknown domain'
    end
  end

  def adaptivity_class
    if controller_name == 'topics'# || (controller_name == 'pages' && params[:action] == 'ongoings')
      :adaptive
    else
      :static
    end
  end

private
  def set_layout
    if request.xhr?
      false
    else
      'application'
    end
  end

  # before фильтры с настройкой сайта
  def mailer_set_url_options
    ActionMailer::Base.default_url_options[:host] = request.host_with_port
  end

  # гугловский бот со странным format иногда ходит
  def fix_googlebot
    if request.format.to_s =~ %r%\*\/\*%
      request.format = :html
    end
  end

  # хром некорректно обрабатывает Back кнопку, если на аякс ответ не послан заголовок Vary: Accept
  def force_vary_accept
    if json?
      response.headers['Vary'] = 'Accept'
      response.headers['Pragma'] = 'no-cache' if request.env['HTTP_USER_AGENT'] =~ /Firefox/
    end
  end

  # трогаем lastonline у текущего пользователя
  def touch_last_online
    return unless user_signed_in? && !params.include?(:format) && current_user.class != Symbol
    current_user.update_last_online if current_user.id != 1
  end

  # корректно определяющийся ip адрес пользователя
  def remote_addr
    ip = request.headers['HTTP_X_FORWARDED_FOR'] || request.headers['HTTP_X_REAL_IP'] || request.headers['REMOTE_ADDR']
    ip = ip+'z' if user_signed_in? && [231, 296, 3801, 16029].include?(current_user.id)
    ip
  end

  def json?
    request.format == Mime::Type.lookup_by_extension('json') || params[:format] == 'json'
  end

  # faye токен текущего пользователя, переданный из заголовков
  def faye_token
    request.headers['X-Faye-Token'] || params[:faye]
  end
end
