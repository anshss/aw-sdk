import { OpenAiIntentMatcher } from './agent';

// Mock OpenAI at module level
const mockCreate = jest.fn();
jest.mock('openai', () => ({
  OpenAI: jest.fn().mockImplementation(() => ({
    chat: {
      completions: {
        create: mockCreate
      }
    }
  }))
}));

// Simplified mock interfaces
interface TransferParams {
  recipient: string;
  amount: string;
  token: string;
}

describe('OpenAiIntentMatcher', () => {
  let matcher: OpenAiIntentMatcher;
  let transferTool: any;

  beforeEach(() => {
    // Reset all mocks
    jest.clearAllMocks();
    
    matcher = new OpenAiIntentMatcher(
      'https://llama8b.gaia.domains/v1',
      'gaia',
      'llama'
    );

    transferTool = {
      name: 'Token Transfer',
      description: 'Transfer tokens from your wallet to another address',
      ipfsCid: 'QmTransferToolCID123',
      parameters: {
        type: {
          recipient: '',
          amount: '',
          token: ''
        },
        descriptions: {
          recipient: 'The recipient wallet address (must start with 0x)',
          amount: 'The amount of tokens to transfer (must be a positive number)',
          token: 'The token symbol (e.g., ETH, USDT)'
        },
        schema: {
          safeParse: (params: Partial<TransferParams>) => {
            const errors: string[] = [];
            
            // Only validate if value is present
            if (params.recipient) {
              if (!params.recipient.match(/^0x[a-fA-F0-9]{40}$/)) {
                errors.push('Invalid Ethereum address');
              }
            }
            
            if (params.amount) {
              if (!params.amount.match(/^\d*\.?\d+$/)) {
                errors.push('Must be a valid number');
              }
            }
            
            if (params.token) {
              if (!params.token.match(/^[A-Z]{2,10}$/)) {
                errors.push('Must be 2-10 uppercase letters');
              }
            }

            return {
              success: errors.length === 0,
              error: {
                issues: errors.map((message, index) => ({
                  path: [Object.keys(params)[index]],
                  message
                }))
              },
              data: errors.length === 0 ? params : null
            };
          }
        },
        validate: function(params: Partial<TransferParams>) {
          const validationResult = this.schema.safeParse(params);
          if (!validationResult.success) {
            return validationResult.error.issues.map(issue => ({
              param: issue.path[0],
              error: issue.message
            }));
          }
          return [];
        }
      },
      policy: {
        type: 'transfer'
      }
    };
  });

  describe('analyzeIntentAndMatchTool', () => {
    it('should match a valid transfer intent', async () => {
      mockCreate
        .mockResolvedValueOnce({ // First call - getToolForIntent
          choices: [{
            message: {
              content: JSON.stringify({
                recommendedCID: 'QmTransferToolCID123',
                reasoning: 'Test reasoning'
              })
            }
          }]
        })
        .mockResolvedValueOnce({ // Second call - parseToolParametersFromIntent
          choices: [{
            message: {
              content: JSON.stringify({
                foundParams: {
                  recipient: '0x742d35Cc6634C0532925a3b844Bc454e4438f44e',
                  amount: '1.5',
                  token: 'ETH'
                },
                missingParams: []
              })
            }
          }]
        });

      const intent = "I want to send 1.5 ETH to 0x742d35Cc6634C0532925a3b844Bc454e4438f44e";
      const result = await matcher.analyzeIntentAndMatchTool(intent, [transferTool]);

      expect(result.matchedTool).toBe(transferTool);
      expect(result.params.foundParams).toEqual({
        recipient: '0x742d35Cc6634C0532925a3b844Bc454e4438f44e',
        amount: '1.5',
        token: 'ETH'
      });
      expect(result.params.validationErrors).toEqual([]);
    }, 10000);

    it('should identify invalid address', async () => {
      mockCreate
        .mockResolvedValueOnce({ // First call - getToolForIntent
          choices: [{
            message: {
              content: JSON.stringify({
                recommendedCID: 'QmTransferToolCID123',
                reasoning: 'Test reasoning'
              })
            }
          }]
        })
        .mockResolvedValueOnce({ // Second call - parseToolParametersFromIntent
          choices: [{
            message: {
              content: JSON.stringify({
                foundParams: {
                  recipient: '0x123',
                  amount: '100',
                  token: 'USDT'
                },
                missingParams: []
              })
            }
          }]
        });

      const intent = "Transfer 100 USDT to 0x123";
      const result = await matcher.analyzeIntentAndMatchTool(intent, [transferTool]);

      expect(result.params.validationErrors).toBeDefined();
      expect(result.params.validationErrors).toEqual(
        expect.arrayContaining([
          expect.objectContaining({
            param: 'recipient',
            error: expect.stringContaining('Invalid')
          })
        ])
      );
    }, 10000);

    it('should handle incomplete information', async () => {
      mockCreate
        .mockResolvedValueOnce({ // First call - getToolForIntent
          choices: [{
            message: {
              content: JSON.stringify({
                recommendedCID: 'QmTransferToolCID123',
                reasoning: 'Test reasoning'
              })
            }
          }]
        })
        .mockResolvedValueOnce({ // Second call - parseToolParametersFromIntent
          choices: [{
            message: {
              content: JSON.stringify({
                foundParams: {},
                missingParams: ['recipient', 'amount', 'token']
              })
            }
          }]
        });

      const intent = "Send some tokens";
      const result = await matcher.analyzeIntentAndMatchTool(intent, [transferTool]);

      expect(result.params.missingParams).toEqual(['recipient', 'amount', 'token']);
      expect(result.params.validationErrors).toBeDefined();
      expect(Array.isArray(result.params.validationErrors)).toBe(true);
      expect(result.params.validationErrors).toHaveLength(0);
    }, 10000);
  });
});