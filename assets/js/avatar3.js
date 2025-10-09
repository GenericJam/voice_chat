// Avatar3 - HeadTTS Avatar with Server TTS
// Extracted from inline script for better organization

export const Avatar3Hook = {
  async mounted() {
    console.log('Avatar3Hook mounted');

    // Initialize the avatar
    await this.initializeAvatar();

    // Set up event handlers from LiveView
    this.handleEvent('speak_avatar', async (data) => {
      await this.speakWithServerTTS(data.text);
    });
  },

  async initializeAvatar() {
    // Dynamic import of TalkingHead from CDN
    const { TalkingHead } = await import('https://cdn.jsdelivr.net/gh/met4citizen/TalkingHead@1.5/modules/talkinghead.mjs');

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
    window.avatar3Head = this.head;

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
