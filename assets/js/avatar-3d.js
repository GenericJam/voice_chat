// TalkingHead 3D Avatar
// Integration with @met4citizen/talkinghead library

import { TalkingHead } from '@met4citizen/talkinghead'

export const TalkingHeadAvatar = {
  async mounted() {
    console.log('[Avatar] TalkingHead hook mounted')
    console.log('[Avatar] Container element:', this.el)

    // Register simple audio test event handler
    console.log('[Avatar] Registering play_audio_only event handler...')
    this.handleEvent('play_audio_only', async (payload) => {
      console.log('[Avatar] ===== PLAY_AUDIO_ONLY EVENT RECEIVED =====')
      console.log('[Avatar] Audio data length:', payload.audioData?.length || 0)

      try {
        // Decode base64 audio data
        const audioData = atob(payload.audioData)
        const audioArray = new Uint8Array(audioData.length)
        for (let i = 0; i < audioData.length; i++) {
          audioArray[i] = audioData.charCodeAt(i)
        }

        // Create a Blob and URL
        const audioBlob = new Blob([audioArray], { type: 'audio/wav' })
        const audioUrl = URL.createObjectURL(audioBlob)

        console.log('[Avatar] Created audio URL:', audioUrl)

        // Create an Audio element and play it
        const audio = new Audio(audioUrl)

        audio.onloadedmetadata = () => {
          console.log('[Avatar] Audio loaded, duration:', audio.duration)
        }

        audio.onplay = () => {
          console.log('[Avatar] Audio started playing')
          this.pushEvent('tts_started', {})
        }

        audio.onended = () => {
          console.log('[Avatar] Audio finished playing')
          URL.revokeObjectURL(audioUrl)
          this.pushEvent('tts_ended', {})
        }

        audio.onerror = (e) => {
          console.error('[Avatar] Audio error:', e)
          console.error('[Avatar] Audio error code:', audio.error?.code)
          console.error('[Avatar] Audio error message:', audio.error?.message)
          URL.revokeObjectURL(audioUrl)
          this.pushEvent('tts_error', { error: `Audio error: ${audio.error?.message || 'Unknown'}` })
        }

        await audio.play()
        console.log('[Avatar] Audio play() called')

      } catch (error) {
        console.error('[Avatar] Error in play_audio_only:', error)
        this.pushEvent('tts_error', { error: error.message })
      }
    })

    // Register event handler for TTS with manual fetch and speakAudio
    console.log('[Avatar] Registering speak_with_tts_manual event handler...')
    this.handleEvent('speak_with_tts_manual', async (payload) => {
      console.log('[Avatar] ===== SPEAK_WITH_TTS_MANUAL EVENT RECEIVED =====')
      console.log('[Avatar] Text:', payload.text)

      try {
        // Notify server that TTS started
        this.pushEvent('tts_started', {})

        // Manually fetch from TTS endpoint
        console.log('[Avatar] Fetching TTS from /api/tts')
        const response = await fetch('/api/tts', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            input: { text: payload.text }
          })
        })

        const data = await response.json()
        console.log('[Avatar] TTS response received, audioContent length:', data.audioContent?.length)

        // Decode base64 audio - the audio is WAV format from Kokoro TTS
        const audioData = atob(data.audioContent)
        const audioArray = new Uint8Array(audioData.length)
        for (let i = 0; i < audioData.length; i++) {
          audioArray[i] = audioData.charCodeAt(i)
        }

        console.log('[Avatar] Audio decoded, size:', audioArray.length)
        console.log('[Avatar] audioCtx state:', this.head.audioCtx?.state)

        // Resume audio context if it's suspended (browser autoplay policy)
        if (this.head.audioCtx && this.head.audioCtx.state === 'suspended') {
          console.log('[Avatar] Resuming suspended AudioContext...')
          await this.head.audioCtx.resume()
          console.log('[Avatar] AudioContext resumed')
        }

        // Decode the audio using Web Audio API first
        console.log('[Avatar] Decoding audio buffer...')
        const audioBuffer = await this.head.audioCtx.decodeAudioData(audioArray.buffer)
        console.log('[Avatar] Audio buffer decoded:', audioBuffer.duration, 'seconds,', audioBuffer.numberOfChannels, 'channels')

        // speakAudio expects an object with audio, words, wtimes, wdurations
        // For basic playback, we can provide minimal word timing
        const durationMs = audioBuffer.duration * 1000
        console.log('[Avatar] Creating speakAudio object with audio and basic timing')

        // Provide fake but reasonable word timings
        // Split text into words and distribute evenly across duration
        const words = payload.text.split(/\s+/)
        const avgWordDuration = durationMs / words.length
        const wtimes = words.map((_, i) => i * avgWordDuration)
        const wdurations = words.map(() => avgWordDuration)

        const audioObj = {
          audio: audioBuffer,
          words: words,
          wtimes: wtimes,
          wdurations: wdurations,
          lipsyncLang: 'en',
          type: 'audio'
        }

        console.log('[Avatar] Audio object:', {
          duration: durationMs,
          wordCount: words.length,
          avgWordDuration: avgWordDuration,
          words: words.join(' ')
        })
        console.log('[Avatar] Avatar visible before speak:', !!this.head.avatar)
        console.log('[Avatar] Calling speakAudio with proper object format')

        try {
          await this.head.speakAudio(audioObj, {}, () => { console.log('[Avatar] onSubtitles callback invoked') })
          console.log('[Avatar] speakAudio completed successfully')
          console.log('[Avatar] Avatar visible after speak:', !!this.head.avatar)
          console.log('[Avatar] isSpeaking after call:', this.head.isSpeaking)
        } catch (speakError) {
          console.error('[Avatar] speakAudio error:', speakError)
          console.error('[Avatar] Error details:', speakError.message, speakError.stack)
          throw speakError
        }

        // Wait for speech to finish
        console.log('[Avatar] Waiting for speech to complete...')
        await new Promise(resolve => setTimeout(resolve, durationMs + 100))
        console.log('[Avatar] Speech should be complete')
        this.pushEvent('tts_ended', {})

      } catch (error) {
        console.error('[Avatar] ===== ERROR IN SPEAK_WITH_TTS_MANUAL =====')
        console.error('[Avatar] Error:', error)
        console.error('[Avatar] Error message:', error.message)
        console.error('[Avatar] Error stack:', error.stack)
        this.pushEvent('tts_error', { error: error.message })
      }
    })
    console.log('[Avatar] Event handler registered')

    try {
      console.log('[Avatar] Creating TalkingHead instance...')

      // Initialize TalkingHead - Vite handles import.meta.url correctly
      // Don't provide audioContext in constructor - let TalkingHead create it
      this.head = new TalkingHead(this.el, {
        cameraView: 'head',
        cameraDistance: 0.5,
        cameraY: 0,
        lipsyncModules: ["en"],  // Only load English lipsync module
        ttsEndpoint: "/api/tts"  // Kokoro TTS endpoint
      })

      console.log('[Avatar] TalkingHead created')

      console.log('[Avatar] TalkingHead instance created:', this.head)
      console.log('[Avatar] TalkingHead methods:', Object.keys(this.head))

      // Register globally for TTS integration
      window.talkingHeadAvatar = this
      console.log('[Avatar] Registered as window.talkingHeadAvatar')

      // Initialize audio graph first
      console.log('[Avatar] Initializing audio graph...')
      await this.head.initAudioGraph()
      console.log('[Avatar] Audio graph initialized')

      // Load a default avatar (using TalkingHead demo avatar)
      const avatarUrl = 'assets/maria.glb'

      console.log('[Avatar] Loading avatar from:', avatarUrl)

      await this.head.showAvatar({
        url: avatarUrl,
        body: 'F',
        avatarMood: 'neutral',
        lipsyncLang: 'en'
      })

      console.log('[Avatar] showAvatar() completed')

      // Manually attach the canvas to the DOM (TalkingHead doesn't do this automatically)
      const canvas = this.head.renderer?.domElement
      console.log('[Avatar] Canvas element:', canvas)
      console.log('[Avatar] Canvas parent:', canvas?.parentElement)
      console.log('[Avatar] Canvas in DOM:', document.contains(canvas))

      // Force attach canvas to our container element
      if (canvas) {
        // Remove from any existing parent first
        if (canvas.parentElement) {
          canvas.parentElement.removeChild(canvas)
        }
        this.el.appendChild(canvas)
        console.log('[Avatar] Canvas attached to container')
        console.log('[Avatar] Canvas now in DOM:', document.contains(canvas))
      }

      console.log('[Avatar] TalkingHead avatar loaded successfully!')
      console.log('[Avatar] Avatar visible:', this.head.avatar !== null)

      // Start animation loop for continuous rendering
      // console.log('[Avatar] Starting animation loop...')
      // const animate = () => {
      //   this.animationFrameId = requestAnimationFrame(animate)
      //   if (this.head && this.head.avatar) {
      //     this.head.render()
      //   }
      // }
      // animate()
      // console.log('[Avatar] Animation loop started')

      // Try to initialize the audio system by checking available methods
      console.log('[Avatar] Checking audio-related properties:')
      console.log('[Avatar] - audioContext:', this.head.audioContext)
      console.log('[Avatar] - mixer:', this.head.mixer)
      console.log('[Avatar] - speakAudio:', typeof this.head.speakAudio)
      console.log('[Avatar] - speakText:', typeof this.head.speakText)

      // Try to initialize audio nodes if there's a method for it
      if (typeof this.head.initAudio === 'function') {
        console.log('[Avatar] Found initAudio method, calling it...')
        await this.head.initAudio()
      } else {
        console.log('[Avatar] No initAudio method found')
      }

      console.log('[Avatar] After potential audio init:')
      console.log('[Avatar] - audioContext:', !!this.head.audioContext)
      console.log('[Avatar] - mixer:', !!this.head.mixer)

    } catch (error) {
      console.error('[Avatar] Failed to initialize TalkingHead:', error)
      console.error('[Avatar] Error stack:', error.stack)
    }
  },

  destroyed() {
    console.log('[Avatar] TalkingHead hook destroyed')

    // Stop animation loop
    if (this.animationFrameId) {
      console.log('[Avatar] Stopping animation loop...')
      cancelAnimationFrame(this.animationFrameId)
      this.animationFrameId = null
    }

    if (this.head) {
      console.log('[Avatar] Disposing TalkingHead...')
      this.head.dispose()
    }
    if (window.talkingHeadAvatar === this) {
      console.log('[Avatar] Clearing window.talkingHeadAvatar')
      window.talkingHeadAvatar = null
    }
  }
}



