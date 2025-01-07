import { SignEcdsaPolicy, type SignEcdsaPolicyType } from '../src/lib/policy';

describe('SignEcdsaPolicy', () => {
  const validPolicy: SignEcdsaPolicyType = {
    type: 'SignEcdsa',
    version: '1.0.0',
    allowedPrefixes: ['Hello', 'Verify:', 'Sign:'],
  };

  describe('SignEcdsaPolicy.schema', () => {
    it('should validate a correct policy', () => {
      const result = SignEcdsaPolicy.schema.safeParse(validPolicy);
      expect(result.success).toBe(true);
    });

    describe('allowedPrefixes validation', () => {
      it('should accept valid prefixes', () => {
        const validPrefixArrays = [
          ['Hello', 'World'],
          ['Verify:', 'Sign:'],
          [], // Empty array is valid
          ['A'.repeat(100)], // Long prefixes are okay
        ];

        validPrefixArrays.forEach((allowedPrefixes) => {
          const result = SignEcdsaPolicy.schema.safeParse({
            ...validPolicy,
            allowedPrefixes,
          });
          expect(result.success).toBe(true);
        });
      });

      it('should reject invalid prefixes', () => {
        const invalidPrefixArrays = [
          undefined,
          null,
          'not an array',
          [123], // Numbers not allowed
          [true], // Booleans not allowed
          [{}], // Objects not allowed
          [[]], // Nested arrays not allowed
        ];

        invalidPrefixArrays.forEach((allowedPrefixes) => {
          const result = SignEcdsaPolicy.schema.safeParse({
            ...validPolicy,
            allowedPrefixes,
          });
          expect(result.success).toBe(false);
        });
      });
    });
  });

  describe('SignEcdsaPolicy.encode', () => {
    it('should encode a valid policy', () => {
      const encoded = SignEcdsaPolicy.encode(validPolicy);
      expect(typeof encoded).toBe('string');
      expect(encoded.startsWith('0x')).toBe(true);
    });

    it('should throw on invalid policy', () => {
      const invalidPolicy = {
        type: 'SignEcdsa' as const,
        version: '1.0.0',
        allowedPrefixes: ['invalid', null as any], // Invalid array contents
      };
      expect(() => {
        SignEcdsaPolicy.encode(invalidPolicy as SignEcdsaPolicyType);
      }).toThrow();
    });
  });

  describe('SignEcdsaPolicy.decode', () => {
    it('should decode an encoded policy correctly', () => {
      const encoded = SignEcdsaPolicy.encode(validPolicy);
      const decoded = SignEcdsaPolicy.decode(encoded);
      expect(decoded).toEqual(validPolicy);
    });

    it('should throw on invalid encoded data', () => {
      const invalidEncoded = '0x1234'; // Invalid encoded data
      expect(() => {
        SignEcdsaPolicy.decode(invalidEncoded);
      }).toThrow();
    });

    it('should maintain data integrity through encode/decode cycle', () => {
      const testCases: SignEcdsaPolicyType[] = [
        validPolicy,
        {
          ...validPolicy,
          allowedPrefixes: [],
        },
        {
          ...validPolicy,
          allowedPrefixes: ['A'.repeat(100)],
        },
      ];

      testCases.forEach((policy) => {
        const encoded = SignEcdsaPolicy.encode(policy);
        const decoded = SignEcdsaPolicy.decode(encoded);
        expect(decoded).toEqual(policy);
      });
    });
  });
});
