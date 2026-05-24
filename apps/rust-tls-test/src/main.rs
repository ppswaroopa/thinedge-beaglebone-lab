use openssl::version;

fn main() {
    println!("OpenSSL version: {}", version::version());
}
