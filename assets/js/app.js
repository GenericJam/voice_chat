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
      
      // First, explicitly request microphone permission
      if (navigator.mediaDevices && navigator.mediaDevices.getUserMedia) {
        navigator.mediaDevices.getUserMedia({ audio: true })
          .then(() => {
            console.log('Microphone permission granted, starting speech recognition...')
            try {
              this.recognition.start()
              console.log('Speech recognition start() called successfully')
            } catch (error) {
              console.error('Speech recognition start error:', error)
              this.pushEvent('speech_error', { error: error.message })
            }
          })
          .catch((error) => {
            console.error('Microphone permission denied:', error)
            let errorMessage = 'Microphone access denied. Please allow microphone access and refresh the page.'
            if (error.name === 'NotAllowedError') {
              errorMessage = 'Microphone access denied. Please click "Allow" when prompted and try again.'
            } else if (error.name === 'NotFoundError') {
              errorMessage = 'No microphone found. Please connect a microphone and try again.'
            }
            this.pushEvent('speech_error', { error: errorMessage })
          })
      } else {
        // Fallback for browsers without getUserMedia - try starting directly
        try {
          console.log('Attempting to start speech recognition (no getUserMedia)...')
          this.recognition.start()
          console.log('Speech recognition start() called successfully')
        } catch (error) {
          console.error('Speech recognition start error:', error)
          this.pushEvent('speech_error', { error: error.message })
        }
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

// Text-to-Speech hook
let TextToSpeech = {
  mounted() {
    console.log('TextToSpeech hook mounted')
    this.speechSynthesis = window.speechSynthesis
    this.currentUtterance = null
    this.isSupported = 'speechSynthesis' in window
    this.voices = []
    this.selectedVoice = null
    
    this.initializeTextToSpeech()
  },

  reconnected() {
    this.initializeTextToSpeech()
  },

  initializeTextToSpeech() {
    console.log('Initializing text-to-speech...')
    
    if (!this.isSupported) {
      console.log('Text-to-speech not supported')
      this.pushEvent('tts_error', { error: 'Text-to-speech not supported in this browser' })
      return
    }

    // Load voices (may need to wait for voices to be loaded)
    this.loadVoices()
    
    // Handle voice loading (Chrome loads voices asynchronously)
    if (this.speechSynthesis.onvoiceschanged !== undefined) {
      this.speechSynthesis.onvoiceschanged = () => {
        this.loadVoices()
      }
    }

    // Handle events from LiveView
    this.handleEvent('speak_text', (data) => {
      console.log('Received speak_text event:', data.text)
      this.speak(data.text)
    })

    this.handleEvent('stop_speech_synthesis', () => {
      console.log('Received stop_speech_synthesis event')
      this.stopSpeaking()
    })

    this.handleEvent('change_voice', (data) => {
      console.log('Received change_voice event:', data.voiceURI)
      this.changeVoice(data.voiceURI)
    })

    this.handleEvent('test_voice', (data) => {
      console.log('Received test_voice event:', data.voiceURI)
      this.testVoice(data.voiceURI, data.text || 'Hello! This is a test of this voice.')
    })

    console.log('TTS initialization complete')
  },

  loadVoices() {
    this.voices = this.speechSynthesis.getVoices()
    console.log('Loaded voices:', this.voices.length)
    
    // Send voice list to LiveView for UI
    this.sendVoicesToLiveView()
    
    // Select default voice if none selected yet
    if (!this.selectedVoice) {
      this.selectedVoice = this.selectDefaultVoice()
    }
    
    if (this.selectedVoice) {
      console.log('Selected voice:', this.selectedVoice.name, this.selectedVoice.lang)
      this.pushEvent('voice_selected', { 
        name: this.selectedVoice.name, 
        lang: this.selectedVoice.lang,
        voiceURI: this.selectedVoice.voiceURI
      })
    }
  },

  selectDefaultVoice() {
    // Voice priority order for default selection
    const voicePreferences = [
      // American English voices (various options)
      v => v.lang === 'en-US' && v.name.toLowerCase().includes('samantha'),
      v => v.lang === 'en-US' && v.name.toLowerCase().includes('alex'),
      v => v.lang === 'en-US' && v.name.toLowerCase().includes('allison'),
      v => v.lang === 'en-US' && v.name.toLowerCase().includes('ava'),
      v => v.lang === 'en-US' && v.name.toLowerCase().includes('susan'),
      v => v.lang === 'en-US' && v.name.toLowerCase().includes('karen'),
      v => v.lang === 'en-US' && v.name.toLowerCase().includes('female'),
      v => v.lang === 'en-US',
      
      // Other English variants
      v => v.lang === 'en-CA', // Canadian
      v => v.lang === 'en-AU', // Australian  
      v => v.lang === 'en-GB', // British
      
      // Any English voice
      v => v.lang.startsWith('en'),
      
      // Any voice as final fallback
      v => true
    ]
    
    for (const preference of voicePreferences) {
      const voice = this.voices.find(preference)
      if (voice) return voice
    }
    
    return this.voices[0] // Ultimate fallback
  },

  sendVoicesToLiveView() {
    // Categorize voices by language/region for better UI
    const categorizedVoices = this.categorizeVoices()
    this.pushEvent('voices_loaded', { voices: categorizedVoices })
  },

  categorizeVoices() {
    const categories = {}
    
    this.voices.forEach(voice => {
      const lang = voice.lang || 'unknown'
      const region = this.getRegionName(lang)
      
      if (!categories[region]) {
        categories[region] = []
      }
      
      categories[region].push({
        name: voice.name,
        lang: voice.lang,
        voiceURI: voice.voiceURI,
        localService: voice.localService,
        default: voice.default
      })
    })
    
    return categories
  },

  getRegionName(langCode) {
    const regionMap = {
      'en-US': 'English (US)',
      'en-GB': 'English (UK)',
      'en-CA': 'English (Canada)',
      'en-AU': 'English (Australia)',
      'en-IN': 'English (India)',
      'en-IE': 'English (Ireland)',
      'en-ZA': 'English (South Africa)',
      'es-ES': 'Spanish (Spain)',
      'es-MX': 'Spanish (Mexico)',
      'es-US': 'Spanish (US)',
      'fr-FR': 'French (France)',
      'fr-CA': 'French (Canada)',
      'de-DE': 'German',
      'it-IT': 'Italian',
      'pt-BR': 'Portuguese (Brazil)',
      'pt-PT': 'Portuguese (Portugal)',
      'ja-JP': 'Japanese',
      'ko-KR': 'Korean',
      'zh-CN': 'Chinese (Simplified)',
      'zh-TW': 'Chinese (Traditional)',
      'ru-RU': 'Russian',
      'ar-SA': 'Arabic',
      'hi-IN': 'Hindi',
      'th-TH': 'Thai',
      'vi-VN': 'Vietnamese'
    }
    
    return regionMap[langCode] || langCode || 'Other'
  },

  speak(text) {
    if (!this.isSupported || !text.trim()) return
    
    // Stop any current speech
    this.stopSpeaking()
    
    // Create new utterance
    this.currentUtterance = new SpeechSynthesisUtterance(text)
    
    // Configure utterance
    if (this.selectedVoice) {
      this.currentUtterance.voice = this.selectedVoice
    }
    this.currentUtterance.rate = 0.9  // Slightly slower for clarity
    this.currentUtterance.pitch = 1.0
    this.currentUtterance.volume = 0.8
    
    // Event handlers
    this.currentUtterance.onstart = () => {
      console.log('TTS started')
      this.pushEvent('tts_started', {})
    }
    
    this.currentUtterance.onend = () => {
      console.log('TTS ended')
      this.pushEvent('tts_ended', {})
      this.currentUtterance = null
    }
    
    this.currentUtterance.onerror = (event) => {
      console.error('TTS error:', event.error)
      this.pushEvent('tts_error', { error: event.error })
      this.currentUtterance = null
    }
    
    // Add mouth animation on word boundaries
    this.currentUtterance.onboundary = (event) => {
      if (event.name === 'word') {
        // Get the current word being spoken
        const currentWord = text.substring(event.charIndex, event.charIndex + event.length || 10)
        console.log('Speaking word:', currentWord, 'at', event.elapsedTime + 'ms')
        
        // Send mouth animation event
        this.pushEvent('mouth_animation', { 
          word: currentWord,
          elapsedTime: event.elapsedTime,
          charIndex: event.charIndex
        })
      }
    }
    
    // Speak
    this.speechSynthesis.speak(this.currentUtterance)
  },

  changeVoice(voiceURI) {
    const newVoice = this.voices.find(voice => voice.voiceURI === voiceURI)
    if (newVoice) {
      this.selectedVoice = newVoice
      console.log('Voice changed to:', newVoice.name, newVoice.lang)
      this.pushEvent('voice_changed', { 
        name: newVoice.name, 
        lang: newVoice.lang,
        voiceURI: newVoice.voiceURI
      })
    }
  },

  testVoice(voiceURI, testText) {
    const testVoice = this.voices.find(voice => voice.voiceURI === voiceURI)
    if (!testVoice) return
    
    // Stop any current speech
    this.stopSpeaking()
    
    // Create test utterance with the specific voice
    const testUtterance = new SpeechSynthesisUtterance(testText)
    testUtterance.voice = testVoice
    testUtterance.rate = 0.9
    testUtterance.pitch = 1.0
    testUtterance.volume = 0.8
    
    // Event handlers for test
    testUtterance.onstart = () => {
      this.pushEvent('voice_test_started', { voiceURI })
    }
    
    testUtterance.onend = () => {
      this.pushEvent('voice_test_ended', { voiceURI })
    }
    
    testUtterance.onerror = (event) => {
      this.pushEvent('voice_test_error', { voiceURI, error: event.error })
    }
    
    // Speak test
    this.speechSynthesis.speak(testUtterance)
  },

  stopSpeaking() {
    if (this.speechSynthesis.speaking) {
      this.speechSynthesis.cancel()
    }
    if (this.currentUtterance) {
      this.currentUtterance = null
    }
  },

  destroyed() {
    this.stopSpeaking()
  }
}

// Mouth Animation hook
let MouthAnimation = {
  mounted() {
    console.log('MouthAnimation hook mounted')
    this.mouth = document.getElementById('mouth-animation')
    this.isAnimating = false
    this.animationQueue = []
    
    // Handle TTS mouth animation
    this.handleEvent('mouth_animation', (data) => {
      console.log('TTS mouth animation:', data.word)
      this.animateMouth(data.word.length * 100) // Duration based on word length
    })
    
    // Handle streaming token mouth animation  
    this.handleEvent('token_mouth_animation', (data) => {
      console.log('Token mouth animation:', data.token)
      this.animateMouth(50) // Short animation for each token
    })
  },
  
  animateMouth(duration = 100) {
    if (!this.mouth) return
    
    // Queue animation if already animating
    if (this.isAnimating) {
      this.animationQueue.push(duration)
      return
    }
    
    this.isAnimating = true
    
    // Open mouth
    this.mouth.style.opacity = '0.8'
    this.mouth.style.transform = 'translateX(-50%) scaleY(1.5)'
    
    setTimeout(() => {
      if (this.mouth) {
        // Close mouth
        this.mouth.style.opacity = '0.3'
        this.mouth.style.transform = 'translateX(-50%) scaleY(0.8)'
        
        setTimeout(() => {
          if (this.mouth) {
            this.mouth.style.opacity = '0'
            this.mouth.style.transform = 'translateX(-50%) scaleY(1)'
          }
          
          this.isAnimating = false
          
          // Process next animation in queue
          if (this.animationQueue.length > 0) {
            const nextDuration = this.animationQueue.shift()
            this.animateMouth(nextDuration)
          }
        }, duration / 3)
      }
    }, duration / 2)
  },
  
  destroyed() {
    this.animationQueue = []
  }
}

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: {AutoResize, SpeechRecognition, TextToSpeech, MouthAnimation}
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