// import { TalkingHead } from "talkinghead";
// import { HeadTTS } from "headtts";

// // Globals
// let head; // TalkingHead instance
// let headtts; // HeadTTS instance
// const el = {}; // DOM elements based in `id` property

// // Avatars
// const persons = {

//   "julia": {
//     avatar: {
//       url: "./avatars/julia.glb",
//       body: "F",
//       avatarMood: "love"
//     },
//     view: {
//       cameraY: 0
//     },
//     setup: {
//       voice: "af_bella",
//       language: "en-us",
//       speed: 1,
//       audioEncoding: "wav"
//     }
//   },

//   "david": {
//     avatar: {
//       url: "./avatars/david.glb",
//       body: "M",
//       avatarMood: "neutral"
//     },
//     view: {
//       cameraY: -0.04 // David is taller, so compensate
//     },
//     setup: {
//       voice: "am_fenrir",
//       language: "en-us",
//       speed: 1,
//       audioEncoding: "wav"
//     }
//   }
// };

// /**
// * Load the currently selected avatar and voice.
// */
// async function loadPerson() {

//   // Selected person
//   const person = persons[el.person.options[el.person.selectedIndex].value];

//   // Progress info
//   const info = { head: "-", headtts:"-" };
//   const updateInfo = (name,ev) => {
//     if ( ev ) {
//       if ( ev.lengthComputable ) {
//         info[name] = Math.min(100,Math.round(ev.loaded/ev.total * 100 )) + "%";
//       } else {
//         info[name] = Math.round(ev.loaded / 1000) + "KB";
//       }
//     }
//     let s = "Loading: " + info.head + " / " + info.headtts;
//     if ( info.hasOwnProperty("error") ) {
//       s += " ERROR:<br>&gt; " + info.error.replaceAll("\n","<br>&gt; ");
//     }
//     el.info.innerHTML = s;
//   }

