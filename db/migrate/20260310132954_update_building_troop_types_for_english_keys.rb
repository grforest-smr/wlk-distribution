class UpdateBuildingTroopTypesForEnglishKeys < ActiveRecord::Migration[8.0]
  def up
    # Обновляем названия зданий с русских на английские ключи
    BuildingTroopType.where(building: 'ТЦ').update_all(building: 'tc')
    BuildingTroopType.where(building: 'Северная').update_all(building: 'north')
    BuildingTroopType.where(building: 'Южная').update_all(building: 'south')
    BuildingTroopType.where(building: 'Западная').update_all(building: 'west')
    BuildingTroopType.where(building: 'Восточная').update_all(building: 'east')
    
    # Обновляем типы войск с русских на английские
    BuildingTroopType.where(troop_type: 'Боец').update_all(troop_type: 'fighter')
    BuildingTroopType.where(troop_type: 'Стрелок').update_all(troop_type: 'archer')
    BuildingTroopType.where(troop_type: 'Наездник').update_all(troop_type: 'rider')
  end

  def down
    # Откат изменений (если понадобится)
    BuildingTroopType.where(building: 'tc').update_all(building: 'ТЦ')
    BuildingTroopType.where(building: 'north').update_all(building: 'Северная')
    BuildingTroopType.where(building: 'south').update_all(building: 'Южная')
    BuildingTroopType.where(building: 'west').update_all(building: 'Западная')
    BuildingTroopType.where(building: 'east').update_all(building: 'Восточная')
    
    BuildingTroopType.where(troop_type: 'fighter').update_all(troop_type: 'Боец')
    BuildingTroopType.where(troop_type: 'archer').update_all(troop_type: 'Стрелок')
    BuildingTroopType.where(troop_type: 'rider').update_all(troop_type: 'Наездник')
  end
end
