// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

// Auto-resize textarea hook
let AutoResize = {
  mounted() {
    this.el.style.height = 'auto'
    this.el.style.height = this.el.scrollHeight + 'px'
    
    this.el.addEventListener('input', () => {
      this.el.style.height = 'auto'
      this.el.style.height = this.el.scrollHeight + 'px'
    })
  },
  
  updated() {
    this.el.style.height = 'auto'
    this.el.style.height = this.el.scrollHeight + 'px'
  }
}

// Speech Recognition hook
let SpeechRecognition = {
  mounted() {
    console.log('SpeechRecognition hook mounted')
    this.recognition = null
    this.isListening = false
    this.isMuted = false
    this.startTime = null
    this.interimTranscript = ''
    this.finalTranscript = ''
    this.submitTimeout = null
    this.countdownInterval = null
    this.submitDelay = 2000 // 2 seconds

    this.initializeSpeechRecognition()
  },

  reconnected() {
    // Reinitialize speech recognition on reconnection
    this.initializeSpeechRecognition()
  },

  initializeSpeechRecognition() {
    console.log('Initializing speech recognition...')
    
    // Check for browser support
    if ('webkitSpeechRecognition' in window || 'SpeechRecognition' in window) {
      console.log('Speech recognition supported')
      const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition
      this.recognition = new SpeechRecognition()
      
      // Configure recognition
      this.recognition.continuous = true
      this.recognition.interimResults = true
      this.recognition.lang = 'en-US'
      
      // Event handlers
      this.recognition.onstart = () => {
        console.log('Speech recognition onstart event fired')
        this.startTime = Date.now() // Track when recognition actually started
        this.isListening = true
        this.isMuted = false
        this.clearSubmitTimeout()
        this.pushEvent('speech_started', {})
      }
      
      this.recognition.onend = () => {
        console.log('Speech recognition onend event fired, duration since start:', Date.now() - (this.startTime || 0))
        this.isListening = false
        this.pushEvent('speech_ended', {})
        // Only start the submit timeout when speech ends after actually being active for a bit
        // and not muted. Don't auto-submit if it ended immediately (likely permission error)
        const durationSinceStart = Date.now() - (this.startTime || 0)
        if (!this.isMuted && durationSinceStart > 1000) { // Only if it ran for more than 1 second
          console.log('Scheduling auto-submit after speech end')
          this.scheduleSubmit()
        } else {
          console.log('Not scheduling auto-submit - duration was too short or muted:', durationSinceStart, 'ms')
        }
      }
      
      this.recognition.onerror = (event) => {
        console.error('Speech recognition error:', event.error, event)
        let errorMessage = event.error
        
        // Provide more user-friendly error messages
        switch(event.error) {
          case 'not-allowed':
            errorMessage = 'Microphone access denied. Please allow microphone access and try again.'
            break
          case 'no-speech':
            errorMessage = 'No speech detected. Please try speaking again.'
            break
          case 'audio-capture':
            errorMessage = 'Microphone not found or not working.'
            break
          case 'network':
            errorMessage = 'Network error occurred during speech recognition.'
            break
          default:
            errorMessage = `Speech recognition error: ${event.error}`
        }
        
        this.pushEvent('speech_error', { error: errorMessage })
        this.isListening = false
        this.isMuted = false
        this.clearSubmitTimeout()
      }
      
      this.recognition.onresult = (event) => {
        // Don't process results if muted
        if (this.isMuted) return
        
        let interimTranscript = ''
        let finalTranscript = ''
        
        for (let i = event.resultIndex; i < event.results.length; i++) {
          const transcript = event.results[i][0].transcript
          if (event.results[i].isFinal) {
            finalTranscript += transcript
          } else {
            interimTranscript += transcript
          }
        }
        
        this.pushEvent('speech_interim', { text: interimTranscript })
        
        if (finalTranscript) {
          this.pushEvent('speech_final', { text: finalTranscript })
          // Reset the submit timeout when we get new final text
          this.scheduleSubmit()
        }
      }
    } else {
      console.log('Speech recognition not supported')
      this.pushEvent('speech_not_supported', {})
    }
    
    console.log('Registering LiveView event handlers...')
    // Handle events from LiveView
    this.handleEvent('start_listening', () => {
      console.log('Received start_listening event')
      this.startListening()
    })
    
    this.handleEvent('stop_listening', () => {
      console.log('Received stop_listening event')
      this.stopListening()
    })
    
    this.handleEvent('mute_listening', () => {
      console.log('Received mute_listening event')
      this.muteListening()
    })
    
    this.handleEvent('unmute_listening', () => {
      console.log('Received unmute_listening event')
      this.unmuteListening()
    })
    
    this.handleEvent('submit_speech_message', () => {
      console.log('Received submit_speech_message event')
      this.submitMessage()
    })
    console.log('Event handlers registered')
  },
  
  startListening() {
    console.log('startListening called, isListening:', this.isListening, 'recognition exists:', !!this.recognition)
    if (this.recognition && !this.isListening) {
      this.clearSubmitTimeout()
      this.isMuted = false
      try {
        console.log('Attempting to start speech recognition...')
        this.recognition.start()
        console.log('Speech recognition start() called successfully')
      } catch (error) {
        console.error('Speech recognition start error:', error)
        this.pushEvent('speech_error', { error: error.message })
      }
    } else {
      console.log('Cannot start - isListening:', this.isListening, 'recognition exists:', !!this.recognition)
    }
  },
  
  stopListening() {
    console.log('stopListening called, isListening:', this.isListening)
    if (this.recognition && this.isListening) {
      this.clearSubmitTimeout() // This will also clear countdown
      this.isMuted = false
      this.recognition.stop()
      console.log('Speech recognition stopped')
    }
  },
  
  muteListening() {
    console.log('muteListening called, isListening:', this.isListening, 'isMuted:', this.isMuted)
    if (this.recognition && this.isListening) {
      this.isMuted = true
      this.clearSubmitTimeout()
      this.pushEvent('speech_muted', {})
      console.log('Speech recognition muted')
    }
  },
  
  unmuteListening() {
    console.log('unmuteListening called, isListening:', this.isListening, 'isMuted:', this.isMuted)
    if (this.recognition && this.isListening) {
      this.isMuted = false
      this.pushEvent('speech_unmuted', {})
      console.log('Speech recognition unmuted')
    }
  },
  
  scheduleSubmit() {
    // Don't schedule submit if muted
    if (this.isMuted) return
    
    this.clearSubmitTimeout()
    this.clearCountdownInterval()
    
    let countdown = this.submitDelay / 1000 // Convert to seconds
    this.pushEvent('auto_submit_countdown', { seconds: countdown })
    
    // Update countdown every 100ms for smooth animation
    this.countdownInterval = setInterval(() => {
      countdown -= 0.1
      if (countdown <= 0) {
        this.clearCountdownInterval()
        this.pushEvent('auto_submit_countdown', { seconds: 0 })
      } else {
        // Round to avoid floating point precision issues
        this.pushEvent('auto_submit_countdown', { seconds: Math.round(Math.max(0, countdown) * 10) / 10 })
      }
    }, 100)
    
    this.submitTimeout = setTimeout(() => {
      this.clearCountdownInterval()
      this.submitMessage()
    }, this.submitDelay)
  },
  
  clearSubmitTimeout() {
    if (this.submitTimeout) {
      clearTimeout(this.submitTimeout)
      this.submitTimeout = null
    }
    this.clearCountdownInterval()
    this.pushEvent('auto_submit_countdown', { seconds: 0 })
  },
  
  clearCountdownInterval() {
    if (this.countdownInterval) {
      clearInterval(this.countdownInterval)
      this.countdownInterval = null
    }
  },
  
  submitMessage() {
    this.clearSubmitTimeout()
    try {
      // Find the form and submit it
      const form = document.getElementById('dialog_input')
      if (form) {
        // Trigger the phx-submit event
        this.pushEvent('auto_submit_speech', {})
      }
    } catch (error) {
      console.error('Submit message error:', error)
    }
  },
  
  destroyed() {
    this.clearSubmitTimeout()
    this.clearCountdownInterval()
    if (this.recognition) {
      this.recognition.stop()
    }
  }
}

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: {AutoResize, SpeechRecognition}
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

