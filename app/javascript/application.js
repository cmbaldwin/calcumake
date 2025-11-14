// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

// Import Bootstrap ESM module and make it globally available
import * as bootstrap from "bootstrap"
window.bootstrap = bootstrap
