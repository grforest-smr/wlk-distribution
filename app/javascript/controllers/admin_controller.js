import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    console.log("Admin controller connected")
    this.loadSettings()
    this.loadBuildingTypes()
    
    document.getElementById("saveSettings")?.addEventListener("click", () => this.saveSettings())
    document.getElementById("saveBuildingTypes")?.addEventListener("click", () => this.saveBuildingTypes())
  }

  async loadSettings() {
    try {
      const response = await fetch("/api/v1/configs")
      const result = await response.json()
      
      if (result.status === "success") {
        result.data.forEach(config => {
          const input = document.getElementById(config.key)
          if (input) input.value = config.value
        })
      }
    } catch (error) {
      console.error(error)
    }
  }

  async loadBuildingTypes() {
    try {
      const response = await fetch("/api/v1/building_troop_types")
      const result = await response.json()
      
      const allBuildings = [
        { key: 'tower_tc', name: 'ТЦ' },
        { key: 'tower_north', name: 'Северная' },
        { key: 'tower_south', name: 'Южная' },
        { key: 'tower_west', name: 'Западная' },
        { key: 'tower_east', name: 'Восточная' }
      ]
      
      const container = document.getElementById("buildingTypes")
      container.innerHTML = ""
      
      const currentTypes = {}
      if (result.status === "success") {
        result.data.forEach(item => {
          currentTypes[item.building] = item.troop_type
        })
      }
      
      allBuildings.forEach(building => {
        const currentValue = currentTypes[building.name] || ""
        
        const div = document.createElement("div")
        div.className = "flex items-center"
        div.innerHTML = `
          <span class="w-32 font-medium">${building.name}:</span>
          <select data-building="${building.name}" class="building-type-select flex-1 p-2 border rounded">
            <option value="" ${currentValue === "" ? "selected" : ""}>🤖 Авто</option>
            <option value="Боец" ${currentValue === "Боец" ? "selected" : ""}>Боец</option>
            <option value="Стрелок" ${currentValue === "Стрелок" ? "selected" : ""}>Стрелок</option>
            <option value="Наездник" ${currentValue === "Наездник" ? "selected" : ""}>Наездник</option>
          </select>
        `
        container.appendChild(div)
      })
    } catch (error) {
      console.error(error)
    }
  }

  async saveSettings() {
    const settings = [
      { key: "max_players_in_tower", value: document.getElementById("max_players_in_tower").value },
      { key: "max_players_in_tc", value: document.getElementById("max_players_in_tc").value },
      { key: "reserve_per_building", value: document.getElementById("reserve_per_building").value }
    ]

    try {
      for (const setting of settings) {
        await fetch(`/api/v1/configs/${setting.key}`, {
          method: "PUT",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ value: setting.value })
        })
      }
      this.showMessage("✅ Настройки сохранены", "success")
    } catch (error) {
      this.showMessage("❌ Ошибка сохранения", "error")
    }
  }

  async saveBuildingTypes() {
    const selects = document.querySelectorAll(".building-type-select")
    
    try {
      for (const select of selects) {
        const building = select.dataset.building
        const troop_type = select.value
        
        await fetch(`/api/v1/building_troop_types/${encodeURIComponent(building)}`, {
          method: "PUT",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ troop_type })
        })
      }
      this.showMessage("✅ Типы зданий сохранены", "success")
    } catch (error) {
      this.showMessage("❌ Ошибка сохранения", "error")
    }
  }

  showMessage(text, type) {
    const msg = document.getElementById("adminMessage")
    msg.textContent = text
    msg.className = `p-4 rounded ${
      type === "success" ? "bg-green-100 text-green-700" : "bg-red-100 text-red-700"
    }`
    msg.classList.remove("hidden")

    setTimeout(() => {
      msg.classList.add("hidden")
    }, 5000)
  }
}