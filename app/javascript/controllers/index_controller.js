import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["playerCount", "uploadMessage", "results", "slot1Results", "slot2Results", 
                    "unassignedPlayers", "unassignedList", "playersList", "playersTable"]
  
  connect() {
    // Получаем переводы из data-атрибута
    this.translations = JSON.parse(this.element.dataset.translations)
    this.loadSettings()
    this.loadBuildingTypes()
  }

  // Функция для получения перевода
    t(key, params = {}) {
      let text = this.translations[key] || key
      
      // Заменяем параметры вида {count}
      Object.keys(params).forEach(param => {
        text = text.replace(`%{${param}}`, params[param])
        text = text.replace(`{${param}}`, params[param])
      })
      
      return text
    }

  // Загрузка настроек
  async loadSettings() {
    try {
      const response = await fetch('/api/v1/configs')
      const result = await response.json()
      
      if (result.status === 'success') {
        result.data.forEach(config => {
          const input = document.getElementById(config.key)
          if (input) input.value = config.value
        })
      }
    } catch (error) {
      console.error('Error loading settings:', error)
    }
  }

  // Загрузка типов зданий
  async loadBuildingTypes() {
    try {
      const response = await fetch('/api/v1/building_troop_types')
      const result = await response.json()
      
      const allBuildings = [
        { key: 'tower_tc', name: 'tc' },
        { key: 'tower_north', name: 'north' },
        { key: 'tower_south', name: 'south' },
        { key: 'tower_west', name: 'west' },
        { key: 'tower_east', name: 'east' }
      ]
      
      const container = document.getElementById('buildingTypes')
      container.innerHTML = ''
      
      const currentTypes = {}
      if (result.status === 'success') {
        result.data.forEach(item => {
          currentTypes[item.building] = item.troop_type
        })
      }
      
      allBuildings.forEach(building => {
        const currentValue = currentTypes[building.name] || ''
        
        const div = document.createElement('div')
        div.className = 'flex items-center mb-2'
        
        // Получаем перевод для названия здания
        const label = document.createElement('span')
        label.className = 'w-48 font-medium'
        label.textContent = `${this.t(building.key)}:`
        div.appendChild(label)
        
        const select = document.createElement('select')
        select.dataset.building = building.name
        select.className = 'building-type-select flex-1 p-2 border rounded'
        
        const options = [
          { value: '', text: this.t('auto') },
          { value: 'fighter', text: this.t('fighter') },
          { value: 'archer', text: this.t('archer') },
          { value: 'rider', text: this.t('rider') }
        ]
        
        options.forEach(opt => {
          const option = document.createElement('option')
          option.value = opt.value
          option.textContent = opt.text
          option.selected = currentValue === opt.value
          select.appendChild(option)
        })
        
        div.appendChild(select)
        container.appendChild(div)
      })
    } catch (error) {
      console.error('Error loading building types:', error)
    }
  }

  // Сохранение всех настроек
  async saveAllSettings() {
    const settings = [
      { key: 'max_players_in_tower', value: document.getElementById('max_players_in_tower').value },
      { key: 'max_players_in_tc', value: document.getElementById('max_players_in_tc').value },
      { key: 'reserve_per_building', value: document.getElementById('reserve_per_building').value }
    ]

    try {
      for (const setting of settings) {
        await fetch(`/api/v1/configs/${setting.key}`, {
          method: 'PUT',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ value: setting.value })
        })
      }
      
      const selects = document.querySelectorAll('.building-type-select')
      for (const select of selects) {
        const building = select.dataset.building
        const troop_type = select.value
        
        await fetch(`/api/v1/building_troop_types/${encodeURIComponent(building)}`, {
          method: 'PUT',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ troop_type })
        })
      }
      
      this.showMessage(this.t('settingsSaved'), 'success')
    } catch (error) {
      this.showMessage(this.t('error'), 'error')
    }
  }

  // Сохранение только типов зданий
  async saveBuildingTypes() {
    const selects = document.querySelectorAll('.building-type-select')
    
    try {
      for (const select of selects) {
        const building = select.dataset.building
        const troop_type = select.value
        
        const response = await fetch(`/api/v1/building_troop_types/${encodeURIComponent(building)}`, {
          method: 'PUT',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ troop_type })
        })
        
        if (!response.ok) {
          throw new Error(`HTTP error! status: ${response.status}`)
        }
      }
      this.showMessage(this.t('typesSaved'), 'success')
      this.loadBuildingTypes()
    } catch (error) {
      this.showMessage(this.t('error'), 'error')
    }
  }

  // Загрузка CSV
