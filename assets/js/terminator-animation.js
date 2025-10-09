// Terminator SVG Mouth Animation
// Syllable-based jaw animation for the SVG Terminator head

import { syllable } from 'syllable'

export const MouthAnimation = {
  mounted() {
    this.jaw = document.getElementById('lower-jaw')
    this.logContainer = document.getElementById('jaw-movement-log')
    this.isOpen = false
    this.maxLogEntries = 100
    this.updateScheduled = false

    // Restore log from global storage (persist across LiveView reconnections)
    if (!window.jawMovementLog) {
      window.jawMovementLog = []
    }
    this.movementLog = window.jawMovementLog

    // Register globally so TextToSpeech can find us
    window.mouthAnimationHook = this

    // Restore existing log display
    if (this.movementLog.length > 0) {
      this.updateLogDisplay()
    } else if (this.logContainer) {
      this.logContainer.innerHTML = '<div class="text-gray-500">Waiting for speech...</div>'
    }
  },

  openJaw(word = '') {
    if (!this.jaw || this.isOpen) return

    this.isOpen = true
    this.currentWord = word
    // Drop jaw straight down 20 pixels
    this.jaw.style.transform = 'translateY(20px)'

    // Log the movement
    this.logMovement('DOWN', word)
  },

  closeJaw() {
    if (!this.jaw || !this.isOpen) return

    this.isOpen = false
    const word = this.currentWord || ''
    this.currentWord = ''
    // Return jaw to closed position
    this.jaw.style.transform = 'translateY(0px)'

    // Log the movement
    this.logMovement('UP', word)
  },

  logMovement(direction, word = '') {
    const now = new Date()
    const timestamp = now.toLocaleTimeString('en-US', {
      hour12: false,
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit',
      fractionalSecondDigits: 3
    })

    const entry = {
      timestamp,
      direction,
      word,
      fullTimestamp: now.toISOString()
    }

    // Add to log
    this.movementLog.push(entry)

    // Keep only last 100 entries (truncate from beginning, not reset)
    if (this.movementLog.length > this.maxLogEntries) {
      this.movementLog.shift()
    }

    // Persist to global storage
    window.jawMovementLog = this.movementLog

    // Throttle display updates to avoid overwhelming LiveView
    this.scheduleLogUpdate()
  },

  scheduleLogUpdate() {
    if (this.updateScheduled) return

    this.updateScheduled = true
    requestAnimationFrame(() => {
      this.updateLogDisplay()
      this.updateScheduled = false
    })
  },

  updateLogDisplay() {
    if (!this.logContainer) return

    // Reverse the array so newest entries appear first (top)
    const reversedLog = [...this.movementLog].reverse()

    // Split into 2 columns
    const columnCount = 2
    const columns = [[], []]
    reversedLog.forEach((entry, index) => {
      const columnIndex = index % columnCount
      columns[columnIndex].push(entry)
    })

    // Build HTML for columns
    const columnsHtml = columns.map(columnEntries => {
      const entriesHtml = columnEntries.map(entry => {
        const color = entry.direction === 'DOWN' ? 'text-yellow-400' : 'text-green-400'
        const wordDisplay = entry.word ? `<span class="text-blue-400">"${entry.word}"</span>` : ''
        return `<div class="mb-1"><span class="text-gray-500">[${entry.timestamp}]</span> <span class="${color}">Jaw ${entry.direction}</span> ${wordDisplay}</div>`
      }).join('')
      return `<div class="flex-1 min-w-0 px-2">${entriesHtml || '<div class="text-gray-500">...</div>'}</div>`
    }).join('')

    this.logContainer.innerHTML = `<div class="flex gap-4">${columnsHtml}</div>`
  },

  destroyed() {
    this.movementLog = []
    // Unregister global reference
    if (window.mouthAnimationHook === this) {
      window.mouthAnimationHook = null
    }
  }
}

