#[test_only]

module bf::bf_tests;

use bf::bf;
use sui::test_scenario;
use sui::test_utils;

#[test]
fun basic_test() {

    // Create a test scenario with the owner as sender
    let owner = @0xCAFE;
    let mut scenario = test_scenario::begin(owner);
    {
        let ctx = test_scenario::ctx(&mut scenario);
        let bf = bf::new(ctx);
    };

}