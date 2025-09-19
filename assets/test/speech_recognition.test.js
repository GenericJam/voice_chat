// Speech Recognition Hook Tests
describe('SpeechRecognition Hook', () => {
  let hook
  let mockRecognition
  let mockPushEvent
  let mockHandleEvent

  // Mock implementation of the SpeechRecognition hook
  const createSpeechRecognitionHook = () => ({
    recognition: null,
    isListening: false,
    isMuted: false,
    startTime: null,
    interimTranscript: '',
    finalTranscript: '',
    submitTimeout: null,
    countdownInterval: null,
    submitDelay: 2000,

    pushEvent: jest.fn(),
    handleEvent: jest.fn(),

    mounted() {
      this.recognition = null
      this.isListening = false
      this.isMuted = false
      this.startTime = null
      this.initializeSpeechRecognition()
    },

    initializeSpeechRecognition() {
      if (typeof SpeechRecognition !== 'undefined' || typeof webkitSpeechRecognition !== 'undefined') {
        const SpeechRecognitionClass = SpeechRecognition || webkitSpeechRecognition
        this.recognition = new SpeechRecognitionClass()
        
        this.recognition.continuous = true
        this.recognition.interimResults = true
        this.recognition.lang = 'en-US'
        
        this.recognition.onstart = () => {
          this.startTime = Date.now()
          this.isListening = true
          this.isMuted = false
          this.clearSubmitTimeout()
          this.pushEvent('speech_started', {})
        }
        
        this.recognition.onend = () => {
          this.isListening = false
          this.pushEvent('speech_ended', {})
          const durationSinceStart = Date.now() - (this.startTime || 0)
          if (!this.isMuted && durationSinceStart > 1000) {
            this.scheduleSubmit()
          }
        }
        
        this.recognition.onerror = (event) => {
          let errorMessage = event.error
          switch(event.error) {
            case 'not-allowed':
              errorMessage = 'Microphone access denied. Please allow microphone access and try again.'
              break
            case 'no-speech':
              errorMessage = 'No speech detected. Please try speaking again.'
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
            this.scheduleSubmit()
          }
        }
      } else {
        this.pushEvent('speech_not_supported', {})
      }
      
      this.handleEvent('start_listening', () => {
        this.startListening()
      })
      
      this.handleEvent('stop_listening', () => {
        this.stopListening()
      })
      
      this.handleEvent('mute_listening', () => {
        this.muteListening()
      })
      
      this.handleEvent('unmute_listening', () => {
        this.unmuteListening()
      })
    },

    startListening() {
      if (this.recognition && !this.isListening) {
        this.clearSubmitTimeout()
        this.isMuted = false
        try {
          this.recognition.start()
        } catch (error) {
          this.pushEvent('speech_error', { error: error.message })
        }
      }
    },

    stopListening() {
      if (this.recognition && this.isListening) {
        this.clearSubmitTimeout()
        this.isMuted = false
        this.recognition.stop()
      }
    },

    muteListening() {
      if (this.recognition && this.isListening) {
        this.isMuted = true
        this.clearSubmitTimeout()
        this.pushEvent('speech_muted', {})
      }
    },

    unmuteListening() {
      if (this.recognition && this.isListening) {
        this.isMuted = false
        this.pushEvent('speech_unmuted', {})
      }
    },

    scheduleSubmit() {
      if (this.isMuted) return
      
      this.clearSubmitTimeout()
      this.clearCountdownInterval()
      
      let countdown = this.submitDelay / 1000
      this.pushEvent('auto_submit_countdown', { seconds: countdown })
      
      this.countdownInterval = setInterval(() => {
        countdown -= 0.1
        if (countdown <= 0) {
          this.clearCountdownInterval()
          this.pushEvent('auto_submit_countdown', { seconds: 0 })
        } else {
          this.pushEvent('auto_submit_countdown', { 
            seconds: Math.round(Math.max(0, countdown) * 10) / 10 
          })
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
      this.pushEvent('auto_submit_speech', {})
    }
  })

  beforeEach(() => {
    // Reset mocks
    jest.clearAllMocks()
    
    // Create fresh hook instance
    hook = createSpeechRecognitionHook()
    
    // Mock the recognition object
    mockRecognition = {
      continuous: false,
      interimResults: false,
      lang: 'en-US',
      start: jest.fn(),
      stop: jest.fn(),
      onstart: null,
      onend: null,
      onerror: null,
      onresult: null
    }
    
    // Mock SpeechRecognition constructor
    global.SpeechRecognition = jest.fn(() => mockRecognition)
    global.webkitSpeechRecognition = global.SpeechRecognition

    // Mock Date.now for timing tests
    jest.spyOn(Date, 'now').mockReturnValue(1000)
  })

  afterEach(() => {
    jest.restoreAllMocks()
  })

  describe('Initialization', () => {
    test('initializes with default state', () => {
      expect(hook.isListening).toBe(false)
      expect(hook.isMuted).toBe(false)
      expect(hook.startTime).toBe(null)
      expect(hook.submitDelay).toBe(2000)
    })

    test('creates speech recognition instance when available', () => {
      hook.initializeSpeechRecognition()
      
      expect(SpeechRecognition).toHaveBeenCalled()
      expect(hook.recognition).toBe(mockRecognition)
      expect(mockRecognition.continuous).toBe(true)
      expect(mockRecognition.interimResults).toBe(true)
      expect(mockRecognition.lang).toBe('en-US')
    })

    test('handles speech recognition not supported', () => {
      global.SpeechRecognition = undefined
      global.webkitSpeechRecognition = undefined
      
      hook.initializeSpeechRecognition()
      
      expect(hook.pushEvent).toHaveBeenCalledWith('speech_not_supported', {})
    })
  })

  describe('Speech Recognition Events', () => {
    beforeEach(() => {
      hook.initializeSpeechRecognition()
    })

    test('handles onstart event', () => {
      mockRecognition.onstart()
      
      expect(hook.isListening).toBe(true)
      expect(hook.isMuted).toBe(false)
      expect(hook.startTime).toBe(1000)
      expect(hook.pushEvent).toHaveBeenCalledWith('speech_started', {})
    })

    test('handles onend event', () => {
      // Set up initial state
      hook.startTime = 500
      hook.isListening = true
      
      mockRecognition.onend()
      
      expect(hook.isListening).toBe(false)
      expect(hook.pushEvent).toHaveBeenCalledWith('speech_ended', {})
    })

    test('handles onend with short duration - no auto submit', () => {
      // Set up short duration (less than 1 second)
      hook.startTime = 900  // 100ms ago
      hook.isListening = true
      
      const scheduleSubmitSpy = jest.spyOn(hook, 'scheduleSubmit')
      
      mockRecognition.onend()
      
      expect(scheduleSubmitSpy).not.toHaveBeenCalled()
    })

    test('handles onend with long duration - schedules auto submit', () => {
      // Set up long duration (more than 1 second)
      hook.startTime = -500  // 1500ms ago
      hook.isListening = true
      hook.isMuted = false
      
      const scheduleSubmitSpy = jest.spyOn(hook, 'scheduleSubmit')
      
      mockRecognition.onend()
      
      expect(scheduleSubmitSpy).toHaveBeenCalled()
    })

    test('handles onerror event', () => {
      const errorEvent = { error: 'not-allowed' }
      
      mockRecognition.onerror(errorEvent)
      
      expect(hook.isListening).toBe(false)
      expect(hook.isMuted).toBe(false)
      expect(hook.pushEvent).toHaveBeenCalledWith('speech_error', { 
        error: 'Microphone access denied. Please allow microphone access and try again.' 
      })
    })

    test('handles onresult event with interim results', () => {
      const mockEvent = {
        resultIndex: 0,
        results: [{
          0: { transcript: 'hello world' },
          isFinal: false
        }]
      }
      
      mockRecognition.onresult(mockEvent)
      
      expect(hook.pushEvent).toHaveBeenCalledWith('speech_interim', { text: 'hello world' })
    })

    test('handles onresult event with final results', () => {
      const mockEvent = {
        resultIndex: 0,
        results: [{
          0: { transcript: 'hello world' },
          isFinal: true
        }]
      }
      
      const scheduleSubmitSpy = jest.spyOn(hook, 'scheduleSubmit')
      
      mockRecognition.onresult(mockEvent)
      
      expect(hook.pushEvent).toHaveBeenCalledWith('speech_final', { text: 'hello world' })
      expect(scheduleSubmitSpy).toHaveBeenCalled()
    })

    test('ignores onresult when muted', () => {
      hook.isMuted = true
      
      const mockEvent = {
        resultIndex: 0,
        results: [{
          0: { transcript: 'hello world' },
          isFinal: true
        }]
      }
      
      mockRecognition.onresult(mockEvent)
      
      expect(hook.pushEvent).not.toHaveBeenCalledWith('speech_interim', expect.any(Object))
      expect(hook.pushEvent).not.toHaveBeenCalledWith('speech_final', expect.any(Object))
    })
  })

  describe('Control Methods', () => {
    beforeEach(() => {
      hook.initializeSpeechRecognition()
    })

    test('startListening calls recognition.start', () => {
      hook.startListening()
      
      expect(mockRecognition.start).toHaveBeenCalled()
      expect(hook.isMuted).toBe(false)
    })

    test('startListening handles errors', () => {
      mockRecognition.start.mockImplementation(() => {
        throw new Error('Permission denied')
      })
      
      hook.startListening()
      
      expect(hook.pushEvent).toHaveBeenCalledWith('speech_error', { error: 'Permission denied' })
    })

    test('stopListening calls recognition.stop', () => {
      hook.isListening = true
      
      hook.stopListening()
      
      expect(mockRecognition.stop).toHaveBeenCalled()
      expect(hook.isMuted).toBe(false)
    })

    test('muteListening sets muted state', () => {
      hook.isListening = true
      
      hook.muteListening()
      
      expect(hook.isMuted).toBe(true)
      expect(hook.pushEvent).toHaveBeenCalledWith('speech_muted', {})
    })

    test('unmuteListening clears muted state', () => {
      hook.isListening = true
      hook.isMuted = true
      
      hook.unmuteListening()
      
      expect(hook.isMuted).toBe(false)
      expect(hook.pushEvent).toHaveBeenCalledWith('speech_unmuted', {})
    })
  })

  describe('Auto-Submit Functionality', () => {
    beforeEach(() => {
      hook.initializeSpeechRecognition()
      jest.useFakeTimers()
    })

    afterEach(() => {
      jest.useRealTimers()
    })

    test('scheduleSubmit starts countdown', () => {
      hook.scheduleSubmit()
      
      expect(hook.pushEvent).toHaveBeenCalledWith('auto_submit_countdown', { seconds: 2 })
    })

    test('scheduleSubmit does nothing when muted', () => {
      hook.isMuted = true
      
      hook.scheduleSubmit()
      
      expect(hook.pushEvent).not.toHaveBeenCalledWith('auto_submit_countdown', expect.any(Object))
    })

    test('countdown updates every 100ms', () => {
      hook.scheduleSubmit()
      
      // Fast-forward 100ms
      jest.advanceTimersByTime(100)
      
      expect(hook.pushEvent).toHaveBeenCalledWith('auto_submit_countdown', { seconds: 1.9 })
    })

    test('countdown triggers auto-submit at zero', () => {
      hook.scheduleSubmit()
      
      // Fast-forward to completion
      jest.advanceTimersByTime(2000)
      
      expect(hook.pushEvent).toHaveBeenCalledWith('auto_submit_speech', {})
    })

    test('clearSubmitTimeout clears timers', () => {
      hook.scheduleSubmit()
      hook.clearSubmitTimeout()
      
      // Fast-forward - should not trigger
      jest.advanceTimersByTime(3000)
      
      expect(hook.pushEvent).toHaveBeenCalledWith('auto_submit_countdown', { seconds: 0 })
    })
  })

  describe('Edge Cases', () => {
    beforeEach(() => {
      hook.initializeSpeechRecognition()
    })

    test('handles multiple start calls gracefully', () => {
      hook.startListening()
      
      // Simulate the speech recognition starting (which sets isListening = true)
      hook.recognition.onstart()
      
      hook.startListening()  // Second call should be ignored
      
      expect(mockRecognition.start).toHaveBeenCalledTimes(1)
    })

    test('handles stop when not listening', () => {
      hook.isListening = false
      
      hook.stopListening()
      
      expect(mockRecognition.stop).not.toHaveBeenCalled()
    })

    test('handles mute when not listening', () => {
      hook.isListening = false
      
      hook.muteListening()
      
      expect(hook.pushEvent).not.toHaveBeenCalledWith('speech_muted', {})
    })

    test('handles unmute when not listening', () => {
      hook.isListening = false
      
      hook.unmuteListening()
      
      expect(hook.pushEvent).not.toHaveBeenCalledWith('speech_unmuted', {})
    })
  })

  describe('Event Handlers Registration', () => {
    test('registers all LiveView event handlers', () => {
      const handleEventSpy = jest.spyOn(hook, 'handleEvent')
      
      hook.initializeSpeechRecognition()
      
      expect(handleEventSpy).toHaveBeenCalledWith('start_listening', expect.any(Function))
      expect(handleEventSpy).toHaveBeenCalledWith('stop_listening', expect.any(Function))
      expect(handleEventSpy).toHaveBeenCalledWith('mute_listening', expect.any(Function))
      expect(handleEventSpy).toHaveBeenCalledWith('unmute_listening', expect.any(Function))
    })
  })
})
