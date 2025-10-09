import { LanguageBase } from "./language.mjs"
import * as utils from "./utils.mjs";

/**
* @class Finnish language module
* @author Mika Suominen
*/

class Language extends LanguageBase {

  /**
  * @constructor
  */
  constructor( settings = null ) {
    super(settings);


    // Add finnish letters with diaritics (upper case)
    // NOTE: Diacritics will be removed unless added to this object.
    this.normalizedLettersUpper = {
      'A': 'A', 'B': 'B', 'C': 'C', 'D': 'D', 'E': 'E', 'F': 'F', 'G': 'G',
      'H': 'H', 'I': 'I', 'J': 'J', 'K': 'K', 'L': 'L', 'M': 'M', 'N': 'N',
      'O': 'O', 'P': 'P', 'Q': 'Q', 'R': 'R', 'S': 'S', 'T': 'T', 'U': 'U',
      'V': 'V', 'W': 'W', 'X': 'X', 'Y': 'Y', 'Z': 'Z', 'ß': 'SS', 'Ø': 'O',
      'Æ': 'AE', 'Œ': 'OE', 'Ð': 'D', 'Þ': 'TH', 'Ł': 'L', "Ä": "Ä",
      "Ö": "Ö", "Å": "Å"
    };

    // Finnish vowels
    this.fiVowels = {
      'A': 'A', 'E': 'E', 'I': 'I', 'O': 'O', 'U': 'U', 'Y': 'Y',
      "Ä": "Ä", "Ö": "Ö", "Å": "Å"
    };

    // Finnish consonants
    this.fiConsonants = {
      'B': 'B', 'C': 'C', 'D': 'D', 'F': 'F', 'G': 'G', 'H': 'H', 'J': 'J',
      'K': 'K', 'L': 'L', 'M': 'M', 'N': 'N', 'P': 'P', 'Q': 'Q', 'R': 'R',
      'S': 'S', 'T': 'T', 'V': 'V', 'W': 'W', 'X': 'X', 'Z': 'Z'
    };

    // Diphthongs in the first syllable that we do not hyphenate
    this.fiDiphthongFirst = {
      "AI": "AI", "EI": "EI", "OI": "OI", "YI": "YI", "ÄI": "ÄI", "ÖI": "ÖI",
      "EY": "EY", "IY": "IY", "ÄY": "ÄY", "ÖY": "ÖY", "AU": "AU", "EU": "EU",
      "IU": "IU", "OU": "OU", "IE": "IE", "UO": "UO", "YÖ": "YÖ"
    };

    // Diphthongs after the first syllable that we do not hyphenate
    this.fiDiphthongEnd = {
      "AI": "AI", "EI": "EI", "OI": "OI", "YI": "YI", "ÄI": "ÄI", "ÖI": "ÖI",
      "EY": "EY", "IY": "IY", "ÄY": "ÄY", "ÖY": "ÖY", "AU": "AU", "EU": "EU",
      "IU": "IU", "OU": "OU", "UO": "UO", "YÖ": "YÖ"
    };

    // Pronounciation rules for Finnish
    this.rules = {
      'A': [ "AUSTR[A]=ɑ ː", "A[A]=ː", "[A]=ɑ" ],
      'B': [ "B[B]=ː", "[B]=b" ],
      'C': [
        "[CITY]=s i t i", "C[C]=ː", "[C]I=s", "[C]E=s",
        "[C]Y=s", "[C]=k"
      ],
      'D': [ "D[D]=ː", "[D]=d" ],
      'E': [ "E[E]=ː", "[E]=e" ],
      'F': [ "[F]=f" ],
      'G': [ "G[G]=ː", "[G]=ɡ" ],
      'H': [ "[H]=h" ],
      'I': [ "I[I]=ː", "[I]=i" ],
      'J': [ "[J]=j" ],
      'K': [ "#LLE[K]#=kː", "#NNE[K]#=kː", "K[K]=ː", "[K]=k" ],
      'L': [ "[L]=l" ],
      'M': [ "SYDÄ[M]=m ː", "[M]=m" ],
      'N': [ "[NG]=ŋ ː", "[N]P=m", "[N]=n" ],
      'O': [ "SYMB[O]LOI=o", "SYMB[O]L=o ː", "O[O]=ː", "[O]=o" ],
      'P': [
        " SHAM[P]O=p ː", " KAM[P]ANJ=p ː", " OTA[P]#=p ː",
        " OLE[P]#=p ː", " TULE[P]#=p ː", "P[P]=ː", "[P]=p"
      ],
      'Q': [ "Q[Q]=ː", "[Q]=q" ],
      'R': [ "[RUO]AN=r u ː", "[R]=r" ],
      'S': [ "[S]=s" ],
      'T': [ "T[T]=ː", "[T]=t" ],
      'U': [ "U[U]=ː", "[U]=u" ],
      'V': [ "[V]=ʋ" ],
      'W': [ "[W]=ʋ" ],
      'X': [ "X[X]=ː s", "[X]=k s" ],
      'Y': [ "Y[Y]=ː", "[Y]=y" ],
      'Z': [ "[Z]=t s" ],
      'Å': [ "Å[Å]=ː", "[Å]=o" ],
      'Ä': [ "Ä[Ä]=ː", "[Ä]=æ" ],
      'Ö': [ "Ö[Ö]=ː", "[Ö]=ø" ]
    };
  
    const ops = {
        '#': '[AEIOUYÄÖÅ]+', // One or more vowels AEIOUYÄÖÅ
        ' ': '\\b' // Start/end of the word
    };

    const IPAToMisaki = {
      "ɚ": ["ɜ","ɹ"], "ˈɝ": ["ˈɜ","ɹ"], "ˌɝ": ["ˌɜ","ɹ"],
      "tʃ": ["ʧ"], "dʒ": ["ʤ"],
      "eɪ": ["A"], "ˈeɪ": ["ˈA"], "ˌeɪ": ["ˌA"],
      "aɪ": ["I"], "ˈaɪ": ["ˈI"], "ˌaɪ": ["ˌI"],
      "aʊ": ["W"], "ˈaʊ": ["ˈW"], "ˌaʊ": ["ˌW"],
      "ɔɪ": ["Y"], "ˈɔɪ": ["ˈY"], "ˌɔɪ": ["ˌY"],
      "oʊ": ["O"], "ˈoʊ": ["ˈO"], "ˌoʊ": ["ˌO"],
      "əʊ": ["Q"], "əʊ": ["ˈQ"], "əʊ": ["ˌQ"]
    };

    // Convert rules to regex
    Object.keys(this.rules).forEach( key =>  {
      this.rules[key] = this.rules[key].map( rule =>  {
        const posL = rule.indexOf('[');
        const posR = rule.indexOf(']');
        const posE = rule.indexOf('=');
        const strLeft = rule.substring(0,posL);
        const strLetters = rule.substring(posL+1,posR);
        const strRight = rule.substring(posR+1,posE);
        const strPhonemes = rule.substring(posE+1);

        const o = { regex: '', move: 0, phonemes: [] };

        let exp = '';
        exp += [...strLeft].map( x => ops[x] || x ).join('');
        const ctxLetters = [...strLetters];
        ctxLetters[0] = ctxLetters[0].toLowerCase();
        exp += ctxLetters.join('');
        o.move = ctxLetters.length;
        exp += [...strRight].map( x => ops[x] || x ).join('');
        o.regex = new RegExp(exp);

        if ( strPhonemes.length ) {
          strPhonemes.split(' ').forEach( ph =>  {
            if ( IPAToMisaki.hasOwnProperty(ph) ) {
              o.phonemes.push( ...IPAToMisaki[ph] );
            } else {
              o.phonemes.push( ph );
            }
          });
        }

        return o;
      });
    });

    // Characters to Finnish words
    this.charactersToWords = {
      '!':	"HUUTOMERKKI", '"': "LAINAUSMERKKI", '#': "RISUAITA", '%': "PROSENTTI",
      '&': "ET-MERKKI", "'": "HIPSUKKA", '(': "SULKU AUKI",
      ')': "SULKU KIINNI", '+': "PLUS", '-': 'VÄLIVIIVA', '—': 'VÄLIVIIVA', ',': "PILKKU",
      '.': "PISTE", '/': "KAUTTAVIIVA", ':': "KAKSOISPISTE", ';': "PUOLIPISTE", '?': "KYSYMYSMERKKI",
      'A': "AA", 'B': "BEE", 'C': "CEE", 'D': "DEE", 'E': "EE", 'F': "ÄF",
      'G': "GEE", 'H': "HOO", 'I': "II", 'J': "JII", 'K': "KOO", 'L': "ÄL",
      'M': "ÄM", 'N': "ÄN", 'O': "OO", 'P': "PEE", 'Q': "KUU", 'R': "ÄR",
      'S': "ÄS", 'T': "TEE", 'U': "UU", 'V': "VEE", 'W': "KAKSOISVEE",
      'X': "ÄKS", 'Y': "YY", 'Z': "TSET", '1': "YKSI", '2': "KAKSI", '3': "KOLME",
      '4': "NELJÄ", '5': "VIISI", '6': "KUUSI", '7': "SEITSEMÄN", '8': "KAHDEKSAN",
      '9': "YHDEKSÄN", '0': "NOLLAO", '{': "AALTOSULKU AUKI", '}': "AALTOSULKU KIINNI",
      '$': "DOLLARI", '€': "EURO"
    };

    // Finnish number words
    this.numbers = [
      'NOLLA', 'YKSI', 'KAKSI', 'KOLME', 'NELJÄ', 'VIISI', 'KUUSI',
      'SEITSEMÄN', 'KAHDEKSAN', 'YHDEKSÄN', "KYMMENEN", "YKSITOISTA",
      "KAKSITOISTA", "KOLMETOISTA", "NELJÄTOISTA", "VIISITOISTA",
      "KUUSITOISTA", 'SEITSEMÄNTOISTA', 'KAHDEKSANTOISTA', 'YHDEKSÄNTOISTA'
    ];

    // Date & Time
    this.days = [
      "", "ENSIMMÄINEN", "TOINEN", "KOLMAS", "NELJÄS", "VIIDES", "KUUDES",
      "SEITSEMÄS", "KAHDEKSAS", "YHDEKSÄS", "KYMMENES", "YHDESTOISTA",
      "KAHDESTOISTA", "KOLMASTOISTA", "NELJÄSTOISTA", "VIIDESTOISTA",
      "KUUDESTOISTA", "SEITSEMÄSTOISTA", "KAHDEKSASTOISTA", "YHDEKSÄSTOISTA",
      "KAHDESKYMMENES", "KAHDESKYMMENES-ENSIMMÄINEN", "KAHDESKYMMENES-TOINEN",
      "KAHDESKYMMENES-KOLMAS", "KAHDESKYMMENES-NELJÄS", "KAHDESKYMMENES-VIIDES",
      "KAHDESKYMMENES-KUUDES", "KAHDESKYMMENES-SEITSEMÄS", "KAHDESKYMMENES-KAHDEKSAS",
      "KAHDESKYMMENES-YHDEKSÄS", "KOLMASKYMMENES", "KOLMASKYMMENES-ENSIMMÄINEN"
    ];
    this.months = [
      "", "TAMMIKUUTA", "HELMIKUUTA", "MAALISKUUTA", "HUHTIKUUTA", "TOUKOKUUTA", "KESÄKUUTA", "HEINÄKUUTA",
      "ELOKUUTA", "SYYSKUUTA", "LOKAKUUTA", "MARRASKUUTA", "JOULUKUUTA"
    ];
    
    // Symbols to Finnish
    // TODO: Implement these
    this.symbols = {
      '%': 'PROSENTTIA', '€': 'EUROA', '&': 'JA', '+': 'PLUS',
      '$': 'DOLLARIA'
    };

    this.symbolsReg = /[%€&\+\$]/g;

    if ( this.settings.trace ) {
      utils.trace( 'Language module "fi" initiated.' );
    }

  }

