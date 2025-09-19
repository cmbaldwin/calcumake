// Import and register all your controllers from the importmap via controllers/**/*_controller
import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"

//console.log("Loading Stimulus controllers...")
//console.log("Application object:", application)

eagerLoadControllersFrom("controllers", application)

//console.log("Controllers loaded. Registered controllers:", application.router.modules)
