// Auto-register all Stimulus controllers
// Controllers are automatically discovered and registered based on their filename
// Example: dropdown_controller.js → "dropdown"
// Example: password_toggle_controller.js → "password-toggle"

import { application } from "./application"

// Import all controllers matching the pattern *_controller.js
const controllers = import.meta.glob("./**/*_controller.js", { eager: true })

// Register each controller automatically
Object.keys(controllers).forEach((path) => {
  // Extract controller name from path
  // ./dropdown_controller.js → dropdown_controller → dropdown
  // ./password_toggle_controller.js → password_toggle_controller → password-toggle
  const fileName = path.replace(/^\.\//, "").replace(/\.js$/, "")
  const controllerName = fileName
    .replace(/_controller$/, "")
    .replace(/_/g, "-")

  // Get the controller class from the module
  const controllerModule = controllers[path]
  const Controller = controllerModule.default || controllerModule

  // Register the controller
  if (Controller) {
    application.register(controllerName, Controller)
  }
})
