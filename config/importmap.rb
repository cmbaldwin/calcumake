# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers", preload: false
pin_all_from "app/javascript/controllers/mixins", under: "controllers/mixins", preload: false
pin "@popperjs/core", to: "https://cdn.jsdelivr.net/npm/@popperjs/core@2.11.8/dist/esm/index.js"
pin "bootstrap", to: "https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.esm.min.js"

# PDF export libraries - preload: false ensures they're only loaded when needed
# Using esm.sh CDN for ESM module support (dynamic imports in pdf_mixin.js)
pin "jspdf", to: "https://esm.sh/jspdf@3.0.3", preload: false
pin "html2canvas", to: "https://esm.sh/html2canvas@1.4.1", preload: false

# Lexxy rich text editor - only used by authenticated users
pin "lexxy", to: "lexxy.js", preload: false
pin "@rails/activestorage", to: "activestorage.esm.js"
