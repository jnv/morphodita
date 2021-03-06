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

#pragma once

#include "common.h"
#include "binary_encoder.h"
#include "persistent_unordered_map.h"

namespace ufal {
namespace morphodita {

template <class Entry, class EntryEncode>
persistent_unordered_map::persistent_unordered_map(const unordered_map<string, Entry>& map, double load_factor, EntryEncode entry_encode) {
  construct(std::map<string, Entry>(map.begin(), map.end()), load_factor, entry_encode);
}

template <class Entry, class EntryEncode>
persistent_unordered_map::persistent_unordered_map(const unordered_map<string, Entry>& map, double load_factor, bool add_prefixes, bool add_suffixes, EntryEncode entry_encode) {
  // Copy data, possibly including prefixes and suffixes
  std::map<string, Entry> enlarged_map(map.begin(), map.end());

  for (auto&& entry : map) {
    const string& key = entry.first;

    if (!key.empty() && add_prefixes)
      for (unsigned i = key.size() - 1; i; i--)
        enlarged_map[key.substr(0, i)];

    if (!key.empty() && add_suffixes)
      for (unsigned i = 1; i < key.size(); i++)
        enlarged_map[key.substr(i)];
  }

  construct(enlarged_map, load_factor, entry_encode);
}

// We could (and used to) use unordered_map as input parameter.
// Nevertheless, as order is unspecified, the resulting persistent_unordered_map
// has different collision chains when generated on 32-bit and 64-bit machines.
// To guarantee uniform binary representation, we use map instead.
template <class Entry, class EntryEncode>
void persistent_unordered_map::construct(const map<string, Entry>& map, double load_factor, EntryEncode entry_encode) {
  // 1) Count number of elements for each size
  vector<int> sizes;
  for (auto&& elem : map) {
    unsigned len = elem.first.size();
    if (len >= sizes.size()) sizes.resize(len + 1);
    sizes[len]++;
  }
  for (auto&& size : sizes)
    resize(unsigned(load_factor * size));

  // 2) Add sizes of element data
  for (auto&& elem : map) {
    binary_encoder enc;
    entry_encode(enc, elem.second);
    add(elem.first.c_str(), elem.first.size(), enc.data.size());
  }
  done_adding();

  // 3) Fill in element data
  for (auto&& elem : map) {
    binary_encoder enc;
    entry_encode(enc, elem.second);
    small_memcpy(fill(elem.first.c_str(), elem.first.size(), enc.data.size()), enc.data.data(), enc.data.size());
  }
  done_filling();
}

void persistent_unordered_map::save(binary_encoder& enc) {
  enc.add_1B(hashes.size());

  for (auto&& hash : hashes)
    hash.save(enc);
}

void persistent_unordered_map::fnv_hash::save(binary_encoder& enc) {
  enc.add_4B(hash.size());
  enc.add_data((const unsigned char*)hash.data(), (const unsigned char*)(hash.data() + hash.size()));

  enc.add_4B(data.size());
  enc.add_data(data.data(), data.data() + data.size());
}

} // namespace morphodita
} // namespace ufal
