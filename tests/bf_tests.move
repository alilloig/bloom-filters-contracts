#[test_only]
module bf::bf_tests {
    use bf::bf;
    use bf::bf_utils;
    use sui::test_scenario::{Self as test, ctx};
    use std::hash;
    use sui::hash as sui_hash;

    const ALICE: address = @0xA;

    // ============================================================================
    // CascadeFilter Tests
    // ============================================================================

    #[test]
    fun test_new_cascade_filter() {
        let mut scenario = test::begin(ALICE);
        {
            let mut cascade_filter = bf::new(ctx(&mut scenario));
            
            // Verify the filter is properly initialized
            // Note: We can't directly access private fields, so we test by behavior
            
            // Test that we can add data without panicking
            bf::add_data(&mut cascade_filter, b"test_data");
            
            // Clean up
            sui::test_utils::destroy(cascade_filter);
        };
        test::end(scenario);
    }

    #[test]
    fun test_add_single_data() {
        let mut scenario = test::begin(ALICE);
        {
            let mut cascade_filter = bf::new(ctx(&mut scenario));
            
            // Add a single piece of data
            let test_data = b"hello_world";
            bf::add_data(&mut cascade_filter, test_data);
            
            // The data should be found in the filter (may be false positive, but should not be false negative)
            let is_excluded = bf::verify_data_exclusion(&mut cascade_filter, test_data);
            assert!(!is_excluded, 1); // Should return false (element may be present)
            
            sui::test_utils::destroy(cascade_filter);
        };
        test::end(scenario);
    }

    #[test]
    fun test_add_multiple_data() {
        let mut scenario = test::begin(ALICE);
        {
            let mut cascade_filter = bf::new(ctx(&mut scenario));
            
            // Add multiple pieces of data
            let data1 = b"data_one";
            let data2 = b"data_two";
            let data3 = b"data_three";
            
            bf::add_data(&mut cascade_filter, data1);
            bf::add_data(&mut cascade_filter, data2);
            bf::add_data(&mut cascade_filter, data3);
            
            // All added data should be found in the filter
            assert!(!bf::verify_data_exclusion(&mut cascade_filter, data1), 2);
            assert!(!bf::verify_data_exclusion(&mut cascade_filter, data2), 3);
            assert!(!bf::verify_data_exclusion(&mut cascade_filter, data3), 4);
            
            sui::test_utils::destroy(cascade_filter);
        };
        test::end(scenario);
    }

    #[test]
    fun test_verify_data_exclusion_with_unknown_data() {
        let mut scenario = test::begin(ALICE);
        {
            let mut cascade_filter = bf::new(ctx(&mut scenario));
            
            // Add some known data
            let known_data = b"known_data";
            bf::add_data(&mut cascade_filter, known_data);
            
            // Test with data that was never added
            let unknown_data = b"definitely_not_added";
            let _is_excluded = bf::verify_data_exclusion(&mut cascade_filter, unknown_data);
            
            // Could be either true (definitely not present) or false (might be present due to hash collision)
            // We mainly test that the function doesn't panic
            
            sui::test_utils::destroy(cascade_filter);
        };
        test::end(scenario);
    }

    #[test]
    fun test_cascade_filter_with_large_amounts_of_data() {
        let mut scenario = test::begin(ALICE);
        {
            let mut cascade_filter = bf::new(ctx(&mut scenario));
            
            // Add many pieces of data to trigger filter switching
            let mut i = 0;
            while (i < 200) { // Add enough data to potentially fill a filter
                let mut data = b"data_";
                vector::append(&mut data, vector[(i as u8)]);
                bf::add_data(&mut cascade_filter, data);
                i = i + 1;
            };
            
            // Verify some of the added data
            let mut test_data = b"data_";
            vector::append(&mut test_data, vector[100u8]);
            assert!(!bf::verify_data_exclusion(&mut cascade_filter, test_data), 5);
            
            sui::test_utils::destroy(cascade_filter);
        };
        test::end(scenario);
    }