export const AmplitudeGraph = {
  mounted() {
    this.canvas = this.el
    this.ctx = this.canvas.getContext('2d')
    this.width = this.canvas.width
    this.height = this.canvas.height

    // State tracking - oscilloscope style
    this.currentState = 'UP'
    this.stateChanges = [] // {state: 'UP'|'DOWN', word: string, x: position}
    this.currentX = this.width // Start from right edge
    this.pixelsPerEvent = 20 // How far to move per state change
    this.currentWord = ''

    // Register globally
    window.amplitudeGraphHook = this

    // Draw initial empty graph
    this.draw()
  },

  addEvent(state, word) {
    // Only add if state actually changed
    if (state === this.currentState && word === this.currentWord) {
      return
    }

    // Move left for new event (oscilloscope style - new data on right)
    this.currentX -= this.pixelsPerEvent

    // Store state change
    this.stateChanges.push({
      state: state,
      word: word,
      x: this.currentX
    })

    // Keep only visible events (plus some buffer)
    this.stateChanges = this.stateChanges.filter(e => e.x > -100)

    this.currentState = state
    this.currentWord = word

    this.draw()
  },

  draw() {
    const ctx = this.ctx
    const width = this.width
    const height = this.height
    const graphHeight = height * 0.7
    const textHeight = height * 0.3

    // Clear canvas
    ctx.fillStyle = '#1a1a1a'
    ctx.fillRect(0, 0, width, height)

    // Draw center line
    ctx.strokeStyle = '#444'
    ctx.lineWidth = 1
    ctx.beginPath()
    ctx.moveTo(0, graphHeight / 2)
    ctx.lineTo(width, graphHeight / 2)
    ctx.stroke()

    // Draw UP/DOWN states as oscilloscope (scrolling right-to-left)
    if (this.stateChanges.length > 0) {
      ctx.strokeStyle = '#00ff00'
      ctx.lineWidth = 3
      ctx.beginPath()

      let started = false
      let lastX = width
      let lastY = this.currentState === 'DOWN' ? graphHeight * 0.75 : graphHeight * 0.25

      // Start from right edge with current state
      ctx.moveTo(width, lastY)

      // Draw in reverse order (newest to oldest, right to left)
      for (let i = this.stateChanges.length - 1; i >= 0; i--) {
        const event = this.stateChanges[i]
        const x = event.x
        const y = event.state === 'DOWN' ? graphHeight * 0.75 : graphHeight * 0.25

        if (x < -50) break // Stop drawing off-screen events

        // Draw horizontal line to this x position
        ctx.lineTo(x, lastY)

        // Draw vertical line to new state
        ctx.lineTo(x, y)

        lastX = x
        lastY = y
      }

      ctx.stroke()

      // Draw word labels below graph (scrolling with waveform)
      ctx.fillStyle = '#ffff00'
      ctx.font = '14px monospace'
      ctx.textAlign = 'center'

      let lastWordDrawn = null
      for (let i = this.stateChanges.length - 1; i >= 0; i--) {
        const event = this.stateChanges[i]
        if (event.word && event.word !== lastWordDrawn) {
          const x = event.x
          if (x >= -50 && x <= width + 50) {
            ctx.fillText(event.word, x, graphHeight + 25)
            lastWordDrawn = event.word
          }
        }
      }
    }

    // Draw state labels
    ctx.fillStyle = '#888'
    ctx.font = '12px monospace'
    ctx.textAlign = 'left'
    ctx.fillText('DOWN', 5, graphHeight * 0.80)
    ctx.fillText('UP', 5, graphHeight * 0.30)
  },

  destroyed() {
    if (window.amplitudeGraphHook === this) {
      window.amplitudeGraphHook = null
    }
  }
}

// Syllable-based animation helper functions
export function processPreviousWord(wordBuffer) {
  if (wordBuffer.length < 2) return

  const prevWord = wordBuffer[wordBuffer.length - 2]
  const currentWord = wordBuffer[wordBuffer.length - 1]

  // Check if already processed
  if (prevWord.processed) {
    return
  }

  const duration = currentWord.startTime - prevWord.startTime
  const wordSyllableCount = syllable(prevWord.word)
  const totalSyllables = wordSyllableCount + 1 // +1 for space after word
  const timePerSyllable = duration / totalSyllables

  // Animate jaw for word syllables only (not the space)
  animateSyllables(prevWord.word, wordSyllableCount, timePerSyllable, prevWord.startTime, [])
  prevWord.processed = true
}

export function processLastWord(wordBuffer) {
  if (wordBuffer.length === 0) return

  const lastWord = wordBuffer[wordBuffer.length - 1]

  // Check if this word was already processed
  if (lastWord.processed) {
    return
  }

  const syllableCount = syllable(lastWord.word)
  const estimatedDuration = syllableCount * 150 // Estimate 150ms per syllable
  const timePerSyllable = estimatedDuration / syllableCount

  animateSyllables(lastWord.word, syllableCount, timePerSyllable, lastWord.startTime, [])
  lastWord.processed = true
}

export function animateSyllables(word, syllableCount, timePerSyllable, startTime, animationTimeouts) {
  for (let i = 0; i < syllableCount; i++) {
    const delay = i * timePerSyllable

    // Open jaw (DOWN)
    const timeoutDown = setTimeout(() => {
      if (window.mouthAnimationHook) {
        window.mouthAnimationHook.openJaw(word)

        // Update graph
        if (window.amplitudeGraphHook) {
          window.amplitudeGraphHook.addEvent('DOWN', word)
        }
      }
    }, delay)

    animationTimeouts.push(timeoutDown)

    // Close jaw (UP) - halfway through syllable
    const timeoutUp = setTimeout(() => {
      if (window.mouthAnimationHook) {
        window.mouthAnimationHook.closeJaw()

        // Update graph
        if (window.amplitudeGraphHook) {
          window.amplitudeGraphHook.addEvent('UP', word)
        }
      }
    }, delay + (timePerSyllable / 2))

    animationTimeouts.push(timeoutUp)
  }
}
