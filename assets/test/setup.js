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
