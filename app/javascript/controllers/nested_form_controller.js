import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["blocksContainer", "blockTemplate", "taskTemplate", "blockEntry", "taskEntry", "blockCount", "taskCount"]

  connect() {
    this.blockIndex = Date.now()
    this.taskIndex = Date.now() + 1000
  }

  addBlock() {
    const template = this.blockTemplateTarget.content.cloneNode(true)
    const index = this.blockIndex++

    template.querySelectorAll("[name]").forEach((el) => {
      el.name = el.name.replace("NEW_BLOCK_RECORD", index)
    })

    const addTaskBtn = template.querySelector("[data-action='nested-form#addTask']")
    if (addTaskBtn) {
      addTaskBtn.dataset.blockIndex = index
    }

    this.blocksContainerTarget.appendChild(template)

    const blocks = this.blocksContainerTarget.querySelectorAll("[data-nested-form-target='blockEntry']")
    const lastBlock = blocks[blocks.length - 1]
    const nameInput = lastBlock.querySelector("input[type='text']")
    if (nameInput) nameInput.focus()

    this.updateCounts()
  }

  removeBlock(event) {
    const block = event.target.closest("[data-nested-form-target='blockEntry']")
    if (!block) return

    const idField = block.querySelector("input[type='hidden'][name*='[id]']")

    if (idField && idField.value) {
      // Persisted block: mark for destruction
      const destroyInput = document.createElement("input")
      destroyInput.type = "hidden"
      destroyInput.name = idField.name.replace("[id]", "[_destroy]")
      destroyInput.value = "1"
      block.appendChild(destroyInput)
      block.style.display = "none"
    } else {
      // New block: remove from DOM
      block.remove()
    }

    this.updateCounts()
  }

  addTask(event) {
    const button = event.currentTarget
    const blockIndex = button.dataset.blockIndex
    const blockEntry = button.closest("[data-nested-form-target='blockEntry']")
    const tasksContainer = blockEntry.querySelector("[data-nested-form-target='tasksContainer']")

    const template = this.taskTemplateTarget.content.cloneNode(true)
    const taskIdx = this.taskIndex++

    template.querySelectorAll("[name]").forEach((el) => {
      el.name = el.name.replace("BLOCK_INDEX", blockIndex).replace("NEW_TASK_RECORD", taskIdx)
    })

    tasksContainer.appendChild(template)

    const tasks = tasksContainer.querySelectorAll("[data-nested-form-target='taskEntry']")
    const lastTask = tasks[tasks.length - 1]
    const nameInput = lastTask.querySelector("input[type='text']")
    if (nameInput) nameInput.focus()

    this.updateCounts()
  }

  removeTask(event) {
    const task = event.target.closest("[data-nested-form-target='taskEntry']")
    if (!task) return

    const idField = task.querySelector("input[type='hidden'][name*='[id]']")

    if (idField && idField.value) {
      // Persisted task: mark for destruction
      const destroyInput = document.createElement("input")
      destroyInput.type = "hidden"
      destroyInput.name = idField.name.replace("[id]", "[_destroy]")
      destroyInput.value = "1"
      task.appendChild(destroyInput)
      task.style.display = "none"
    } else {
      // New task: remove from DOM
      task.remove()
    }

    this.updateCounts()
  }

  updateCounts() {
    const visibleBlocks = this.blocksContainerTarget.querySelectorAll("[data-nested-form-target='blockEntry']:not([style*='display: none'])")
    let totalTasks = 0

    visibleBlocks.forEach((block) => {
      const visibleTasks = block.querySelectorAll("[data-nested-form-target='taskEntry']:not([style*='display: none'])")
      totalTasks += visibleTasks.length

      const countEl = block.querySelector("[data-nested-form-target='blockTaskCount']")
      if (countEl) {
        countEl.textContent = `${visibleTasks.length} tareas`
      }
    })

    if (this.hasBlockCountTarget) {
      this.blockCountTarget.textContent = visibleBlocks.length
    }
    if (this.hasTaskCountTarget) {
      this.taskCountTarget.textContent = totalTasks
    }
  }
}