//   // Load and show the avatar
//   try {
//     el.speak.disabled = true;
//     el.person.disabled = true;
//     el.info.style.display = 'block';
//     el.info.textContent = "Loading...";

//     await Promise.all([
//       head.showAvatar( person.avatar, updateInfo.bind(null,"head") ),
//       headtts.connect( null, updateInfo.bind(null,"headtts"))
//     ]);

//     // Setup view
//     head.setView(head.viewName, person.view );
//     head.cameraClock = 999; // Hack to prevent smooth transition

//     // Setup voice
//     headtts.setup( person.setup );

//     el.info.style.display = 'none';
//     el.person.disabled = false;
//     el.speak.disabled = false;
//   } catch (error) {
//     console.log(error);
//     info.error = error.message?.slice() || "Unknown error.";
//     updateInfo();
//   }

// }

// // SUBTITLES
// let timerSubtitles; // Subtitles clear timer

// /**
// * Add the given word to subtitles and reset the clear timer.
// * Play hand gestures for pre-defined keywords.
// *
// * @param {Object} msg HeadTTS response message
// * @param {string} word Word that is been currently spoken
// * @param {number} [ms=2000] Timeout for clearing subtitles, in milliseconds
// */
// function addSubtitle(msg, word, ms=2000) {

//   // Add the word and scroll to bottom
//   if ( word ) {
//     el.subtitles.textContent += word;
//     el.subtitles.scrollTop = el.subtitles.scrollHeight;
//   }