  /**
  * Add one dictionary line. For Finnish, it is a dictionary
  * of compound words.
  * NOTE: We only add three characters for the last part as
  * we need only partial match.
  *
  * @param {string} s Line
  */
  addToDictionary(s) {
    if ( s.startsWith(";;;") ) return; // Ignore comment line
    const parts = s.split("\t");
    const len = parts.length;
    if ( len >= 2 ) {
      const first = parts[0];
      if ( !this.dictionary.hasOwnProperty(parts[0]) ) {
        this.dictionary[first] = {};
      }
      for( let i=1; i<len; i++ ) {
        const second = parts[i];
        this.dictionary[first][second] = null;
      }
    }
  }  

  /**
  * Convert number to words.
  *
  * @param {number|string} num Number
  * @return {string} String
  */
  convertNumberToWords(num) {
    const w = [];
    let n = parseFloat(num);
    if ( n === undefined ) return num;
    let p = (n,z,w0,w1,w2) => {
      if ( n < z ) return n;
      const d = Math.floor(n/z);
      w.push( w0 + ((d === 1) ? w1 : this.convertNumberToWords(d.toString()) + w2) );
      return n - d * z;
    }
    if ( n < 0 ) {
      w.push('MIINUS ');
      n = Math.abs(n);
    }
    n = p(n,1000000000,' ','MILJARDI',' MILJARDIA');
    n = p(n,1000000,' ','MILJOONA',' MILJOONAA');
    n = p(n,1000,'', 'TUHAT','TUHATTA');
    n = p(n,100,'','SATA','SATAA');
    if ( n > 20 ) n = p(n,10,'','','KYMMENTÄ');
    if ( n >= 1) {
      let d = Math.floor(n);
      w.push( this.numbers[d] );
      n -= d;
    }
    if ( n >= 0 && Math.abs(parseFloat(num)) < 1) w.push( 'NOLLA' );
    if ( n > 0 ) {
      let d = num.split('.');
      if ( d.length > 1 ) {
        w.push( ' PILKKU' );
        let c = [...d[d.length-1]];
        for( let i=0; i<c.length; i++ ) {
          w.push( ' ' + this.numbers[c[i]] );
        }
      }
    }
    return w.join('').trim();
  }


