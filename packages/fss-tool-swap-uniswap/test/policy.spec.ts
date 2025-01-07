import { ethers } from 'ethers';

import {
  SwapUniswapPolicy,
  type SwapUniswapPolicyType
} from '../src/lib/policy';

describe('SwapUniswapPolicy', () => {
  const validPolicy: SwapUniswapPolicyType = {
    type: 'SwapUniswap',
    version: '1.0.0',
    maxAmount: ethers.utils.parseEther('1.0').toString(), // 1 ETH in wei
    allowedTokens: [
      ethers.utils.getAddress('0x1234567890123456789012345678901234567890'),
      ethers.utils.getAddress('0xabcdefabcdefabcdefabcdefabcdefabcdefabcd'),
    ],
  };

  describe('SwapUniswapPolicy.schema', () => {
    it('should validate a correct policy', () => {
      const result = SwapUniswapPolicy.schema.safeParse(validPolicy);
      expect(result.success).toBe(true);
    });

    describe('maxAmount validation', () => {
      it('should accept valid BigNumber strings', () => {
        const validAmounts = [
          '1000000000000000000', // 1 ETH in wei
          '0',
          ethers.constants.MaxUint256.toString(),
        ];

        validAmounts.forEach((maxAmount) => {
          const result = SwapUniswapPolicy.schema.safeParse({
            ...validPolicy,
            maxAmount,
          });
          expect(result.success).toBe(true);
        });
      });

      it('should reject invalid amounts', () => {
        const invalidAmounts = [
          'abc', // not a number
          'invalid',
          '1.5', // No decimals allowed in wei
          '',
          'NaN',
          'undefined',
          null as any,
          undefined as any,
          '0x', // empty hex
          '0xZ', // invalid hex
          '-1000000000000000000', // negative numbers not allowed for uint256
        ];

        invalidAmounts.forEach((maxAmount) => {
          const result = SwapUniswapPolicy.schema.safeParse({
            ...validPolicy,
            maxAmount,
          });
          expect(result.success).toBe(false);
        });
      });

      it('should reject negative numbers', () => {
        const result = SwapUniswapPolicy.schema.safeParse({
          ...validPolicy,
          maxAmount: '-1000000000000000000',
        });
        expect(result.success).toBe(false);

        // Get the error message
        if (!result.success) {
          expect(result.error.errors[0].message).toBe(
            'Invalid amount format. Must be a non-negative integer.'
          );
        }
      });
    });

    describe('allowedTokens validation', () => {
      it('should accept valid Ethereum addresses', () => {
        const result = SwapUniswapPolicy.schema.safeParse(validPolicy);
        expect(result.success).toBe(true);
      });

      it('should reject invalid Ethereum addresses', () => {
        const invalidPolicy = {
          ...validPolicy,
          allowedTokens: [
            '0x123', // too short
            '0xGGGG567890123456789012345678901234567890', // invalid hex
          ],
        };
        const result = SwapUniswapPolicy.schema.safeParse(invalidPolicy);
        expect(result.success).toBe(false);
      });

      it('should accept empty array of allowed tokens', () => {
        const result = SwapUniswapPolicy.schema.safeParse({
          ...validPolicy,
          allowedTokens: [],
        });
        expect(result.success).toBe(true);
      });

      it('should normalize address case', () => {
        const mixedCasePolicy = {
          ...validPolicy,
          allowedTokens: [
            '0x1234567890123456789012345678901234567890',
            '0xaBcDeF1234567890123456789012345678901234',
          ],
        };
        const result = SwapUniswapPolicy.schema.safeParse(mixedCasePolicy);
        expect(result.success).toBe(true);
      });
    });
  });

  describe('SwapUniswapPolicy.encode', () => {
    it('should encode a valid policy', () => {
      const encoded = SwapUniswapPolicy.encode(validPolicy);
      expect(typeof encoded).toBe('string');
      expect(encoded.startsWith('0x')).toBe(true);
    });

    it('should throw on invalid policy', () => {
      const invalidPolicy = {
        type: 'SwapUniswap' as const,
        version: '1.0.0',
        maxAmount: 'invalid',
        allowedTokens: ['0x123'], // Invalid address
      };
      expect(() => {
        SwapUniswapPolicy.encode(invalidPolicy as SwapUniswapPolicyType);
      }).toThrow();
    });
  });

  describe('SwapUniswapPolicy.decode', () => {
    it('should decode an encoded policy correctly', () => {
      const encoded = SwapUniswapPolicy.encode(validPolicy);
      const decoded = SwapUniswapPolicy.decode(encoded);

      // Compare with normalized addresses
      const normalizedPolicy = {
        ...validPolicy,
        allowedTokens: validPolicy.allowedTokens.map((addr: string) =>
          ethers.utils.getAddress(addr)
        ),
      };

      expect(decoded).toEqual(normalizedPolicy);
    });

    it('should throw on invalid encoded data', () => {
      const invalidEncoded = '0x1234'; // Invalid encoded data
      expect(() => {
        SwapUniswapPolicy.decode(invalidEncoded);
      }).toThrow();
    });

    it('should maintain data integrity through encode/decode cycle', () => {
      const testCases: SwapUniswapPolicyType[] = [
        validPolicy,
        {
          ...validPolicy,
          maxAmount: '0',
          allowedTokens: [],
        },
        {
          ...validPolicy,
          maxAmount: ethers.constants.MaxUint256.toString(),
        },
      ];

      testCases.forEach((policy) => {
        const encoded = SwapUniswapPolicy.encode(policy);
        const decoded = SwapUniswapPolicy.decode(encoded);

        // Normalize addresses in the original policy for comparison
        const normalizedPolicy = {
          ...policy,
          allowedTokens: policy.allowedTokens.map((addr) =>
            ethers.utils.getAddress(addr)
          ),
        };

        expect(decoded).toEqual(normalizedPolicy);
      });
    });
  });
}); 