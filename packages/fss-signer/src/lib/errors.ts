export enum FssSignerErrorType {
  ADMIN_MISSING_PRIVATE_KEY = 'ADMIN_MISSING_PRIVATE_KEY',
  ADMIN_MULTISIG_NOT_IMPLEMENTED = 'ADMIN_MULTISIG_NOT_IMPLEMENTED',
  INSUFFICIENT_BALANCE_PKP_MINT = 'INSUFFICIENT_BALANCE_PKP_MINT',
  INSUFFICIENT_BALANCE_CAPACITY_CREDIT_MINT = 'INSUFFICIENT_BALANCE_CAPACITY_CREDIT_MINT',
  STORAGE_FAILED_TO_GET_ITEM = 'STORAGE_FAILED_TO_GET_ITEM',
}

export type ErrorDetails = {
  name?: string;
  message?: string;
  stack?: string;
  type?: FssSignerErrorType;
  details?: unknown;
  [key: string]: unknown;
};

export class FssSignerError extends Error {
  public readonly serializedDetails: string;

  constructor(
    public readonly type: FssSignerErrorType,
    message: string,
    public readonly details?: Record<string, ErrorDetails | unknown>
  ) {
    super(message);
    this.name = 'FssSignerError';

    // Store a serialized version of details for better error logging
    this.serializedDetails = details
      ? JSON.stringify(
          details,
          (key, value) => {
            if (value instanceof Error) {
              // Handle nested errors
              return {
                name: value.name,
                message: value.message,
                stack: value.stack,
                ...(value instanceof FssSignerError
                  ? {
                      type: value.type,
                      details: value.serializedDetails
                        ? JSON.parse(value.serializedDetails)
                        : undefined,
                    }
                  : {}),
              };
            }
            return value;
          },
          2
        )
      : '';
  }

  // Override toJSON to provide better serialization
  toJSON() {
    return {
      name: this.name,
      type: this.type,
      message: this.message,
      details: this.serializedDetails
        ? JSON.parse(this.serializedDetails)
        : undefined,
      stack: this.stack,
    };
  }
}
