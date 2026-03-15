
module ApplicationHelper
  def t(key, options = {})
    I18n.t(key, **options)
  end
  
  def t_lang(lang, key, options = {})
    I18n.t(key, locale: lang, **options)
  end
end
