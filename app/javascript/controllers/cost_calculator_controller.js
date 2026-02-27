import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "globalRate",
    "blockEntry", "blockHours", "blockCost",
    "taskRow", "taskHours", "taskRate", "taskCost",
    "progressFill",
    "totalHoursText", "workingDaysText",
    "statTotalHours", "statTotalCost"
  ]

  recalculate() {
    const globalRate = parseFloat(this.globalRateTarget.value) || 0
    let grandTotalHours = 0
    let grandTotalCost = 0

    // Find max hours for progress bar scaling
    let maxHours = 0
    this.taskHoursTargets.forEach((input) => {
      const h = parseFloat(input.value) || 0
      if (h > maxHours) maxHours = h
    })
    if (maxHours === 0) maxHours = 1

    this.blockEntryTargets.forEach((block) => {
      let blockHours = 0
      let blockCost = 0

      const rows = block.querySelectorAll("[data-cost-calculator-target~='taskRow']")
      rows.forEach((row) => {
        const hoursInput = row.querySelector("[data-cost-calculator-target~='taskHours']")
        const rateInput = row.querySelector("[data-cost-calculator-target~='taskRate']")
        const costEl = row.querySelector("[data-cost-calculator-target~='taskCost']")
        const progressFill = row.querySelector("[data-cost-calculator-target~='progressFill']")

        const hours = parseFloat(hoursInput?.value) || 0
        const rate = parseFloat(rateInput?.value) || globalRate
        const cost = hours * rate

        blockHours += hours
        blockCost += cost

        if (costEl) costEl.textContent = this.formatNumber(Math.round(cost)) + this.currencySymbol
        if (progressFill) {
          const pct = (hours / maxHours * 100).toFixed(1)
          progressFill.style.width = `${pct}%`
        }
      })

      grandTotalHours += blockHours
      grandTotalCost += blockCost

      const blockHoursEl = block.querySelector("[data-cost-calculator-target~='blockHours']")
      const blockCostEl = block.querySelector("[data-cost-calculator-target~='blockCost']")

      if (blockHoursEl) blockHoursEl.textContent = `${Math.round(blockHours)}h`
      if (blockCostEl) blockCostEl.textContent = this.formatNumber(Math.round(blockCost)) + this.currencySymbol
    })

    // Update global stats
    if (this.hasTotalHoursTextTarget) this.totalHoursTextTarget.textContent = Math.round(grandTotalHours)
    if (this.hasWorkingDaysTextTarget) this.workingDaysTextTarget.textContent = (grandTotalHours / 8).toFixed(1)
    if (this.hasStatTotalHoursTarget) this.statTotalHoursTarget.textContent = `${Math.round(grandTotalHours)}h`
    if (this.hasStatTotalCostTarget) this.statTotalCostTarget.textContent = this.formatNumber(Math.round(grandTotalCost)) + this.currencySymbol
  }

  get currencySymbol() {
    // Detect from existing text on the page
    const costEl = this.hasStatTotalCostTarget ? this.statTotalCostTarget : null
    if (costEl && costEl.textContent.includes("$")) return "$"
    return "\u20AC"
  }

  formatNumber(num) {
    return num.toLocaleString("es-ES")
  }
}
