module bf::bf;

use std::hash;
use sui::hash as sui_hash;
use bf::bf_utils;

/// A CascadeFilter is a data structure that maintains multiple Bloom filters in a cascading manner.
/// It automatically creates new Bloom filters when the current one becomes full, allowing for
/// continuous data insertion without loss of information.
public struct CascadeFilter has key, store {
    id: UID,
    filters: vector<BloomFilter>,
    writing_filter: u64
}

/// Creates a new empty CascadeFilter instance.
/// Returns a fresh CascadeFilter with no Bloom filters initialized.
public fun new(ctx: &mut TxContext): CascadeFilter {
    CascadeFilter {
        id: object::new(ctx),
        filters: vector::singleton(new_filter()),
        writing_filter: 0
    }
}

/// Adds data to the current active Bloom filter in the cascade.
/// If the current filter becomes full, it automatically switches to the next filter.
public fun add_data (cascade_filter: &mut CascadeFilter, data: vector<u8>) {
    cascade_filter.filters[cascade_filter.writing_filter].add_data_to_filter(data);
    cascade_filter.check_writing_filter_is_full()
}

/// Checks if the current writing filter is full and advances to the next filter if needed.
/// This ensures we always have an available filter for new data insertion.
fun check_writing_filter_is_full (cascade_filter: &mut CascadeFilter) {
    if (cascade_filter.filters[cascade_filter.writing_filter].is_full) {
        cascade_filter.writing_filter = cascade_filter.writing_filter + 1;
        cascade_filter.filters.push_back(new_filter())
    } 
}

/// Returns true if the element is NOT in the filter
/// returns false if the element MAY BE on the filter
public fun verify_data_exclusion (cascade_filter: &mut CascadeFilter, data: vector<u8>): bool {
    let mut i = 0;
    let mut result: bool = false;
    while (i < cascade_filter.filters.length()) {
        result = cascade_filter.filters[i].verify_exclusion(data);
        if (!result) break;
        i = i + 1;
    };
    return result
}

/// A BloomFilter is a space-efficient probabilistic data structure used to test whether an element
/// is a member of a set. It may return false positives but never false negatives.
/// This implementation uses a 256-bit array to store the filter state.
public struct BloomFilter has store {
    bits: u256,
    is_full: bool
}

/// Initializes an empty bloom filter
fun new_filter(): BloomFilter {
    BloomFilter {
        bits: 0,
        is_full: false,
    }
}

/// Adds data to the Bloom filter by computing two hash functions and setting the corresponding bits.
/// Uses both SHA3-256 and BLAKE2b-256 hash functions to reduce false positive probability.
fun add_data_to_filter (filter: &mut BloomFilter, data: vector<u8>) {
    filter.set_filter_bit(bf_utils::hash_to_modulo_position(hash::sha3_256(data)));
    filter.set_filter_bit(bf_utils::hash_to_modulo_position(sui_hash::blake2b256(&data)));
    filter.check_is_full()
}

/// Sets a specific bit position in the filter to 1.
/// This is used to mark the presence of an element in the set.
fun set_filter_bit (filter: &mut BloomFilter, bit_position: u8) {
    filter.bits = bf_utils::set_to_one(filter.bits, bit_position)
}

/// Checks if the filter is considered full (half of its bits are set to 1).
/// This helps determine when to create a new filter in the cascade.
fun check_is_full (filter: &mut BloomFilter) {
    if (bf_utils::are_half_ones(filter.bits)) filter.is_full = true
}

fun verify_exclusion(filter: &BloomFilter, data: vector<u8>): bool {
    if (bf_utils::is_not_set(filter.bits, bf_utils::hash_to_modulo_position(hash::sha3_256(data)))) return true;
    if (bf_utils::is_not_set(filter.bits, bf_utils::hash_to_modulo_position(sui_hash::blake2b256(&data)))) return true;
    false
}