module bf::bf_utils;

public fun hash_to_modulo_position(hash: vector<u8>): u8 {
    (hash_to_uint(hash) % 256) as u8
}

fun hash_to_uint(hash: vector<u8>): u256 {
    let mut result: u256 = 0;
    let mut i = 0;
    while (i < hash.length()) {
        result = result + (hash[i] as u256);
        i = i + 1;
    };
    result
}

/// Sets a specific bit position to 1 in a u256 number
/// 
/// This function takes a u256 number and a bit position, and returns a new number
/// with the specified bit position set to 1 while preserving all other bits.
/// The function uses a bitwise OR operation with a shifted 1 to set the target bit.
/// # Example
/// If num = 5 (101 in binary) and position = 1, the result will be 7 (111 in binary)
public fun set_to_one(num: u256, position: u8): u256 {
    let result = num | 1 << position;
    result
}

/// Checks if a u256 number has at least half of its bits (128 or more) set to 1
/// 
/// This function determines if a number has 128 or more bits set to 1 in its binary representation.
/// It uses a bit-counting algorithm that iteratively removes the least significant set bit.
/// For example, for a number with 130 bits set to 1, the function returns true.
/// This is useful in MMR operations where checking for numbers with a significant number of set bits
/// is important for tree structure analysis or optimization.
public fun are_half_ones(num: u256): bool {
    let mut value = num;
    let mut bit_count = 0;
    while (value != 0) {
        value = value & (value - 1);
        bit_count = bit_count + 1;
        if (bit_count >= 128) return true;
    };
    false
}

public fun is_set_to_one(num: u256, position: u8): bool {
    num & (1 << position) != 0
}