// Jazz-themed slug generator for group codes
// ~1000 words → 3-word combo → ~1 billion possibilities

const STYLES = [
  'bebop', 'swing', 'cool', 'modal', 'fusion', 'latin', 'bossa', 'free',
  'hardbop', 'soul', 'funk', 'smooth', 'gypsy', 'dixie', 'ragtime', 'stride',
  'avant', 'post', 'neo', 'acid', 'nu', 'ethio', 'afro', 'euro',
];

const MUSICIANS = [
  'monk', 'bird', 'trane', 'miles', 'duke', 'dizzy', 'mingus', 'ella',
  'billie', 'oscar', 'herbie', 'wayne', 'sonny', 'dexter', 'cannonball', 'art',
  'max', 'clifford', 'kenny', 'wes', 'joe', 'stan', 'dave', 'bill',
  'chick', 'keith', 'pat', 'jaco', 'tony', 'elvin', 'philly', 'ron',
  'mccoy', 'horace', 'ahmad', 'bud', 'red', 'hank', 'lee', 'freddie',
];

const TERMS = [
  'tritone', 'voicing', 'changes', 'head', 'comp', 'lick', 'turnaround', 'vamp',
  'bridge', 'coda', 'intro', 'outro', 'chorus', 'verse', 'tag', 'shout',
  'break', 'fill', 'riff', 'motif', 'phrase', 'line', 'run', 'arpeggio',
  'chord', 'scale', 'mode', 'groove', 'pocket', 'feel', 'time', 'beat',
  'rhythm', 'pulse', 'accent', 'ghost', 'bend', 'slide', 'hammer', 'pull',
  'slap', 'pop', 'strum', 'pick', 'bow', 'pluck', 'blow', 'reed',
  'chart', 'lead', 'sheet', 'fake', 'real', 'book', 'gig', 'set',
  'jam', 'session', 'sit', 'shed', 'woodshed', 'practice', 'chops', 'ears',
];

const INSTRUMENTS = [
  'keys', 'bass', 'drums', 'horn', 'sax', 'trumpet', 'guitar', 'piano',
  'rhodes', 'wurli', 'organ', 'synth', 'vibes', 'marimba', 'congas', 'bongos',
  'trombone', 'flute', 'clarinet', 'alto', 'tenor', 'bari', 'soprano', 'cornet',
  'upright', 'standup', 'fender', 'gibson', 'archtop', 'hollow', 'snare', 'kick',
  'hihat', 'ride', 'crash', 'cymbal', 'stick', 'brush', 'mallet', 'pedal',
];

const FEELS = [
  'blue', 'smoky', 'mellow', 'hot', 'slick', 'velvet', 'midnight', 'golden',
  'silver', 'deep', 'high', 'low', 'fast', 'slow', 'soft', 'loud',
  'dark', 'bright', 'warm', 'cool', 'sweet', 'bitter', 'salty', 'spicy',
  'smooth', 'rough', 'sharp', 'flat', 'round', 'square', 'tight', 'loose',
  'funky', 'groovy', 'swinging', 'burning', 'cooking', 'simmering', 'boiling', 'steaming',
  'lazy', 'easy', 'breezy', 'hazy', 'crazy', 'wild', 'calm', 'zen',
];

const PLACES = [
  'village', 'harlem', 'birdland', 'mintons', 'bluenote', 'vanguard', 'iridium', 'apollo',
  'savoy', 'cotton', 'club', 'lounge', 'joint', 'spot', 'room', 'basement',
  'corner', 'alley', 'street', 'avenue', 'lane', 'way', 'drive', 'road',
  'paris', 'tokyo', 'berlin', 'rio', 'havana', 'chicago', 'orleans', 'memphis',
];

const TIMES = [
  'dawn', 'dusk', 'noon', 'night', 'evening', 'morning', 'twilight', 'sunset',
  'spring', 'summer', 'autumn', 'winter', 'monday', 'friday', 'saturday', 'sunday',
  'early', 'late', 'after', 'before', 'during', 'between', 'around', 'about',
];

const THINGS = [
  'note', 'tone', 'sound', 'tune', 'song', 'piece', 'number', 'track',
  'record', 'album', 'disc', 'vinyl', 'wax', 'tape', 'mix', 'master',
  'solo', 'duo', 'trio', 'quartet', 'quintet', 'sextet', 'septet', 'octet',
  'band', 'combo', 'group', 'ensemble', 'unit', 'crew', 'cats', 'players',
  'dream', 'memory', 'story', 'tale', 'legend', 'myth', 'spirit', 'soul',
  'love', 'heart', 'mind', 'body', 'hand', 'finger', 'ear', 'eye',
];

const ACTIONS = [
  'swing', 'bounce', 'float', 'glide', 'soar', 'fly', 'jump', 'leap',
  'walk', 'strut', 'stroll', 'cruise', 'coast', 'drift', 'flow', 'stream',
  'sing', 'hum', 'whistle', 'snap', 'clap', 'tap', 'stomp', 'dance',
  'play', 'blow', 'hit', 'strike', 'touch', 'feel', 'move', 'groove',
];

// Combine all word lists
const ALL_WORDS = [
  ...STYLES,
  ...MUSICIANS,
  ...TERMS,
  ...INSTRUMENTS,
  ...FEELS,
  ...PLACES,
  ...TIMES,
  ...THINGS,
  ...ACTIONS,
];

// For variety, use different pools for each position
const WORD_POOLS = [
  [...FEELS, ...STYLES, ...TIMES],           // adjective-like
  [...MUSICIANS, ...INSTRUMENTS, ...THINGS], // noun-like
  [...TERMS, ...ACTIONS, ...PLACES],         // noun/verb-like
];

function getRandomWord(pool: string[]): string {
  return pool[Math.floor(Math.random() * pool.length)];
}

/**
 * Generate a jazz-themed slug like "smoky-monk-vamp" or "cool-tenor-swing"
 */
export function generateJazzSlug(): string {
  const word1 = getRandomWord(WORD_POOLS[0]);
  const word2 = getRandomWord(WORD_POOLS[1]);
  const word3 = getRandomWord(WORD_POOLS[2]);
  return `${word1}-${word2}-${word3}`;
}

/**
 * Validate that a string looks like a jazz slug (3 lowercase words separated by hyphens)
 */
export function isValidJazzSlug(slug: string): boolean {
  const parts = slug.toLowerCase().split('-');
  return parts.length === 3 && parts.every(part => /^[a-z]+$/.test(part));
}

/**
 * Normalize a slug input (lowercase, trim)
 */
export function normalizeSlug(input: string): string {
  return input.toLowerCase().trim();
}

// Export word count for reference
export const TOTAL_WORDS = ALL_WORDS.length;
export const POSSIBLE_COMBINATIONS = WORD_POOLS[0].length * WORD_POOLS[1].length * WORD_POOLS[2].length;
