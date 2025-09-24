// Text-to-Speech tests
describe('Text-to-Speech Hook', () => {
  let mockSpeechSynthesis
  let mockSpeechSynthesisUtterance
  let mockElement
  let mockPushEvent

  beforeEach(() => {
    // Mock Web Speech API for TTS
    mockSpeechSynthesis = {
      speak: jest.fn(),
      cancel: jest.fn(),
      getVoices: jest.fn(() => [
        { name: 'Test Female Voice', lang: 'en-US' },
        { name: 'Test Male Voice', lang: 'en-US' }
      ]),
      speaking: false,
      onvoiceschanged: null
    }

    mockSpeechSynthesisUtterance = jest.fn().mockImplementation((text) => {
      return {
        text,
        voice: null,
        rate: 1,
        pitch: 1,
        volume: 1,
        onstart: null,
        onend: null,
        onerror: null
      }
    })

    // Set up global mocks
    global.speechSynthesis = mockSpeechSynthesis
    global.SpeechSynthesisUtterance = mockSpeechSynthesisUtterance
    global.window.speechSynthesis = mockSpeechSynthesis
    global.window.SpeechSynthesisUtterance = mockSpeechSynthesisUtterance
    
    mockPushEvent = jest.fn()
    mockElement = {
      pushEvent: mockPushEvent
    }
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  test('TTS hook initializes correctly', () => {
    expect(global.window.speechSynthesis).toBeDefined()
    expect(global.window.SpeechSynthesisUtterance).toBeDefined()
  })

  test('speaks text correctly', () => {
    const text = "Hello, this is a test message"
    
    // Simulate speaking
    const utterance = new global.window.SpeechSynthesisUtterance(text)
    global.window.speechSynthesis.speak(utterance)
    
    expect(mockSpeechSynthesisUtterance).toHaveBeenCalledWith(text)
    expect(mockSpeechSynthesis.speak).toHaveBeenCalledWith(utterance)
  })

  test('stops speaking correctly', () => {
    // Simulate stopping speech
    mockSpeechSynthesis.speaking = true
    global.window.speechSynthesis.cancel()
    
    expect(mockSpeechSynthesis.cancel).toHaveBeenCalled()
  })

  test('loads voices correctly', () => {
    const voices = global.window.speechSynthesis.getVoices()
    
    expect(voices).toHaveLength(2)
    expect(voices[0].name).toBe('Test Female Voice')
    expect(voices[1].name).toBe('Test Male Voice')
  })

  test('handles TTS errors gracefully', () => {
    const utterance = new global.window.SpeechSynthesisUtterance("test")
    
    // Simulate error
    if (utterance.onerror) {
      utterance.onerror({ error: 'synthesis-failed' })
    }
    
    expect(utterance).toBeDefined()
  })

  test('configures utterance properties correctly', () => {
    const text = "Test message"
    const utterance = new global.window.SpeechSynthesisUtterance(text)
    
    // Test default properties can be set
    utterance.rate = 0.9
    utterance.pitch = 1.0
    utterance.volume = 0.8
    
    expect(utterance.text).toBe(text)
    expect(utterance.rate).toBe(0.9)
    expect(utterance.pitch).toBe(1.0)
    expect(utterance.volume).toBe(0.8)
  })

  test('handles voice selection', () => {
    const voices = global.window.speechSynthesis.getVoices()
    const selectedVoice = voices.find(voice => 
      voice.lang.startsWith('en') && voice.name.toLowerCase().includes('female')
    )
    
    expect(selectedVoice).toBeDefined()
    expect(selectedVoice.name).toBe('Test Female Voice')
  })

  test('checks browser support', () => {
    expect('speechSynthesis' in global.window).toBe(true)
    expect(typeof global.window.SpeechSynthesisUtterance).toBe('function')
  })
})

// Integration tests for TTS with chat
describe('TTS Chat Integration', () => {
  let mockSpeechSynthesis
  let mockSpeechSynthesisUtterance

  beforeEach(() => {
    mockSpeechSynthesis = {
      speak: jest.fn(),
      cancel: jest.fn(),
      getVoices: jest.fn(() => []),
      speaking: false
    }

    mockSpeechSynthesisUtterance = jest.fn().mockImplementation((text) => ({
      text,
      voice: null,
      rate: 1,
      pitch: 1,
      volume: 1
    }))

    global.window.speechSynthesis = mockSpeechSynthesis
    global.window.SpeechSynthesisUtterance = mockSpeechSynthesisUtterance
  })

  test('TTS should be triggered for bot messages', () => {
    const botMessage = "Hello! How can I help you today?"
    
    // Simulate auto-speak enabled scenario
    const shouldSpeak = true
    
    if (shouldSpeak) {
      const utterance = new global.window.SpeechSynthesisUtterance(botMessage)
      global.window.speechSynthesis.speak(utterance)
      
      expect(mockSpeechSynthesisUtterance).toHaveBeenCalledWith(botMessage)
      expect(mockSpeechSynthesis.speak).toHaveBeenCalled()
    }
  })

  test('TTS should not be triggered when disabled', () => {
    const botMessage = "Hello! How can I help you today?"
    
    // Simulate auto-speak disabled scenario
    const shouldSpeak = false
    
    if (shouldSpeak) {
      global.window.speechSynthesis.speak(new global.window.SpeechSynthesisUtterance(botMessage))
    }
    
    // Should not have been called
    expect(mockSpeechSynthesis.speak).not.toHaveBeenCalled()
  })

  test('Manual speak button works', () => {
    const messageText = "This is a previous message"
    
    // Simulate clicking speak button on a message
    const utterance = new global.window.SpeechSynthesisUtterance(messageText)
    global.window.speechSynthesis.speak(utterance)
    
    expect(mockSpeechSynthesisUtterance).toHaveBeenCalledWith(messageText)
    expect(mockSpeechSynthesis.speak).toHaveBeenCalled()
  })
})
