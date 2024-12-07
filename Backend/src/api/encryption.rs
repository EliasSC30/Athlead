
pub mod encryption
{
    use std::fmt;
    use std::mem::swap;
    use std::ptr::copy;

    pub struct BigInt<const N: usize> {
        pub bits: [u32;N]
    }

    impl<const N: usize> Clone for BigInt<N> {
        fn clone(&self) -> Self { BigInt::<N> { bits: self.bits.clone() } }
    }

    impl<const N: usize> fmt::Display for BigInt<N> {
        fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
            let mut bytes = Vec::new();

            for &num in self.bits.iter() {
                // Extract each byte of the u32 using bit shifting and masking
                bytes.push((num & 0xFF) as u8);          // least significant byte
                bytes.push(((num >> 8) & 0xFF) as u8);  // second byte
                bytes.push(((num >> 16) & 0xFF) as u8); // third byte
                bytes.push((num >> 24) as u8); // most significant byte
            }

            write!(f, "{:?}", bytes)
        }
    }

    impl<const N: usize> Into<BigInt<N>> for u32 {
        fn into(self) -> BigInt<N> {
            BigInt::<N>{ bits: [self;N]}
        }
    }

    pub fn add_with_carry(a:u32, b:u32) -> (u32, u32)
    {
        // This is a+b = Max + carry <=> carry = a - (Max - b) to get the carry, if there is any
        if (u32::MAX - b) > a { (a+b,0) } else { (a.wrapping_add(b), 1) }
    }

    impl<const N: usize> BigInt<N> {

        pub fn new(bits_to_take_over: [u32;N]) -> BigInt<N> { BigInt::<N> { bits: bits_to_take_over } }

        pub fn compare<const M:usize>(&self, other: &BigInt<M>) -> i32 {
            let mut ret = 0i32;
            let mut this_is_smaller = false;
            let mut smaller_size = M;

            if M > N {
                smaller_size = N; this_is_smaller = true;
            };

            for index in 0..smaller_size
            {
                let my_part = self.bits[index];
                let other_part = other.bits[index];
                if my_part != other_part {
                    if my_part > other_part { ret = 1; } else { ret = -1; };
                }
            }

            if this_is_smaller {
                if self.bits[M..].iter().any(|&x| x != 0) { return 1;}
            } else {
                if other.bits[M..].iter().any(|&x| x != 0) { return -1;}
            };

            ret
        }

        fn add_with_carry(a:u32, b:u32) -> (u32, u32)
        {
            // This is a+b = Max + carry <=> carry = a - (Max - b) to get the carry, if there is any
            //if (u32::MAX - b) > a { (a+b,0) } else { (a.wrapping_add(b), 1) }
            let a_as_64 = a as u64;
            let b_as_64 = b as u64;

            let res = a_as_64 + b_as_64;

            ((res & (0xFFFFFFFF)) as u32, ((res & (0xFFFFFFFF << 32)) >> 32) as u32)
        }

        fn mul_with_carry(a:u32, b:u32) -> (u32, u32)
        {
            let a_as_64 = a as u64;
            let b_as_64 = b as u64;

            let res = a_as_64 * b_as_64;

            ((res & (0xFFFFFFFF)) as u32, ((res & (0xFFFFFFFF << 32)) >> 32) as u32)
        }

        fn div_with_remainder(a:u32, b:u32) -> (u32, u32)
        {
            let without_remainder = a / b;

            (without_remainder, a - b * without_remainder)
        }

        fn div_a_n<const M: usize>(a_n: u32, a_index: usize, d: u32, d_index: usize) -> (u32, i32, u32)
        {
            let (res, rem) = Self::div_with_remainder(a_n,d);

            (res,a_index as i32 - d_index as i32,rem)
        }

        unsafe fn expand_to_m<const M: usize>(&self) -> BigInt<M> {
            assert!(N < M, "M must be smaller than N, consider using expand_to_m");

            let mut return_bits = [0u32; M];
            return_bits.clone_from_slice(&self.bits[..M]);

            BigInt::<M>::new(return_bits)
        }

        unsafe fn shrink_to_m<const M: usize>(&self) -> BigInt<M> {
            assert!(N > M, "M must be smaller than N, consider using expand_to_m");

            let mut return_bits = [0u32;M];
            return_bits.clone_from_slice(&self.bits[..M]);

            BigInt::<M>::new(return_bits)
        }

        pub fn mul<const TWO_N : usize>(self, other: &BigInt<N>) -> Result<BigInt<TWO_N>, &'static str>
        {
            assert!(N > 0usize, "N must be positive");
            let mut return_value = [0u32; TWO_N];
            let mut carry = 0u32;

            for outer_index in 0..N
            {
                let part = self.bits[outer_index];
                for inner_index in 0..N
                {
                    let cur_index = outer_index + inner_index;
                    let (mul_r, mul_c) = Self::mul_with_carry(part, other.bits[inner_index]);
                    let (add_r, add_c) = Self::add_with_carry(return_value[cur_index], carry);

                    let (add_to_return_value_r, add_to_return_value_c) = Self::add_with_carry(add_r, mul_r);

                    return_value[cur_index] = add_to_return_value_r;
                    carry = mul_c + add_to_return_value_c + add_c;
                }
            }

            if carry == 0u32 { Ok(BigInt::<TWO_N> { bits: return_value}) } else { Err("Overflow") }
        }

        // We are computing self/other = (whole_result, remainder)
        pub fn div<const M: usize, const M_MINUS_N: usize>(self, other: &BigInt<M>) -> (BigInt<M_MINUS_N>, BigInt<M>)
        {
            assert!(N > 0usize && M > 0usize, "N and M must be positive");
            assert_eq!(M_MINUS_N, M - N, "M_MINUS_N must be M-N");

            // If self is smaller than other the result is simply (0,self)
            if self.compare(&other) < 0 {
                let mut ret: BigInt<M> = 0u32.into();
                ret.bits.copy_from_slice(&self.bits[..M]);
                return (0u32.into(), ret);
            };

            let mut whole_return_value = [0u32;M_MINUS_N];
            let mut other_copy = other.bits.clone();
            let mut cur_remainder_part = 0u32;
            let mut remainder_return_value = [0u32;M];

            remainder_return_value.clone_from_slice(&self.bits[..M]);

            for numerator_index in 0..N
            {
                let a_n = self.bits[numerator_index];

                for denominator_index in 0..M
                {
                    let d = other.bits[denominator_index];
                    match numerator_index - denominator_index {
                        1.. => {},
                        0 => {},
                        power_smaller_than_M => {}
                    }
                }
            }

            (BigInt::<M_MINUS_N> { bits: whole_return_value }, BigInt::<M> { bits: remainder_return_value })
        }

        pub fn add(self, other: &BigInt<N>) -> Result<BigInt<N>, &'static str>
        {
            assert!(N > 0usize, "N must be positive");

            let mut return_value = [0u32;N];
            let mut carry = 0u32;

            for index in 0..N
            {
                let a = self.bits[index];
                let b = other.bits[index];

                let (a_plus_b_wrapped, a_plus_b_carry) = Self::add_with_carry(a, b);
                let (a_plus_b_plus_carry_wrapped, final_carry) = Self::add_with_carry(a_plus_b_wrapped, carry);

                return_value[index] = a_plus_b_plus_carry_wrapped;
                carry = if a_plus_b_carry != 0 || final_carry != 0 { 1 } else { 0 };
            }

            match carry {
                0 => Ok(BigInt{bits: return_value}),
                _ => Err("BigInt overflow")
            }
        }
    }
    pub fn generate_key() -> (u128, u128, u128)
    {
        let p = 7; // GPT...
        let q = 47; // GPT...

        let n = p*q;
        let phi_n = (p-1u128) * (q -1u128);

        let e = 17;

        let gcd = gcd(e, phi_n);

        (e, gcd.1, n)
    }

    // Solving for gcd(a,b) = s*a + t*b
    fn gcd(a: u128, b: u128) -> (u128,u128,u128)
    {
        let mut r_0 = a;
        let mut r_1 = b;
        let mut s_0 = 1;
        let mut s_1 = 0;
        let mut t_0 = 0;
        let mut t_1 = 1;

        let mut n = 0u32;
        while r_1 > 0u128
        {
            let q = r_0 / r_1;
            r_0 = if r_0 > q*r_1 { r_0-q*r_1 } else { q*r_1-r_0 };
            swap(&mut r_0, &mut r_1);
            s_0 = s_0+q*s_1;
            swap(&mut s_0, &mut s_1);
            t_0 = t_0+q*t_1;
            swap(&mut t_0, &mut t_1);
            n += 1;
        }
        if (n%2) != 0 {s_0 = b-s_0;} else {t_0 = a-t_0;};

        (r_0, s_0, t_0)
    }

    // Solving c = m ^ d mod n
    // and m = c ^ e mod n
    pub fn crypt(m: u128, d:u128, n: u128) -> u128
    {
        let mut intermediate = m % n;
        let mut total_remainder = 1u128;

        let highest_bit_pos_of_d = highest_bit_pos(d);

        for i in 0..=highest_bit_pos_of_d
        {
            total_remainder *= if get_nth_bit(d, i) {intermediate} else {1};
            total_remainder = total_remainder % n;

            intermediate = (intermediate * intermediate) % n;
        }

        total_remainder
    }

    pub fn crypt_many(ms: Vec<u128>, d_or_e : u128, n: u128) -> Vec<u128>
    {
        ms.iter().map(|m| crypt(*m, d_or_e, n)).collect()
    }

    fn highest_bit_pos(n: u128) -> u32 {
        128 - n.leading_zeros() - 1
    }

    fn get_nth_bit(d: u128, n: u32) -> bool
    {
        (d & ((1 << n) as u128)) == (1 << n) as u128
    }
}




