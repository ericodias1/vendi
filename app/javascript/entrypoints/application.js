import "~/stylesheets/application.tailwind.css";

import Alpine from "alpinejs";
window.Alpine = Alpine;
Alpine.start();

// Entry point for the build script in your package.json
import "@hotwired/turbo-rails";
import "../controllers";