    #[test]
    fun test_cascade_filter_empty_data() {
        let mut scenario = test::begin(ALICE);
        {
            let mut cascade_filter = bf::new(ctx(&mut scenario));
            
            // Test with empty vector
            let empty_data = vector::empty<u8>();
            bf::add_data(&mut cascade_filter, empty_data);
            
            // Verify the empty data can be found
            assert!(!bf::verify_data_exclusion(&mut cascade_filter, empty_data), 6);
            
            sui::test_utils::destroy(cascade_filter);
        };
        test::end(scenario);
    }

    #[test]
    fun test_cascade_filter_identical_data() {
        let mut scenario = test::begin(ALICE);
        {
            let mut cascade_filter = bf::new(ctx(&mut scenario));
            
            // Add the same data multiple times
            let data = b"duplicate_data";
            bf::add_data(&mut cascade_filter, data);
            bf::add_data(&mut cascade_filter, data);
            bf::add_data(&mut cascade_filter, data);
            
            // Should still be findable
            assert!(!bf::verify_data_exclusion(&mut cascade_filter, data), 7);
            
            sui::test_utils::destroy(cascade_filter);
        };
        test::end(scenario);
    }

    // ============================================================================
    // bf_utils Tests
    // ============================================================================

    #[test]
    fun test_hash_to_modulo_position() {
        // Test with known hash values
        let hash1 = hash::sha3_256(b"test");
        let position1 = bf_utils::hash_to_modulo_position(hash1);
        assert!(position1 < 255, 8); // Should be within valid range
        
        let hash2 = hash::sha3_256(b"different");
        let position2 = bf_utils::hash_to_modulo_position(hash2);
        assert!(position2 < 255, 9); // Should be within valid range
        
        // Different inputs should (likely) produce different positions
        // Note: This could theoretically fail due to hash collisions, but very unlikely
    }

    #[test]
    fun test_hash_to_modulo_position_consistency() {
        // Same input should always produce same output
        let data = b"consistent_test";
        let hash = hash::sha3_256(data);
        let position1 = bf_utils::hash_to_modulo_position(hash);
        let position2 = bf_utils::hash_to_modulo_position(hash);
        assert!(position1 == position2, 10);
    }

    #[test]
    fun test_set_to_one_basic() {
        // Test setting bit 0
        let result = bf_utils::set_to_one(0, 0);
        assert!(result == 1, 11);
        
        // Test setting bit 1
        let result = bf_utils::set_to_one(0, 1);
        assert!(result == 2, 12);
        
        // Test setting bit 2
        let result = bf_utils::set_to_one(0, 2);
        assert!(result == 4, 13);
    }

    #[test]
    fun test_set_to_one_already_set() {
        // Test setting a bit that's already set
        let result = bf_utils::set_to_one(1, 0); // Bit 0 already set
        assert!(result == 1, 14); // Should remain 1
        
        let result = bf_utils::set_to_one(3, 1); // Both bits 0 and 1 set, set bit 1 again
        assert!(result == 3, 15); // Should remain 3
    }

    #[test]
    fun test_set_to_one_multiple_bits() {
        // Start with number that has some bits set
        let mut num = 5; // Binary: 101 (bits 0 and 2 set)
        
        // Set bit 1
        num = bf_utils::set_to_one(num, 1);
        assert!(num == 7, 16); // Binary: 111
        
        // Set bit 3
        num = bf_utils::set_to_one(num, 3);
        assert!(num == 15, 17); // Binary: 1111
    }

    #[test]
    fun test_set_to_one_high_positions() {
        // Test with higher bit positions
        let result = bf_utils::set_to_one(0, 63);
        assert!(result == (1u256 << 63), 18);
        
        let result = bf_utils::set_to_one(0, 100);
        assert!(result == (1u256 << 100), 19);
    }

