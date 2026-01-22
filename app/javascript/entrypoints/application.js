import "~/stylesheets/application.tailwind.css";

// Entry point for the build script in your package.json
import "@hotwired/turbo-rails";
import "../controllers";

// Import discount calculator BEFORE Alpine starts
import { discountCalculator } from "../discount_calculator";

import Alpine from "alpinejs";

// Register discountCalculator as an Alpine data component
Alpine.data("discountCalculator", discountCalculator);

// Make it available globally as well for direct calls
window.discountCalculator = discountCalculator;

window.Alpine = Alpine;

// Ensure discountCalculator is always available, even after Turbo navigations
document.addEventListener("turbo:load", () => {
  if (!window.discountCalculator) {
    window.discountCalculator = discountCalculator;
  }
  // Re-register with Alpine if needed
  if (window.Alpine && !window.Alpine.data("discountCalculator")) {
    window.Alpine.data("discountCalculator", discountCalculator);
  }
});

Alpine.start();