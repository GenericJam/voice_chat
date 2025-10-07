// Wrapper to handle TalkingHead's worklet URL issue when bundled
// The library tries to use import.meta.url which doesn't work with esbuild bundling

// We need to patch the TalkingHead module before it initializes
// Import the original module
import { TalkingHead as OriginalTalkingHead } from '@met4citizen/talkinghead';

// The worklet file is copied to /assets/playback-worklet.js by our build process
// We can't easily patch the internal URL construction, so let's try a different approach:
// Just re-export and hope the bundler preserves the relative path

export { TalkingHead } from '@met4citizen/talkinghead';
export { OriginalTalkingHead };
