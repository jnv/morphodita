// This file is part of MorphoDiTa.
//
// Copyright 2013 by Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// MorphoDiTa is free software: you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as
// published by the Free Software Foundation, either version 3 of
// the License, or (at your option) any later version.
//
// MorphoDiTa is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with MorphoDiTa.  If not, see <http://www.gnu.org/licenses/>.

#include <cstring>
#include <unordered_set>

#include "english_tokenizer.h"
#include "unilib/unicode.h"
#include "unilib/utf8.h"

namespace ufal {
namespace morphodita {

%%{
  machine english_tokenizer;
  write data noerror nofinal;
}%%

// The list of lower cased words that when preceding eos do not end sentence.
static unordered_set<string> eos_word_exceptions = {
  // Titles
  "adj", "adm", "adv", "assoc", "asst", "bart", "bldg", "brig", "bros", "capt",
  "cmdr", "col", "comdr", "con", "corp", "cpl", "d", "dr", "dr", "drs", "ens",
  "gen", "gov", "hon", "hosp", "hr", "insp", "lt", "mm", "mr", "mrs", "ms",
  "maj", "messrs", "mlle", "mme", "mr", "mrs", "ms", "msgr", "op", "ord",
  "pfc", "ph", "phd", "prof", "pvt", "rep", "reps", "res", "rev", "rt", "sen",
  "sens", "sfc", "sgt", "sr", "st", "supt", "surg", "univ",
  // Common abbrevs
  "addr", "approx", "apr", "aug", "calif", "co", "corp", "dec", "def", "e",
  "e.g", "eg", "feb", "fla", "ft", "gen", "gov", "hrs", "i.", "i.e", "ie",
  "inc", "jan", "jr", "ltd", "mar", "max", "min", "mph", "mt", "n", "nov",
  "oct", "ont", "pa", "pres", "rep", "rev", "s", "sec", "sen", "sep", "sept",
  "sgt", "sr", "tel", "un", "univ", "v", "va", "vs", "w", "yrs",
};

bool english_tokenizer::next_sentence(vector<string_piece>& forms) {
  int cs, act;
  const char* ts, *te;
  const char* text_start = text;

  const char* unary_text;
  const char* whitespace = nullptr; // Suppress "may be uninitialized" warning
  unsigned split_len = 0; // Suppress "may be uninitialized" warning
  %%{
    variable p text;
    variable pe text_end;
    variable eof text_end;
    alphtype unsigned char;
    getkey (unsigned char)*text;

    include utf8 "ragel/utf8.rl";
    include url "ragel/url.rl";

    # Tokenization
    apo = "'" | "’"; apo1 = "'"; apo3 = "’";
    backapo = "`" | "‘";

    action unary_minus_allowed { text == text_start || (utf8_back(unary_text=text, text_start), unicode::category(utf8::first(unary_text, text - unary_text)) & ~(unicode::L | unicode::M | unicode::N | unicode::Pd)) }
    action unary_plus_allowed { text == text_start || (utf8_back(unary_text=text, text_start), unicode::category(utf8::first(unary_text, text - unary_text)) & ~(unicode::L | unicode::M | unicode::N) && *unary_text != '+') }
    whitespace = [\r\t\n] | utf8_Zs;
    eol = '\r' ('' >(eol,0) | '\n' >(eol,1)) | '\n' ('' >(eol,0) | '\r' >(eol,1));
    word = (utf8_L (utf8_L | utf8_M | '-' | apo)*) -- ('--' | apo apo);
    number = ('-' when unary_minus_allowed | '+' when unary_plus_allowed)? utf8_Nd+ (',' (utf8_Nd{3}))* ([.] utf8_Nd+)? ([eE] [+\-]? utf8_Nd+)?;

    multiletter_punctuation = "--" | apo apo | backapo backapo | "...";

    action split_2 { split_len = 2; }
    action split_3 { split_len = 3; }
    action split_4 { split_len = 4; }
    action split_5 { split_len = 5; }
    word_with_split =
      (word apo1 ('s'i | 'm'i | 'd'i)) %split_2 | (word apo3 ('s'i | 'm'i | 'd'i)) %split_4 |
      (word apo1 ('ll'i | 're'i | 've'i)) %split_3 | (word apo3 ('ll'i | 're'i | 've'i)) %split_5 |
      (word 'n'i apo1 't'i) %split_3 | (word 'n'i apo3 't'i) %split_5 |
      ('cannot'i) %split_3 |
      ('d'i apo 'ye'i) %split_2 |
      ('gimme'i) %split_2 |
      ('gonna'i) %split_2 |
      ('gotta'i) %split_2 |
      ('lemme'i) %split_2 |
      ('more'i apo1 'n'i) %split_2 | ('more'i apo3 'n'i) %split_4 |
      (apo 'tis'i) %split_2 |
      (apo 'twas'i) %split_3 |
      ('wanna'i) %split_2;

    # Segmentation
    action mark_whitespace { whitespace = text; }
    eos = [.!?] | '…';
    closing = '"' | "'" | ';' | utf8_Pe | utf8_Pf;
    opening = '"' | '`' | utf8_Ps | utf8_Pi;

    main := |*
      word_with_split
        { forms.emplace_back(ts, te - split_len - ts);
          forms.emplace_back(te - split_len, split_len);

          if (emergency_sentence_split(forms)) fbreak;
        };

      word | number | url | multiletter_punctuation | (utf8_any - whitespace)
        { forms.emplace_back(ts, te - ts);

          if (emergency_sentence_split(forms)) fbreak;
        };

      eos closing* whitespace+ >mark_whitespace opening* (utf8_Lu | utf8_Lt)
        {
          // Does this eos character marks end of sentence?
          bool eos_word_exception = false;
          if (!forms.empty()) {
            // Is it single Lut?
            string_piece form = forms.back();
            eos_word_exception = unicode::category(utf8::decode(form.str, form.len)) & unicode::Lut && !form.len;

            // Is the lower case variant in eos_word_exceptions?
            buffer.clear();
            utf8::map(unicode::lowercase, forms.back().str, forms.back().len, buffer);
            eos_word_exception |= eos_word_exceptions.count(buffer);
          }

          // Add all characters until first space to forms and break if eos.
          for (text = ts; text < whitespace; forms.emplace_back(ts, text - ts), ts = text) utf8_advance(text, whitespace);
          fexec whitespace;
          if (!eos_word_exception) fbreak;
        };

      whitespace+ -- eol eol;

      eol eol
        { if (!forms.empty()) fbreak; };
    *|;

    write init;
    write exec;
  }%%
  (void)act; // Suppress unused variable warning

  return !forms.empty();
}

} // namespace morphodita
} // namespace ufal


