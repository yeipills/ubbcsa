// app/javascript/controllers/quiz_timer_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["display", "progress"]
  static values = { 
    duration: Number,
    warningTime: Number,
    criticalTime: Number
  }

  connect() {
    this.remaining = this.durationValue
    this.warningTimeValue = this.durationValue * 0.3
    this.criticalTimeValue = this.durationValue * 0.1
    this.startTimer()
  }

  startTimer() {
    this.timer = setInterval(() => {
      this.remaining -= 1
      this.updateDisplay()
      this.updateProgress()
      
      if (this.remaining <= 0) {
        this.timeUp()
      } else if (this.remaining <= this.criticalTimeValue) {
        this.setCriticalState()
      } else if (this.remaining <= this.warningTimeValue) {
        this.setWarningState()
      }
    }, 1000)
  }

  updateDisplay() {
    const minutes = Math.floor(this.remaining / 60)
    const seconds = this.remaining % 60
    this.displayTarget.textContent = 
      `${String(minutes).padStart(2, '0')}:${String(seconds).padStart(2, '0')}`
  }

  updateProgress() {
    const percentage = (this.remaining / this.durationValue) * 100
    this.progressTarget.style.width = `${percentage}%`
  }

  setWarningState() {
    this.progressTarget.classList.remove('bg-blue-500')
    this.progressTarget.classList.add('bg-yellow-500')
    this.displayTarget.classList.add('text-yellow-600')
  }

  setCriticalState() {
    this.progressTarget.classList.remove('bg-yellow-500')
    this.progressTarget.classList.add('bg-red-500')
    this.displayTarget.classList.add('text-red-600', 'animate-pulse')
  }

  timeUp() {
    clearInterval(this.timer)
    this.element.dispatchEvent(new CustomEvent('timeUp'))
  }

  disconnect() {
    if (this.timer) {
      clearInterval(this.timer)
    }
  }
}