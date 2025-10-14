// Avatar - TalkingHead Avatar with Server TTS
// Handles 3D avatar integration with Kokoro TTS

import { TalkingHead } from '@met4citizen/talkinghead'

export const AvatarHook = {
  async mounted() {
    console.log('AvatarHook mounted');

    // Initialize the avatar
    await this.initializeAvatar();

    // Set up event handlers from LiveView
    this.handleEvent('speak_avatar', async (data) => {
      await this.speakWithServerTTS(data.text);
    });

    // Handle audio chunks pushed from server during streaming
    this.handleEvent('audio_chunk_ready', async (data) => {
      console.log('[Avatar] Received audio chunk for text:', data.text);
      console.log('[Avatar] Word timings:', data.words);
      await this.queueAudioChunk(data.audio, data.text, data.words, data.duration_ms);
    });

    // Handle voice changes from LiveView
    this.handleEvent('change_avatar_voice', (data) => {
      const person = this.personEl.options[this.personEl.selectedIndex].value;
      if (this.persons[person]) {
        this.persons[person].voice = data.voice;
        console.log(`Changed ${person} voice to ${data.voice}`);
      }
    });
  },

  async initializeAvatar() {
    // Use the local TalkingHead library

    // Get DOM elements - look in the avatar container (this.el)
    this.avatarEl = this.el.querySelector('#avatar');
    this.infoEl = this.el.querySelector('#info');
    this.subtitlesEl = this.el.querySelector('#subtitles');

    // Person selector is in the header (outside this.el)
    this.personEl = document.querySelector('#person');

    // Avatars configuration
    this.persons = {
      "julia": {
        avatar: {
          url: "/headtts/avatars/julia.glb",
          body: "F",
          avatarMood: "neutral"
        },
        view: {
          cameraY: 0
        },
        voice: "af_bella"
      },
      "david": {
        avatar: {
          url: "/headtts/avatars/david.glb",
          body: "M",
          avatarMood: "neutral"
        },
        view: {
          cameraY: -0.04
        },
        voice: "am_fenrir"
      }
    };

    // Instantiate TalkingHead
    this.head = new TalkingHead(this.avatarEl, {
      ttsEndpoint: "N/A",
      lipsyncModules: ["en"],
      cameraView: "upper",
      mixerGainSpeech: 3,
      cameraRotateEnable: false
    });

    // For debugging
    window.avatarHead = this.head;

    // Load initial person
    await this.loadPerson();

    // Event listener for person change (handled by LiveView now but keep for backup)
    this.personEl.addEventListener("change", () => {
      this.loadPerson();
    });

    // Pause animation when document is not visible
    document.addEventListener("visibilitychange", async () => {
      if (document.visibilityState === "visible") {
        this.head.start();
      } else {
        this.head.stop();
      }
    });
  },

  async loadPerson() {
    const person = this.persons[this.personEl.options[this.personEl.selectedIndex].value];

    const updateInfo = (ev) => {
      if (ev) {
        if (ev.lengthComputable) {
          const pct = Math.min(100, Math.round(ev.loaded / ev.total * 100));
          this.infoEl.textContent = "Loading: " + pct + "%";
        } else {
          this.infoEl.textContent = "Loading: " + Math.round(ev.loaded / 1000) + "KB";
        }
      }
    };

    try {
      this.personEl.disabled = true;
      this.infoEl.style.display = 'block';
      this.infoEl.textContent = "Loading...";

      await this.head.showAvatar(person.avatar, updateInfo);

      this.head.setView(this.head.viewName, person.view);
      this.head.cameraClock = 999;

      this.infoEl.style.display = 'none';
      this.personEl.disabled = false;
    } catch (error) {
      console.log(error);
      this.infoEl.innerHTML = "ERROR:<br>&gt; " + (error.message?.slice() || "Unknown error.").replaceAll("\n", "<br>&gt; ");
    }
  },

  addSubtitle(word, ms = 2000) {
    if (word) {
      this.subtitlesEl.textContent += word;
      this.subtitlesEl.scrollTop = this.subtitlesEl.scrollHeight;
    }

    if (this.timerSubtitles) {
      clearTimeout(this.timerSubtitles);
      this.timerSubtitles = null;
    }
    this.timerSubtitles = setTimeout(() => this.clearSubtitles(), ms);
  },

  clearSubtitles(ms = 0) {
    if (this.timerSubtitles) {
      clearTimeout(this.timerSubtitles);
      this.timerSubtitles = null;
    }
    if (ms > 0) {
      this.timerSubtitles = setTimeout(() => this.clearSubtitles(), ms);
    } else {
      this.subtitlesEl.textContent = "";
    }
  },

  async queueAudioChunk(audioBase64, text, wordTimings, durationMs) {
    try {
      // Decode base64 audio
      const audioData = Uint8Array.from(atob(audioBase64), c => c.charCodeAt(0)).buffer;
      const audioBuffer = await this.head.audioCtx.decodeAudioData(audioData);

      // Use word timings from server
      const words = wordTimings.map(wt => wt.word);
      const wtimes = wordTimings.map(wt => Math.round(wt.start_ms));
      const wdurations = wordTimings.map(wt => Math.round(wt.duration_ms));

      const audioObj = {
        audio: audioBuffer,
        words: words,
        wtimes: wtimes,
        wdurations: wdurations
      };

      // Use the built-in speakAudio - let TalkingHead handle the queueing
      this.head.speakAudio(audioObj, {}, (word) => this.addSubtitle(word + ' '));

      // Schedule progressive word display in dialog panel
      this.scheduleWordDisplay(wordTimings);

      // Update queue timing for next chunk
      this.updateQueueEndTime(durationMs);

      console.log('[Avatar] Chunk queued successfully');

    } catch (error) {
      console.error('[Avatar] Error queueing audio chunk:', error);
      this.infoEl.innerHTML = "ERROR:<br>&gt; " + error.message.replaceAll("\n", "<br>&gt; ");
      this.infoEl.style.display = 'block';
    }
  },

  scheduleWordDisplay(wordTimings) {
    // Get the current playback start time (when this chunk will actually start playing)
    // TalkingHead queues audio, so we need to account for any audio already playing
    const audioContext = this.head.audioCtx;
    const currentTime = audioContext.currentTime;

    // Check if there's audio currently playing in the queue
    const queueDelay = this.calculateQueueDelay();

    wordTimings.forEach((wordTiming) => {
      const displayTime = queueDelay + wordTiming.start_ms;

      setTimeout(() => {
        // Push word to LiveView for display in dialog panel
        this.pushEvent('display_word', { word: wordTiming.word });
      }, displayTime);
    });
  },

  calculateQueueDelay() {
    // Calculate how long until this chunk will start playing
    // This is a simplified version - TalkingHead has internal queue timing
    // For now, we'll track this ourselves
    if (!this.queueEndTime) {
      this.queueEndTime = Date.now();
    }

    const now = Date.now();
    const delay = Math.max(0, this.queueEndTime - now);

    return delay;
  },

  updateQueueEndTime(durationMs) {
    const now = Date.now();
    if (!this.queueEndTime || this.queueEndTime < now) {
      this.queueEndTime = now + durationMs;
    } else {
      this.queueEndTime += durationMs;
    }
    // Add the 300ms break that TalkingHead adds
    this.queueEndTime += 300;
  },

  async speakWithServerTTS(text) {
    const person = this.persons[this.personEl.options[this.personEl.selectedIndex].value];

    try {
      const response = await fetch('/api/tts', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          text: text,
          voice: person.voice,
          speed: 1.0
        })
      });

      if (!response.ok) {
        throw new Error(`Server error: ${response.status}`);
      }

      const data = await response.json();

      const audioData = Uint8Array.from(atob(data.audio), c => c.charCodeAt(0)).buffer;
      const audioBuffer = await this.head.audioCtx.decodeAudioData(audioData);

      const words = text.split(/\s+/);
      const durationMs = audioBuffer.duration * 1000;
      const timePerWordMs = durationMs / words.length;
      const wtimes = words.map((_, i) => Math.round(i * timePerWordMs));
      const wdurations = words.map(() => Math.round(timePerWordMs));

      const audioObj = {
        audio: audioBuffer,
        words: words,
        wtimes: wtimes,
        wdurations: wdurations
      };

      this.clearSubtitles();
      await this.head.speakAudio(audioObj, {}, (word) => this.addSubtitle(word));

    } catch (error) {
      console.error('TTS Error:', error);
      this.infoEl.innerHTML = "TTS ERROR:<br>&gt; " + error.message.replaceAll("\n", "<br>&gt; ");
      this.infoEl.style.display = 'block';
    } finally {
      this.pushEvent('speaking_complete', {});
    }
  },

  destroyed() {
    if (this.head) {
      this.head.stop();
    }
    if (this.timerSubtitles) {
      clearTimeout(this.timerSubtitles);
    }
  }
};
