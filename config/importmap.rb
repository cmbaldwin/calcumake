# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "@hotwired--turbo-rails.js" # @7.3.0
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "rails_admin" # @3.3.0
pin "@hotwired/turbo", to: "@hotwired--turbo.js" # @7.3.0
pin "@popperjs/core", to: "@popperjs--core.js" # @2.11.8
pin "@rails/actioncable/src", to: "@rails--actioncable--src.js" # @7.2.202
pin "@rails/ujs", to: "@rails--ujs.js" # @6.1.710
pin "bootstrap" # @5.3.8
pin "flatpickr" # @4.6.13
pin "jquery" # @3.7.1
