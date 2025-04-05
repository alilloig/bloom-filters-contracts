# Bloom Filters

## Introduction

A Bloom Filter is a space-efficient probabilistic data structure that tests whether an element is a member of a set. Bloom filters are designed to be compact and fast, with a trade-off of allowing some false positives but never false negatives. 
This implementation extends the basic concept with a Cascade Filter system that maintains multiple Bloom filters in sequence to handle large datasets efficiently.

## Properties and Applications

1. Space Efficiency: Uses minimal memory compared to traditional data structures
1. Fast Lookups: O(k) lookup time, where k is the number of hash functions
1. No False Negatives: If a Bloom filter indicates an element is not in the set, it definitely isn't
1. Probabilistic: May return false positives (indicating an element is in the set when it isn't)
1. Cascading Expansion: Automatically creates new filters when current ones become saturated

## Basic Structure and Formation

In a Bloom filter, when an element is added to the set, it is hashed by multiple hash functions. 
The resulting hash values determine which bits in a bit array are set to 1. 
To test if an element is in the set, it is hashed by the same functions, and if all corresponding bits are 1, the element is considered to be in the set (with some probability of a false positive).

## Visualizing a Bloom Filter

Let's visualize a simple Bloom filter with 8 bits and 2 hash functions:

```pseudocode
Initial state: [0, 0, 0, 0, 0, 0, 0, 0]

Adding element "A":
- Hash1("A") = 1, Hash2("A") = 6
- Set bits 1 and 6 to 1
- State: [0, 1, 0, 0, 0, 0, 1, 0]

Adding element "B":
- Hash1("B") = 3, Hash2("B") = 7
- Set bits 3 and 7 to 1
- State: [0, 1, 0, 1, 0, 0, 1, 1]

Testing element "C":
- Hash1("C") = 1, Hash2("C") = 7
- Check bits 1 and 7 (both are 1)
- Result: "C" may be in the set (false positive!)

Testing element "D":
- Hash1("D") = 2, Hash2("D") = 5
- Check bits 2 and 5 (both are 0)
- Result: "D" is definitely not in the set
```

## Implementation key concepts

### Bit Array

The foundation of a Bloom filter is its bit array, which in this implementation is a 256-bit array represented as a u256 value. 
Each bit position corresponds to a possible hash output.

### Hash Functions

This implementation uses two cryptographic hash functions:

1. SHA3-256: A secure hash algorithm that produces a 256-bit hash value
1. BLAKE2b-256: Another cryptographic hash function that produces a 256-bit output

Using multiple hash functions reduces the probability of false positives.

### Filter Fullness

A Bloom filter becomes less efficient as more elements are added (increasing the false positive rate). 
This implementation tracks filter fullness and considers a filter "full" when half of its bits (128 out of 256) are set to 1.

### Cascade Filter

The Cascade Filter structure extends basic Bloom filters by maintaining a vector of filters. 
When the current active filter becomes full, a new empty filter is created and becomes the active one.

## Implementation Details

### Structures
#### BloomFilter
```move
public struct BloomFilter has store {
    bits: u256,
    is_full: bool
}
```
The BloomFilter structure maintains:

- A 256-bit array (bits) to store the set membership information
- A boolean flag indicating whether the filter is considered full

#### CascadeFilter
```move
public struct CascadeFilter has key, store {
    id: UID,
    filters: vector<BloomFilter>,
    writing_filter: u64
}
```
The CascadeFilter structure maintains:

- A unique identifier
- A vector of Bloom filters
- The index of the current active filter for writing

### Operations
#### Adding Data
When adding data to the Cascade Filter:

- The data is hashed using both SHA3-256 and BLAKE2b-256
- The hash values are modulo mapped to positions in the bit array
- The corresponding bits are set to 1
- If the current filter becomes full, a new filter is created and added to the cascade

#### Verifying Data Exclusion
To verify if data is not in the Cascade Filter:


## Advantages of Cascade Filters

1. Scalability: As data grows, new filters are added automatically
1. Controlled False Positive Rate: By limiting each filter's fullness, the false positive rate remains bounded
1. Efficient Updates: Adding new data is fast (O(1) operation)
1. Memory Efficiency: Minimal memory footprint even for large datasets