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
import * as topbarModule from "../vendor/topbar"
const topbar = topbarModule.default || topbarModule
import {syllable} from "syllable"
import {TalkingHead} from "@met4citizen/talkinghead"

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
      console.log('Received speak_text event:', data.text, 'rate:', data.rate)
      this.speak(data.text, data.rate || 0.9)
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

  speak(text, rate = 0.9) {
    if (!this.isSupported || !text.trim()) return
    
    // Stop any current speech
    this.stopSpeaking()
    
    // Initialize word buffer for syllable-based timing
    this.wordBuffer = []
    this.currentWordIndex = 0
    this.animationTimeouts = [] // Track all animation timeouts
    
    // Create new utterance
    this.currentUtterance = new SpeechSynthesisUtterance(text)
    
    // Configure utterance
    if (this.selectedVoice) {
      this.currentUtterance.voice = this.selectedVoice
    }
    this.currentUtterance.rate = rate
    this.currentUtterance.pitch = 1.0
    this.currentUtterance.volume = 0.8
    
    // Event handlers
    this.currentUtterance.onstart = () => {
      console.log('TTS started')
      this.pushEvent('tts_started', {})
      this.startAmplitudeAnalysis()
    }
    
    this.currentUtterance.onerror = (event) => {
      console.error('TTS error:', event.error)
      this.pushEvent('tts_error', { error: event.error })
      this.currentUtterance = null
    }
    
    // Add mouth animation on word boundaries
    this.currentUtterance.onboundary = (event) => {
      console.log('*** NEW ONBOUNDARY HANDLER FIRED ***', event.name)
      if (event.name === 'word') {
        // Get the current word being spoken
        // Extract just the word at charIndex by finding the next space or end
        const remainingText = text.substring(event.charIndex)
        const wordMatch = remainingText.match(/^\S+/)
        const currentWord = wordMatch ? wordMatch[0] : remainingText.substring(0, 10)
        console.log('Speaking word:', currentWord, 'at', event.elapsedTime + 'ms')
        
        // Add to word buffer
        this.wordBuffer.push({
          word: currentWord,
          startTime: event.elapsedTime,
          charIndex: event.charIndex
        })
        
        console.log('Word buffer length:', this.wordBuffer.length)
        
        // Process previous word if we have timing data
        if (this.wordBuffer.length >= 2) {
          console.log('Processing previous word...')
          this.processPreviousWord()
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
      console.log('TTS ended')
      console.log('Word buffer at end:', this.wordBuffer.length, 'words')
      
      // Process the last word in buffer only if it wasn't already processed
      // (last word gets processed when we don't have a "next" word to calculate duration)
      if (this.wordBuffer.length > 0) {
        console.log('Processing final word...')
        this.processLastWord()
      }
      
      this.pushEvent('tts_ended', {})
      this.stopAmplitudeAnalysis()
      this.currentUtterance = null
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

  processPreviousWord() {
    if (this.wordBuffer.length < 2) return
    
    const prevWord = this.wordBuffer[this.wordBuffer.length - 2]
    const currentWord = this.wordBuffer[this.wordBuffer.length - 1]
    
    // Check if already processed
    if (prevWord.processed) {
      return
    }
    
    const duration = currentWord.startTime - prevWord.startTime
    const wordSyllableCount = syllable(prevWord.word)
    const totalSyllables = wordSyllableCount + 1 // +1 for space after word
    const timePerSyllable = duration / totalSyllables
    
    console.log(`Word: "${prevWord.word}", Duration: ${duration}ms, Word syllables: ${wordSyllableCount}, Total (with space): ${totalSyllables}, Time/syllable: ${timePerSyllable}ms`)
    
    // Animate jaw for word syllables only (not the space)
    this.animateSyllables(prevWord.word, wordSyllableCount, timePerSyllable, prevWord.startTime)
    prevWord.processed = true
  },
  
  processLastWord() {
    if (this.wordBuffer.length === 0) return
    
    const lastWord = this.wordBuffer[this.wordBuffer.length - 1]
    
    // Check if this word was already processed
    if (lastWord.processed) {
      console.log('Last word already processed, skipping')
      return
    }
    
    const syllableCount = syllable(lastWord.word)
    const estimatedDuration = syllableCount * 150 // Estimate 150ms per syllable
    const timePerSyllable = estimatedDuration / syllableCount
    
    console.log(`Last word: "${lastWord.word}", Syllables: ${syllableCount}, Estimated time/syllable: ${timePerSyllable}ms`)
    
    this.animateSyllables(lastWord.word, syllableCount, timePerSyllable, lastWord.startTime)
    lastWord.processed = true
  },
  
  animateSyllables(word, syllableCount, timePerSyllable, startTime) {
    console.log(`Animating ${syllableCount} syllables for "${word}"`)
    
    for (let i = 0; i < syllableCount; i++) {
      const delay = i * timePerSyllable
      
      // Open jaw (DOWN)
      const timeoutDown = setTimeout(() => {
        console.log(`Syllable ${i+1}/${syllableCount} DOWN for "${word}"`)
        if (window.mouthAnimationHook) {
          window.mouthAnimationHook.openJaw(word)
          
          // Update graph
          if (window.amplitudeGraphHook) {
            window.amplitudeGraphHook.addEvent('DOWN', word)
          }
        } else {
          console.error('No mouthAnimationHook found!')
        }
      }, delay)
      
      this.animationTimeouts.push(timeoutDown)
      
      // Close jaw (UP) - halfway through syllable
      const timeoutUp = setTimeout(() => {
        console.log(`Syllable ${i+1}/${syllableCount} UP for "${word}"`)
        if (window.mouthAnimationHook) {
          window.mouthAnimationHook.closeJaw()
          
          // Update graph
          if (window.amplitudeGraphHook) {
            window.amplitudeGraphHook.addEvent('UP', word)
          }
        }
      }, delay + (timePerSyllable / 2))
      
      this.animationTimeouts.push(timeoutUp)
    }
  },

  startAmplitudeAnalysis() {
    console.log('Starting amplitude analysis...')
    this.analyzing = true
    this.amplitudeThreshold = 5 // Threshold for detecting sound
    console.log('AudioContext state:', this.audioContext.state)
    console.log('Analyser:', this.analyser)
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
    
    // Log amplitude to console
    console.log('Amplitude:', Math.round(average), 'Threshold:', this.amplitudeThreshold)
    
    // Store in history for graph
    this.amplitudeHistory.push(average)
    if (this.amplitudeHistory.length > this.maxHistoryLength) {
      this.amplitudeHistory.shift()
    }
    
    // Update graph
    if (window.amplitudeGraphHook) {
      window.amplitudeGraphHook.updateGraph(this.amplitudeHistory, average)
    } else {
      console.log('No amplitudeGraphHook found')
    }
    
    // Note: Jaw control is now handled by syllable-based timing, not amplitude
    
    // Continue analysis
    requestAnimationFrame(() => this.analyzeAmplitude())
  },

  stopSpeaking() {
    if (this.speechSynthesis.speaking) {
      this.speechSynthesis.cancel()
    }
    if (this.currentUtterance) {
      this.currentUtterance = null
    }
    
    // Cancel all pending animation timeouts
    if (this.animationTimeouts) {
      console.log(`Cancelling ${this.animationTimeouts.length} pending animations`)
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

// Mouth Animation hook
let MouthAnimation = {
  mounted() {
    console.log('MouthAnimation hook mounted')
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
    
    // Old event handlers removed - now using syllable-based timing
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
    
    console.log(`Jaw ${direction} at ${timestamp}`)
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

// Jaw State Graph hook
let AmplitudeGraph = {
  mounted() {
    console.log('Jaw State Graph hook mounted')
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

// TalkingHead 3D Avatar hook
let TalkingHeadAvatar = {
  async mounted() {
    console.log('TalkingHead hook mounted')
    console.log('Container element:', this.el)

    try {
      // Initialize TalkingHead - Vite handles import.meta.url correctly
      this.head = new TalkingHead(this.el, {
        cameraView: 'head',
        cameraDistance: 0.5,
        cameraY: 0
      })

      console.log('TalkingHead instance created:', this.head)

      // Register globally for TTS integration
      window.talkingHeadAvatar = this

      // Load a default avatar (using Ready Player Me)
      const avatarUrl = 'https://models.readyplayer.me/6746a87836c17aaa1a3d5f03.glb'

      console.log('Loading avatar from:', avatarUrl)

      await this.head.showAvatar({
        url: avatarUrl,
        body: 'F',
        avatarMood: 'neutral',
        lipsyncLang: 'en'
      })

      console.log('TalkingHead avatar loaded successfully!')

    } catch (error) {
      console.error('Failed to initialize TalkingHead:', error)
      console.error('Error stack:', error.stack)
    }
  },

  destroyed() {
    if (this.head) {
      this.head.dispose()
    }
    if (window.talkingHeadAvatar === this) {
      window.talkingHeadAvatar = null
    }
  }
}

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: {AutoResize, SpeechRecognition, TextToSpeech, MouthAnimation, AmplitudeGraph, TalkingHeadAvatar}
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

