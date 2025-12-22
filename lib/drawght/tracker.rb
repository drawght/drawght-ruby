# encoding: utf-8

module Drawght

module Tracker
  LENGTH = Parser::LENGTH
  CONTEXT = Parser::CONTEXT

  def pathing hash, *pathkeys
    if i = pathkeys.index CONTEXT
      prefixes, suffixes = pathkeys.slice(0..i - 1), pathkeys.slice(i + 1..-1)
      result = pathing(hash, *prefixes).map{ |item| pathing item, *suffixes }
      suffixes.last == LENGTH ? result.reduce(&:+) : result
    elsif pathkeys.last == LENGTH
      hash.dig(*pathkeys.slice(0..-2)).length
    else
      hash.dig *pathkeys
    end
  rescue => error
    raise error, "The pathkeys \"#{pathkeys.join ' '}\" is a not valid path"
  end
end

end # Drawght
