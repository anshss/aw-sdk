import type { SignEcdsaLitActionParameters } from '../src/lib/tool';
import { SignEcdsa } from '../src/lib/tool';

describe('SignEcdsa', () => {
  const validParams: SignEcdsaLitActionParameters = {
    message: 'Hello World',
  };

  describe('SignEcdsa.parameters.schema', () => {
    it('should validate correct parameters', () => {
      const result = SignEcdsa.parameters.schema.safeParse(validParams);
      expect(result.success).toBe(true);
    });

    describe('message validation', () => {
      it('should accept valid messages', () => {
        const validMessages = [
          'Hello World',
          'Verify: 0x1234...',
          '', // Empty string is technically valid
          'A'.repeat(1000), // Long messages are okay
        ];

        validMessages.forEach((message) => {
          const result = SignEcdsa.parameters.schema.safeParse({
            message,
          });
          expect(result.success).toBe(true);
        });
      });

      it('should reject invalid messages', () => {
        const invalidMessages = [undefined, null, 123, true, {}, []];

        invalidMessages.forEach((message) => {
          const result = SignEcdsa.parameters.schema.safeParse({
            message,
          });
          expect(result.success).toBe(false);
        });
      });
    });
  });

  describe('SignEcdsa.parameters.validate', () => {
    it('should return true for valid parameters', () => {
      expect(SignEcdsa.parameters.validate(validParams)).toBe(true);
    });

    it('should return array of errors for invalid parameters', () => {
      const invalidParams = [
        {
          // Missing message
        },
        {
          message: 123, // Wrong type
        },
        null,
        undefined,
        'not an object',
        [],
      ];

      invalidParams.forEach((params) => {
        const result = SignEcdsa.parameters.validate(params);
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

  describe('SignEcdsa metadata', () => {
    it('should have the correct structure', () => {
      expect(SignEcdsa).toMatchObject({
        name: expect.any(String),
        description: expect.any(String),
        parameters: expect.any(Object),
      });
    });

    it('should have descriptions for all parameters', () => {
      const params = Object.keys(SignEcdsa.parameters.descriptions);
      const required = ['message'];
      expect(params.sort()).toEqual(required.sort());
    });
  });
});
