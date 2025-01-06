export enum FssToolRegistryErrorType {
  TOOL_NOT_FOUND = 'TOOL_NOT_FOUND',
  IPFS_CID_NOT_FOUND = 'IPFS_CID_NOT_FOUND',
}

export type ErrorDetails = {
  name?: string;
  message?: string;
  stack?: string;
  type?: FssToolRegistryErrorType;
  details?: unknown;
  [key: string]: unknown;
};

export class FssToolRegistryError extends Error {
  public readonly serializedDetails: string;

  constructor(
    public readonly type: FssToolRegistryErrorType,
    message: string,
    public readonly details?: Record<string, ErrorDetails | unknown>
  ) {
    super(message);
    this.name = 'RegistryError';

    // Store a serialized version of details for better error logging
    this.serializedDetails = details
      ? JSON.stringify(
          details,
          (key, value) => {
            if (value instanceof Error) {
              return {
                name: value.name,
                message: value.message,
                stack: value.stack,
                ...(value instanceof FssToolRegistryError
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

  toJSON() {
    return {
      name: this.name,
      message: this.message,
      type: this.type,
      details: this.serializedDetails
        ? JSON.parse(this.serializedDetails)
        : undefined,
      stack: this.stack,
    };
  }
}
