import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.updateTheme()
    if (localStorage.theme === 'dark') {
      document.documentElement.classList.add('dark')
    } else {
      document.documentElement.classList.remove('dark')
    }
  }

  toggle() {
    if (localStorage.theme === 'dark') {
      localStorage.theme = 'light'
      document.documentElement.classList.remove('dark')
    } else {
      localStorage.theme = 'dark'
      document.documentElement.classList.add('dark')
    }
  }

  updateTheme() {
    if (!('theme' in localStorage)) {
      localStorage.theme = 'dark'
    }
  }
}