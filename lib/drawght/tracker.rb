# encoding: utf-8

module Drawght

module Tracker
  def pathing hash, *pathkeys
    if i = pathkeys.index Parser::CONJUNCTION
      prefix_pathkeys, suffix_pathkeys = pathkeys[0..i - 1], pathkeys[i + 1..-1]
      pathing(hash, *prefix_pathkeys).map{ |item| pathing item, *suffix_pathkeys }
    else
      hash.dig *pathkeys
    end
  rescue => error
    raise error, "The pathkeys \"#{pathkeys.join ', '}\" is a not valid path"
  end
end

end # Drawght
