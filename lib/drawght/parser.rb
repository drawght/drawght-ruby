class Drawght::Parser
  PREFIX, ATTRIBUTE, QUERY, ITEM, SUFFIX,  = "{", ".", ":", "#", "}"
  KEY, LIST, INDEX = "(?<key>.*?)", "(?<list>.*?)", "(?<index>.*?)"
  EOL = /\r?\n/

  KEY_PATTERN = Regexp.new "#{PREFIX}#{KEY}#{SUFFIX}"
  LIST_PATTERN = Regexp.new "#{PREFIX}#{LIST}#{QUERY}#{KEY}#{SUFFIX}"
  ITEM_PATTERN = Regexp.new "#{LIST}#{ITEM}#{INDEX}([#{ATTRIBUTE}]#{KEY})?$"

  def initialize(template)
    @template = template
  end

  def parse(data)
    self.parse_keys(self.parse_queries(@template, data), data)
  end

  def parse_queries(template, data)
    template.split(EOL).map do |line|
      result = line
      line.scan LIST_PATTERN do |(list, key)|
        value = value_from_key(list, data)
        if value && (value.kind_of? Array) && key
          partial = line.gsub("#{list}#{QUERY}", "")
          parsed_lines = value.map { |item| parse_template(partial, item) }
          result = result.gsub(line, parsed_lines.join("\n"))
        end
      end
      result
    end.join("\n")
  end

  def parse_keys(template, data)
    template.split(EOL).map do |line|
      parse_template(line, data)
    end.join("\n"); 
  end

  def parse_template(template, data)
    result = template
    template.scan KEY_PATTERN do |(key)|
      template_key = "#{PREFIX}#{key}#{SUFFIX}"
      value = value_from_key(key, data) || template_key
      if value.kind_of? Array
        result = value.map { |item| template.gsub(template_key, item) }.join("\n")
      else
        result = result.gsub(template_key, value.to_s)
      end
    end
    result
  end

  private

  def value_from_key(nested_key, data)
    item = nested_key.match ITEM_PATTERN
    if item
      list, index, key = item.captures
      index = index && (index.to_i)
      value = data.dig *list.split(ATTRIBUTE)
      if value && (value.kind_of? Array) && index
        key ? value[index - 1][key] : value[index - 1]
      end
    else
      data.dig *nested_key.split(ATTRIBUTE)
    end
  end
end