  /**
  * Set the `text` to be spoken by analysing the part content.
  *
  * @param {Object} part Current part
  * @param {number} i Index
  * @param {Object[]} arr All the parts.
  */
  partSetText(part,i,arr) {
    
    // Call super to pre-populate
    super.partSetText(part,i,arr);

    // Language specific implementation
    switch( part.type ) {

      case "text":
        // Check if this is actually a number
        const s = part.text;
        if ( s ) {
          const num = s.replace(/,/g, '').trim();
          if ( !isNaN(num) && !isNaN(parseFloat(num)) ) {
            part.text = this.convertNumberToWords(num) + " ";
          }
        }
        break;

      case "characters":
        const t = [];
        const chars = [...part.value.toUpperCase()];
        const len = chars.length;
        for( let i=0; i<len; i++ ) {
          const c = chars[i];
          if ( this.charactersToWords.hasOwnProperty(c) ) {
            t.push( this.charactersToWords[c] );
          } else {
            t.push(""); // Generates a space for unknown characters
          }
        }
        part.text = t.join(" ") + " ";
        break;

      case "number":
        part.text = this.convertNumberToWords(part.value) + " ";
        break;

      case "date":
        const date = new Date(part.value);
        const month = this.months[date.getMonth()];
        const day = this.days[date.getDate()];
        const year = this.convertNumberToWords(date.getFullYear());
        part.text = day + " " + month + " " + year + " ";
        break;

      case "time":
        const time = new Date(part.value);
        let hours = time.getHours(); // 0–23
        const minutes = time.getMinutes(); // 0–59
        part.text = this.convertNumberToWords(hours) + " ";
        part.text += this.convertNumberToWords(minutes) + " ";
        break;
    }

  }
  

