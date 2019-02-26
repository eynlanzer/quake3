require_relative "log_parser" 
require_relative "player" 

class Game
	attr_accessor :game_match, :players, :total_kills, :means_of_death

	def initialize(game_log_text)
		@game_match = game_log_text
    @players = []
    @total_kills = 0
    @means_of_death = {}
	end

  def total_players
    # :players names >> |any char until Client| |any char until n\| |name| |ranges from words and spaces| |\t|
    players_names = game_match.scan(/.+ClientUserinfoChanged:.+n\\(?<name>[\w\s]+)\\t/).uniq
    players << players_names.flatten
  end

	def kill_events
		# :killer >> |any char until Kill| |any char until :| |any char with killer name| |space| 
		# :victim >> |space| |"killed"| |any char with victim name| |ranges from words and spaces| |by|
    game_match.scan(/.+Kill:.+:\s*(?<killer>.+?)\skilled\s(?<victim>[\w\s]+)?by/)
  end

  def killer_infos
    kill_events.map do |kill_event|
      { killer: kill_event[0], victim: kill_event[1] }
    end
  end

  def death_infos
    # :means_of_death >> |any char until ... space, repeat| |any char with means of death|
    kill_methods = game_match.scan(/.+Kill:.+:\s*.+\skilled\s.+\sby\s(?<means_of_death>.+)/)
    kill_methods.group_by{|e| e}.map{|k, v| [k, v.length]}.to_h
  end

  def player_kills
    players.each_with_object({}) { |play, hsh| hsh[play.name] = play.kills }
  end

  def games_results
    index = 1
    @results = {}

    @game_match.each do |game|
      if game_match.any?
        @results.merge!(
          "Game_#{index}" => {
          total_kills: game.kill_events.size, # count number of kill events
          players: game.total_players,
          means_of_death: game.death_infos
        }
        )
        index += 1
      end
    end
    @results
  end

end