async handleFileUpload() {
  const file = document.getElementById('csvFile').files[0]
  if (!file) {
    this.showMessage(this.t('fileRequired'), 'error')
    return
  }

  const useStrength = document.getElementById('useStrength').checked
  
  const formData = new FormData()
  formData.append('file', file)
  formData.append('use_strength', useStrength)

  try {
    const response = await fetch('/api/v1/players/upload_csv', {
      method: 'POST',
      body: formData
    })
    
    const result = await response.json()
    
    if (result.status === 'success') {
      console.log('Загружено игроков:', result.count)
      
      this.showMessage(this.t('playersLoaded', { count: result.count }), 'success')
      
      const countElement = document.getElementById('playerCount')
      if (countElement) {
        // Пробуем использовать перевод
        const translatedText = this.t('loadedCount', { count: result.count })
        countElement.textContent = translatedText
        
        // Если перевод не сработал, используем прямой текст
        if (translatedText === 'loadedCount' || translatedText.includes('loadedCount')) {
          countElement.textContent = `Загружено: ${result.count} игроков`
        }
      } else {
        console.error('Element playerCount not found!')
      }
    } else {
      this.showMessage(`❌ ${result.message}`, 'error')
    }
  } catch (error) {
    console.error('Error uploading file:', error)
    this.showMessage(this.t('error'), 'error')
  }
}
  // Показать загруженных игроков
  async showPlayers() {
    try {
      const response = await fetch('/api/v1/players')
      const result = await response.json()
      
      if (result.status === 'success') {
        const container = document.getElementById('playersTable')
        container.innerHTML = ''
        
        if (result.data.length === 0) {
          container.innerHTML = '<p class="text-gray-500">Нет загруженных игроков</p>'
        } else {
          let html = `<table class="min-w-full border"><tr>
            <th class="border p-2">${this.t('nickname')}</th>
            <th class="border p-2">${this.t('alliance')}</th>
            <th class="border p-2">${this.t('type')}</th>
            <th class="border p-2">${this.t('march')}</th>
            <th class="border p-2">${this.t('ga')}</th>
          </tr>`
          
          result.data.forEach(p => {
            html += `<tr>
              <td class="border p-2">${p.nickname}</td>
              <td class="border p-2">${p.alliance || '-'}</td>
              <td class="border p-2">${this.t(p.troop_type?.toLowerCase() || 'fighter')}</td>
              <td class="border p-2 text-right">${p.march_size?.toLocaleString()}</td>
              <td class="border p-2 text-right">${p.group_attack?.toLocaleString()}</td>
            </tr>`
          })
          html += '</table>'
          container.innerHTML = html
        }
        document.getElementById('playersList').classList.remove('hidden')
      }
    } catch (error) {
      console.error(error)
    }
  }

  // Запуск распределения
  async runDistribution() {
    const useStrength = document.getElementById('useStrength').checked
    
    try {
      const response = await fetch('/api/v1/distributions/run', { 
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ use_strength: useStrength })
      })
      const result = await response.json()
      
      if (result.status === 'success') {
        this.displayResults(result.data)
        this.showMessage(this.t('distributionCompleted'), 'success')
      } else {
        this.showMessage(`❌ ${result.message}`, 'error')
      }
    } catch (error) {
      this.showMessage(this.t('error'), 'error')
    }
  }

  // Отображение результатов
  displayResults(data) {
    document.getElementById('results').classList.remove('hidden')
    
    this.displaySlotResults('slot1Results', data.slot1)
    this.displaySlotResults('slot2Results', data.slot2)
    this.displayUnassignedPlayers(data)
  }

  // Отображение результатов для слота
  displaySlotResults(containerId, slotData) {
    const container = document.getElementById(containerId)
    container.innerHTML = ''
    
    for (const [building, buildingData] of Object.entries(slotData)) {
      if (!buildingData.captain) continue
      
      const buildingDiv = document.createElement('div')
      buildingDiv.className = 'border rounded p-4 mb-4'
      
      // Используем this.t() для переводов
      const buildingName = this.t(`tower_${building}`)
      const troopType = this.t(buildingData.troop_type?.toLowerCase() || 'fighter')
      
      let html = `<h4 class="font-bold text-lg mb-2">🏰 ${buildingName} (${troopType})</h4>`
      
      const captain = buildingData.captain
      const captainAlliance = captain.alliance ? `(${captain.alliance}) ` : ''
      const captainMarch = buildingData.captain_march || captain.march_size
      
      html += `<div class="mb-3 p-2 bg-yellow-100 rounded">
        <div class="font-semibold">${this.t('captain')}: ${captainAlliance}${captain.nickname}</div>
        <div class="text-sm grid grid-cols-2 gap-2 mt-1">
          <span>${this.t('ga')}: ${captain.group_attack?.toLocaleString()}</span>
          <span>${this.t('march')}: ${captain.march_size?.toLocaleString()}</span>
          <span class="col-span-2 font-bold">${this.t('captain')}: ${captainMarch.toLocaleString()}</span>
        </div>
      </div>`
      
      if (buildingData.participants && buildingData.participants.length > 0) {
        html += `<div class="mb-2"><span class="font-semibold">${this.t('participants')}:</span></div>`
        html += '<div class="space-y-1">'
        
        const participantsWithMarch = buildingData.participants.map(participant => {
          const participantMarch = (buildingData.participants_march && buildingData.participants_march[participant.nickname]) 
                                  ? buildingData.participants_march[participant.nickname] 
                                  : participant.march_size
          return { ...participant, march: participantMarch }
        })
        
        participantsWithMarch.sort((a, b) => b.march - a.march)
        
        participantsWithMarch.forEach((participant, index) => {
          const participantAlliance = participant.alliance ? `(${participant.alliance}) ` : ''
          
          html += `<div class="pl-4 py-1 border-b last:border-0 text-sm grid grid-cols-2 gap-2">
            <span>${index + 1}. ${participantAlliance}${participant.nickname}</span>
            <span class="font-mono text-right"> - ${participant.march.toLocaleString()}</span>
          </div>`
        })
        html += '</div>'
        
        const participantsTotal = participantsWithMarch.reduce((sum, p) => sum + p.march, 0)
        const captainGA = captain.group_attack || 0
        const usagePercent = captainGA > 0 ? ((participantsTotal / captainGA) * 100).toFixed(1) : 0
        
        html += `<div class="mt-3 pt-2 border-t text-sm">
          <div class="flex justify-between">
            <span>${this.t('totalParticipants')}:</span>
            <span class="font-bold">${participantsTotal.toLocaleString()}</span>
          </div>
          <div class="flex justify-between">
            <span>${this.t('captainGA')}:</span>
            <span class="font-bold">${captainGA.toLocaleString()}</span>
          </div>
          <div class="flex justify-between ${participantsTotal > captainGA ? 'text-red-600 font-bold' : 'text-green-600'}">
            <span>${this.t('usageGA')}:</span>
            <span>${usagePercent}%</span>
          </div>
        </div>`
      } else {
        html += `<div class="text-gray-500 italic pl-4">${this.t('no_participants')}</div>`
      }
      
      buildingDiv.innerHTML = html
      container.appendChild(buildingDiv)
    }
  }

  // Отображение нераспределенных игроков
  displayUnassignedPlayers(data) {
    const assignedPlayers = new Set()
    
    Object.values(data.slot1).forEach(building => {
      if (building.captain) {
        assignedPlayers.add(building.captain.nickname)
        building.participants.forEach(p => assignedPlayers.add(p.nickname))
      }
    })
    
    Object.values(data.slot2).forEach(building => {
      if (building.captain) {
        assignedPlayers.add(building.captain.nickname)
        building.participants.forEach(p => assignedPlayers.add(p.nickname))
      }
    })
    
    fetch('/api/v1/players')
      .then(response => response.json())
      .then(result => {
        if (result.status === 'success') {
          const unassigned = result.data.filter(p => !assignedPlayers.has(p.nickname))
          
          if (unassigned.length > 0) {
            unassigned.sort((a, b) => (b.march_size || 0) - (a.march_size || 0))
            
            const container = document.getElementById('unassignedList')
            container.innerHTML = ''
            
            unassigned.forEach((player, index) => {
              const playerAlliance = player.alliance ? `(${player.alliance}) ` : ''
              const playerDiv = document.createElement('div')
              playerDiv.className = 'pl-4 py-1 border-b last:border-0 text-sm grid grid-cols-3 gap-2'
              playerDiv.innerHTML = `
                <span>${index + 1}. ${playerAlliance}${player.nickname}</span>
                <span class="text-gray-600">${this.t(player.troop_type?.toLowerCase() || 'fighter')}</span>
                <span class="font-mono text-right"> - ${player.march_size?.toLocaleString() || 0}</span>
              `
              container.appendChild(playerDiv)
            })
            
            document.getElementById('unassignedPlayers').classList.remove('hidden')
          } else {
            document.getElementById('unassignedPlayers').classList.add('hidden')
          }
        }
      })
      .catch(error => console.error('Error loading unassigned players:', error))
  }

  // Показать сообщение
  showMessage(text, type) {
    const msg = document.getElementById('uploadMessage')
    msg.textContent = text
    msg.className = `p-4 rounded ${
      type === 'success' ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'
    }`
    msg.classList.remove('hidden')

    setTimeout(() => {
      msg.classList.add('hidden')
    }, 5000)
  }
}