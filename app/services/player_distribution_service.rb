class PlayerDistributionService
  CONFIG = {
    troop_types: ['fighter', 'archer', 'rider'],
    buildings: ['tc', 'north', 'south', 'west', 'east'],
    slots: ['slot1', 'slot2', 'any']
  }

  LEVEL_VALUES = {
    'T14' => 14, 'T13' => 13, 'T12' => 12, 'T11' => 11,
    'T10' => 10, 'T9' => 9, 'T8' => 8, 'T7' => 7, 'T6' => 6,
    'T5' => 5, 'T4' => 4, 'T3' => 3, 'T2' => 2, 'T1' => 1
  }

  TROOP_TYPE_MAP = {
    'Боец' => 'fighter',
    'Стрелок' => 'archer',
    'Наездник' => 'rider'
  }

  SLOT_MAP = {
    'Слот1' => 'slot1',
    'Слот2' => 'slot2',
    'Любое' => 'any'
  }

  BUILDING_MAP = {
    'ТЦ' => 'tc',
    'Северная' => 'north',
    'Южная' => 'south',
    'Западная' => 'west',
    'Восточная' => 'east'
  }

  REVERSE_BUILDING_MAP = {
    'tc' => 'ТЦ',
    'north' => 'Северная',
    'south' => 'Южная',
    'west' => 'Западная',
    'east' => 'Восточная'
  }

  def initialize
    @players = []
    @settings = {}
    @building_types_by_slot = { 1 => {}, 2 => {} }
    load_settings
    load_players
  end

  def load_settings
    Config.all.each do |config|
      @settings[config.key] = config.value
    end

    # Загружаем ручные назначения типов по слотам
    BuildingTroopType.all.each do |bt|
      building_key = BUILDING_MAP[bt.building] || bt.building
      @building_types_by_slot[bt.slot][building_key] = bt.troop_type
    end

    required_params = ['max_players_in_tower', 'max_players_in_tc', 'reserve_per_building']
    missing_params = required_params.select { |p| @settings[p].nil? }
    raise "Missing settings: #{missing_params.join(', ')}" if missing_params.any?
  end

  def load_players
    @players = Player.all.map do |p|
      {
        id: p.id,
        nickname: p.nickname,
        alliance: p.alliance,
        troop_type: TROOP_TYPE_MAP[p.troop_type] || 'fighter',
        level: p.level,
        march_size: p.march_size.to_i,
        group_attack: p.group_attack.to_i,
        troop_power: p.troop_power.to_i,
        slot: SLOT_MAP[p.slot] || 'any',
        wants_captain: p.wants_captain || 'Не важно',
        assigned_to_slot: nil,
        assigned_to_building: nil
      }
    end
  end

  def calculate_player_strength(player)
    level_value = LEVEL_VALUES[player[:level]] || 0
    
    level_weight = 0.001
    march_weight = 0.001
    group_attack_weight = 0.001
    troop_power_weight = 0.997

    level_score = level_value * 10000
    march_score = player[:march_size]
    group_attack_score = player[:group_attack]
    troop_power_score = player[:troop_power]

    (level_score * level_weight) +
    (march_score * march_weight) +
    (group_attack_score * group_attack_weight) +
    (troop_power_score * troop_power_weight)
  end

  def captain_score(player)
    score = calculate_player_strength(player)
    
    if player[:wants_captain] == 'Да'
      score += 10_000_000
    elsif player[:wants_captain] == 'Не важно'
      score += 5_000_000
    end
    
    score
  end

  def max_players_for(building)
    if building == 'tc'
      @settings['max_players_in_tc'].to_i
    else
      @settings['max_players_in_tower'].to_i
    end
  end

  def new_slot_distribution
    slot = {}
    CONFIG[:buildings].each { |b| slot[b] = { captain: nil, participants: [], troop_type: nil } }
    slot
  end

  def distribute_all_slots(use_strength = true)
    all_players = @players.dup
    return { error: 'No players' } if all_players.empty?

    all_players.each { |p| p[:assigned_to_slot] = nil }

    slot1_players = all_players.select { |p| p[:slot] == 'slot1' || p[:slot] == 'any' }.map(&:dup)
    slot2_players = all_players.select { |p| p[:slot] == 'slot2' || p[:slot] == 'any' }.map(&:dup)

    result = { slot1: new_slot_distribution, slot2: new_slot_distribution }

    # Распределяем каждый слот с передачей номера слота
    distribute_slot(result[:slot1], slot1_players, 'slot1', 1, use_strength)
    distribute_slot(result[:slot2], slot2_players, 'slot2', 2, use_strength)

    march_data = calculate_march(result)

    march_data[:slot1].each do |building, data|
      result[:slot1][building][:captain_march] = data[:captain][:march]
      result[:slot1][building][:participants_march] = data[:participants]
    end

    march_data[:slot2].each do |building, data|
      result[:slot2][building][:captain_march] = data[:captain][:march]
      result[:slot2][building][:participants_march] = data[:participants]
    end

    {
      slot1: result[:slot1],
      slot2: result[:slot2],
      output: result
    }
  end

  def distribute_slot(slot_data, players, slot_name, slot_number, use_strength = true)
    return if players.empty?

    # Получаем ручные назначения для этого слота
    manual_assignments = @building_types_by_slot[slot_number] || {}
    
    assignments = if manual_assignments.any?
                    manual_assignments
                  else
                    auto_assign_types(players)
                  end

    assignments.each do |building, troop_type|
      candidates = players.select { |p| p[:troop_type] == troop_type && !p[:assigned_to_slot] }
      next if candidates.empty?

      captain = candidates.max_by { |p| captain_score(p) }
      slot_data[building][:captain] = captain
      slot_data[building][:troop_type] = troop_type
      captain[:assigned_to_slot] = slot_name
      captain[:assigned_to_building] = building
    end

    remaining = players.reject { |p| p[:assigned_to_slot] }
    return if remaining.empty?

    remaining.each do |player|
      suitable = CONFIG[:buildings].find do |b|
        slot_data[b][:captain] && 
        slot_data[b][:troop_type] == player[:troop_type] && 
        slot_data[b][:participants].size < max_players_for(b) - 1
      end

      if suitable
        slot_data[suitable][:participants] << player
        player[:assigned_to_slot] = slot_name
        player[:assigned_to_building] = suitable
      end
    end
  end

  def auto_assign_types(players)
    counts = Hash.new(0)
    players.each { |p| counts[p[:troop_type]] += 1 }
    
    sorted = CONFIG[:troop_types].sort_by { |t| -counts[t] }
    
    assignments = {}
    available = CONFIG[:buildings].dup
    
    assignments['tc'] = sorted.first || 'fighter'
    available.delete('tc')
    
    available.each_with_index do |b, i|
      assignments[b] = sorted[(i + 1) % sorted.size] || 'fighter'
    end
    
    assignments
  end

  def calculate_march(slot_data)
    result = { slot1: {}, slot2: {} }
    
    # Слот 1
    CONFIG[:buildings].each do |building|
      bdata = slot_data[:slot1][building]
      next unless bdata[:captain]
      
      captain = bdata[:captain]
      participants = bdata[:participants]
      
      captain_march = captain[:march_size]
      
      participants_march = {}
      if participants.any?
        ga_limit = captain[:group_attack]
        
        min_per_player = 10000
        min_total = participants.size * min_per_player
        
        if min_total > ga_limit
          min_per_player = (ga_limit / participants.size).floor
          min_per_player = (min_per_player / 1000).floor * 1000
          min_total = participants.size * min_per_player
        end
        
        remaining = ga_limit - min_total
        
        total_strength = participants.sum { |p| calculate_player_strength(p) }
        
        participants.each do |p|
          base = min_per_player
          
          extra = 0
          if remaining > 0 && total_strength > 0
            share = calculate_player_strength(p) / total_strength
            extra = (share * remaining).floor
            extra = [extra, p[:march_size] - base].min
            extra = (extra / 1000).floor * 1000
          end
          
          march = base + extra
          march = [march, p[:march_size]].min
          
          participants_march[p[:nickname]] = march
        end
        
        total = participants_march.values.sum
        if total > ga_limit
          excess = total - ga_limit
          strongest = participants.max_by { |p| calculate_player_strength(p) }[:nickname]
          participants_march[strongest] -= excess
        end
      end
      
      result[:slot1][building] = {
        captain: { name: captain[:nickname], march: captain_march },
        participants: participants_march
      }
    end
    
    # Слот 2
    CONFIG[:buildings].each do |building|
      bdata = slot_data[:slot2][building]
      next unless bdata[:captain]
      
      captain = bdata[:captain]
      participants = bdata[:participants]
      
      captain_march = captain[:march_size]
      
      participants_march = {}
      if participants.any?
        ga_limit = captain[:group_attack]
        
        min_per_player = 10000
        min_total = participants.size * min_per_player
        
        if min_total > ga_limit
          min_per_player = (ga_limit / participants.size).floor
          min_per_player = (min_per_player / 1000).floor * 1000
          min_total = participants.size * min_per_player
        end
        
        remaining = ga_limit - min_total
        
        total_strength = participants.sum { |p| calculate_player_strength(p) }
        
        participants.each do |p|
          base = min_per_player
          
          extra = 0
          if remaining > 0 && total_strength > 0
            share = calculate_player_strength(p) / total_strength
            extra = (share * remaining).floor
            extra = [extra, p[:march_size] - base].min
            extra = (extra / 1000).floor * 1000
          end
          
          march = base + extra
          march = [march, p[:march_size]].min
          
          participants_march[p[:nickname]] = march
        end
        
        total = participants_march.values.sum
        if total > ga_limit
          excess = total - ga_limit
          strongest = participants.max_by { |p| calculate_player_strength(p) }[:nickname]
          participants_march[strongest] -= excess
        end
      end
      
      result[:slot2][building] = {
        captain: { name: captain[:nickname], march: captain_march },
        participants: participants_march
      }
    end
    
    result
  end

  def save_distribution(distribution_data)
    distribution_date = Date.current
    Distribution.where(distribution_date: distribution_date).destroy_all

    # Слот 1
    distribution_data[:slot1].each do |building, data|
      next unless data[:captain]
      
      russian_building = REVERSE_BUILDING_MAP[building] || building
      
      Distribution.create(
        slot: 1,
        building: russian_building,
        player_id: data[:captain][:id],
        role: 'captain',
        allocated_troops: data[:captain][:march_size],
        distribution_date: distribution_date
      )
      
      data[:participants].each do |participant|
        participant_march = if data[:participants_march] && data[:participants_march][participant[:nickname]]
                              data[:participants_march][participant[:nickname]]
                            else
                              participant[:march_size]
                            end
        
        Distribution.create(
          slot: 1,
          building: russian_building,
          player_id: participant[:id],
          role: 'participant',
          allocated_troops: participant_march,
          distribution_date: distribution_date
        )
      end
    end

    # Слот 2
    distribution_data[:slot2].each do |building, data|
      next unless data[:captain]
      
      russian_building = REVERSE_BUILDING_MAP[building] || building
      
      Distribution.create(
        slot: 2,
        building: russian_building,
        player_id: data[:captain][:id],
        role: 'captain',
        allocated_troops: data[:captain][:march_size],
        distribution_date: distribution_date
      )
      
      data[:participants].each do |participant|
        participant_march = if data[:participants_march] && data[:participants_march][participant[:nickname]]
                              data[:participants_march][participant[:nickname]]
                            else
                              participant[:march_size]
                            end
        
        Distribution.create(
          slot: 2,
          building: russian_building,
          player_id: participant[:id],
          role: 'participant',
          allocated_troops: participant_march,
          distribution_date: distribution_date
        )
      end
    end
  end
end