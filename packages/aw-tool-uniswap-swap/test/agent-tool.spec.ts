import type { UniswapSwapLitActionParameters } from '../src/lib/tool';
import { UniswapSwap } from '../src/lib/tool';

describe('UniswapSwap', () => {
  const validParams: UniswapSwapLitActionParameters = {
    tokenIn: '0x1234567890123456789012345678901234567890',
    tokenOut: '0xabcdefabcdefabcdefabcdefabcdefabcdefabcd',
    amountIn: '1.5',
    chainId: '1',
    rpcUrl: 'https://eth-mainnet.example.com',
  };

  describe('UniswapSwap.parameters.schema', () => {
    it('should validate correct parameters', () => {
      const result = UniswapSwap.parameters.schema.safeParse(validParams);
      expect(result.success).toBe(true);
    });

    describe('tokenIn validation', () => {
      it('should reject invalid Ethereum addresses', () => {
        const invalidTokens = [
          '0x123', // too short
          '0xGGGG567890123456789012345678901234567890', // invalid hex
          '1234567890123456789012345678901234567890', // missing 0x prefix
          '0x12345678901234567890123456789012345678901', // too long
        ];

        invalidTokens.forEach((tokenIn) => {
          const result = UniswapSwap.parameters.schema.safeParse({
            ...validParams,
            tokenIn,
          });
          expect(result.success).toBe(false);
        });
      });
    });

    describe('tokenOut validation', () => {
      it('should reject invalid Ethereum addresses', () => {
        const invalidTokens = [
          '0x123', // too short
          '0xGGGGdefabcdefabcdefabcdefabcdefabcdefabcd', // invalid hex
          'abcdefabcdefabcdefabcdefabcdefabcdefabcd', // missing 0x prefix
          '0xabcdefabcdefabcdefabcdefabcdefabcdefabcde', // too long
        ];

        invalidTokens.forEach((tokenOut) => {
          const result = UniswapSwap.parameters.schema.safeParse({
            ...validParams,
            tokenOut,
          });
          expect(result.success).toBe(false);
        });
      });
    });

    describe('amountIn validation', () => {
      it('should accept valid decimal numbers as strings', () => {
        const validAmounts = ['1.5', '100', '0.01', '1000.55555'];

        validAmounts.forEach((amountIn) => {
          const result = UniswapSwap.parameters.schema.safeParse({
            ...validParams,
            amountIn,
          });
          expect(result.success).toBe(true);
        });
      });

      it('should reject invalid amounts', () => {
        const invalidAmounts = [
          'abc', // not a number
          '1.2.3', // multiple decimals
          '-1.5', // negative numbers
          '1,5', // wrong decimal separator
          '', // empty string
        ];

        invalidAmounts.forEach((amountIn) => {
          const result = UniswapSwap.parameters.schema.safeParse({
            ...validParams,
            amountIn,
          });
          expect(result.success).toBe(false);
        });
      });
    });

    describe('chainId validation', () => {
      it('should accept valid chain IDs', () => {
        const validChainIds = ['1', '8453', '42161'];

        validChainIds.forEach((chainId) => {
          const result = UniswapSwap.parameters.schema.safeParse({
            ...validParams,
            chainId,
          });
          expect(result.success).toBe(true);
        });
      });

      it('should reject invalid chain IDs', () => {
        const invalidChainIds = [
          'abc', // not a number
          '1.5', // decimal
          '-1', // negative
          '', // empty string
        ];

        invalidChainIds.forEach((chainId) => {
          const result = UniswapSwap.parameters.schema.safeParse({
            ...validParams,
            chainId,
          });
          expect(result.success).toBe(false);
        });
      });
    });

    describe('rpcUrl validation', () => {
      it('should accept valid HTTPS URLs', () => {
        const validUrls = [
          'https://eth-mainnet.example.com',
          'https://base-sepolia-rpc.publicnode.com',
          'https://arbitrum-mainnet.infura.io/v3/123',
        ];

        validUrls.forEach((rpcUrl) => {
          const result = UniswapSwap.parameters.schema.safeParse({
            ...validParams,
            rpcUrl,
          });
          expect(result.success).toBe(true);
        });
      });

      it('should reject invalid URLs', () => {
        const invalidUrls = [
          'not a url',
          'http://insecure.com', // not HTTPS
          'ftp://wrong-protocol.com',
          '', // empty string
        ];

        invalidUrls.forEach((rpcUrl) => {
          const result = UniswapSwap.parameters.schema.safeParse({
            ...validParams,
            rpcUrl,
          });
          expect(result.success).toBe(false);
        });
      });
    });
  });

  describe('UniswapSwap.parameters.validate', () => {
    it('should return true for valid parameters', () => {
      expect(UniswapSwap.parameters.validate(validParams)).toBe(true);
    });

    it('should return array of errors for invalid parameters', () => {
      const invalidParams = [
        {
          ...validParams,
          tokenIn: '0x123', // invalid address
        },
        {
          ...validParams,
          amountIn: 'abc', // invalid amount
        },
        {
          tokenIn: validParams.tokenIn,
          // missing parameters
        },
        null,
        undefined,
        'not an object',
        [],
      ];

      invalidParams.forEach((params) => {
        const result = UniswapSwap.parameters.validate(params);
        expect(Array.isArray(result)).toBe(true);
        if (Array.isArray(result)) {
          expect(result.length).toBeGreaterThan(0);
          expect(result[0]).toMatchObject({
            error: expect.any(String),
          });
          // param field may be undefined for some validation errors
          if (result[0].param !== undefined) {
            expect(typeof result[0].param).toBe('string');
          }
        }
      });
    });
  });

  describe('UniswapSwap metadata', () => {
    it('should have the correct structure', () => {
      expect(UniswapSwap).toMatchObject({
        name: expect.any(String),
        description: expect.any(String),
        parameters: expect.any(Object),
      });
    });

    it('should have descriptions for all parameters', () => {
      const params = Object.keys(UniswapSwap.parameters.descriptions);
      const required = ['tokenIn', 'tokenOut', 'amountIn', 'chainId', 'rpcUrl'];
      expect(params.sort()).toEqual(required.sort());
    });
  });
});
