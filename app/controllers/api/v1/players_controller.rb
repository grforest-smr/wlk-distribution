class Api::V1::PlayersController < ApplicationController
  skip_before_action :verify_authenticity_token

  def index
    @players = Player.all
    render json: { status: 'success', data: @players }
  end

  def show
    @player = Player.find_by!(nickname: params[:nickname])
    render json: { status: 'success', data: @player }
  rescue ActiveRecord::RecordNotFound
    render json: { status: 'error', message: 'Player not found' }, status: :not_found
  end

  def register
    @player = Player.new(player_params)
    @player.registration_time = Time.current
    
    if @player.save
      render json: { status: 'success', message: 'Player registered', data: @player }
    else
      render json: { status: 'error', errors: @player.errors.full_messages }
    end
  end

 def upload_csv
  require 'csv'
  
  file = params[:file]
  use_strength = params[:use_strength] == 'true'
  
  if !file
    render json: { status: 'error', message: 'Файл не выбран' } and return
  end

  Distribution.destroy_all
  Player.destroy_all

  players = []
  errors = []
  players_by_nick = {}

  CSV.foreach(file.path, headers: true, col_sep: ',') do |row|
    begin
      nickname = row[1].to_s.strip
      next if nickname.blank?
      
      registration_time = Time.parse(row[0].to_s) rescue Time.current
      alliance = row[2].to_s.strip
      troop_type = row[3].to_s.strip
      level = row[4].to_s.strip
      march_size = row[5].to_s.gsub(/[^\d]/, '').to_i
      group_attack = row[6].to_s.gsub(/[^\d]/, '').to_i
      troop_power = row[7].to_s.gsub(/[^\d]/, '').to_i
      slot = row[8].to_s.strip.presence || 'Любое'
      wants_captain = row[9].to_s.strip.presence || 'Не важно'

      if players_by_nick[nickname]
        existing = players_by_nick[nickname]
        if registration_time > existing[:registration_time]
          players_by_nick[nickname] = {
            nickname: nickname,
            alliance: alliance,
            troop_type: troop_type,
            level: level,
            march_size: march_size,
            group_attack: group_attack,
            troop_power: troop_power,
            slot: slot,
            wants_captain: wants_captain,
            registration_time: registration_time
          }
        end
      else
        players_by_nick[nickname] = {
          nickname: nickname,
          alliance: alliance,
          troop_type: troop_type,
          level: level,
          march_size: march_size,
          group_attack: group_attack,
          troop_power: troop_power,
          slot: slot,
          wants_captain: wants_captain,
          registration_time: registration_time
        }
      end
      
    rescue => e
      errors << "Строка #{$.}: #{e.message}"
    end
  end

  players_by_nick.each do |nickname, data|
    player = Player.new(
      nickname: data[:nickname],
      alliance: data[:alliance],
      troop_type: data[:troop_type],
      level: data[:level],
      march_size: data[:march_size],
      group_attack: data[:group_attack],
      troop_power: data[:troop_power],
      slot: data[:slot],
      wants_captain: data[:wants_captain],
      registration_time: data[:registration_time]
    )
    
    if player.save
      players << player
    else
      errors << "Не удалось сохранить #{nickname}: #{player.errors.full_messages.join(', ')}"
    end
  end

  if errors.any?
    render json: { status: 'error', message: errors.join('; ') }
  else
    render json: { 
      status: 'success', 
      message: 'Файл обработан', 
      count: players.size,
      players: players.map { |p| { 
        nickname: p.nickname, 
        alliance: p.alliance,
        troop_type: p.troop_type,
        level: p.level,
        march_size: p.march_size,
        group_attack: p.group_attack,
        wants_captain: p.wants_captain,
        slot: p.slot
      } }
    }
  end
end
end