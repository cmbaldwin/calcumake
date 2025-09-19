# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"

# Action Text and Active Storage for rich text editing
# pin "@rails/actiontext", to: "actiontext.esm.js"
# pin "lexxy", to: "lexxy.js"
# pin "@rails/activestorage", to: "activestorage.esm.js"