//   // Timeout to clear subtitles
//   if ( timerSubtitles ) {
//     clearTimeout(timerSubtitles);
//     timerSubtitles = null;
//   }
//   timerSubtitles = setTimeout( clearSubtitles, ms );
// }


// /**
// * Clear subtitles.
// *
// * @param {number} [ms=0] Timeout for clearing subtitles, in milliseconds
// */
// function clearSubtitles(ms=0) {

//   if ( timerSubtitles ) {
//     clearTimeout(timerSubtitles);
//     timerSubtitles = null;
//   }
//   if ( ms > 0 ) {
//     timerSubtitles = setTimeout( clearSubtitles, ms );
//   } else {
//     el.subtitles.textContent = "";
//   }

// }

// // WEB PAGE LOADED
// document.addEventListener('DOMContentLoaded', async function(e) {

//   // Get all DOM elements with an `id`
//   document.querySelectorAll('[id]').forEach( x => el[x.id] = x );

//   // Instantiate the TalkingHead class
//   head = new TalkingHead( el.avatar, {
//     ttsEndpoint: "N/A",
//     lipsyncModules: [],
//     cameraView: "upper",
//     mixerGainSpeech: 3,
//     cameraRotateEnable: false
//   });

//   // Instantiate HeadTTS text-to-speech class
//   headtts = new HeadTTS({
//     endpoints: ["webgpu", "ws://127.0.0.1:8882/", "wasm"], // Endpoints
//     languages: ["en-us"], // Language to be pre-loaded
//     voices: ["af_bella","am_fenrir"], // Voices to be pre-loaded
//     voiceURL: "../voices", // Use local voice files
//     audioCtx: head.audioCtx, // Share audio context with TalkingHead
//     trace: 0,
//   });

//   // For debugging
//   window.head = head;
//   window.headtts = headtts;

//   // Speak and lipsync
//   headtts.onmessage = (message) => {
//     if ( message.type === "audio" ) {
//       try {
//         head.speakMarker( clearSubtitles );
//         head.speakAudio( message.data, {}, addSubtitle.bind(null,message) );
//       } catch(error) {
//         console.log(error);
//       }
//     } else if ( message.type === "custom" ) {
//       console.error("Received custom message, data=", message.data );
//     } else if ( message.type === "error" ) {
//       console.error("Received error message, error=", (message.data?.error || "Unknown error."));
//     }
//   }

//   // Load the currently chosen person
//   await loadPerson();

//   // Change the avatar
//   el.person.addEventListener("change", (event) => {
//     loadPerson();
//   });

//   // Speak when clicked
//   el.speak.addEventListener('click', async function () {
//     let text = document.getElementById('text').value;
//     if ( text ) {
//       headtts.synthesize({
//         input: text
//       });
//     }
//   });

//   // Pause animation when document is not visible
//   document.addEventListener("visibilitychange", async function (ev) {
//     if (document.visibilityState === "visible") {
//       head.start();
//     } else {
//       head.stop();
//     }
//   });

// });