    #[test]
    fun test_are_half_ones_empty() {
        // Test with 0 (no bits set)
        assert!(!bf_utils::are_half_ones(0), 20);
    }

    #[test]
    fun test_are_half_ones_few_bits() {
        // Test with numbers having fewer than 128 bits set
        assert!(!bf_utils::are_half_ones(1), 21); // 1 bit
        assert!(!bf_utils::are_half_ones(7), 22); // 3 bits
        assert!(!bf_utils::are_half_ones(255), 23); // 8 bits
    }

    #[test]
    fun test_are_half_ones_exactly_half() {
        // Create a number with exactly 128 bits set
        let mut num = 0u256;
        let mut i = 0;
        while (i < 128) {
            num = bf_utils::set_to_one(num, i);
            i = i + 1;
        };
        assert!(bf_utils::are_half_ones(num), 24);
    }

    #[test]
    fun test_are_half_ones_more_than_half() {
        // Create a number with more than 128 bits set
        let mut num = 0u256;
        let mut i = 0;
        while (i < 150) {
            num = bf_utils::set_to_one(num, i);
            i = i + 1;
        };
        assert!(bf_utils::are_half_ones(num), 25);
    }

    #[test]
    fun test_are_half_ones_scattered_bits() {
        // Test with scattered bits (not consecutive)
        let mut num = 0u256;
        let mut i = 0;
        while (i < 128) {
            num = bf_utils::set_to_one(num, i * 2); // Set every other bit
            i = i + 1;
        };
        assert!(bf_utils::are_half_ones(num), 26);
    }

    #[test]
    fun test_is_not_set_basic() {
        // Test with 0 (no bits set)
        assert!(bf_utils::is_not_set(0, 0), 27);
        assert!(bf_utils::is_not_set(0, 5), 28);
        assert!(bf_utils::is_not_set(0, 255), 29);
    }

    #[test]
    fun test_is_not_set_with_set_bits() {
        let num = 5; // Binary: 101 (bits 0 and 2 set)
        
        // Check set bits
        assert!(!bf_utils::is_not_set(num, 0), 30); // Bit 0 is set
        assert!(!bf_utils::is_not_set(num, 2), 31); // Bit 2 is set
        
        // Check unset bits
        assert!(bf_utils::is_not_set(num, 1), 32); // Bit 1 is not set
        assert!(bf_utils::is_not_set(num, 3), 33); // Bit 3 is not set
    }

    #[test]
    fun test_is_not_set_high_positions() {
        let num = 1u256 << 100; // Only bit 100 is set
        
        assert!(!bf_utils::is_not_set(num, 100), 34); // Bit 100 is set
        assert!(bf_utils::is_not_set(num, 99), 35);   // Bit 99 is not set
        assert!(bf_utils::is_not_set(num, 101), 36);  // Bit 101 is not set
    }

    #[test]
    fun test_is_not_set_all_bits_set() {
        // Test with a number that has many bits set
        let mut num = 0u256;
        let mut i = 0;
        while (i < 50) {
            num = bf_utils::set_to_one(num, i);
            i = i + 1;
        };
        
        // Check that first 50 bits are set
        i = 0;
        while (i < 50) {
            assert!(!bf_utils::is_not_set(num, i), 37);
            i = i + 1;
        };
        
        // Check that bit 51 is not set
        assert!(bf_utils::is_not_set(num, 51), 38);
    }

    // ============================================================================
    // Integration Tests
    // ============================================================================

