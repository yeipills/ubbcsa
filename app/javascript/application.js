// Configure your import map in config/importmap.rb
import "@hotwired/turbo-rails"
import "controllers"

import { Application } from "@hotwired/stimulus"
import { registerControllers } from "@hotwired/stimulus-loading"

const application = Application.start()
const context = require.context("./controllers", true, /\.js$/)
registerControllers(context, application)