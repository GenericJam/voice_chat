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
// Import topbar - temporarily disabled due to bundling issues
// import topbar from "../vendor/topbar"
const topbar = { config: () => {}, show: () => {}, hide: () => {} }

// Import avatar module
import { AvatarHook } from "./avatar.js"

// Auto-resize textarea hook
let AutoResize = {
  mounted() {
    this.el.style.height = 'auto'
    this.el.style.height = this.el.scrollHeight + 'px'

    this.el.addEventListener('input', () => {
      this.el.style.height = 'auto'
      this.el.style.height = this.el.scrollHeight + 'px'
    })

    // Submit on Enter, newline on Shift+Enter
    this.el.addEventListener('keydown', (e) => {
      if (e.key === 'Enter' && !e.shiftKey) {
        e.preventDefault()
        const form = this.el.closest('form')
        if (form) {
          form.requestSubmit()
        }
      }
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
    this.submitDelay = 1000 // 1 second

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

    // Initialize Web Audio API for amplitude analysis
    this.audioContext = new (window.AudioContext || window.webkitAudioContext)()
    this.analyser = this.audioContext.createAnalyser()
    this.analyser.fftSize = 256
    this.bufferLength = this.analyser.frequencyBinCount
    this.dataArray = new Uint8Array(this.bufferLength)
    this.amplitudeHistory = []
    this.maxHistoryLength = 200 // Keep last 200 samples for graph
    
    // Connect to audio destination
    this.analyser.connect(this.audioContext.destination)

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
      console.log('Received speak_text event:', data.text, 'rate:', data.rate, 'target:', data.target)
      this.speak(data.text, data.rate || 0.9, data.target)
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

  speak(text, rate = 0.9, target = null) {
    console.log('[TTS] speak() called with text:', text?.substring(0, 50), 'rate:', rate, 'target:', target)
    if (!text.trim()) {
      console.log('[TTS] speak() aborted - text empty')
      return
    }

    console.log('[TTS] Stopping any current speech...')
    // Stop any current speech
    this.stopSpeaking()

    console.log('[TTS] Checking for TalkingHead avatar...')
    console.log('[TTS] window.talkingHeadAvatar:', window.talkingHeadAvatar)
    console.log('[TTS] window.talkingHeadAvatar?.head:', window.talkingHeadAvatar?.head)

    // If target is explicitly "avatar", show a message for now
    // (3D avatar TTS requires audio buffer which browser SpeechSynthesis doesn't provide)
    if (target === 'avatar') {
      console.log('[TTS] Avatar button clicked - 3D avatar TTS requires audio service')
      this.pushEvent('tts_error', {
        error: '3D Avatar TTS requires an audio service. Use Terminator button for now, or set up a TTS endpoint for full 3D avatar support.'
      })
      return
    }

    // If target is explicitly "terminator" or not specified, use browser SpeechSynthesis
    console.log('[TTS] Using browser SpeechSynthesis for Terminator')

    // Fallback to browser SpeechSynthesis (for Terminator SVG animation)
    if (!this.isSupported) {
      console.log('[TTS] Browser SpeechSynthesis not supported')
      return
    }

    // Initialize word buffer for syllable-based timing
    this.wordBuffer = []
    this.currentWordIndex = 0
    this.animationTimeouts = [] // Track all animation timeouts

    console.log('[TTS] Creating SpeechSynthesisUtterance...')
    // Create new utterance
    this.currentUtterance = new SpeechSynthesisUtterance(text)

    // Configure utterance
    if (this.selectedVoice) {
      this.currentUtterance.voice = this.selectedVoice
      console.log('[TTS] Using voice:', this.selectedVoice.name)
    }
    this.currentUtterance.rate = rate
    this.currentUtterance.pitch = 1.0
    this.currentUtterance.volume = 0.8
    
    // Event handlers
    this.currentUtterance.onstart = () => {
      console.log('[TTS] onstart - TTS started')
      this.pushEvent('tts_started', {})
      this.startAmplitudeAnalysis()
    }

    this.currentUtterance.onerror = (event) => {
      console.error('[TTS] onerror - TTS error:', event.error, event)
      this.pushEvent('tts_error', { error: event.error })
      this.currentUtterance = null
    }
    
    // Add mouth animation on word boundaries
    this.currentUtterance.onboundary = (event) => {
      if (event.name === 'word') {
        // Get the current word being spoken
        // Extract just the word at charIndex by finding the next space or end
        const remainingText = text.substring(event.charIndex)
        const wordMatch = remainingText.match(/^\S+/)
        const currentWord = wordMatch ? wordMatch[0] : remainingText.substring(0, 10)

        // Add to word buffer
        this.wordBuffer.push({
          word: currentWord,
          startTime: event.elapsedTime,
          charIndex: event.charIndex
        })

        // Process previous word if we have timing data
        if (this.wordBuffer.length >= 2) {
          processPreviousWord(this)
        }

        // Also send to LiveView for any server-side tracking (optional, doesn't block animation)
        this.pushEvent('mouth_animation', {
          word: currentWord,
          elapsedTime: event.elapsedTime,
          charIndex: event.charIndex
        })
      }
    }
    
    this.currentUtterance.onend = () => {
      console.log('[TTS] onend - TTS ended')
      // Process the last word in buffer only if it wasn't already processed
      // (last word gets processed when we don't have a "next" word to calculate duration)
      if (this.wordBuffer.length > 0) {
        processLastWord(this)
      }

      this.pushEvent('tts_ended', {})
      this.stopAmplitudeAnalysis()
      this.currentUtterance = null
    }

    // Speak
    console.log('[TTS] Calling speechSynthesis.speak()...')
    this.speechSynthesis.speak(this.currentUtterance)
    console.log('[TTS] speak() completed successfully')
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


  startAmplitudeAnalysis() {
    this.analyzing = true
    this.amplitudeThreshold = 5 // Threshold for detecting sound
    this.analyzeAmplitude()
  },
  
  stopAmplitudeAnalysis() {
    this.analyzing = false
  },
  
  analyzeAmplitude() {
    if (!this.analyzing) return

    // Get frequency data
    this.analyser.getByteFrequencyData(this.dataArray)

    // Calculate average amplitude
    let sum = 0
    for (let i = 0; i < this.bufferLength; i++) {
      sum += this.dataArray[i]
    }
    const average = sum / this.bufferLength

    // Store in history for graph
    this.amplitudeHistory.push(average)
    if (this.amplitudeHistory.length > this.maxHistoryLength) {
      this.amplitudeHistory.shift()
    }

    // Update graph
    if (window.amplitudeGraphHook && typeof window.amplitudeGraphHook.updateGraph === 'function') {
      window.amplitudeGraphHook.updateGraph(this.amplitudeHistory, average)
    }

    // Note: Jaw control is now handled by syllable-based timing, not amplitude

    // Continue analysis
    requestAnimationFrame(() => this.analyzeAmplitude())
  },

  stopSpeaking() {
    console.log('[TTS] stopSpeaking() called')

    // Stop TalkingHead speech if available
    if (window.talkingHeadAvatar && window.talkingHeadAvatar.head) {
      try {
        console.log('[TTS] Stopping TalkingHead speech...')
        window.talkingHeadAvatar.head.stopSpeaking()
      } catch (error) {
        console.error('[TTS] Error stopping TalkingHead:', error)
      }
    }

    // Stop browser speech synthesis
    if (this.speechSynthesis.speaking) {
      console.log('[TTS] Stopping browser SpeechSynthesis...')
      this.speechSynthesis.cancel()
    }
    if (this.currentUtterance) {
      this.currentUtterance = null
    }

    // Cancel all pending animation timeouts
    if (this.animationTimeouts) {
      this.animationTimeouts.forEach(timeout => clearTimeout(timeout))
      this.animationTimeouts = []
    }

    this.stopAmplitudeAnalysis()
  },

  destroyed() {
    this.stopSpeaking()
    if (this.audioContext) {
      this.audioContext.close()
    }
  }
}




// Auto login hook
let AutoLogin = {
  mounted() {
    this.handleEvent('auto_login', () => {
      // Submit the form to /api/auto_login
      const form = document.createElement('form')
      form.method = 'POST'
      form.action = '/api/auto_login'

      // Add CSRF token
      const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
      const csrfInput = document.createElement('input')
      csrfInput.type = 'hidden'
      csrfInput.name = '_csrf_token'
      csrfInput.value = csrfToken
      form.appendChild(csrfInput)

      document.body.appendChild(form)
      form.submit()
    })
  }
}

// Server-side AudioRecorder hook (replaces Web Speech API)
let ServerAudioRecorder = {
  mounted() {
    this.mediaRecorder = null
    this.audioChunks = []
    this.audioContext = null
    this.isRecording = false

    // Listen for toggle_listening event (same as old SpeechRecognition hook)
    this.handleEvent("toggle_listening", () => {
      if (this.isRecording) {
        this.stopRecording()
      } else {
        this.startRecording()
      }
    })
  },

  async startRecording() {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({
        audio: {
          channelCount: 1,
          sampleRate: 16000,
          echoCancellation: true,
          noiseSuppression: true
        }
      })

      this.audioChunks = []
      this.mediaRecorder = new MediaRecorder(stream)
      this.stream = stream

      this.mediaRecorder.ondataavailable = (event) => {
        if (event.data.size > 0) {
          this.audioChunks.push(event.data)
        }
      }

      this.mediaRecorder.onstop = async () => {
        const audioBlob = new Blob(this.audioChunks, { type: 'audio/webm' })
        await this.processAudio(audioBlob)

        // Stop all tracks
        this.stream.getTracks().forEach(track => track.stop())
      }

      this.mediaRecorder.start()
      this.isRecording = true
      this.pushEvent('speech_started', {})
      console.log("Server-side recording started")
    } catch (error) {
      console.error("Error accessing microphone:", error)
      this.pushEvent('speech_error', { error: `Could not access microphone: ${error.message}` })
    }
  },

  stopRecording() {
    if (this.mediaRecorder && this.mediaRecorder.state === "recording") {
      this.mediaRecorder.stop()
      this.isRecording = false
      this.pushEvent('speech_ended', {})
      console.log("Server-side recording stopped")

      // Don't auto-submit here - wait for transcription to complete
      // Auto-submit will be triggered by the server after transcription
    }
  },

  async processAudio(audioBlob) {
    try {
      // Create audio context if it doesn't exist
      if (!this.audioContext) {
        this.audioContext = new (window.AudioContext || window.webkitAudioContext)({
          sampleRate: 16000
        })
      }

      // Convert blob to array buffer
      const arrayBuffer = await audioBlob.arrayBuffer()

      // Decode audio data
      const audioBuffer = await this.audioContext.decodeAudioData(arrayBuffer)

      // Get channel data (mono)
      const channelData = audioBuffer.getChannelData(0)

      // Convert Float32Array [-1, 1] to Int16Array (16-bit PCM)
      const pcmData = new Int16Array(channelData.length)
      for (let i = 0; i < channelData.length; i++) {
        const s = Math.max(-1, Math.min(1, channelData[i]))
        pcmData[i] = s < 0 ? s * 0x8000 : s * 0x7FFF
      }

      // Convert to base64 (chunk to avoid call stack overflow)
      const bytes = new Uint8Array(pcmData.buffer)
      let binary = ''
      const chunkSize = 8192
      for (let i = 0; i < bytes.length; i += chunkSize) {
        const chunk = bytes.subarray(i, Math.min(i + chunkSize, bytes.length))
        binary += String.fromCharCode.apply(null, chunk)
      }
      const base64 = btoa(binary)

      // Send to server for transcription
      this.pushEvent("audio_data_server", { audio: base64 })
      console.log("Audio sent to server for transcription, length:", pcmData.length)
    } catch (error) {
      console.error("Error processing audio:", error)
      this.pushEvent('speech_error', { error: `Error processing audio: ${error.message}` })
    }
  }
}

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: {AutoResize, SpeechRecognition, ServerAudioRecorder, TextToSpeech, AutoLogin, AvatarHook}
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