  /**
  * Split compound word into its parts.
  * 
  * @param {string} word Normalized word in upper case
  * @return {string[]} Parts of the word
  */
  splitOnCompoundWords(s) {

    // Split for hyphens
    const hyphens = s.split("-").filter( x => x.length );
    const len = hyphens.length;

    if ( len > 1 ) {

      // Check if parts are compound words
      return hyphens.map( (x,i) => {
        const isLast = i === (len-1);
        return this.splitOnCompoundWords( x + (isLast ? "" : "-") );
      }).flat();

    } else {

      // Check compound word dictionary
      for( let i=s.length; i>2; i-- ) {
        const partFirst = s.substring(0,i);
        if ( this.dictionary.hasOwnProperty(partFirst) ) {
          const item = this.dictionary[partFirst];
          const partNext4 = s.substring(i,i+4);
          const partNext3 = s.substring(i,i+3);
          if ( item.hasOwnProperty(partNext4) || item.hasOwnProperty(partNext3) ) {
            return [ partFirst, ...this.splitOnCompoundWords(s.substring(i)) ];
          }
        }
      }
      return [s];

    }
    
  }


  /**
  * Split single word into syllables.
  * NOTE: Doesn't handle compound words, so you slip on
  * compound words before calling this method.
  *
  * @param {string} s Normalized and upper case word
  * @return {string[]} Syllables.
  */
  splitOnSyllables(s) {
    const syllables = [];

    const chars = [...s];
    let len = chars.length;
    let i = 0;
    let syllable = "";
    let isVowelFound = false;
    let isConsonantFound = false;
    while( i < len ) {

      const isLast = i === (len-1);
      const c = chars[i];
      const isVowel = this.fiVowels.hasOwnProperty(c);
      const isConsonant = this.fiConsonants.hasOwnProperty(c);
      isVowelFound ||= isVowel;
      isConsonantFound ||= isConsonant;
      const isNotLetter = !isVowel && !isConsonant;
      const cSecond = isLast ? null : chars[i+1];
      const isSecondVowel = this.fiVowels.hasOwnProperty(cSecond);
      const cTwo = isLast ? null : (c + cSecond);
      const isDiphthong  = isVowel && isSecondVowel && (c !== cSecond) &&
        (syllables.length === 0 ? !this.fiDiphthongFirst.hasOwnProperty(cTwo) : !this.fiDiphthongEnd.hasOwnProperty(cTwo));
      const isBreakBefore = isVowelFound && isConsonant && isSecondVowel;
      const isBreakAfter = isLast || isDiphthong || isNotLetter;

      // Break before current letter
      if ( isBreakBefore ) {
        syllables.push( syllable );
        syllable = "";
      }
      
      syllable += c;
      
      // Break after the current letter
      if ( isBreakAfter ) {
        syllables.push( syllable );
        syllable = "";
      }

      i++;
    }

    return syllables;
  }


