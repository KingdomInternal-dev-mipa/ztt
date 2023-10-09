#[no_mangle]
pub extern "C" fn rs_fn() {
        main();
}

fn main() {
    println!("Hello from Rust!");
}
