class String
  RussianRange = ("А".ord)..("я".ord)

  def keywords
    self
      .downcase
      .gsub(/ (?: 's | : ) ( \b | $ | [ ] ) /xi, ' ')
      .gsub('&dagger;', '') #.gsub(/\.[A-zА-я0-9]+$/, '') # не знаю, для чего эта строка #.gsub(/^(\w+)\.(\w+)$/, '\1 \2')
      .gsub('!', 'EXCM')
      .gsub('?', 'QUEM')
      .gsub('QUEM', '?')
      .gsub('EXCM', '!')
      .gsub(/\d+x\d+|\d+/, '')
      .gsub(/~/, ' ')
      .gsub(/ +/, ' ')
      .gsub(/\b(?:the|for|in|by|to|[A-zА-я0-9])\b/, '')
      .strip
      .split(' ')
      .uniq
      .select {|v| v.length > 1 }
  end

  def specials
    self
      .downcase
      .gsub(/\b(ova|specials|ona|prologue|epilogue|picture)\b|(?!\bova\b|\bspecials\b|\bona\b|\bprologue\b|\bepilogue\b|\bpicture\b)./, '\1 ')
      .gsub(/^ +| +$/, '')
      .gsub(/ +/, ' ')
      .split(' ')
      .uniq
  end

  def capitalize
    Unicode.capitalize self
  end

  def downcase
    Unicode.downcase self
  end

  def to_underscore!
    self.gsub!(/(.)([A-Z])/,'\1_\2')
    self.downcase!
  end

  def to_underscore
    self.clone.to_underscore!
  end

  # нормализация японского названия
  def cleanup_japanese
    self.gsub('=', '＝').gsub(/･|·/, '・').gsub(/「|」/, '').gsub(/　/, ' ')
  end

  # восстанвление кривой раскладки
  def broken_translit
    result = []
    self.each_char {|v|
       result << (BrokenTranslit.include?(v.downcase) ? BrokenTranslit[v.downcase] : v)
    }
    result.join('')
  end

  # привод кривой строки в валидное состояние
  def fix_encoding encoding=nil, dont_unpack=false
    result = self
    encoding ||= 'utf-8'

    if result.encoding.name == "ASCII-8BIT"
      result = result.force_encoding encoding
    end

    unless result.encoding.name == "UTF-8"
      result = result.encode encoding
    end

    unless result.valid_encoding? || dont_unpack
      result = result.unpack('C*').pack('U*')
    end

    unless result.valid_encoding?
      result = result.encode 'utf-8', 'utf-8', undef: :replace, invalid: :replace, replace: ''
    end

    result
  end

  # японский ли текст?
  def contains_cjkv?
    each_char do |ch|
      return true if CJKV_RANGES.any? {|range| range.cover? ch.unpack('H*').first.hex }
    end
    false
  end

  # русский ли текст?
  def contains_russian?
    matched = 0
    each_char do |char|
      matched += 1 if RussianRange.cover?(char.ord) || char == ' '
    end
    matched >= size / 2
  end

  def permalinked
    Russian.translit self
      .gsub(/&#szlig;|ß/, 'ss')
      .gsub(/&#\d{4};/, '-')
      .gsub(/[^A-zА-я0-9]/, '-')
      .gsub(/\]|\[|-+/, '-')
      .gsub('Ä', 'A')
      .gsub(/^-|-$|[`'"]/, '')
      .downcase
  end

  def with_http
    sub %r{\A(?!https?://)}, 'http://'
  end

  def without_http
    sub %r{\A(?:https?:)?//}, ''
  end

  def extract_domain
    without_http.sub(%r{/.*}, '')
  end

  def pretext?
    self =~ Pretext
  end

  BrokenTranslit = {
    'q' => 'й',
    'w' => 'ц',
    'e' => 'у',
    'r' => 'к',
    't' => 'е',
    'y' => 'н',
    'u' => 'г',
    'i' => 'ш',
    'o' => 'щ',
    'p' => 'з',
    '[' => 'х',
    ']' => 'ъ',
    'a' => 'ф',
    's' => 'ы',
    'd' => 'в',
    'f' => 'а',
    'g' => 'п',
    'h' => 'р',
    'j' => 'о',
    'k' => 'л',
    'l' => 'д',
    ';' => 'ж',
    '\'' => 'э',
    'z' => 'я',
    'x' => 'ч',
    'c' => 'с',
    'v' => 'м',
    'b' => 'и',
    'n' => 'т',
    'm' => 'ь',
    ',' => 'б',
    '.' => 'ю'
  }.invert

  CJKV_RANGES = [
      (0xe2ba80..0xe2bbbf),
      (0xe2bfb0..0xe2bfbf),
      (0xe38080..0xe380bf),
      (0xe38180..0xe383bf),
      (0xe38480..0xe386bf),
      (0xe38780..0xe387bf),
      (0xe38880..0xe38bbf),
      (0xe38c80..0xe38fbf),
      (0xe39080..0xe4b6bf),
      (0xe4b780..0xe4b7bf),
      (0xe4b880..0xe9bfbf),
      (0xea8080..0xea98bf),
      (0xeaa080..0xeaaebf),
      (0xeaaf80..0xefbfbf),
  ]

  # регексп для определения предлог ли слово?
  Pretext = /
    ^
      (?:
        [Бб]ез |
        [Бб]езо |
        [Бб]лиз |
        [Вв] |
        [Вв]о |
        [Вв]место |
        [Вв]не |
        [Дд]ля |
        [Дд]о |
        [Зз]а |
        [Ии]з |
        [Ии]з-за |
        [Ии]з-под |
        [Кк] |
        [Кк]о |
        [Кк]роме |
        [Мм]ежду |
        [Нн]а |
        [Нн]ад |
        [Нн]адо |
        [Оо] |
        [Оо]б |
        [Оо]бо |
        [Оо]т |
        [Оо]то |
        [Пп]еред |
        [Пп]ередо |
        [Пп]ред |
        [Пп]редо |
        [Пп]o |
        [Пп]од |
        [Пп]одо |
        [Пп]ри |
        [Пп]ро |
        [Рр]ади |
        [Сс] |
        [Сс]о |
        [Сс]квозь |
        [Сс]реди |
        [Уу] |
        [Чч]ерез |
        [Чч]рез |
        [Ии] |
        [Аа] |
        [Нн]о |
        [Дд]а |
        [Ии]ли |
        [Чч]тобы |
        [Кк]огда |
        [Ее]сли |
        [Пп]отому |
        [Рр]азве |
        [Нн]еужели |
        [Кк]ак |
        [Дд]аже |
        [Уу]же |
        [Уу]ж |
        [Вв]едь |
        [Вв]от |
        [Тт]о |
        [Жж]е |
        [Нн]и |
        [Тт]олько |
        [Лл]ишь
      )
    $
  /x
end