  /**
  * Split word or compound word on stress.
  *
  * @param {string} s Normalized and upper case word or compound word
  * @return {string[]} Stresses parts.
  */
  splitOnStress(s) {
    const stressed = [];

    const words = this.splitOnCompoundWords(s);
    const lenWords = words.length;
    for( let i=0; i<lenWords; i++ ) {
      const word = words[i];
      const syllables = this.splitOnSyllables(word);
      const lenSyllables = syllables.length;
      let stress = "";
      for( let j=0; j<lenSyllables; j++ ) {
        const syllable = syllables[j];
        const isLast = j === (lenSyllables-1);
        if ( j > 0 && (j-1) % 2 && !isLast ) {
          stressed.push( stress );
          stress = "";
        }
        stress += syllable;
        if ( isLast ) {
          stressed.push( stress );
          break;
        }
      }
    }

    return stressed;
  }

  

  /**
  * Convert graphemes to phonemes.
  *
  * @param {string} s Word, normalized and in upper case
  * @return {string[]} Array of phonemes
  */
  phonemizeWord(s) {
    let phonemes = [];

    // Split on stress
    const parts = this.splitOnStress(s);

    parts.forEach( (x,i) => {

      // Stress
      if ( x ) {
        if ( i === 0 ) {
          phonemes.push("ˈ");
        } else {
          phonemes.push("ˌ");
        }
      }

      // Phonemize
      const chars = [...x];
      let len = chars.length;
      let j = 0;
      while( j < len ) {
        const c = chars[j];
        if ( this.punctuations.hasOwnProperty(c) ) {
          phonemes.push( this.punctuations[c] );
          j++;
        } else {
          const ruleset = this.rules[c];
          if ( ruleset ) {
            const lenRuleset = ruleset.length;
            for(let k=0; k<lenRuleset; k++) {
              const rule = ruleset[k];
              const test = x.substring(0, j) + c.toLowerCase() + x.substring(j+1);
              let matches = test.match(rule.regex);
              if ( matches ) {
                phonemes.push( ...rule.phonemes );
                j += rule.move;
                break;
              }
            }
          } else {
            j++;  
          }
        }
      }
    });

    if ( this.settings.trace ) {
      utils.trace( 'Rules: "' + s + '" => "' + phonemes.join("") + '"' );
    }

    return phonemes;
  }

  /**
  * Post process the parts to be spoken.
  *
  * @param {Object[]} parts Parts
  */
  postProcessSpeak(parts) {
    parts.forEach( x => {

    });
    return parts;
  }

}

export { Language };
