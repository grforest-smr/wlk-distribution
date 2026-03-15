import { Application } from "@hotwired/stimulus"
import { definitionsFromContext } from "@hotwired/stimulus-webpack-helpers"

const application = Application.start()
application.debug = false
window.Stimulus = application

// Автоматически загружаем все контроллеры из папки controllers
const context = require.context("./controllers", true, /\.js$/)
application.load(definitionsFromContext(context))

export { application }