    #[test]
    fun test_bloom_filter_integration() {
        let mut scenario = test::begin(ALICE);
        {
            let mut cascade_filter = bf::new(ctx(&mut scenario));
            
            // Test the complete workflow
            let data1 = b"integration_test_1";
            let data2 = b"integration_test_2";
            let unknown_data = b"not_in_filter";
            
            // Add data
            bf::add_data(&mut cascade_filter, data1);
            bf::add_data(&mut cascade_filter, data2);
            
            // Verify added data (should not be excluded)
            assert!(!bf::verify_data_exclusion(&mut cascade_filter, data1), 39);
            assert!(!bf::verify_data_exclusion(&mut cascade_filter, data2), 40);
            
            // Test with data that was never added - might or might not be excluded
            // depending on hash collisions, but function should not panic
            bf::verify_data_exclusion(&mut cascade_filter, unknown_data);
            
            sui::test_utils::destroy(cascade_filter);
        };
        test::end(scenario);
    }

    #[test]
    fun test_hash_functions_consistency() {
        // Test that our hash functions produce consistent results
        let data = b"consistency_test";
        let sha3_hash = hash::sha3_256(data);
        let blake2b_hash = sui_hash::blake2b256(&data);
        
        let pos1 = bf_utils::hash_to_modulo_position(sha3_hash);
        let pos2 = bf_utils::hash_to_modulo_position(blake2b_hash);
        
        // Both should be valid positions
        assert!(pos1 < 255, 41);
        assert!(pos2 < 255, 42);
        
        // They should be consistent across multiple calls
        assert!(pos1 == bf_utils::hash_to_modulo_position(hash::sha3_256(data)), 43);
        assert!(pos2 == bf_utils::hash_to_modulo_position(sui_hash::blake2b256(&data)), 44);
    }

    #[test]
    fun test_filter_with_various_data_types() {
        let mut scenario = test::begin(ALICE);
        {
            let mut cascade_filter = bf::new(ctx(&mut scenario));
            
            // Test with different types of data
            let string_data = b"string_data";
            let number_data = vector[1u8, 2u8, 3u8, 4u8];
            let large_data = b"this is a much larger piece of data that we want to test with the bloom filter to ensure it works correctly with varying data sizes";
            
            bf::add_data(&mut cascade_filter, string_data);
            bf::add_data(&mut cascade_filter, number_data);
            bf::add_data(&mut cascade_filter, large_data);
            
            // All should be found
            assert!(!bf::verify_data_exclusion(&mut cascade_filter, string_data), 45);
            assert!(!bf::verify_data_exclusion(&mut cascade_filter, number_data), 46);
            assert!(!bf::verify_data_exclusion(&mut cascade_filter, large_data), 47);
            
            sui::test_utils::destroy(cascade_filter);
        };
        test::end(scenario);
    }

    #[test]
    fun test_bit_manipulation_edge_cases() {
        // Test edge cases for bit manipulation functions
        
        // Test with maximum bit position (255 for u8)
        let result = bf_utils::set_to_one(0, 255);
        assert!(result == (1u256 << 255), 48);
        assert!(!bf_utils::is_not_set(result, 255), 49);
        assert!(bf_utils::is_not_set(result, 254), 50);
        
        // Test with 0 position
        let result = bf_utils::set_to_one(0, 0);
        assert!(result == 1, 51);
        assert!(!bf_utils::is_not_set(result, 0), 52);
        assert!(bf_utils::is_not_set(result, 1), 53);
    }

    #[test]
    fun test_cascade_filter_memory_efficiency() {
        let mut scenario = test::begin(ALICE);
        {
            let mut cascade_filter = bf::new(ctx(&mut scenario));
            
            // Add a reasonable amount of data
            let mut i = 0;
            while (i < 50) {
                let mut data = b"memory_test_";
                vector::append(&mut data, vector[(i as u8)]);
                bf::add_data(&mut cascade_filter, data);
                i = i + 1;
            };
            
            // Verify some of the data
            let mut j = 0;
            while (j < 10) {
                let mut test_data = b"memory_test_";
                vector::append(&mut test_data, vector[(j as u8)]);
                assert!(!bf::verify_data_exclusion(&mut cascade_filter, test_data), 54);
                j = j + 1;
            };
            
            sui::test_utils::destroy(cascade_filter);
        };
        test::end(scenario);
    }
}