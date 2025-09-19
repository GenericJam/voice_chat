# Speech-to-Text Testing Guide

This document explains how to run the comprehensive tests for the speech-to-text functionality we built.

## 🧪 Test Coverage

### **Backend Tests (Elixir/LiveView)**
Located in `test/chat_web/live/chat_live_speech_test.exs`

**Coverage:**
- ✅ Speech recognition event handlers
- ✅ State management (listening, muted, supported)
- ✅ Auto-submit functionality
- ✅ Mute/unmute flows
- ✅ Error handling and recovery
- ✅ UI state integration
- ✅ Edge cases and error scenarios

### **Frontend Tests (JavaScript)**
Located in `assets/test/speech_recognition.test.js`

**Coverage:**
- ✅ Speech Recognition Hook initialization
- ✅ Web Speech API integration
- ✅ Event handling and LiveView communication
- ✅ Auto-submit timer functionality
- ✅ Mute/unmute state management
- ✅ Error handling scenarios
- ✅ Edge cases and race conditions

## 🚀 Running the Tests

### **Backend Tests**

```bash
# Run all tests
mix test

# Run only speech recognition tests
mix test test/chat_web/live/chat_live_speech_test.exs

# Run with coverage
mix test --cover

# Run specific test group
mix test test/chat_web/live/chat_live_speech_test.exs -t "Speech Recognition - Basic Events"
```

### **Frontend Tests**

```bash
# Install dependencies (first time only)
cd assets && npm install

# Run all JavaScript tests
npm test

# Run tests in watch mode (for development)
npm run test:watch

# Run tests with coverage
npm run test:coverage

# Run specific test file
npm test -- speech_recognition.test.js
```

## 📊 Test Categories

### **1. Basic Speech Recognition Events**
Tests core speech recognition functionality:
- `speech_started` - Sets listening state
- `speech_ended` - Clears listening state  
- `speech_interim` - Updates live transcription
- `speech_final` - Appends to message draft
- `speech_error` - Handles recognition errors
- `speech_not_supported` - Disables features gracefully

### **2. Mute/Unmute Functionality**
Tests privacy controls:
- `speech_muted` - Sets muted state
- `speech_unmuted` - Clears muted state
- `toggle_speech` - Cycles through states
- `stop_speech` - Completely stops recognition

### **3. Auto-Submit System**
Tests automatic message submission:
- `auto_submit_countdown` - Countdown timer updates
- `auto_submit_speech` - Automatic message submission
- Timer cancellation when user types
- Text combination (speech + typed)

### **4. State Integration**
Tests complex workflows:
- Complete speech → transcription → auto-submit flow
- Mute/unmute during active sessions
- Error recovery after permission denial
- State cleanup after message submission

### **5. UI Rendering**
Tests visual elements:
- Microphone button states
- Speech recognition indicators
- Mute/countdown displays
- Error messages and notifications

### **6. Edge Cases**
Tests error scenarios and boundary conditions:
- Rapid button clicking
- Events in wrong order
- Multiple simultaneous sessions
- Very long/empty speech text
- Invalid countdown values
- Browser compatibility issues

## 🔍 Test Commands Reference

### **Run Specific Test Groups**

```bash
# Backend - Basic Events
mix test test/chat_web/live/chat_live_speech_test.exs -t "Speech Recognition - Basic Events"

# Backend - Auto-Submit
mix test test/chat_web/live/chat_live_speech_test.exs -t "Auto-Submit Functionality"

# Backend - State Integration  
mix test test/chat_web/live/chat_live_speech_test.exs -t "Speech State Integration"

# Frontend - Initialization
cd assets && npm test -- --testNamePattern="Initialization"

# Frontend - Control Methods
cd assets && npm test -- --testNamePattern="Control Methods"

# Frontend - Auto-Submit
cd assets && npm test -- --testNamePattern="Auto-Submit"
```

### **Debug Test Issues**

```bash
# Backend - Verbose output
mix test test/chat_web/live/chat_live_speech_test.exs --trace

# Frontend - Debug mode
cd assets && npm test -- --verbose --no-cache

# Check test coverage gaps
mix test --cover
cd assets && npm run test:coverage
```

## 🎯 Test Success Criteria

All tests should pass with:
- ✅ **0 failures** - All functionality works correctly
- ✅ **No crashes** - LiveView processes remain responsive
- ✅ **Proper state management** - Speech states transition correctly
- ✅ **Error resilience** - Graceful handling of edge cases
- ✅ **Integration flows** - Complete workflows work end-to-end

## 🐛 Common Test Issues

### **Backend Issues**
- **Mock failures**: Check that all required mocks are set up
- **State assertions**: Verify assigns are updated correctly
- **Event handling**: Ensure events reach the correct handlers

### **Frontend Issues**
- **Speech API mocking**: Verify Web Speech API mocks are configured
- **Timing tests**: Use `jest.useFakeTimers()` for timer tests
- **Event simulation**: Check that event objects have correct structure

## 📈 Coverage Goals

- **Backend**: >95% line coverage for speech event handlers
- **Frontend**: >90% line coverage for speech recognition hook
- **Integration**: All major user flows tested end-to-end
- **Edge Cases**: All error conditions and boundary values tested

## 🔄 Continuous Integration

Add to your CI pipeline:

```yaml
# .github/workflows/test.yml
- name: Run Elixir Tests
  run: mix test --cover

- name: Run JavaScript Tests  
  run: |
    cd assets
    npm ci
    npm run test:coverage
```

This comprehensive test suite ensures that the speech-to-text functionality is robust, reliable, and ready for production use! 🚀
