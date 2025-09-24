// Test setup for Jest
require('@testing-library/jest-dom')

// Mock the Web Speech API since it's not available in Jest/Node
global.SpeechRecognition = jest.fn().mockImplementation(() => ({
  continuous: false,
  interimResults: false,
  lang: 'en-US',
  start: jest.fn(),
  stop: jest.fn(),
  abort: jest.fn(),
  onstart: null,
  onend: null,
  onerror: null,
  onresult: null,
  onspeechstart: null,
  onspeechend: null,
  onnomatch: null,
  onsoundstart: null,
  onsoundend: null,
  onaudiostart: null,
  onaudioend: null
}))

global.webkitSpeechRecognition = global.SpeechRecognition

// Mock the Speech Synthesis API for TTS
global.speechSynthesis = {
  speak: jest.fn(),
  cancel: jest.fn(),
  getVoices: jest.fn(() => [
    { name: 'Test Female Voice', lang: 'en-US' },
    { name: 'Test Male Voice', lang: 'en-US' }
  ]),
  speaking: false,
  onvoiceschanged: null
}

global.SpeechSynthesisUtterance = jest.fn().mockImplementation((text) => ({
  text,
  voice: null,
  rate: 1,
  pitch: 1,
  volume: 1,
  onstart: null,
  onend: null,
  onerror: null
}))

// Mock the LiveView hook interface
global.mockLiveViewHook = () => ({
  pushEvent: jest.fn(),
  handleEvent: jest.fn()
})

// Mock console methods to reduce test noise
global.console = {
  ...console,
  log: jest.fn(),
  error: jest.fn(),
  warn: jest.fn(),
  info: jest.fn()
}
