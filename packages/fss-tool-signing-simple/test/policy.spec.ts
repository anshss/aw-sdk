import {
  SigningSimplePolicy,
  type SigningSimplePolicyType
} from '../src/lib/policy';

describe('SigningSimplePolicy', () => {
  const validPolicy: SigningSimplePolicyType = {
    type: 'SigningSimple',
    version: '1.0.0',
    allowedPrefixes: [
      'Hello',
      'Verify:',
      'Sign:',
    ],
  };

  describe('SigningSimplePolicy.schema', () => {
    it('should validate a correct policy', () => {
      const result = SigningSimplePolicy.schema.safeParse(validPolicy);
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
          const result = SigningSimplePolicy.schema.safeParse({
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
          const result = SigningSimplePolicy.schema.safeParse({
            ...validPolicy,
            allowedPrefixes,
          });
          expect(result.success).toBe(false);
        });
      });
    });
  });

  describe('SigningSimplePolicy.encode', () => {
    it('should encode a valid policy', () => {
      const encoded = SigningSimplePolicy.encode(validPolicy);
      expect(typeof encoded).toBe('string');
      expect(encoded.startsWith('0x')).toBe(true);
    });

    it('should throw on invalid policy', () => {
      const invalidPolicy = {
        type: 'SigningSimple' as const,
        version: '1.0.0',
        allowedPrefixes: ['invalid', null as any], // Invalid array contents
      };
      expect(() => {
        SigningSimplePolicy.encode(invalidPolicy as SigningSimplePolicyType);
      }).toThrow();
    });
  });

  describe('SigningSimplePolicy.decode', () => {
    it('should decode an encoded policy correctly', () => {
      const encoded = SigningSimplePolicy.encode(validPolicy);
      const decoded = SigningSimplePolicy.decode(encoded);
      expect(decoded).toEqual(validPolicy);
    });

    it('should throw on invalid encoded data', () => {
      const invalidEncoded = '0x1234'; // Invalid encoded data
      expect(() => {
        SigningSimplePolicy.decode(invalidEncoded);
      }).toThrow();
    });

    it('should maintain data integrity through encode/decode cycle', () => {
      const testCases: SigningSimplePolicyType[] = [
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
        const encoded = SigningSimplePolicy.encode(policy);
        const decoded = SigningSimplePolicy.decode(encoded);
        expect(decoded).toEqual(policy);
      });
    });
  });
}); 