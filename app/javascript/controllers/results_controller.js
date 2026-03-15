import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    console.log("Results controller connected")
  }

  async load() {
    try {
      const response = await fetch("/api/v1/distributions/latest")
      const result = await response.json()

      if (result.status === "success" && result.data.length > 0) {
        this.displayResults(result.data)
      } else {
        this.showNoResults()
      }
    } catch (error) {
      console.error(error)
      alert("Ошибка загрузки результатов")
    }
  }

  displayResults(data) {
    const tbody = document.getElementById("resultsBody")
    tbody.innerHTML = ""

    data.forEach(item => {
      const row = document.createElement("tr")
      row.className = item.role === "captain" ? "bg-yellow-50" : ""
      
      row.innerHTML = `
        <td class="px-4 py-2 border">Слот ${item.slot}</td>
        <td class="px-4 py-2 border">${item.building}</td>
        <td class="px-4 py-2 border">${item.player.nickname}</td>
        <td class="px-4 py-2 border">${item.role === "captain" ? "👑 Капитан" : "Участник"}</td>
        <td class="px-4 py-2 border text-right">${item.allocated_troops.toLocaleString()}</td>
      `
      tbody.appendChild(row)
    })

    document.getElementById("resultsTable").classList.remove("hidden")
    document.getElementById("noResults").classList.add("hidden")
  }

  showNoResults() {
    document.getElementById("resultsTable").classList.add("hidden")
    document.getElementById("noResults").classList.remove("hidden")
  }
}