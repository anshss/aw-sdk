import { ethers } from 'ethers';

import {
  SendERC20Policy,
  SendERC20PolicySchema,
  encodeSendERC20Policy,
  decodeSendERC20Policy,
} from './policy';

describe('SendERC20Policy', () => {
  const validPolicy: SendERC20Policy = {
    type: 'SendERC20',
    version: '1.0.0',
    maxAmount: ethers.utils.parseEther('1.0').toString(), // 1 ETH in wei
    allowedTokens: [
      ethers.utils.getAddress('0x1234567890123456789012345678901234567890'),
      ethers.utils.getAddress('0xabcdefabcdefabcdefabcdefabcdefabcdefabcd'),
    ],
    allowedRecipients: [
      ethers.utils.getAddress('0x2234567890123456789012345678901234567890'),
      ethers.utils.getAddress('0xbbcdefabcdefabcdefabcdefabcdefabcdefabcd'),
    ],
  };

  describe('SendERC20PolicySchema', () => {
    it('should validate a correct policy', () => {
      const result = SendERC20PolicySchema.safeParse(validPolicy);
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
          const result = SendERC20PolicySchema.safeParse({
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
          const result = SendERC20PolicySchema.safeParse({
            ...validPolicy,
            maxAmount,
          });
          expect(result.success).toBe(false);
        });
      });

      it('should reject negative numbers', () => {
        const result = SendERC20PolicySchema.safeParse({
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
        const result = SendERC20PolicySchema.safeParse(validPolicy);
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
        const result = SendERC20PolicySchema.safeParse(invalidPolicy);
        expect(result.success).toBe(false);
      });

      it('should accept empty array of allowed tokens', () => {
        const result = SendERC20PolicySchema.safeParse({
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
        const result = SendERC20PolicySchema.safeParse(mixedCasePolicy);
        expect(result.success).toBe(true);
      });
    });

    describe('allowedRecipients validation', () => {
      it('should accept valid Ethereum addresses', () => {
        const result = SendERC20PolicySchema.safeParse(validPolicy);
        expect(result.success).toBe(true);
      });

      it('should reject invalid Ethereum addresses', () => {
        const invalidPolicy = {
          ...validPolicy,
          allowedRecipients: [
            '0x123', // too short
            '0xGGGG567890123456789012345678901234567890', // invalid hex
          ],
        };
        const result = SendERC20PolicySchema.safeParse(invalidPolicy);
        expect(result.success).toBe(false);
      });

      it('should accept empty array of allowed recipients', () => {
        const result = SendERC20PolicySchema.safeParse({
          ...validPolicy,
          allowedRecipients: [],
        });
        expect(result.success).toBe(true);
      });

      it('should normalize address case', () => {
        const mixedCasePolicy = {
          ...validPolicy,
          allowedRecipients: [
            '0x1234567890123456789012345678901234567890',
            '0xaBcDeF1234567890123456789012345678901234',
          ],
        };
        const result = SendERC20PolicySchema.safeParse(mixedCasePolicy);
        expect(result.success).toBe(true);
      });
    });
  });

  describe('encodeSendERC20Policy', () => {
    it('should encode a valid policy', () => {
      const encoded = encodeSendERC20Policy(validPolicy);
      expect(typeof encoded).toBe('string');
      expect(encoded.startsWith('0x')).toBe(true);
    });

    it('should throw on invalid policy', () => {
      const invalidPolicy = {
        ...validPolicy,
        maxAmount: 'invalid',
      };
      expect(() => {
        encodeSendERC20Policy(invalidPolicy);
      }).toThrow();
    });
  });

  describe('decodeSendERC20Policy', () => {
    it('should decode an encoded policy correctly', () => {
      const encoded = encodeSendERC20Policy(validPolicy);
      const decoded = decodeSendERC20Policy(encoded, validPolicy.version);

      // Compare with normalized addresses
      const normalizedPolicy = {
        ...validPolicy,
        allowedTokens: validPolicy.allowedTokens.map((addr) =>
          ethers.utils.getAddress(addr)
        ),
        allowedRecipients: validPolicy.allowedRecipients.map((addr) =>
          ethers.utils.getAddress(addr)
        ),
      };

      expect(decoded).toEqual(normalizedPolicy);
    });

    it('should throw on invalid encoded data', () => {
      const invalidEncoded = '0x1234'; // Invalid encoded data
      expect(() => {
        decodeSendERC20Policy(invalidEncoded, '1.0.0');
      }).toThrow();
    });

    it('should maintain data integrity through encode/decode cycle', () => {
      const testCases: SendERC20Policy[] = [
        validPolicy,
        {
          ...validPolicy,
          maxAmount: '0',
          allowedTokens: [],
          allowedRecipients: [],
        },
        {
          ...validPolicy,
          maxAmount: ethers.constants.MaxUint256.toString(),
        },
      ];

      testCases.forEach((policy) => {
        const encoded = encodeSendERC20Policy(policy);
        const decoded = decodeSendERC20Policy(encoded, policy.version);

        // Normalize addresses in the original policy for comparison
        const normalizedPolicy = {
          ...policy,
          allowedTokens: policy.allowedTokens.map((addr) =>
            ethers.utils.getAddress(addr)
          ),
          allowedRecipients: policy.allowedRecipients.map((addr) =>
            ethers.utils.getAddress(addr)
          ),
        };

        expect(decoded).toEqual(normalizedPolicy);
      });
    });
  });
});
