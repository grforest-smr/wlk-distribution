import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "message"]

  connect() {
    console.log("Register controller connected")
  }

  async submit(event) {
    event.preventDefault()
    
    const formData = new FormData(this.formTarget)
    const data = {
      player: {
        nickname: formData.get("nickname"),
        alliance: formData.get("alliance"),
        troop_type: formData.get("troop_type"),
        level: formData.get("level"),
        march_size: parseInt(formData.get("march_size")),
        group_attack: parseInt(formData.get("group_attack") || 0),
        troop_power: parseInt(formData.get("troop_power") || 0),
        slot: formData.get("slot") || "Любое",
        wants_captain: formData.get("wants_captain") || "Не важно"
      }
    }

    try {
      const response = await fetch("/api/v1/players/register", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify(data)
      })

      const result = await response.json()

      if (result.status === "success") {
        this.showMessage("✅ Регистрация успешна!", "success")
        this.formTarget.reset()
      } else {
        this.showMessage("❌ Ошибка: " + (result.errors || result.message), "error")
      }
    } catch (error) {
      this.showMessage("❌ Ошибка соединения", "error")
      console.error(error)
    }
  }

  showMessage(text, type) {
    this.messageTarget.textContent = text
    this.messageTarget.className = `mb-4 p-4 rounded ${
      type === "success" ? "bg-green-100 text-green-700" : "bg-red-100 text-red-700"
    }`
    this.messageTarget.classList.remove("hidden")

    setTimeout(() => {
      this.messageTarget.classList.add("hidden")
    }, 5000)
  }
}