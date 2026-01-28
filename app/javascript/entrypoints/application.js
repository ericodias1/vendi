import "~/stylesheets/application.tailwind.css";

// Entry point for the build script in your package.json
import "@hotwired/turbo-rails";
import "../controllers";

// Import discount calculator BEFORE Alpine starts
import { discountCalculator } from "../discount_calculator";
// Import product import component
import { productImport, productImportWithSettings } from "../product_import";
// Import product import review component
import { productImportReview } from "../product_import_review";

import Alpine from "alpinejs";

// Register discountCalculator as an Alpine data component
Alpine.data("discountCalculator", discountCalculator);
// Register productImport as an Alpine data component
Alpine.data("productImport", productImport);
// Register productImportWithSettings as an Alpine data component
Alpine.data("productImportWithSettings", productImportWithSettings);
// Register productImportReview as an Alpine data component
Alpine.data("productImportReview", productImportReview);

// Make it available globally as well for direct calls
window.discountCalculator = discountCalculator;

window.Alpine = Alpine;

// Ensure components are always available, even after Turbo navigations
document.addEventListener("turbo:load", () => {
  if (!window.discountCalculator) {
    window.discountCalculator = discountCalculator;
  }
  // Re-register with Alpine if needed
  if (window.Alpine) {
    if (!window.Alpine.data("discountCalculator")) {
      Alpine.data("discountCalculator", discountCalculator);
    }
    if (!window.Alpine.data("productImport")) {
      Alpine.data("productImport", productImport);
    }
    if (!window.Alpine.data("productImportWithSettings")) {
      Alpine.data("productImportWithSettings", productImportWithSettings);
    }
    if (!window.Alpine.data("productImportReview")) {
      Alpine.data("productImportReview", productImportReview);
    }
  }
});

Alpine.start();
