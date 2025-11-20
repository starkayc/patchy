# Stripped down version of:
# https://github.com/iv-org/invidious/blob/master/src/invidious/helpers/i18n.cr

LOCALES_LIST = {
  "en" => "English", # English
  "es" => "Español", # Spanish
}

LOCALES = load_all_locales()

def load_all_locales : Hash(String, Hash(String, JSON::Any))
  locales = {} of String => Hash(String, JSON::Any)

  LOCALES_LIST.each_key do |name|
    locales[name] = JSON.parse(Locales.get("#{name}.json")).as_h
  end

  return locales
end

def translate(locale : String?, key : String, text : String | Hash(String, String) | Nil = nil) : String
  if locale
    locale = locale.split("-")[0]
  end
  # Log a warning if "key" doesn't exist in en-US locale and return
  # that key as the text, so this is more or less transparent to the user.
  if !LOCALES["en"].has_key?(key)
    Log.warn &.emit("i18n: Missing translation key \"#{key}\"")
    return key
  end

  # Default to english, whenever the locale doesn't exist,
  # or the key requested has not been translated
  if locale && LOCALES.has_key?(locale) && LOCALES[locale].has_key?(key)
    raw_data = LOCALES[locale][key]
  else
    raw_data = LOCALES["en"][key]
  end

  case raw_data
  when .as_h?
    # Init
    translation = ""
    match_length = 0

    raw_data.as_h.each do |hash_key, value|
      if text.is_a?(String)
        if md = text.try &.match(/#{hash_key}/)
          if md[0].size >= match_length
            translation = value.as_s
            match_length = md[0].size
          end
        end
      end
    end
  when .as_s?
    translation = raw_data.as_s
  else
    raise "Invalid translation \"#{raw_data}\""
  end

  if text.is_a?(String)
    translation = translation.gsub("`x`", text)
  elsif text.is_a?(Hash(String, String))
    # adds support for multi string interpolation. Based on i18next https://www.i18next.com/translation-function/interpolation#basic
    text.each_key do |hash_key|
      translation = translation.gsub("{{#{hash_key}}}", text[hash_key])
    end
  end

  return translation
end

def translate_bool(locale : String?, translation : Bool)
  case translation
  when true
    return translate(locale, "Yes")
  when false
    return translate(locale, "No")
  end
end

def translate_js(locale : String?, key : String) : String
  translation = translate(locale, key)
  "<script id=\"_translate-#{key}\" type=\"application/json\">{\"msg\":\"#{translation}\"}</script>"
end
